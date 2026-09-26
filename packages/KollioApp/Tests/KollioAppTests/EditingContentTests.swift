import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// CAN-04, "Edit content in place".
///
/// The three acceptance criteria are decidable, and one of them — "Cmd+Z in the
/// field undoes typing, not an old branch" — turned out to be a claim about two
/// separate undo systems. The test decides the part the repository owns: while a
/// draft is open, the document's undo cannot touch it.
@Suite("CAN-04: editing content in place")
@MainActor
struct EditingContentTests {
    private func isolatedStore() -> (DocumentFileStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-can04-\(UUID().uuidString)")
        return (DocumentFileStore(directory: directory), directory)
    }

    private func makeModel(
        _ languageCode: String = "fr"
    ) -> (KollioModel, URL) {
        let (store, directory) = isolatedStore()
        return (
            KollioModel(document: SarahFixture.document(),
                        service: KollioModel.makeDemoService(languageCode: languageCode),
                        fileStore: store,
                        languageCode: languageCode),
            directory
        )
    }

    private let csv = KollioID.object("sarah-csv")

    // MARK: AC01 — the text is not reduced to a summary

    @Test("An edit stores the exact characters typed, whatever their length")
    func theTextIsNotReduced() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        // Long, multi-line, accented, punctuated. A summary would drop the second
        // paragraph and normalise the punctuation.
        let authored = """
        Nous voulons organiser une journée de découverte.
        Salle de 30 places, deux intervenants, aucun budget publicitaire.

        Contrainte réelle : les identifiants d'API du CRM ne sont pas disponibles \
        pour cette initiative — c'est ce qui rend l'export CSV intéressant.
        """
        model.startEditing(anchor: csv)
        model.composer?.text = authored
        #expect(model.applyEdit(to: csv, text: authored))

        #expect(model.document.object(csv)?.text.text == authored)
        // The object is still the same object: an edit changes content, not identity.
        #expect(model.document.object(csv)?.kind == SarahFixture.document().object(csv)?.kind)
    }

    @Test("An edit is one transaction and one undo")
    func anEditIsOneUndo() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let before = model.document.object(csv)?.text.text

        #expect(model.applyEdit(to: csv, text: "Une formulation différente"))
        #expect(model.document.object(csv)?.text.text == "Une formulation différente")

        model.undo()
        #expect(model.document.object(csv)?.text.text == before)
    }

    @Test("An edit that changes nothing does not advance the version")
    func aNoOpEditDoesNotAdvanceTheVersion() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let version = try! #require(model.document.object(csv)?.objectVersion)

        // Same words, re-submitted. A version that rose here would make every other
        // writer look stale for no reason at all.
        #expect(model.applyEdit(to: csv, text: model.document.object(csv)!.text.text))
        #expect(model.document.object(csv)?.objectVersion == version)

        #expect(model.applyEdit(to: csv, text: "Quelque chose de nouveau"))
        #expect(model.document.object(csv)?.objectVersion == version + 1)
    }

    // MARK: AC02 — the field's undo is not the document's undo

    @Test("The document's undo cannot touch an unsaved draft")
    func theDocumentUndoCannotTouchTheDraft() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let objectBefore = model.document.object(csv)?.text.text

        // Something to undo, so the document's history is not empty.
        #expect(model.applyEdit(to: csv, text: "Une première version"))
        #expect(model.canUndo)

        model.startEditing(anchor: csv)
        model.composer?.text = "Un brouillon jamais enregistré"
        let draft = model.composer?.text

        // The document's undo runs. The draft is not part of the document, so it
        // cannot be affected by anything the document does.
        model.undo()

        // The document went back; the draft did not move, because a draft is not
        // part of the document and no document operation can reach it.
        #expect(model.document.object(csv)?.text.text == objectBefore)
        #expect(model.composer?.text == draft)
        // And the draft is now honestly out of date: the text it was written
        // against is no longer the text on the canvas. Reporting that is the
        // point of remembering the version, so the conflict is asserted rather
        // than wished away.
        #expect(model.hasEditConflict(model.composer!))
    }

    @Test("Closing an edit keeps the text somewhere findable")
    func closingAnEditKeepsTheText() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let before = model.document.object(csv)?.text.text

        model.startEditing(anchor: csv)
        model.composer?.text = "du texte non soumis"
        model.dismissOneLevel()

        // The surface closed. Nothing was written, and nothing was thrown away
        // either: reopening starts from what is really there, not from nothing.
        #expect(model.composer == nil)
        #expect(model.document.object(csv)?.text.text == before)

        model.startEditing(anchor: csv)
        #expect(model.composer?.text == before)
    }

    // MARK: AC03 — the interface language does not touch the content

    @Test("Changing the interface language leaves the text exactly as written")
    func theInterfaceLanguageDoesNotTranslateTheText() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let authored = "Préparer la liste de contacts depuis l'export"
        let document = SarahFixture.document()

        let french = KollioModel(document: document, service: KollioModel.makeDemoService(languageCode: "fr"),
                                 fileStore: store, languageCode: "fr")
        #expect(french.applyEdit(to: csv, text: authored))

        // The same document, read back in the other interface language. The
        // authored text is French and stays French; only labels change.
        let english = KollioModel(document: french.document, service: KollioModel.makeDemoService(languageCode: "en"),
                                  fileStore: store, languageCode: "en")
        #expect(english.document.object(csv)?.text.text == authored)
        #expect(english.text(of: csv) == authored)

        french.languageCode = "en"
        #expect(french.text(of: csv) == authored)
    }

    // MARK: The conflict the specification asks for

    @Test("A text changed elsewhere is refused, and the draft survives")
    func aStaleEditIsRefusedAndTheDraftSurvives() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        // A person opens the editor and starts typing.
        model.startEditing(anchor: csv)
        let baseVersion = try! #require(model.composer?.baseVersion)
        model.composer?.text = "Ma version"

        // Meanwhile the object moved on, which is what a second person or a
        // background change looks like from here.
        #expect(model.applyEdit(to: csv, text: "La version de quelqu'un d'autre"))
        #expect(model.hasEditConflict(model.composer!))

        // The person presses the key. The write is refused, their text is still
        // there, and the current text is still readable beside it.
        let submitted = model.composer?.text ?? ""
        #expect(model.applyEdit(to: csv, text: submitted, expectedVersion: baseVersion) == false)
        #expect(model.composer?.text == "Ma version")
        #expect(model.document.object(csv)?.text.text == "La version de quelqu'un d'autre")
        #expect(model.status == L10n.errorEditConflict)
    }

    @Test("An edit against the version it was opened on succeeds")
    func anEditAgainstTheCurrentVersionSucceeds() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        model.startEditing(anchor: csv)
        let baseVersion = try! #require(model.composer?.baseVersion)
        #expect(!model.hasEditConflict(model.composer!))

        let retyped = "Une reformulation de la même idée"
        #expect(model.applyEdit(to: csv, text: retyped, expectedVersion: baseVersion))
        #expect(model.document.object(csv)?.text.text == retyped)
        // One transaction, so one undo restores it.
        #expect(model.canUndo)
        model.undo()
        #expect(model.document.object(csv)?.text.text != retyped)
    }

    @Test("Re-submitting the same words is not a change and needs no undo")
    func resubmittingTheSameWordsIsNotAChange() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        model.startEditing(anchor: csv)
        let baseVersion = try! #require(model.composer?.baseVersion)
        let unchanged = model.composer?.text ?? ""

        // The editor opens pre-filled with what is already there, so pressing the
        // key without typing anything is the common case. It must not create an
        // undo entry that appears to do something.
        #expect(model.applyEdit(to: csv, text: unchanged, expectedVersion: baseVersion))
        #expect(model.document.object(csv)?.objectVersion == baseVersion)
        #expect(model.canUndo == false)
    }

    @Test("The interface says the object moved on before the person submits")
    func theConflictIsVisibleBeforeSubmitting() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        model.startEditing(anchor: csv)
        #expect(!model.hasEditConflict(model.composer!))

        #expect(model.applyEdit(to: csv, text: "Un changement entre-temps"))
        #expect(model.hasEditConflict(model.composer!))

        // And a fresh editor on the new text is not in conflict, so the state does
        // not stick around and block the person forever.
        model.startEditing(anchor: csv)
        #expect(!model.hasEditConflict(model.composer!))
    }

    @Test("Editing an object invalidates a proposal computed before the edit")
    func anEditInvalidatesTheProposalThatUsedTheObject() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")

        await model.explore(crm)
        let preview = try! #require(model.preview)
        let baseRevision = preview.proposal.baseSemanticRevision

        // Editing moves the document past the revision the proposal was computed
        // for. The proposal keeps its own preconditions, so the keep is refused
        // rather than applied to a document it was never computed against.
        #expect(model.applyEdit(to: crm, text: "Un contexte reformulé"))
        #expect(model.document.semanticRevision > baseRevision)
        #expect(model.hasEditConflict(KollioModel.ComposerState(
            anchorID: crm, text: "", intent: .edit, baseVersion: baseRevision
        )))
    }
}
