import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// Answering a question from the interface.
///
/// The behaviours that matter are the ones a person can get wrong: an answer lost on
/// the way in, an empty field stored as if it were an answer, and "I don't know"
/// quietly turning into a blank.
@Suite("Clarification interface")
@MainActor
struct ClarificationInterfaceTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(
                directory: URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("kollio-clar-\(UUID().uuidString)")
            )
        )
    }

    private let csv = ObjectID("object:sarah-csv")

    /// Ask a question the way the service does, then open its input.
    private func asked(_ model: KollioModel) throws -> Clarification {
        model.handle(
            ProposalResponse.needsInput([LocalizedText("Which export is available today?")]),
            anchor: csv,
            requestId: "request:test"
        )
        let question = try #require(model.openClarification(for: csv))
        #expect(model.clarificationDraft?.clarificationID == question.id)
        return question
    }

    @Test("A question asked by the service becomes a thing in the document")
    func questionIsPersistent() throws {
        let model = model()
        let question = try asked(model)

        #expect(model.document.clarifications.clarification(question.id) != nil)
        #expect(model.document.clarifications.open(for: csv)?.id == question.id)
        // No longer a transient line of status: the question has an identity and
        // belongs to an object.
        #expect(model.status == nil)
    }

    @Test("An answer is written into the document, not kept as a draft")
    func answerReachesTheDocument() throws {
        let model = model()
        let question = try asked(model)
        model.clarificationDraft?.text = "The export from the source tool."
        #expect(model.resolveClarification())

        let stored = try #require(model.document.clarifications.clarification(question.id))
        #expect(stored.state.answerText == "The export from the source tool.")
        // And the card and the draft are gone, because the question is dealt with.
        #expect(model.openClarification(for: csv) == nil)
        #expect(model.clarificationDraft == nil)
    }

    @Test("An empty field is refused, and the sentence is kept")
    func emptyAnswerIsRefusedAndTheDraftSurvives() throws {
        let model = model()
        let question = try asked(model)
        model.clarificationDraft?.text = "   "
        #expect(model.resolveClarification() == false)
        // Still open, and the draft is untouched so nothing is retyped.
        #expect(model.document.clarifications.open(for: csv)?.id == question.id)
        #expect(model.status != nil)
    }

    @Test("'I don't know' is a real answer that stays unknown")
    func unknownIsAnswered() throws {
        let model = model()
        let question = try asked(model)
        #expect(model.resolveClarification(asUnknown: true))

        let stored = try #require(model.document.clarifications.clarification(question.id))
        if case .unknown = stored.state {} else {
            Issue.record("the question should be unknown, not answered")
        }
        // The important half: no answer text exists to be read as a fact.
        #expect(stored.state.answerText == nil)
        #expect(model.openClarification(for: csv) == nil)
    }

    @Test("An answer survives a save and a reload, which is what surviving a failure means")
    func answerSurvivesARoundTrip() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-clar-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DocumentFileStore(directory: directory)
        let model = KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        let question = try asked(model)
        model.clarificationDraft?.text = "The export exists."
        #expect(model.resolveClarification())
        #expect(model.save() != nil)

        // A fresh model over the same directory: the answer is not a draft that
        // lived in a view, it is in the document.
        let reloaded = KollioModel(document: nil, fileStore: store)
        #expect(reloaded.document.clarifications.clarification(question.id)?.state.answerText
            == "The export exists.")
    }
}
