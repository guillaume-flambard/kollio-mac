import Foundation
import Testing
@testable import KollioCore

/// AI-04 — answer a clarification.
///
/// Three states, and the requirement is that they stay distinct: asked, answered,
/// and *unknown*. Collapsing the last two is how uncertainty gets quietly upgraded
/// into a fact.
///
/// The three acceptance criteria:
///
/// - AC01 the answer stays in the document after a failure
/// - AC02 "I don't know" stays unknown
/// - AC03 a question resolves without a new sidebar
@Suite("Clarifications")
struct ClarificationTests {
    private func store() -> DocumentStore {
        DocumentStore(document: Fixture.sarah())
    }

    private func question(_ id: String = "question:1") -> Clarification {
        Clarification(
            id: ClarificationID(id),
            originatingRequestId: "request:1",
            objectID: "object:sarah-csv",
            question: LocalizedText("Which export is available today?")
        )
    }

    private func ask(_ id: String = "question:1") -> Command {
        .askClarification(.init(clarification: question(id), provenance: .human("apple:on-device")))
    }

    @Test("A question is asked, and it belongs to an object")
    func askingAQuestion() throws {
        var store = store()
        try store.apply([ask()])
        let stored = try #require(store.document.clarifications.clarification("question:1"))
        #expect(stored.state == .open)
        #expect(stored.objectID == "object:sarah-csv")
        #expect(stored.originatingRequestId == "request:1")
        // It is a real thing in the document, findable by the object it is about.
        #expect(store.document.clarifications.open(for: "object:sarah-csv") != nil)
    }

    @Test("A question about an object that is not there is refused")
    func questionNeedsAnObject() throws {
        var store = store()
        let orphan = Clarification(
            id: "question:x", originatingRequestId: "request:1",
            objectID: "object:ghost", question: LocalizedText("Anything?")
        )
        #expect(throws: DocumentError.unknownObject("object:ghost")) {
            try store.apply([.askClarification(.init(clarification: orphan, provenance: .human("me")))])
        }
    }

    @Test("An empty question is refused rather than stored")
    func emptyQuestionIsRefused() throws {
        var store = store()
        let blank = Clarification(
            id: "question:blank", originatingRequestId: "request:1",
            objectID: "object:sarah-csv", question: LocalizedText("   ")
        )
        #expect(throws: DocumentError.emptyClarification("question:blank")) {
            try store.apply([.askClarification(.init(clarification: blank, provenance: .human("me")))])
        }
    }

    // MARK: AC01

    @Test("AC01: an answer is in the document, not in a draft")
    func answerIsInTheDocument() throws {
        var store = store()
        try store.apply([ask()])
        try store.apply([.answerClarification(.init(
            clarificationID: "question:1", text: "The export from the source tool.",
            provenance: .human("person:owner")
        ))])

        let stored = try #require(store.document.clarifications.clarification("question:1"))
        #expect(stored.state.answerText == "The export from the source tool.")
        if case .answered(let answer) = stored.state {
            #expect(answer.by == "person:owner")
        } else {
            Issue.record("the clarification should be answered, with its author")
        }
        // It is no longer the thing waiting to be answered.
        #expect(store.document.clarifications.open(for: "object:sarah-csv") == nil)
    }

    @Test("An answer survives a save and a reload, which is what surviving a failure means")
    func answerSurvivesARoundTrip() throws {
        var store = store()
        try store.apply([ask()])
        try store.apply([.answerClarification(.init(
            clarificationID: "question:1", text: "The export from the source tool.",
            provenance: .human("person:owner")
        ))])

        let reloaded = try DocumentCodec.decode(try DocumentCodec.encode(store.document))
        #expect(reloaded.clarifications.clarification("question:1")?.state.answerText
            == "The export from the source tool.")
    }

    @Test("An empty field is not sent as a fact")
    func emptyAnswerIsRefused() throws {
        var store = store()
        try store.apply([ask()])
        #expect(throws: DocumentError.emptyClarification("question:1")) {
            try store.apply([.answerClarification(.init(
                clarificationID: "question:1", text: "   ", provenance: .human("person:owner")
            ))])
        }
        // Still open. A blank answer in the document would read as something a
        // person considered and had nothing to say about.
        #expect(store.document.clarifications.clarification("question:1")?.state == .open)
    }

    // MARK: AC02

    @Test("AC02: 'I don't know' stays unknown, and is not an answer")
    func unknownIsItsOwnState() throws {
        var store = store()
        try store.apply([ask()])
        try store.apply([.markClarificationUnknown(.init(
            clarificationID: "question:1", provenance: .human("person:owner")
        ))])

        let stored = try #require(store.document.clarifications.clarification("question:1"))
        if case .unknown = stored.state {} else {
            Issue.record("the clarification should be unknown, not answered")
        }
        // The distinction that matters: an unknown has no answer text, so nothing
        // downstream can read it as one.
        #expect(stored.state.answerText == nil)
        #expect(store.document.clarifications.open(for: "object:sarah-csv") == nil)
    }

    @Test("A reason is optional when saying 'I don't know'")
    func unknownNeedsNoReason() throws {
        var store = store()
        try store.apply([ask()])
        // Being pressed for a reason would turn an honest gap back into a task.
        try store.apply([.markClarificationUnknown(.init(
            clarificationID: "question:1", provenance: .human("person:owner")
        ))])
        #expect(store.document.clarifications.clarification("question:1")?.state.answerText == nil)
    }

    @Test("An unknown can be revised once the person knows")
    func unknownIsNotATombstone() throws {
        var store = store()
        try store.apply([ask()])
        try store.apply([.markClarificationUnknown(.init(
            clarificationID: "question:1", provenance: .human("person:owner")
        ))])
        // The uncertainty was real and can change. What must not happen is it being
        // silently replaced, and the revision is a second event in the document.
        try store.apply([.answerClarification(.init(
            clarificationID: "question:1", text: "Found it: the export exists.",
            provenance: .human("person:owner")
        ))])
        #expect(store.document.clarifications.clarification("question:1")?.state.answerText
            == "Found it: the export exists.")
    }

    // MARK: Obsolescence

    @Test("A question that the document moved past keeps its answer")
    func obsoleteQuestionKeepsItsAnswer() throws {
        var store = store()
        try store.apply([ask()])
        try store.apply([.answerClarification(.init(
            clarificationID: "question:1", text: "The export exists.",
            provenance: .human("person:owner")
        ))])

        let obsolete = try #require(store.document.clarifications.clarification("question:1"))
            .superseded(because: "the object was rewritten")
        #expect(obsolete.isObsolete)
        // Obsolete is not deleted, and the answer is not thrown away.
        #expect(obsolete.state.answerText == "The export exists.")
        #expect(obsolete.obsoleteReason == "the object was rewritten")
    }

    // MARK: Intelligence

    @Test("Intelligence may ask, and may not answer")
    func onlyAPersonAnswers() throws {
        let document = Fixture.sarah()
        let scope = ProposalRequest.Scope()

        // Asking is allowed, and it must arrive open.
        let askProposal = Proposal(
            proposalId: "proposal:ask",
            requestId: "request:1",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("A question worth asking"),
            operations: [.askClarification(.init(
                clarification: question(), provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))],
            generator: .init(name: "apple-on-device", deterministic: false)
        )
        try ProposalValidator().validate(askProposal, against: document, scope: scope)

        // Answering is not. A model that could answer its own question would be
        // manufacturing the contribution the answer is supposed to be.
        for command: Command in [
            .answerClarification(.init(
                clarificationID: "question:1", text: "I would say the export exists.",
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            )),
            .markClarificationUnknown(.init(
                clarificationID: "question:1",
                reason: "I am not sure",
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))
        ] {
            let proposal = Proposal(
                proposalId: "proposal:answer",
                requestId: "request:1",
                documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision,
                summary: LocalizedText("Answering my own question"),
                operations: [command],
                generator: .init(name: "apple-on-device", deterministic: false)
            )
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(proposal, against: document, scope: scope)
            }
        }
    }

    @Test("Clarifications survive a save and a reload")
    func clarificationsRoundTrip() throws {
        var store = store()
        try store.apply([ask()])
        try store.apply([.markClarificationUnknown(.init(
            clarificationID: "question:1", reason: "nobody has looked",
            provenance: .human("person:owner")
        ))])
        let reloaded = try DocumentCodec.decode(try DocumentCodec.encode(store.document))
        if case .unknown(let reason) = reloaded.clarifications.clarification("question:1")!.state {
            #expect(reason == "nobody has looked")
        } else {
            Issue.record("the unknown should survive a round trip with its reason")
        }
    }
}
