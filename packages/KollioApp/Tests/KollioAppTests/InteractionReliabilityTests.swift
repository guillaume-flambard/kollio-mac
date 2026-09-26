import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// Records every request it receives so a test can prove what the model actually
/// asked the intelligence source, and can fail the call on demand.
final class CapturingSuggestionService: SuggestionService, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [ProposalRequest] = []
    private let failure: (any Error)?

    init(failingWith failure: (any Error)? = nil) {
        self.failure = failure
    }

    var capabilities: SuggestionCapabilities { .offline }

    var requests: [ProposalRequest] {
        lock.withLock { stored }
    }

    func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        lock.withLock { stored.append(request) }
        if let failure { throw failure }
        return .noChange()
    }
}

struct ServiceUnavailable: Error {}

/// What the canvas must do with a person's words and with their document: the
/// typed sentence has to reach the intelligence source, the work has to survive
/// a quit without Cmd+S, and a local decision must not move the view.
@Suite("Interaction reliability")
@MainActor
struct InteractionReliabilityTests {
    private func isolatedStore() -> (DocumentFileStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-interaction-\(UUID().uuidString)")
        return (DocumentFileStore(directory: directory), directory)
    }

    // MARK: A. The typed sentence

    /// CTX-01 changed where this sentence lives, not whether it survives.
    ///
    /// It used to reach the intelligence source, and this test proved it could not be
    /// dropped on the way there. It is now written into the document first and the
    /// source is asked separately, so the guarantee is stronger rather than different:
    /// the sentence is not on its way to anywhere, it has arrived.
    @Test("What the user typed reaches the document, not only a request")
    func composerTextIsNotDropped() async {
        let service = CapturingSuggestionService()
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: service, fileStore: store)
        let typed = "Et si on Demand exportait aussi les étiquettes ?"

        model.startComposer(anchor: KollioID.object("sarah-csv"), intent: .add)
        model.composer?.text = typed
        await model.submitComposer()

        // The sentence is the whole point of the composer. It cannot be dropped.
        #expect(model.document.content.values.contains { $0.text.text == typed })
        // And nothing was spent asking for it: that is a separate, later action.
        #expect(service.requests.isEmpty)
    }

    /// Losing work is the worst failure this app can have. Where the draft now goes
    /// depends on the intent, and both destinations are checked: a note that was
    /// written, and a draft that is still there when the write was refused.
    @Test("Typed work survives every failure on the way")
    func typedWorkSurvives() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let typed = "Une phrase que je ne veux pas perdre"
        let anchor = KollioID.object("sarah-csv")

        // Add writes locally, so there is no service that can take the sentence away.
        let failing = CapturingSuggestionService(failingWith: ServiceUnavailable())
        let adding = KollioModel(document: SarahFixture.document(), service: failing, fileStore: store)
        adding.startComposer(anchor: anchor, intent: .add)
        adding.composer?.text = typed
        await adding.submitComposer()
        #expect(adding.document.content.values.contains { $0.text.text == typed })

        // Edit goes through the command system, and a refused write leaves the draft
        // in the composer, ready to retry.
        let editing = KollioModel(document: SarahFixture.document(),
                                  service: CapturingSuggestionService(), fileStore: store)
        editing.startComposer(anchor: anchor, intent: .edit)
        editing.composer?.text = typed
        // Pretend the object moved on while the draft was open, which is the honest
        // way to make the write be refused rather than forcing a failure.
        editing.composer?.baseVersion = 99
        await editing.submitComposer()
        #expect(editing.composer?.text == typed)
        #expect(editing.object(anchor)?.text.text != typed)
    }

    @Test("An empty composer adds nothing and asks nothing")
    func emptyComposerIsANoOp() async {
        let service = CapturingSuggestionService()
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: service, fileStore: store)

        model.startComposer(anchor: KollioID.object("sarah-csv"), intent: .add)
        model.composer?.text = "   "
        await model.submitComposer()
        #expect(service.requests.isEmpty)
    }

    // MARK: B. Save on quit

    @Test("Quitting without Cmd+S still saves the document")
    func quitSavesWithoutAnExplicitSave() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)

        // The person explores, keeps, and then quits with the mouse.
        await model.explore(KollioID.object("sarah-csv"))
        model.keepPreview()
        let keptRevision = model.document.semanticRevision
        #expect(keptRevision > 0)

        // No Cmd+S anywhere in this test. This is the delegate's job.
        model.save()

        // Relaunch: a new model, reading only what reached the disk.
        let relaunched = KollioModel(document: nil, service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        #expect(relaunched.document.content.count == 9)
        #expect(relaunched.document.semanticRevision == keptRevision)
    }

    @Test("Quitting through the real delegate saves the document")
    func quittingThroughTheDelegateSaves() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)

        // The work happens with no Cmd+S, exactly as in a real session.
        await model.explore(KollioID.object("sarah-csv"))
        model.keepPreview()
        let keptRevision = model.document.semanticRevision

        // The quit path, not save() directly: this is the wiring under test.
        let delegate = AppDelegate()
        delegate.model = model
        #expect(delegate.applicationShouldTerminate(NSApplication.shared) == .terminateNow)

        let relaunched = KollioModel(document: nil, service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        #expect(relaunched.document.content.count == 9)
        #expect(relaunched.document.semanticRevision == keptRevision)
    }

    @Test("A document edited with no delegate still reaches the disk")
    func saveStillWorksWithoutTheDelegate() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        await model.explore(KollioID.object("sarah-csv"))
        model.keepPreview()
        let revision = model.document.semanticRevision
        #expect(model.save())
        let relaunched = KollioModel(document: nil, service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        #expect(relaunched.document.semanticRevision == revision)
    }

    // MARK: C. The camera stays where the user left it

    @Test("Setting a direction aside does not move the camera")
    func setAsideKeepsTheCamera() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        model.camera = Camera(zoom: 1.8, translation: Position(x: -140, y: 96))
        let before = model.camera

        model.setAside(KollioID.object("sarah-csv"), reason: "Pas maintenant")

        // Cmd+0 is the explicit fit command. A local decision is not that.
        #expect(model.camera == before)
    }

    @Test("Reopening does not move the camera")
    func reopenKeepsTheCamera() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        model.setAside(KollioID.object("sarah-csv"), reason: "Pas maintenant")
        model.camera = Camera(zoom: 0.75, translation: Position(x: 220, y: -60))
        let before = model.camera

        model.reopen(KollioID.object("sarah-csv"))

        #expect(model.camera == before)
    }

    @Test("Reopening restores the exact same objects and positions")
    func reopenDoesNotReorganise() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        let before = Dictionary(
            uniqueKeysWithValues: model.document.presentation.instances.map { ($0.objectID, $0.position) }
        )
        model.setAside(KollioID.object("sarah-csv"), reason: "Pas maintenant")
        model.reopen(KollioID.object("sarah-csv"))
        for instance in model.document.presentation.instances {
            #expect(instance.position == before[instance.objectID])
        }
    }

    @Test("Cmd+0 is still the explicit way to fit the content")
    func fitContentStillWorks() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel(document: SarahFixture.document(), service: KollioModel.makeDemoService(languageCode: "fr"), fileStore: store)
        model.camera = Camera(zoom: 2.5, translation: Position(x: 900, y: 900))
        model.fitContent()
        // Fitting really reframes: the content is centred in the viewport.
        let bounds = try? #require(model.contentBounds())
        #expect(bounds != nil)
        if let bounds {
            let centre = model.camera.toScreen(bounds.center)
            #expect(abs(centre.x - (model.viewport.width / 2)) < 120)
        }
    }
}
