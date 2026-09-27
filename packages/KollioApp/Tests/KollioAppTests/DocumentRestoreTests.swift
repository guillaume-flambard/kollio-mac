import Foundation
import Testing
@testable import KollioApp
import KollioCore

/// What a launch opens, and what a quit leaves behind.
///
/// Both of these were found by driving the real window with a real typed
/// sentence, which is the only way they could be found: every test in this
/// repository passed while the app was writing documents it could never read back.
///
/// The failure, in full, because the shape of it matters. A launch with nothing in
/// it saved an empty document to the *default* file name. The store then preferred
/// the default file whenever it existed, whatever its age. So from that moment every
/// launch opened the empty file, and every quit wrote the empty file again. Real
/// documents kept being written, to their own names, and were never opened again.
@Suite("What a launch opens and a quit leaves")
@MainActor
struct DocumentRestoreTests {
    private func temporaryStore() -> DocumentFileStore {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-restore-\(UUID().uuidString)")
        return DocumentFileStore(directory: directory)
    }

    private func document(with text: String) -> KollioDocument {
        var builder = DocumentBuilder()
        _ = builder.object("ctx", kind: .context, text, en: text, at: .zero)
        return builder.document
    }

    // MARK: - The store

    @Test("The newest document is the one a launch opens, whatever it is called")
    func theNewestDocumentWinsByDate() throws {
        let store = temporaryStore()
        let older = store.url(named: "Kollio")
        let newer = store.url(named: "Kollio-20260101-000000-AAAA")
        try store.save(document(with: "plus ancien"), to: older)
        try store.save(document(with: "plus récent"), to: newer)

        // The default name is not a claim about which file is the work. When it was,
        // this returned the older file and the newer one was never opened again.
        #expect(store.mostRecentDocumentURL?.path == newer.path)
    }

    @Test("An empty document on disk does not shadow real work")
    func anEmptyFileDoesNotShadowWork() throws {
        let store = temporaryStore()
        // The exact situation this machine was in: an empty default file, written
        // hours before the real document.
        try store.save(KollioDocument(), to: store.defaultDocumentURL)
        let work = store.url(named: "Kollio-20260101-000000-BBBB")
        try store.save(document(with: "le travail"), to: work)

        // A launch opens the work. Opening the empty file would show the invitation
        // and look exactly like losing everything.
        let opened = try store.load(try #require(store.mostRecentDocumentURL))
        #expect(opened.content.isEmpty == false)
        #expect(opened.objects.first?.text.text.contains("le travail") == true)
    }

    @Test("No document on disk means no document to open")
    func nothingStored() {
        let store = temporaryStore()
        #expect(store.mostRecentDocumentURL == nil)
    }

    // MARK: - The model

    @Test("A quit with nothing in the document writes nothing")
    func anEmptyDocumentIsNotWritten() {
        let store = temporaryStore()
        let model = KollioModel(
            document: KollioDocument(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        #expect(model.save())
        // Reported as a success, because there was nothing to fail at, and nothing
        // was written.
        #expect(FileManager.default.fileExists(atPath: model.documentURL.path) == false)
        #expect(store.mostRecentDocumentURL == nil)
    }

    @Test("Work is written on quit, and the next launch opens it")
    func workSurvivesAQuitAndIsReopened() throws {
        let store = temporaryStore()
        let first = KollioModel(
            document: document(with: "réduire l'inscription"),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        // A new document gets its own file, so the previous one is not overwritten.
        first.adoptNewSaveTargetForTest()
        #expect(first.save())
        let written = try #require(store.mostRecentDocumentURL)

        // The next launch, with no document handed to it: what a person does.
        let second = KollioModel(
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        #expect(second.documentURL == written)
        #expect(second.loadFailure == nil)
        #expect(second.document.objects.first?.text.text.contains("réduire l'inscription") == true)
        #expect(second.isEmpty == false)
    }

    @Test("Two documents written in turn: the second is the one that opens")
    func theSecondDocumentIsTheOneThatOpens() throws {
        let store = temporaryStore()
        let first = KollioModel(
            document: document(with: "le premier"), service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        first.adoptNewSaveTargetForTest()
        #expect(first.save())

        let second = KollioModel(
            document: document(with: "le second"), service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        second.adoptNewSaveTargetForTest()
        #expect(second.save())

        let reopened = KollioModel(
            service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store
        )
        #expect(reopened.document.objects.first?.text.text.contains("le second") == true)
        // The first is still on disk: a new document never destroys the previous one.
        #expect(store.mostRecentDocumentURL?.path == second.documentURL.path)
    }
}
