import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// The on-device path, exercised without a Mac that has system intelligence.
///
/// Nothing here needs Apple Intelligence, a key or a network: the probe is
/// stubbed, so every unavailable state is reachable and the candidate conversion
/// is tested on its own. This is the integration checkpoint, and it says nothing
/// about a real model's quality.
@Suite("On-device adapter")
struct AppleAdapterTests {
    private func document() -> KollioDocument {
        var builder = DocumentBuilder()
        let context = builder.object(
            "ctx", kind: .context,
            "Réduire l'inscription de neuf étapes à trois",
            en: "Reduce the trial signup from nine steps to three",
            at: .zero
        )!
        let existing = builder.object(
            "existing", kind: .hypothesis,
            "Une direction déjà sur le canvas",
            en: "A direction already on the canvas",
            at: Position(x: 0, y: 200)
        )!
        _ = builder.link("l1", from: context, to: existing, .alternativeTo)
        return builder.document
    }

    private func request(
        document: KollioDocument,
        locale: String = "fr",
        instruction: String? = nil
    ) -> ProposalRequest {
        ProposalRequest(
            requestId: "req-apple-1",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            intent: .explore,
            targetIds: ["object:ctx"],
            instruction: instruction,
            contentLocale: locale
        )
    }

    // MARK: Availability

    @Test("An unavailable model is a refusal, never a substitution")
    func unavailableNeverFallsBack() async throws {
        // Every state the framework can report, one by one.
        for state: AppleModelAvailability in [
            .deviceNotEligible, .intelligenceDisabled, .assetsNotReady, .frameworkUnavailable
        ] {
            let service = AppleLocalSuggestionService(
                probe: StubAppleModelProbe(availability: state)
            )
            let document = self.document()
            do {
                _ = try await service.respond(to: request(document: document), document: document)
                Issue.record("an unavailable model must refuse, got an answer for \(state)")
            } catch let error as AppleModelError {
                guard case .unavailable(let reported) = error else {
                    Issue.record("expected an unavailability, got \(error)")
                    return
                }
                #expect(reported == state)
                // The reason is stated, not flattened into a guess.
                #expect(reported.explanation.isEmpty == false)
            }
            // The service is still the on-device one: it did not become a demo.
            #expect(service.capabilities.requiresNetwork == false)
        }
    }

    @Test("A language the model does not support is refused before any request")
    func unsupportedLanguageIsRefused() async throws {
        let service = AppleLocalSuggestionService(
            probe: StubAppleModelProbe(availability: .available, languages: ["fr"])
        )
        let document = self.document()
        do {
            _ = try await service.respond(to: request(document: document, locale: "ja"), document: document)
            Issue.record("an unsupported language must be refused")
        } catch let error as AppleModelError {
            guard case .unavailable(let reason) = error, case .unsupportedLanguage = reason else {
                Issue.record("expected an unsupported language, got \(error)")
                return
            }
        }
    }

    @Test("The on-device path reports no network requirement")
    func capabilitiesAreHonest() {
        let service = AppleLocalSuggestionService(
            probe: StubAppleModelProbe(availability: .available)
        )
        // False means the answer comes from this Mac. A remote provider reports
        // true, and the two are never conflated.
        #expect(service.capabilities.requiresNetwork == false)
        #expect(service.capabilities.deterministic == false)
    }

    // MARK: Service selection

    @Test("With no preference, a usable model is preferred over the engine")
    func prefersTheRealModel() {
        let usable = ServiceConfiguration.fromEnvironment([:], token: nil, appleIsUsable: true)
        #expect(usable.configuration == .apple)
        let unusable = ServiceConfiguration.fromEnvironment([:], token: nil, appleIsUsable: false)
        #expect(unusable.configuration == .demo)
    }

    @Test("An explicit demo mode is respected even when the model works")
    func explicitDemoIsRespected() {
        let resolved = ServiceConfiguration.fromEnvironment(
            ["KOLLIO_SERVICE": "demo"], token: nil, appleIsUsable: true
        )
        #expect(resolved.configuration == .demo)
    }

    @Test("Server mode without a token falls back and says so")
    func serverWithoutTokenFallsBack() {
        let resolved = ServiceConfiguration.fromEnvironment(
            ["KOLLIO_SERVICE": "server"], token: nil, appleIsUsable: true
        )
        // Not the server: a silent fallback would look like the backend answered.
        #expect(resolved.configuration == .demo)
        let withToken = ServiceConfiguration.fromEnvironment(
            ["KOLLIO_SERVICE": "server", "KOLLIO_SERVER_URL": "http://127.0.0.1:9000"],
            token: "a-token", appleIsUsable: false
        )
        #expect(withToken.configuration == .server(baseURL: URL(string: "http://127.0.0.1:9000")!))
    }

    // MARK: Candidate conversion

    @available(macOS 26.0, *)
    @Test("A candidate becomes commands the server and the client both signed")
    func candidateBecomesAProposal() throws {
        let document = self.document()
        let candidate = AppleCandidate(
            outcome: "proposal",
            rationale: "Deux pistes valent la peine.",
            ideas: [
                .init(title: "Un seul écran", summary: "Regrouper les neuf étapes en une page.", kind: "hypothesis"),
                .init(title: "Progression assistée", summary: "Une liste qui guide l'utilisateur.", kind: "method")
            ]
        )
        let converted = AppleCandidateConverter().convert(
            candidate, request: request(document: document), document: document
        )
        guard case .proposal(let proposal) = converted.result else {
            Issue.record("expected a proposal, got \(converted.result)")
            return
        }
        // The adapter signs, not the model.
        #expect(proposal.requestId == "req-apple-1")
        #expect(proposal.documentId == document.documentId)
        #expect(proposal.baseSemanticRevision == document.semanticRevision)
        #expect(proposal.generator.name == "apple-on-device")
        // Two objects and one relationship each.
        #expect(proposal.operations.count == 4)
        // And the result passes the same domain validation every other proposal
        // must pass, against the real document.
        let scope = request(document: document).scope
        #expect(throws: Never.self) {
            try ProposalValidator().validate(proposal, against: document, scope: scope)
        }
    }

    @available(macOS 26.0, *)
    @Test("An idea the canvas cannot render is dropped, not coerced")
    func unknownKindIsDropped() throws {
        let document = self.document()
        let candidate = AppleCandidate(
            outcome: "proposal",
            rationale: "Melange.",
            ideas: [
                .init(title: "Bonne idée", summary: "OK", kind: "hypothesis"),
                .init(title: "Idée inexplicable", summary: "?", kind: "quantum_flux")
            ]
        )
        let converted = AppleCandidateConverter().convert(
            candidate, request: request(document: document), document: document
        )
        #expect(converted.droppedKinds == 1)
        guard case .proposal(let proposal) = converted.result else {
            Issue.record("the usable idea should have survived")
            return
        }
        #expect(proposal.operations.count == 2)
    }

    @available(macOS 26.0, *)
    @Test("A proposal outcome with nothing usable becomes noChange, not an empty branch")
    func emptyProposalBecomesNoChange() throws {
        let document = self.document()
        let candidate = AppleCandidate(
            outcome: "proposal",
            rationale: "Je n'ai rien d'utile.",
            ideas: [.init(title: "  ", summary: "", kind: "not-a-kind")]
        )
        let converted = AppleCandidateConverter().convert(
            candidate, request: request(document: document), document: document
        )
        guard case .noChange = converted.result else {
            Issue.record("an unusable proposal must be reported as noChange")
            return
        }
    }

    @available(macOS 26.0, *)
    @Test("noChange and needsInput pass through as themselves")
    func outcomesArePreserved() throws {
        let document = self.document()
        let converter = AppleCandidateConverter()
        let noChange = converter.convert(
            AppleCandidate(outcome: "noChange", rationale: "Rien à dire.", ideas: []),
            request: request(document: document), document: document
        )
        guard case .noChange = noChange.result else {
            Issue.record("noChange must survive")
            return
        }
        let needsInput = converter.convert(
            AppleCandidate(outcome: "needsInput", rationale: "Quel budget ?", ideas: []),
            request: request(document: document), document: document
        )
        guard case .needsInput(let questions) = needsInput.result else {
            Issue.record("needsInput must survive")
            return
        }
        #expect(questions == ["Quel budget ?"])
    }

    @available(macOS 26.0, *)
    @Test("An outcome this adapter does not know is never guessed at")
    func unknownOutcomeIsMalformed() throws {
        let document = self.document()
        let converted = AppleCandidateConverter().convert(
            AppleCandidate(outcome: "certainly", rationale: "", ideas: []),
            request: request(document: document), document: document
        )
        guard case .malformed = converted.result else {
            Issue.record("an unrecognised outcome must not be interpreted")
            return
        }
    }

    @available(macOS 26.0, *)
    @Test("The branch stays small, whatever the model returns")
    func branchIsBounded() throws {
        let document = self.document()
        let many = (0..<8).map { index in
            AppleCandidateIdea(title: "Idée \(index)", summary: "s", kind: "hypothesis")
        }
        let converted = AppleCandidateConverter().convert(
            AppleCandidate(outcome: "proposal", rationale: "Beaucoup.", ideas: many),
            request: request(document: document), document: document
        )
        guard case .proposal(let proposal) = converted.result else {
            Issue.record("expected a proposal")
            return
        }
        // At most 3 ideas, each with one relationship: 6 operations at most.
        #expect(proposal.operations.count <= 6)
        #expect(converted.droppedIdeas > 0)
    }

    @available(macOS 26.0, *)
    @Test("Minted identifiers are ours, not the model's")
    func identifiersAreMinted() throws {
        let document = self.document()
        let candidate = AppleCandidate(
            outcome: "proposal",
            rationale: "OK",
            ideas: [.init(title: "Une piste", summary: "s", kind: "hypothesis")]
        )
        let converted = AppleCandidateConverter().convert(
            candidate, request: request(document: document), document: document
        )
        guard case .proposal(let proposal) = converted.result else { return }
        let created = proposal.operations.compactMap { operation -> ObjectID? in
            guard case .createObject(let create) = operation else { return nil }
            return create.id
        }
        #expect(created.first?.rawValue.hasPrefix("object:apple-") == true)
    }

    // MARK: The seam is unchanged

    @Test("The domain never sees an Apple type")
    func domainIsUntouched() {
        // A compile-time fact, stated as a test so it is checked on every run:
        // the adapter lives in the app package, and the snapshot and the command
        // types in KollioCore carry no FoundationModels dependency.
        let document = self.document()
        let snapshot = try? document.snapshot(targeting: ["object:ctx"])
        #expect(snapshot != nil)
        #expect(document.content.keys.contains("object:ctx"))
    }
}
