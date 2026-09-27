import Foundation
import Testing
@testable import KollioApp
import KollioCore

/// CAN-10 at the interface: reading the document along a path, and the three
/// things that make that safe.
///
/// AC01 a complete keyboard path, AC02 exit returns to the previous context, AC03
/// no model call to present. The path itself is proved in `ReadingPathTests`.
@Suite("Presentation in the interface")
@MainActor
struct PresentationInterfaceTests {
    /// Records an issue if anything asks it for a proposal. AC03 is proved by the
    /// absence of a call, so the failure has to be the proof.
    private final class ExplodingService: SuggestionService, @unchecked Sendable {
        var capabilities: SuggestionCapabilities {
            SuggestionCapabilities(intents: [.explore, .add, .clarify], deterministic: false, requiresNetwork: true)
        }
        func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
            Issue.record("presenting the document asked the intelligence source for a proposal")
            return .noChange()
        }
    }

    private func model(service: (any SuggestionService)? = nil) -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: service ?? KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    // MARK: - AC01, a complete keyboard path

    @Test("AC01: a tour is started, walked and left without touching a pointer")
    func theWholePathIsReachable() throws {
        let model = model()
        // Start.
        #expect(model.beginPresentation())
        #expect(model.isPresenting)
        let session = try #require(model.presentation)
        // Walk forwards to the end of the document.
        var steps = 0
        while model.advancePresentation() { steps += 1 }
        #expect(steps == session.count - 1)
        // And all the way back, then no further.
        while model.rewindPresentation() {}
        #expect(model.presentation?.index == 0)
        #expect(model.rewindPresentation() == false)
        // And leave, through Escape rather than a button.
        #expect(KollioModel.TransientLevel.topmost(in: model) == .presentation)
        #expect(model.dismissOneLevel() == .presentation)
        #expect(model.isPresenting == false)
    }

    @Test("A tour walks forwards and backwards over the same steps")
    func walkingIsSymmetric() throws {
        let model = model()
        #expect(model.beginPresentation())
        let count = try #require(model.presentation).count
        #expect(count > 2)
        #expect(model.advancePresentation())
        #expect(model.advancePresentation())
        #expect(model.presentation?.index == 2)
        #expect(model.rewindPresentation())
        #expect(model.presentation?.index == 1)
        // It stops at the ends rather than wrapping: a tour that wraps is a
        // carousel, and the reader loses track of where they are in the document.
        #expect(model.advancePresentation() == false || model.advancePresentation())
        while model.advancePresentation() {}
        #expect(model.presentation?.index == count - 1)
        #expect(model.advancePresentation() == false)
    }

    @Test("The step says what kind of thing it is")
    func theStepIsNamed() throws {
        let model = model()
        #expect(model.beginPresentation())
        let session = try #require(model.presentation)
        // A document is its objects, its evidence and its reasoning. A step that did
        // not say which one it was would leave a reader following nothing.
        let kinds = Set(session.resolution.entries.map(\.kind))
        #expect(kinds.contains(.object))
        #expect(session.resolution.entries.first?.kind == .object)
        #expect(session.position == 1, "one-based, so the first step is not '0 of n'")
    }

    @Test("A tour over an empty document is refused rather than opened over nothing")
    func anEmptyDocumentHasNothingToRead() {
        let model = KollioModel(
            document: KollioDocument(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
        #expect(model.beginPresentation() == false)
        #expect(model.isPresenting == false)
        #expect(model.status == L10n.presentationNothingToPresent)
    }

    // MARK: - AC02, exit returns to the previous context

    @Test("AC02: leaving puts the camera back exactly where it was")
    func exitRestoresTheCamera() throws {
        let model = model()
        // Put the view somewhere deliberate, not at the default, so "restored" cannot
        // be satisfied by the tour never having moved it.
        model.camera = Camera(zoom: 0.42, translation: Position(x: 137, y: -88))
        let before = model.camera
        #expect(model.beginPresentation())
        let during = try #require(model.presentation).didMoveCamera
        #expect(during, "the first step should have moved the view")
        #expect(model.camera != before)

        model.exitPresentation()
        // The exact camera, not a reframe that happens to look similar.
        #expect(model.camera == before)
        #expect(model.camera.zoom == 0.42)
        #expect(model.isPresenting == false)
    }

    @Test("AC02: leaving through Escape restores the camera too")
    func escapeRestoresTheCamera() throws {
        let model = model()
        model.camera = Camera(zoom: 1.3, translation: Position(x: -20, y: 64))
        let before = model.camera
        #expect(model.beginPresentation())
        model.advancePresentation()
        model.dismissOneLevel()
        #expect(model.camera == before)
    }

    @Test("AC02: a tour moves the view, and reading it changes nothing else")
    func aTourChangesNoStatus() throws {
        let model = model()
        let documentBefore = model.document
        let semanticBefore = model.document.semanticRevision
        #expect(model.beginPresentation())
        model.advancePresentation()
        model.advancePresentation()
        // The view moved and the selection followed it, which is where the reader
        // is. Nothing else did.
        #expect(model.document == documentBefore)
        #expect(model.document.semanticRevision == semanticBefore)
        #expect(model.canUndo == false)
    }

    @Test("A tour closes the cards that were open, rather than sitting on top of them")
    func aTourClearsWhatWasOpen() {
        let model = model()
        model.openSearch()
        model.updateSearch("export")
        #expect(model.composer == nil)
        #expect(model.beginPresentation())
        // A reading mode with a claim editor open underneath is a trap: a stray
        // keystroke lands in a field the person cannot see.
        #expect(model.search == nil)
    }

    // MARK: - A reader cannot change the document

    @Test("Nothing can be written while a tour is running")
    func aReaderCannotChangeTheDocument() throws {
        let model = model()
        #expect(model.beginPresentation())
        let documentBefore = model.document
        let semanticBefore = model.document.semanticRevision

        // Every shape a change can take, including the one that goes straight to
        // the session rather than through `perform`.
        model.setAside(KollioID.object("sarah-csv"), reason: "parce que")
        model.reopen(KollioID.object("sarah-csv"))
        model.createIdea("Une idée", near: KollioID.object("sarah-csv"))
        model.perform([.updateObjectText(UpdateObjectText(
            id: KollioID.object("sarah-csv"), text: LocalizedText("autre chose"),
            provenance: .human("me")
        ))], label: "test")
        model.editRelationship(RelationshipID("relationship:sarah-l2"), .retitle(LocalizedText("autre chose")))
        model.keepPreview()
        model.discardPreview()
        model.perform([.moveNodeInstances(MoveNodeInstances(moves: []))], label: "test")
        model.perform([.recordDecision(.init(
            id: "decision:while-presenting", kind: .setAside,
            targetObjectID: KollioID.object("sarah-csv"),
            rationale: LocalizedText("non"), provenance: .human("me")
        ))], label: "test")

        #expect(model.document == documentBefore)
        #expect(model.document.semanticRevision == semanticBefore)
        // And it says so, because a key that does nothing is worse than one that
        // explains itself.
        #expect(model.status == L10n.presentationReadOnly)
    }

    @Test("No editing command is offered while a tour is running")
    func noEditingCommandIsOffered() throws {
        let model = model()
        let target = KollioID.object("sarah-csv")
        // Before, the object offers the three the specification names.
        #expect(model.contextualActions(for: target).contains(.explore))
        #expect(model.beginPresentation())
        let actions = model.contextualActions(for: target)
        // After, it offers nothing at all. The command layer refuses a write in
        // either case, but a person invited to press something during a tour is
        // being invited to find out.
        #expect(actions.primary.isEmpty)
        #expect(actions.secondary.isEmpty)
        #expect(actions.isDefault == nil)
        // The bar is not drawn at all rather than drawn empty, which is why the set
        // is empty above and not merely primary-less: an empty bar with a "More"
        // control in it is a menu of nothing.
        #expect(actions.isEmpty == false)
        // And the tour's own navigation is untouched by any of that.
        #expect(model.advancePresentation())
    }

    @Test("The document can be changed again once the tour is over")
    func writingWorksAgainAfterwards() throws {
        let model = model()
        #expect(model.beginPresentation())
        model.setAside(KollioID.object("sarah-csv"), reason: "parce que")
        model.exitPresentation()
        model.setAside(KollioID.object("sarah-csv"), reason: "parce que")
        #expect(model.document.object("object:sarah-csv")?.isSetAside == true)
        #expect(model.document.semanticRevision > 0)
    }

    // MARK: - AC03, no model call to present

    @Test("AC03: presenting asks no model, on any of its steps")
    func presentingAsksNoModel() throws {
        let model = model(service: ExplodingService())
        #expect(model.beginPresentation())
        while model.advancePresentation() {}
        model.rewindPresentation()
        model.exitPresentation()
        // Not one call: the seam is not touched at all. A presentation is a reading
        // of what is already in the document, and there is nothing to ask about it.
        #expect(model.isPresenting == false)
    }

    // MARK: - Skipped points

    @Test("A point that is gone is counted, and the steps around it keep their places")
    func aSkippedPointIsCounted() throws {
        let model = model()
        // A path chosen against a document, with one point removed before the tour.
        let path = ReadingPath(objects: [
            KollioID.object("sarah-csv"),
            KollioID.object("sarah-question"),
            KollioID.object("sarah-viable"),
        ])
        try #require(model.perform([.removeObject(.init(id: KollioID.object("sarah-question")))], label: "test"))
        #expect(model.beginPresentation(path: path))
        let session = try #require(model.presentation)
        #expect(session.resolution.skipped.count == 1)
        #expect(session.resolution.isPartial)
        #expect(session.count == 2)
        // The tour is two steps long and both are the ones that are there: the
        // reader is not shown something else in the gap's place.
        #expect(session.resolution.entries.map(\.point) == [
            .object(KollioID.object("sarah-csv")), .object(KollioID.object("sarah-viable")),
        ])
    }

    // MARK: - Strings

    @Test("Every string the tour shows is a translated one")
    func tourStringsAreLocalized() {
        let strings = [
            L10n.presentation, L10n.presentationStart, L10n.presentationExit,
            L10n.presentationNext, L10n.presentationPrevious, L10n.presentationReadOnly,
            L10n.presentationNothingToPresent, L10n.presentationSkipped,
            L10n.presentationNoAnchor, L10n.presentationOpenSource,
            L10n.presentationKindObject, L10n.presentationKindSource, L10n.presentationKindDecision,
            L10n.presentationProgress(2, 7),
        ]
        for string in strings {
            #expect(string.isEmpty == false)
            #expect(string.contains("presentation.") == false, "a key is never shown: \(string)")
        }
        #expect(L10n.presentationProgress(2, 7).contains("2"))
        #expect(L10n.presentationProgress(2, 7).contains("7"))
    }
}
