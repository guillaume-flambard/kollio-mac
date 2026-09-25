import Foundation
import Testing
import Vapor
import XCTVapor
import KollioCore
import KollioServerKit
@testable import KollioApp

/// The server-backed flow, end to end.
///
/// A request goes through the real routes with the real token, comes back as
/// real HTTP, and is then decoded and validated by the real client. The only
/// step not exercised here is URLSession's own socket handling.
@Suite("Server-backed flow")
struct ServerBackedTests {
    private static let token = "server-backed-test-token"

    private static let document: KollioDocument = {
        var builder = DocumentBuilder()
        let context = builder.object(
            "ctx", kind: .context,
            "Récupérer la liste des prospects sans dépendre du CRM",
            en: "Recover the prospect list without depending on the CRM",
            at: Position(x: 0, y: 0)
        )!
        let csv = builder.object(
            "csv", kind: .hypothesis, "Export CSV depuis l’outil source", en: "CSV export from the source tool",
            at: Position(x: 240, y: 200)
        )!
        _ = builder.link("l1", from: context, to: csv, .alternativeTo)
        return builder.document
    }()

    private static func makeApp() async throws -> Application {
        let app = try await Application.make(.testing)
        let configuration = ServerConfiguration(environment: ["KOLLIO_API_TOKEN": token])
        let server = KollioServer(
            configuration: configuration,
            provider: DemoProvider(),
            documentProvider: { Self.document }
        )
        try server.configure(app)
        return app
    }

    private func call(
        app: Application,
        _ path: String,
        method: HTTPMethod = .GET,
        token: String,
        body: Data? = nil
    ) async throws -> (status: Int, data: Data) {
        var headers = HTTPHeaders()
        headers.contentType = .json
        if !token.isEmpty { headers.add(name: .authorization, value: "Bearer \(token)") }
        let request = TestingHTTPRequest(
            method: method,
            url: URI(path: path),
            headers: headers,
            body: body.map { ByteBuffer(data: $0) } ?? ByteBuffer()
        )
        let response = try await app.testable().performTest(request: request)
        return (Int(response.status.code), Data(response.body.readableBytesView))
    }

    private func client(token: String) -> RemoteSuggestionService {
        RemoteSuggestionService(baseURL: URL(string: "http://127.0.0.1:8080")!, token: token)
    }

    private func request(locale: String = "en") -> ProposalRequest {
        ProposalRequest(
            requestId: UUID().uuidString,
            documentId: Self.document.documentId,
            baseSemanticRevision: Self.document.semanticRevision,
            intent: .explore,
            targetIds: ["object:csv"],
            contentLocale: locale
        )
    }

    @Test("A client request reaches the server and comes back as a validated proposal")
    func clientToServerAndBack() async throws {
        let app = try await Self.makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        let document = Self.document
        let outgoing = request()

        let answer = try await call(
            app: app,
            "/v1/proposals",
            method: .POST,
            token: Self.token,
            body: try JSONEncoder.kollioWire.encode(outgoing)
        )
        #expect(answer.status == 200)

        let response = try client(token: Self.token)
            .decode(answer.data, statusCode: answer.status, for: outgoing, document: document)
        #expect(response.status == .proposed)
        let proposal = try #require(response.proposal)
        #expect(proposal.generator.name == "demo")
        #expect(proposal.operations.contains { if case .createObject = $0 { return true }; return false })

        // And the proposal applies locally, unchanged, as one transaction.
        var session = KollioSession(document: document)
        let applied = session.apply([.applyProposal(.init(
            proposal: proposal,
            placements: [:],
            provenance: .human("local-user")
        ))], label: "keep")
        #expect(applied)
        #expect(session.document.content.count > document.content.count)
        let undone = session.undo()
        #expect(undone)
        #expect(session.document == document)
    }

    @Test("The same request in French and in English is answered by the server")
    func bothLanguages() async throws {
        let app = try await Self.makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        for locale in ["fr", "en"] {
            let outgoing = request(locale: locale)
            let answer = try await call(
                app: app,
                "/v1/proposals",
                method: .POST,
                token: Self.token,
                body: try JSONEncoder.kollioWire.encode(outgoing)
            )
            #expect(answer.status == 200)
        }
    }

    @Test("A request computed on a revision that no longer exists is refused")
    func staleIsRejected() async throws {
        let app = try await Self.makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        var movedOn = Self.document
        movedOn.semanticRevision += 1
        let outgoing = request()
        let answer = try await call(
            app: app,
            "/v1/proposals",
            method: .POST,
            token: Self.token,
            body: try JSONEncoder.kollioWire.encode(outgoing)
        )
        // The server had no way to know: it is not authoritative for the
        // document. The client's own validation is the last gate, and it refuses
        // a proposal computed against a revision that no longer exists.
        do {
            _ = try client(token: Self.token)
                .decode(answer.data, statusCode: answer.status, for: outgoing, document: movedOn)
            Issue.record("A proposal computed on a dead revision must be refused")
        } catch RemoteSuggestionService.ClientError.rejected(let reason) {
            #expect(reason.contains("baseSemanticRevision"))
        } catch {
            Issue.record("Expected the client to refuse the proposal, got \(error)")
        }
    }

    @Test("An unknown token never reaches a provider")
    func unauthorized() async throws {
        let app = try await Self.makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        let outgoing = request()
        let answer = try await call(
            app: app,
            "/v1/proposals",
            method: .POST,
            token: "not-the-token",
            body: try JSONEncoder.kollioWire.encode(outgoing)
        )
        #expect(answer.status == 401)
        do {
            _ = try client(token: "not-the-token")
                .decode(answer.data, statusCode: answer.status, for: outgoing, document: Self.document)
            Issue.record("An unknown token must be rejected")
        } catch RemoteSuggestionService.ClientError.unauthorized {
            // expected
        }
    }

    @Test("Capabilities come back from the server for an authenticated client")
    func capabilities() async throws {
        let app = try await Self.makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        let answer = try await call(app: app, "/v1/capabilities", token: Self.token)
        #expect(answer.status == 200)
        let json = try JSONDecoder().decode([String: String].self, from: answer.data)
        #expect(json["generator"] == "demo")
    }
}
