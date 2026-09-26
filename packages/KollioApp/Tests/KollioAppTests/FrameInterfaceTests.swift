import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// Putting things in a frame from the interface, and folding one away.
///
/// What is worth protecting is the whole path: the action appears only with a
/// selection, the frame is named by the person rather than by the app, folding
/// hides the drawings in the view and changes nothing else, the drag is one
/// transaction, and one undo puts it all back.
@Suite("Frames from the interface")
@MainActor
struct FrameInterfaceTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    private let crm = ObjectID("object:sarah-crm")
    private let csv = ObjectID("object:sarah-csv")
    private let blocked = ObjectID("object:sarah-blocked")

    @Test("A frame is offered only with something selected")
    func theActionFollowsTheSelection() {
        var model = model()
        model.selection = []
        #expect(model.contextualActions(for: crm).contains(.groupInFrame) == false)

        model.selection = [crm, blocked]
        let actions = model.contextualActions(for: crm)
        #expect(actions.contains(.groupInFrame))
        // Behind the one named control: the specification fixes three primary
        // actions for an ordinary idea and this is not one of them.
        #expect(actions.primary.contains(.groupInFrame) == false)
        #expect(actions.secondary.contains(.groupInFrame))
    }

    @Test("A frame holds the selection's drawings and nothing else")
    func aFrameHoldsTheSelection() throws {
        var model = model()
        model.selection = [crm, csv]
        let id = try #require(model.createFrame(named: "The two directions"))

        let frame = try #require(model.frame(id))
        #expect(frame.name.text == "The two directions")
        #expect(frame.memberInstanceIDs.count == 2)
        #expect(frame.memberInstanceIDs.contains(try #require(model.document.presentation.instance(for: crm)?.id)))
        // The frame is presentation, so creating one is not a change of meaning.
        #expect(model.document.semanticRevision == SarahFixture.document().semanticRevision)
    }

    @Test("An empty frame is refused rather than invented")
    func anEmptyFrameIsRefused() {
        var model = model()
        model.selection = []
        #expect(model.createFrame(named: "Nothing") == nil)
        #expect(model.canvasFrames.isEmpty)
        #expect(model.status != nil)
    }

    @Test("The frame is named by the person, and the name is kept on a refusal")
    func theNameIsTypedAndKept() throws {
        var model = model()
        model.selection = [crm]
        let id = try #require(model.createFrame(named: ""))

        // Created with a placeholder name, then asked for: the person names their
        // own frame, and the field opens with what is already there.
        model.startRenaming(id)
        #expect(model.renamingFrameID == id)
        #expect(model.renamingFrameDraft == L10n.frameDefaultName)

        // Blank is refused and the sentence stays in the field, because a frame
        // whose name is gone is harder to find than one whose name is empty.
        model.renamingFrameDraft = "   "
        #expect(model.submitFrameName() == false)
        #expect(model.renamingFrameID == id)
        #expect(model.status != nil)

        model.renamingFrameDraft = "Direct connection"
        #expect(model.submitFrameName())
        #expect(model.frame(id)?.name.text == "Direct connection")
        #expect(model.renamingFrameID == nil)
        #expect(model.renamingFrameDraft.isEmpty)
    }

    @Test("Renaming a frame does not rename what is inside it")
    func renamingTouchesNothingInside() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Blocked"))
        let before = model.document

        #expect(model.renameFrame(id, to: "The credentials problem"))
        #expect(model.frame(id)?.name.text == "The credentials problem")
        // Every word the person wrote, and every link, is byte-identical.
        #expect(model.document.content == before.content)
        #expect(model.document.relationships == before.relationships)
    }

    @Test("Folding hides the drawings in this view and changes nothing else")
    func foldingIsAViewState() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Two"))
        let members = try #require(model.frame(id)).memberInstanceIDs
        let content = model.document.content
        let decisions = model.document.decisions
        let semantic = model.document.semanticRevision

        #expect(model.toggleFold(id))
        // Hidden in the view, and gone from the connectors too, since a line to
        // something nobody can see is a line to nowhere.
        for member in members {
            #expect(model.visibleInstances.contains { $0.id == member } == false)
        }
        // And nothing else: not the text, not a decision, not the meaning.
        #expect(model.document.content == content)
        #expect(model.document.decisions == decisions)
        #expect(model.document.semanticRevision == semantic)
        #expect(model.document.objects.allSatisfy { $0.lifecycle == .active })

        #expect(model.toggleFold(id))
        // The members are back in the view, and so is everything that was never in
        // the frame: unfolding a frame does not disturb the rest of the canvas.
        let visible = Set(model.visibleInstances.map(\.id))
        #expect(Set(members).isSubset(of: visible))
        #expect(visible == Set(model.document.presentation.instances.map(\.id)))
    }

    @Test("A folded frame keeps the object that is also drawn elsewhere")
    func aSharedObjectStaysVisible() throws {
        var model = model()
        // The same idea drawn twice: once to be framed, once left alone.
        let original = try #require(model.document.presentation.instance(for: crm)?.id)
        let copy = try #require(model.duplicateOccurrence(of: original))
        model.selection = [crm]
        let id = try #require(model.createFrame(named: "One drawing"))

        #expect(model.toggleFold(id))
        // The framed drawing is gone from the view and the other one is not, which
        // is what "an object shared elsewhere stays visible" has to mean.
        #expect(model.visibleInstances.contains { $0.id == original } == false)
        #expect(model.visibleInstances.contains { $0.id == copy })

        // A folded frame's members are counted, not summarised: the chip says how
        // much is inside, so folding never looks like a branch was closed.
        let frame = try #require(model.frame(id))
        #expect(frame.isFolded)
        #expect(frame.memberInstanceIDs == [original])
    }

    @Test("Moving a frame moves its members and one undo puts them back")
    func movingIsOneTransaction() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Two"))
        let members = try #require(model.frame(id)).memberInstanceIDs
        let before = model.document

        #expect(model.moveFrame(id, by: Position(x: 120, y: 60)))
        for member in members {
            let was = try #require(before.presentation.instance(id: member)).position
            let now = try #require(model.document.presentation.instance(id: member)).position
            #expect(now.x == was.x + 120 && now.y == was.y + 60)
        }

        model.undo()
        #expect(model.document.presentation == before.presentation)
    }

    @Test("A drag on a frame draws live and writes once")
    func aFrameDragIsOneWrite() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Two"))
        let before = model.document
        let member = try #require(model.frame(id)).memberInstanceIDs[0]

        model.beginFrameDrag(id, screenTranslation: CGSize(width: 40, height: 20))
        #expect(model.frameDragOffset(for: id) != .zero)
        // The node inside follows the frame while the pointer moves, and the document
        // is untouched until the pointer is released.
        #expect(model.nodeDragOffset(for: member) != .zero)
        #expect(model.document == before)

        model.endFrameDrag()
        #expect(model.frameDrag == nil)
        #expect(model.document != before)
        #expect(model.document.revision == before.revision + 1)
    }

    @Test("A cancelled frame drag writes nothing")
    func cancellingWritesNothing() throws {
        var model = model()
        model.selection = [crm]
        let id = try #require(model.createFrame(named: "One"))
        let before = model.document
        model.beginFrameDrag(id, screenTranslation: CGSize(width: 80, height: 40))
        model.cancelFrameDrag()
        #expect(model.document == before)
    }

    @Test("A member can be taken out, and stays where it is")
    func aMemberCanLeave() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Two"))
        let members = try #require(model.frame(id)).memberInstanceIDs
        let positions = Dictionary(uniqueKeysWithValues: try members.map { member in
            (member, try #require(model.document.presentation.instance(id: member)).position)
        })

        #expect(model.removeFromFrame(id, instanceID: members[0]))
        #expect(model.frame(id)?.memberInstanceIDs == [members[1]])
        // Nothing moved on the way out: leaving a frame is not a move.
        for member in members {
            #expect(model.document.presentation.instance(id: member)?.position == positions[member])
        }
        #expect(model.visibleInstances.count == model.document.presentation.instances.count)
    }

    @Test("Removing a frame leaves its members, and one undo brings it back")
    func removingIsUndoable() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Two"))
        let presentation = model.document.presentation

        #expect(model.removeFrame(id))
        #expect(model.canvasFrames.isEmpty)
        #expect(model.document.presentation.instances == presentation.instances)

        model.undo()
        #expect(model.canvasFrames.count == 1)
    }

    @Test("Escape closes the name field before the selection")
    func escapeClosesTheFieldFirst() throws {
        var model = model()
        model.selection = [crm]
        let id = try #require(model.createFrame(named: "One"))
        model.startRenaming(id)
        #expect(model.dismissOneLevel() == .frameName)
        #expect(model.selection == [crm])
        #expect(model.renamingFrameID == nil)
        // The frame keeps the name it had; closing a field is not a decision.
        #expect(try #require(model.frame(id)).name.text == "One")
    }

    @Test("A frame survives a save and a reload")
    func framesArePersisted() throws {
        var model = model()
        model.selection = [crm, blocked]
        let id = try #require(model.createFrame(named: "Two directions"))
        _ = model.setFolded(id, true)

        let url = model.fileStore.url(named: "frames")
        try model.fileStore.save(model.document, to: url)
        let reloaded = try model.fileStore.load(url)
        // Folding and the name are the two things a person would be annoyed to lose
        // on quit, so both are checked rather than the count.
        #expect(reloaded.presentation.frames.count == 1)
        #expect(reloaded.presentation.frame(id)?.name.text == "Two directions")
        #expect(reloaded.presentation.frame(id)?.isFolded == true)
        #expect(reloaded.presentation.hiddenInstanceIDs().count == 2)
    }

    @Test("Intelligence is refused the frame commands")
    func intelligenceCannotArrangeTheCanvas() throws {
        let document = SarahFixture.document()
        let proposal = Proposal(
            proposalId: "p1",
            requestId: "r1",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("tidy up"),
            operations: [.setFrameFolded(.init(id: "frame:x", isFolded: true))],
            generator: .init(name: "test", deterministic: true)
        )
        #expect(throws: DocumentError.self) {
            try ProposalValidator().validate(
                proposal, against: document, scope: .init(maxOperations: 32, allowNewObjects: true)
            )
        }
    }
}
