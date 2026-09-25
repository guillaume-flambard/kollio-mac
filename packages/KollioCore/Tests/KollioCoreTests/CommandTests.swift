import Foundation
import Testing
@testable import KollioCore

@Suite("Commands and transactions")
struct CommandTests {
    @Test("A transaction is atomic: one invalid command changes nothing")
    func atomicity() throws {
        var store = DocumentStore(document: Fixture.sarah())
        let before = store.document
        let commands: [Command] = [
            .updateObjectText(.init(id: KollioID.object("sarah-csv"), text: LocalizedText("Nouvel export"), provenance: .human("me"))),
            .addRelationship(.init(id: "relationship:bad", from: KollioID.object("sarah-csv"), to: KollioID.object("ghost"), kind: .supports, provenance: .human("me")))
        ]
        #expect(throws: DocumentError.unknownObject(KollioID.object("ghost"))) {
            try store.apply(commands)
        }
        #expect(store.document == before)
    }

    @Test("Moving an object bumps the revision but not the semantic revision")
    func movementIsPresentationOnly() throws {
        var store = DocumentStore(document: Fixture.sarah())
        let semanticBefore = store.semanticRevision
        let revisionBefore = store.revision
        try store.apply([.moveNodeInstances(MoveNodeInstances(moves: [
            .init(instanceID: InstanceID("instance:object:sarah-csv"), position: Position(x: 12, y: 34))
        ]))])
        #expect(store.revision == revisionBefore + 1)
        #expect(store.semanticRevision == semanticBefore)
    }

    @Test("Changing a decision bumps the semantic revision")
    func decisionIsSemantic() throws {
        var store = DocumentStore(document: Fixture.sarah())
        let semanticBefore = store.semanticRevision
        try store.apply([.recordDecision(.init(
            id: "decision:1",
            kind: .setAside,
            targetObjectID: KollioID.object("sarah-csv"),
            rationale: LocalizedText("On garde le CRM"),
            provenance: .human("me")
        ))])
        #expect(store.semanticRevision == semanticBefore + 1)
    }

    @Test("Rejects a relationship pointing at an unknown object")
    func invalidRelationship() throws {
        var store = DocumentStore(document: Fixture.sarah())
        #expect(throws: DocumentError.unknownObject(ObjectID("nope"))) {
            try store.apply([.addRelationship(.init(
                id: "relationship:x",
                from: KollioID.object("sarah-csv"),
                to: ObjectID("nope"),
                kind: .supports,
                provenance: .human("me")
            ))])
        }
    }

    @Test("Rejects a self relationship")
    func selfRelationship() throws {
        var store = DocumentStore(document: Fixture.sarah())
        #expect(throws: DocumentError.selfRelationship("relationship:self")) {
            try store.apply([.addRelationship(.init(
                id: "relationship:self",
                from: KollioID.object("sarah-csv"),
                to: KollioID.object("sarah-csv"),
                kind: .supports,
                provenance: .human("me")
            ))])
        }
    }

    @Test("Rejects duplicate object ids")
    func duplicateObject() throws {
        var store = DocumentStore(document: Fixture.sarah())
        #expect(throws: DocumentError.duplicateObject(KollioID.object("sarah-csv"))) {
            try store.apply([.createObject(.init(
                id: KollioID.object("sarah-csv"),
                kind: .note,
                text: LocalizedText("x"),
                provenance: .human("me")
            ))])
        }
    }

    @Test("Rejects an object that references an unknown contribution")
    func referenceValidation() throws {
        var store = DocumentStore(document: Fixture.sarah())
        #expect(throws: DocumentError.unknownContributionReference(KollioID.object("new"), KollioID.contribution("ghost"))) {
            try store.apply([.createObject(.init(
                id: KollioID.object("new"),
                kind: .contribution,
                text: LocalizedText("x"),
                contributionID: KollioID.contribution("ghost"),
                provenance: .human("me")
            ))])
        }
    }
}

@Suite("Decisions are durable project memory")
struct DecisionTests {
    @Test("Setting a direction aside collapses it without deleting anything")
    func setAside() throws {
        var store = DocumentStore(document: Fixture.sarah())
        let csv = KollioID.object("sarah-csv")
        try store.apply([.recordDecision(.init(
            id: "decision:aside",
            kind: .setAside,
            targetObjectID: csv,
            rationale: LocalizedText("L’export ne suffit pas pour l’instant"),
            provenance: .human("me")
        ))])
        let document = store.document
        #expect(document.object(csv)?.isSetAside == true)
        // The whole branch collapsed...
        #expect(document.object(KollioID.object("sarah-viable"))?.isSetAside == true)
        #expect(document.object(KollioID.object("sarah-question"))?.isSetAside == true)
        // ...but nothing was deleted, and the other direction is untouched.
        #expect(document.content.count == 6)
        #expect(document.object(KollioID.object("sarah-crm"))?.isSetAside == false)
        #expect(document.decisions["decision:aside"]?.rationale?.text == "L’export ne suffit pas pour l’instant")
    }

    @Test("Reopening restores the exact objects and positions")
    func reopen() throws {
        var store = DocumentStore(document: Fixture.sarah())
        let csv = KollioID.object("sarah-csv")
        let originalPositions = Dictionary(
            uniqueKeysWithValues: store.document.presentation.instances.map { ($0.objectID, $0.position) }
        )
        try store.apply([.recordDecision(.init(id: "d1", kind: .setAside, targetObjectID: csv, rationale: LocalizedText("pas maintenant"), provenance: .human("me")))])
        try store.apply([.recordDecision(.init(id: "d2", kind: .reopened, targetObjectID: csv, provenance: .human("me")))])

        let document = store.document
        #expect(document.object(csv)?.isSetAside == false)
        #expect(document.object(KollioID.object("sarah-question"))?.isSetAside == false)
        for instance in document.presentation.instances {
            #expect(instance.position == originalPositions[instance.objectID])
        }
    }

    @Test("A decision survives undo, save and reload")
    func decisionSurvivesUndo() throws {
        var session = KollioSession(document: Fixture.sarah())
        let csv = KollioID.object("sarah-csv")
        let setAside = Command.recordDecision(.init(
            id: "d1", kind: .setAside, targetObjectID: csv,
            rationale: LocalizedText("Identifiants API indisponibles"),
            provenance: .human("me")
        ))
        let setAsideAgain = Command.recordDecision(.init(
            id: "d2", kind: .setAside, targetObjectID: csv,
            rationale: LocalizedText("Identifiants API indisponibles"),
            provenance: .human("me")
        ))

        let firstApplied = session.apply([setAside], label: "set aside")
        let undone = session.undo()
        let activeAfterUndo = session.document.object(csv)?.isSetAside == false
        #expect(firstApplied)
        #expect(undone)
        #expect(activeAfterUndo)

        // Re-apply, then simulate a full save / quit / reopen cycle.
        let secondApplied = session.apply([setAsideAgain], label: "set aside")
        #expect(secondApplied)
        let reloaded = try DocumentCodec.decode(try DocumentCodec.encode(session.document))
        #expect(reloaded.object(csv)?.isSetAside == true)
        #expect(reloaded.decisions["d2"]?.rationale?.text == "Identifiants API indisponibles")
    }

    @Test("A shared object stays visible when a sibling branch is set aside")
    func sharedObjectStaysVisible() throws {
        var store = DocumentStore(document: Fixture.sarah())
        let crm = KollioID.object("sarah-crm")
        let blocked = KollioID.object("sarah-blocked")
        try store.apply([.addRelationship(.init(
            id: "relationship:shared",
            from: KollioID.object("sarah-csv"),
            to: blocked,
            kind: .supports,
            provenance: .human("me")
        ))])
        try store.apply([.recordDecision(.init(id: "d1", kind: .setAside, targetObjectID: crm, provenance: .human("me")))])
        #expect(store.document.object(crm)?.isSetAside == true)
        #expect(store.document.object(blocked)?.isSetAside == false)
    }
}

@Suite("Undo and redo")
struct UndoTests {
    @Test("Applying a proposal is undone as one coherent action")
    func proposalUndo() async throws {
        var session = KollioSession(document: Fixture.sarah())
        let before = session.document
        let target = KollioID.object("sarah-csv")
        let request = ProposalRequest(
            requestId: "req-1",
            documentId: session.document.documentId,
            baseSemanticRevision: session.semanticRevision,
            intent: .explore,
            targetIds: [target]
        )
        let response = try await LocalDemoSuggestionService().respond(to: request, document: session.document)
        let proposal = try #require(response.proposal)
        #expect(response.status == .proposed)

        let kept = session.apply([.applyProposal(.init(
            proposal: proposal,
            placements: [:],
            provenance: .human("me")
        ))], label: "keep")

        var createdCount = 0
        for operation in proposal.operations {
            if case .createObject = operation { createdCount += 1 }
        }
        let grewByEveryCreatedObject = session.document.content.count - before.content.count == createdCount
        let undone = session.undo()
        let restored = session.document == before
        #expect(kept)
        #expect(grewByEveryCreatedObject)
        #expect(undone)
        #expect(restored)
    }

    @Test("Redo replays the same transaction")
    func redo() {
        var session = KollioSession(document: Fixture.sarah())
        let before = session.document
        let applied = session.apply([.updateObjectText(.init(
            id: KollioID.object("sarah-csv"),
            text: LocalizedText("Autre chose"),
            provenance: .human("me")
        ))], label: "edit")
        let after = session.document
        let undone = session.undo()
        let backToStart = session.document == before
        let redone = session.redo()
        let forwardAgain = session.document == after
        #expect(applied)
        #expect(undone)
        #expect(backToStart)
        #expect(redone)
        #expect(forwardAgain)
    }

    @Test("A new action after an undo drops the redo tail")
    func redoTail() {
        var session = KollioSession(document: Fixture.sarah())
        let text = KollioID.object("sarah-csv")
        func edit(_ value: String) -> Command {
            .updateObjectText(.init(id: text, text: LocalizedText(value), provenance: .human("me")))
        }
        let first = session.apply([edit("A")], label: "a")
        let second = session.apply([edit("B")], label: "b")
        let undone = session.undo()
        let third = session.apply([edit("C")], label: "c")
        let cannotRedo = session.redo() == false
        let text3 = session.document.object(text)?.text.text
        #expect(first)
        #expect(second)
        #expect(undone)
        #expect(third)
        #expect(cannotRedo)
        #expect(text3 == "C")
    }
}
