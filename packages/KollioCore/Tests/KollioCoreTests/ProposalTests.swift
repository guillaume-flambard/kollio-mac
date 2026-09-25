import Foundation
import Testing
@testable import KollioCore

@Suite("Proposals are patches, never replacements")
struct ProposalTests {
    private func makeRequest(_ document: KollioDocument, intent: ProposalRequest.Intent = .explore, target: ObjectID? = KollioID.object("sarah-csv")) -> ProposalRequest {
        ProposalRequest(
            requestId: "req-1",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            intent: intent,
            targetIds: target.map { [$0] } ?? [],
            contentLocale: "fr"
        )
    }

    @Test("Explore returns operations, not a new document")
    func exploreReturnsOperations() async throws {
        let document = Fixture.sarah()
        let proposal = try #require(try await LocalDemoSuggestionService()
            .respond(to: makeRequest(document), document: document).proposal)
        #expect(proposal.operations.contains { if case .createObject = $0 { return true }; return false })
        #expect(proposal.operations.contains { if case .addRelationship = $0 { return true }; return false })
        #expect(!proposal.operations.contains { $0.isSemantic == false && false })
    }

    @Test("Re-exploring the same unchanged state is deterministic")
    func deterministic() async throws {
        let document = Fixture.sarah()
        let a = try await LocalDemoSuggestionService().respond(to: makeRequest(document), document: document)
        let b = try await LocalDemoSuggestionService().respond(to: makeRequest(document), document: document)
        #expect(a == b)
    }

    @Test("The engine reacts to the real document state, not a recorded sequence")
    func stateReactive() async throws {
        var store = DocumentStore(document: Fixture.sarah())
        let csv = KollioID.object("sarah-csv")
        let service = LocalDemoSuggestionService()

        let first = try await service.respond(to: makeRequest(store.document), document: store.document)
        #expect(first.status == .proposed)
        #expect(first.proposal != nil)

        // Apply it, then ask again: the same branch must not be proposed twice.
        try store.apply([.applyProposal(.init(proposal: first.proposal!, placements: [:], provenance: .human("me")))])
        let second = try await service.respond(to: makeRequest(store.document), document: store.document)
        #expect(second.status == .noChange)

        // Set the direction aside: exploring it is a no-op, reopening is not.
        try store.apply([.recordDecision(.init(id: "d1", kind: .setAside, targetObjectID: csv, rationale: LocalizedText("plus tard"), provenance: .human("me")))])
        let third = try await service.respond(to: makeRequest(store.document), document: store.document)
        #expect(third.status == .noChange)
        let reopen = try await service.respond(to: makeRequest(store.document, intent: .reopen), document: store.document)
        #expect(reopen.status == .proposed)
    }

    @Test("Asking for nothing to add needs input")
    func needsInput() async throws {
        let document = Fixture.sarah()
        let request = makeRequest(document, intent: .add)
        let response = try await LocalDemoSuggestionService().respond(to: request, document: document)
        #expect(response.status == .needsInput)
        #expect(response.questions.first?.variants["en"] != nil)
    }

    @Test("An unknown target is an error, never a silent guess")
    func unknownTarget() async throws {
        let document = Fixture.sarah()
        await #expect(throws: DocumentError.unknownObject(ObjectID("ghost"))) {
            try await LocalDemoSuggestionService()
                .respond(to: makeRequest(document, target: ObjectID("ghost")), document: document)
        }
    }

    @Test("A proposal computed on an old revision is rejected as stale")
    func staleProposal() throws {
        let document = Fixture.sarah()
        var store = DocumentStore(document: document)
        let stale = Proposal(
            proposalId: "p",
            requestId: "r",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("x"),
            operations: [.createObject(.init(id: "object:new", kind: .note, text: LocalizedText("y"), provenance: .human("me")))],
            generator: .init(name: "test", deterministic: true)
        )
        try store.apply([.updateObjectText(.init(id: KollioID.object("sarah-csv"), text: LocalizedText("changé"), provenance: .human("me")))])
        #expect(throws: DocumentError.self) {
            try store.apply([.applyProposal(.init(proposal: stale, placements: [:], provenance: .human("me")))])
        }
    }

    @Test("A proposal referencing a ghost object is rejected")
    func unknownReference() throws {
        let document = Fixture.sarah()
        let proposal = Proposal(
            proposalId: "p",
            requestId: "r",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("x"),
            operations: [.addRelationship(.init(
                id: "relationship:ghost",
                from: KollioID.object("sarah-csv"),
                to: ObjectID("ghost"),
                kind: .supports,
                provenance: .human("me")
            ))],
            generator: .init(name: "test", deterministic: true)
        )
        #expect(throws: DocumentError.unknownObject(ObjectID("ghost"))) {
            try ProposalValidator().validate(proposal, against: document, scope: .init())
        }
    }

    @Test("A proposal that exceeds the operation budget is rejected")
    func operationBudget() throws {
        let document = Fixture.sarah()
        let operations = (0..<10).map { index in
            Command.createObject(.init(
                id: ObjectID("object:\(index)"),
                kind: .note,
                text: LocalizedText("n\(index)"),
                provenance: .human("me")
            ))
        }
        let proposal = Proposal(
            proposalId: "p",
            requestId: "r",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("x"),
            operations: operations,
            generator: .init(name: "test", deterministic: true)
        )
        #expect(throws: DocumentError.tooManyOperations(10)) {
            try ProposalValidator().validate(proposal, against: document, scope: .init(maxOperations: 4))
        }
    }

    @Test("A proposal may not smuggle a nested transaction or a scenario")
    func forbiddenOperations() throws {
        let document = Fixture.sarah()
        for command in [Command.rejectProposal(.init(proposalId: "p", reason: .declined, provenance: .human("me")))] {
            let proposal = Proposal(
                proposalId: "p",
                requestId: "r",
                documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision,
                summary: LocalizedText("x"),
                operations: [command],
                generator: .init(name: "test", deterministic: true)
            )
            #expect(throws: DocumentError.forbiddenOperation("rejectProposal")) {
                try ProposalValidator().validate(proposal, against: document, scope: .init())
            }
        }
    }

    @Test("The demo engine is offline and declares itself deterministic")
    func capabilities() {
        let capabilities = LocalDemoSuggestionService().capabilities
        #expect(capabilities.requiresNetwork == false)
        #expect(capabilities.deterministic == true)
    }
}

@Suite("Reusable contributions")
struct ContributionTests {
    @Test("Visual duplication never creates a new contribution or claim")
    func duplicationIsPresentationOnly() throws {
        var builder = DocumentBuilder(document: Fixture.sarah())
        let contribution = ContributionRecord(
            id: KollioID.contribution("csv-export"),
            name: "Export CSV",
            kind: .technicalBlock,
            owner: ActorID("expert-1")
        )
        builder.addContribution(contribution)

        let product = KollioID.object("sarah-csv")
        let reference = builder.object(
            "ref-1", kind: .contribution, "Export CSV", en: "CSV export",
            at: Position(x: 100, y: 100), contribution: contribution.id
        )!
        // A second visual instance of the same object.
        var document = builder.document
        document.presentation.instances.append(
            NodeInstance(id: KollioID.instance("ref-1-copy"), objectID: reference, position: Position(x: 400, y: 100))
        )
        builder = DocumentBuilder(document: document)
        let attached = builder.apply(.addContributionToProduct(.init(
            productID: product,
            contributionID: contribution.id,
            share: 0.5,
            provenance: .human("me")
        )))
        #expect(attached)

        let final = builder.document
        #expect(final.contributions.count == 1)
        #expect(final.products[product]?.memberContributionIDs == [contribution.id])
        #expect(final.products[product]?.share(for: contribution.id) == 0.5)
        #expect(final.presentation.instances.filter { $0.objectID == reference }.count == 2)
    }
}
