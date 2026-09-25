import Foundation
import Testing
import KollioCore
@testable import KollioServerKit

/// Records the exact bytes the provider would put on the wire, and answers with
/// a canned completion. No network, no key, no Groq account.
///
/// The recorded body is class-level state, because `URLProtocol` is registered
/// per session and instantiates its own object. The suite that uses this is
/// therefore `.serialized`: the tests must not read each other's bytes.
final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var storedRequest: URLRequest?
    nonisolated(unsafe) private static var storedBody: Data?
    nonisolated(unsafe) static var statusCode: Int = 200
    nonisolated(unsafe) static var completion: String = "{}"

    static var lastRequest: URLRequest? { lock.withLock { storedRequest } }
    static var lastBody: Data? { lock.withLock { storedBody } }

    static func reset(statusCode: Int = 200, completion: String) {
        lock.withLock {
            self.statusCode = statusCode
            self.completion = completion
            storedRequest = nil
            storedBody = nil
        }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        // The body arrives as a stream by this point, so it is read here: this is
        // what the server would actually transmit.
        var body = request.httpBody
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            let size = 4096
            var buffer = [UInt8](repeating: 0, count: size)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: size)
                if read <= 0 { break }
                data.append(contentsOf: buffer[0..<read])
            }
            stream.close()
            body = data
        }
        let (status, payload) = Self.lock.withLock { () -> (Int, String) in
            Self.storedRequest = request
            Self.storedBody = body
            return (Self.statusCode, Self.completion)
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(payload.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

/// Wraps a candidate the way a chat completion does, so the provider sees the
/// real shape rather than a hand-escaped string.
private func chatCompletion(containing candidate: ProviderCandidate) throws -> String {
    struct Envelope: Encodable {
        struct Choice: Encodable {
            struct Message: Encodable { var content: String }
            var message: Message
        }
        var choices: [Choice]
    }
    // A chat completion's `content` is a string holding the model's JSON. The
    // envelope encoder does that escaping for us.
    let inner = String(decoding: try JSONEncoder().encode(candidate), as: UTF8.self)
    let envelope = Envelope(choices: [.init(message: .init(content: inner))])
    return String(decoding: try JSONEncoder().encode(envelope), as: UTF8.self)
}

private func sendableRequest(_ document: KollioDocument, target: ObjectID = "object:ctx") throws -> ProposalRequest {
    let snapshot = try document.snapshot(targeting: [target])
    return ProposalRequest(
        requestId: "req-fixed-id",
        documentId: document.documentId,
        baseSemanticRevision: document.semanticRevision,
        intent: .explore,
        targetIds: [target],
        contentLocale: "en",
        snapshot: snapshot
    )
}

/// Serialized because the transport records the transmitted bytes in
/// class-level state: a parallel test would read another test's body.
@Suite("Provider wire contract", .serialized)
struct ProviderWireTests {
    private func document() -> KollioDocument {
        var builder = DocumentBuilder()
        let ctx = builder.object("ctx", kind: .context, "Recover the list", en: "Recover the list", at: .zero)!
        let alt = builder.object("alt", kind: .hypothesis, "Direct", en: "Direct", at: Position(x: 0, y: 200))!
        _ = builder.link("l1", from: ctx, to: alt, .alternativeTo)
        return builder.document
    }

    @Test("The request body uses the documented response_format field")
    func usesDocumentedFieldName() async throws {
        URLProtocolStub.reset(completion: try chatCompletion(containing: .init(outcome: .noChange)))
        let provider = GroqProvider(apiKey: "test-key-not-a-secret", session: URLProtocolStub.makeSession())
        _ = try? await provider.complete(try sendableRequest(document()), document: document())

        let body = try #require(URLProtocolStub.lastBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        // The old code sent "responseFormat", which the API does not accept.
        #expect(json["response_format"] != nil)
        #expect(json["responseFormat"] == nil)
        let format = try #require(json["response_format"] as? [String: Any])
        #expect(format["type"] as? String == "json_schema")
        let schema = try #require(format["json_schema"] as? [String: Any])
        #expect(schema["strict"] as? Bool == true)
        #expect(schema["name"] as? String == "kollio_proposal_candidate")
    }

    @Test("The schema sent on the wire describes the candidate that is decoded")
    func schemaMatchesDecoder() async throws {
        URLProtocolStub.reset(completion: try chatCompletion(containing: .init(outcome: .noChange)))
        let provider = GroqProvider(apiKey: "test-key-not-a-secret", session: URLProtocolStub.makeSession())
        _ = try? await provider.complete(try sendableRequest(document()), document: document())

        let body = try #require(URLProtocolStub.lastBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let format = try #require(json["response_format"] as? [String: Any])
        let wrapper = try #require(format["json_schema"] as? [String: Any])
        let schema = try #require(wrapper["schema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: Any])

        // Every key the decoder requires is declared, and nothing is optional:
        // strict mode rejects a schema that is not exhaustive.
        for key in ["outcome", "rationale", "questions", "summary", "objects", "relations"] {
            #expect(properties[key] != nil, "schema is missing \(key)")
        }
        let required = try #require(schema["required"] as? [String])
        #expect(required.count == 6)
        #expect(schema["additionalProperties"] as? Bool == false)

        // The candidate really does decode with exactly these keys.
        let candidate = try JSONDecoder().decode(ProviderCandidate.self, from: Data(#"{"outcome":"noChange","rationale":"","questions":[],"summary":"","objects":[],"relations":[]}"#.utf8))
        #expect(candidate.outcome == .noChange)
    }

    @Test("A valid candidate becomes a proposal the server signed")
    func validCandidateBecomesAProposal() async throws {
        let candidate = ProviderCandidate(
            outcome: .proposal,
            rationale: "Two directions worth comparing.",
            summary: "Compare the two routes",
            objects: [
                .init(ref: "n1", kind: "hypothesis", text: "Ask Demand directly", detail: "One email, low effort"),
                .init(ref: "n2", kind: "constraint", text: "Demand needs a new token", detail: nil)
            ],
            relations: [
                .init(from: "object:ctx", to: "n1", kind: "alternativeTo", label: "instead of"),
                .init(from: "n1", to: "n2", kind: "constrains", label: nil)
            ]
        )
        // Built with an encoder, so the escaping is the real wire format rather
        // than something hand-written and easy to get wrong.
        let completion = try chatCompletion(containing: candidate)
        URLProtocolStub.reset(completion: completion)
        let doc = document()
        let provider = GroqProvider(apiKey: "test-key-not-a-secret", session: URLProtocolStub.makeSession())
        let result = try await provider.complete(try sendableRequest(doc), document: doc)

        guard case .proposal(let proposal) = result else {
            Issue.record("expected a proposal, got \(result)")
            return
        }
        // The server, not the model, decides identity and association.
        #expect(proposal.requestId == "req-fixed-id")
        #expect(proposal.documentId == doc.documentId)
        #expect(proposal.baseSemanticRevision == doc.semanticRevision)
        #expect(proposal.generator.name == "groq")
        #expect(proposal.operations.count == 4)
        // The model's own "ref" never becomes an id.
        let createdIDs = proposal.operations.compactMap { operation -> ObjectID? in
            guard case .createObject(let create) = operation else { return nil }
            return create.id
        }
        #expect(createdIDs.contains { $0.rawValue == "n1" } == false)
    }

    @Test("Missing fields are rejected, not half-applied")
    func missingFields() async throws {
        // A truncated object: the candidate cannot be decoded at all.
        URLProtocolStub.reset(completion: #"{"choices":[{"message":{"content":"{\"outcome\":\"proposal\""}}]}"#)
        let doc = document()
        let provider = GroqProvider(apiKey: "test-key-not-a-secret", session: URLProtocolStub.makeSession())
        let result = try await provider.complete(try sendableRequest(doc), document: doc)
        guard case .malformed = result else {
            Issue.record("expected malformed, got \(result)")
            return
        }
    }

    @Test("Truncated output is rejected")
    func truncatedOutput() async throws {
        URLProtocolStub.reset(completion: #"{"choices":[{"message":{"content":"{\"outcome\":\"proposal\",\"objects\":[{\"ref\":"}}]}"#)
        let doc = document()
        let provider = GroqProvider(apiKey: "test-key-not-a-secret", session: URLProtocolStub.makeSession())
        let result = try await provider.complete(try sendableRequest(doc), document: doc)
        guard case .malformed = result else {
            Issue.record("expected malformed, got \(result)")
            return
        }
    }

    @Test("A quota error is a transport fault, not a malformed answer")
    func quotaError() async throws {
        URLProtocolStub.reset(statusCode: 429, completion: #"{"error":{"message":"rate limit exceeded"}}"#)
        let doc = document()
        let provider = GroqProvider(apiKey: "test-key-not-a-secret", session: URLProtocolStub.makeSession())
        do {
            _ = try await provider.complete(try sendableRequest(doc), document: doc)
            Issue.record("a 429 must not be reported as a successful answer")
        } catch {
            // Expected: the caller maps this to providerUnavailable.
        }
    }

    @Test("A provider without a key stays disabled")
    func disabledWithoutKey() async throws {
        let provider = GroqProvider(apiKey: nil)
        #expect(provider.isEnabled == false)
        do {
            _ = try await provider.complete(try sendableRequest(document()), document: document())
            Issue.record("a provider without a key must refuse to answer")
        } catch {
            // Expected.
        }
    }

    @Test("An unknown reference is dropped, and the rest of the answer survives")
    func unknownReferenceIsDropped() throws {
        let doc = document()
        let request = try sendableRequest(doc)
        let candidate = ProviderCandidate(
            outcome: .proposal,
            rationale: "Mixed quality.",
            objects: [.init(ref: "n1", kind: "hypothesis", text: "Real one")],
            relations: [
                .init(from: "object:ctx", to: "n1", kind: "alternativeTo"),
                .init(from: "object:does-not-exist", to: "n1", kind: "supports")
            ]
        )
        let outcome = CandidateAssembler().assemble(
            candidate, request: request, document: doc, providerName: "groq", deterministic: false
        )
        guard case .proposal(let proposal) = outcome.result else {
            Issue.record("the valid relation should have survived")
            return
        }
        #expect(outcome.droppedReferences == 1)
        // One object, one valid relationship.
        #expect(proposal.operations.count == 2)
    }

    @Test("An unknown kind is dropped rather than invented")
    func unknownKindIsDropped() throws {
        let doc = document()
        let request = try sendableRequest(doc)
        let candidate = ProviderCandidate(
            outcome: .proposal,
            objects: [.init(ref: "n1", kind: "not-a-kind", text: "Nope")]
        )
        let outcome = CandidateAssembler().assemble(
            candidate, request: request, document: doc, providerName: "groq", deterministic: false
        )
        #expect(outcome.droppedUnknownKinds == 1)
        // Nothing usable, so it is reported honestly as no change rather than as
        // an empty branch the user has to dismiss.
        guard case .noChange = outcome.result else {
            Issue.record("an empty proposal must be reported as noChange")
            return
        }
    }

    @Test("A refusal is passed through as a refusal")
    func refusalPassesThrough() throws {
        let doc = document()
        let request = try sendableRequest(doc)
        let candidate = ProviderCandidate(outcome: .refused, rationale: "I will not upload this.")
        let outcome = CandidateAssembler().assemble(
            candidate, request: request, document: doc, providerName: "groq", deterministic: false
        )
        guard case .refused(let reason) = outcome.result else {
            Issue.record("expected a refusal")
            return
        }
        #expect(reason == "I will not upload this.")
    }

    @Test("A timeout is a timeout")
    func timeout() async throws {
        // A provider that never answers, so the deadline is what ends it.
        struct SilentProvider: LLMProvider {
            let name = "silent"
            let isEnabled = true
            func complete(_ request: ProposalRequest, document: KollioDocument) async throws -> ProviderResult {
                try await Task.sleep(for: .seconds(60))
                return .noChange
            }
        }
        let doc = document()
        let service = ProposalService(provider: SilentProvider(), timeout: .milliseconds(80))
        do {
            _ = try await service.respond(to: try sendableRequest(doc), document: doc)
            Issue.record("a provider that never answers must time out")
        } catch let error as ProposalService.Rejection {
            guard case .timedOut = error else {
                Issue.record("expected a timeout, got \(error)")
                return
            }
        }
    }
}
