import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// What the second half of DEC-06 claims, and what the first half left out.
///
/// The timeline reads the journal. These four tests cover the three acts the
/// specification names and nobody had built: a preview, a restore, and a purge.
/// Each of them could pass by accident on an interface that only reads, so each
/// is written against the document rather than against the card.
@Suite("DEC-06: preview, restore and purge")
@MainActor
struct HistoryRestoreTests {
    /// Two objects and one link, then two edits to the second object.
    ///
    /// The builder writes the document but not the journal: only a command
    /// applied through the model is recorded. A fixture that relied on the
    /// builder's contents would have had nothing to preview.
    private func modelWithHistory() -> KollioModel {
        var builder = DocumentBuilder()
        builder.object("cause", kind: .context, "Cause", en: "Cause", at: Position(x: 0, y: 0))
        builder.object("effect", kind: .hypothesis, "Effet", en: "Effect", at: Position(x: 400, y: 0))
        builder.link("link-1", from: ObjectID("object:cause"), to: ObjectID("object:effect"), .supports)
        let model = KollioModel(
            document: builder.document,
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
        model.applyEdit(to: ObjectID("object:effect"), text: "Effet mesuré")
        model.applyEdit(to: ObjectID("object:effect"), text: "Effet révisé")
        return model
    }

    @Test("A preview of an earlier state shows that state, and changes nothing")
    func previewIsReadOnly() throws {
        let model = modelWithHistory()
        let entries = model.document.history.entries
        #expect(entries.count >= 2, "the fixture needs at least two recorded actions")
        let first = entries[0].id

        let before = model.document
        let preview = try #require(try model.previewHistory(at: first))

        // The state before the second edit: the original text, not the new one.
        #expect(preview.object(ObjectID("object:effect"))?.text.text == "Effet")
        // And the document the person is looking at has not moved.
        #expect(model.document == before)
    }

    @Test("A preview does not resurrect something that was taken back")
    func previewSkipsReversals() throws {
        let model = modelWithHistory()
        let undone = try #require(model.document.history.entries.last?.id)
        model.undo()
        let preview = try #require(try model.previewHistory(at: undone))

        // The state at that entry is the first edit and not the second: the
        // replay stopped before the action that was undone, so what it shows is
        // the text that stands. A replay that applied the reversal's payload
        // would have produced "Effet révisé" instead, which is the exact
        // opposite of having been taken back.
        #expect(preview.object(ObjectID("object:effect"))?.text.text == "Effet mesuré")
    }

    @Test("A restore is a new recorded action, not an invisible rollback")
    func restoreIsANewAction() throws {
        let model = modelWithHistory()
        let first = try #require(model.document.history.entries.first?.id)
        let before = model.document
        let entriesBefore = before.history.count

        #expect(model.restoreHistory(to: first, label: "Rétabli"))

        // The content went back...
        #expect(model.document.object(ObjectID("object:effect"))?.text.text == "Effet")
        // ...as an action of its own, so the journal has grown rather than
        // shrunk, and the person can see that they did this.
        #expect(model.document.history.count == entriesBefore + 1)
        #expect(model.document.history.entries.last?.label == "Rétabli")
        // And the entries that came before are still there to read.
        #expect(model.document.history.entries.first?.id == first)
    }

    @Test("A restore leaves the journal readable, because the journal is the record")
    func restoreKeepsTheJournal() throws {
        let model = modelWithHistory()
        let first = try #require(model.document.history.entries.first?.id)
        #expect(model.restoreHistory(to: first, label: "Rétabli"))

        // A restore rebuilt from a preview that had emptied the ledger would
        // take the timeline with it: the history of what happened would no longer
        // contain the history of the restore.
        let timeline = model.history(of: ObjectID("object:effect"))
        #expect(timeline.isEmpty == false, "the timeline an object was read from must survive a restore")
    }

    @Test("A purge removes what it says it removes, and reports the count")
    func purgeIsExplicitAndCounted() throws {
        let model = modelWithHistory()
        let total = model.document.history.count
        #expect(total >= 2)

        // A horizon before anything was recorded removes everything.
        let removed = model.purgeHistory(olderThan: Date().addingTimeInterval(3600))
        #expect(removed == total)
        #expect(model.document.history.count == 0)
    }

    @Test("A purge that matches nothing removes nothing")
    func purgeKeepsWhatIsStillInRetention() throws {
        let model = modelWithHistory()
        let total = model.document.history.count

        let removed = model.purgeHistory(olderThan: Date().addingTimeInterval(-3600))

        #expect(removed == 0)
        #expect(model.document.history.count == total)
    }
}
