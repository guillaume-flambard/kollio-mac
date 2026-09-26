import Foundation
import Testing
@testable import KollioCore

/// CAN-07: a named frame with explicit members.
///
/// The behaviours worth protecting are the ones where "just a visual grouping" would
/// quietly become a business change: a fold that sets a branch aside, a frame move
/// that drags an unrelated drawing along, a rename that reaches the sources, and a
/// membership that nobody can take back.
@Suite("Frames")
struct FrameTests {
    private func world() -> KollioDocument {
        var builder = DocumentBuilder()
        builder.object("one", kind: .hypothesis, "First")
        builder.object("two", kind: .hypothesis, "Second")
        builder.object("three", kind: .hypothesis, "Third elsewhere")
        builder.link("l1", from: ObjectID("object:one"), to: ObjectID("object:two"), .alternativeTo)
        return builder.document
    }

    private var one: ObjectID { ObjectID("object:one") }
    private var two: ObjectID { ObjectID("object:two") }
    private var three: ObjectID { ObjectID("object:three") }

    private func instance(_ document: KollioDocument, _ objectID: ObjectID) throws -> InstanceID {
        try #require(document.presentation.instance(for: objectID)?.id)
    }

    private func frame(_ members: [ObjectID], in document: KollioDocument) -> Frame {
        Frame(
            id: FrameID("frame:test"),
            name: LocalizedText("A group"),
            position: .zero,
            memberInstanceIDs: members.compactMap { document.presentation.instance(for: $0)?.id }
        )
    }

    // MARK: AC01 folding is not a decision

    @Test("Folding changes no business status at all")
    func foldingIsNotADecision() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let frame = frame([one, two], in: document)
        #expect(try store.apply([.createFrame(.init(frame: frame))]).semanticRevision == document.semanticRevision)

        let created = store.document
        let folded = try store.apply([.setFrameFolded(.init(id: frame.id, isFolded: true))])
        #expect(folded.semanticRevision == document.semanticRevision)
        // One presentation step, and it is counted as one, so the undo that undoes it
        // is a single press rather than two.
        #expect(folded.revision == created.revision + 1)
        // Nothing about the objects changed: not their lifecycle, not their text, not
        // their version. A fold is a way of looking at the canvas.
        for object in [one, two] {
            #expect(folded.object(object) == document.object(object))
        }
        #expect(folded.decisions.isEmpty)
        // The frame hides exactly the occurrences it holds, and only those.
        #expect(Set(folded.presentation.hiddenInstanceIDs())
                == Set(folded.presentation.frame(frame.id)!.memberInstanceIDs))
    }

    @Test("Unfolding brings back exactly what was there")
    func unfoldingIsTheInverse() throws {
        var store = DocumentStore(document: world())
        let before = store.document
        let frame = frame([one], in: before)
        try store.apply([.createFrame(.init(frame: frame))])
        // The state a fold is supposed to be able to undo: the frame, unfolded.
        let unfolded = store.document
        try store.apply([.setFrameFolded(.init(id: frame.id, isFolded: true))])
        #expect(store.document.presentation.hiddenInstanceIDs().isEmpty == false)
        _ = try store.apply([.setFrameFolded(.init(id: frame.id, isFolded: false))])
        // Exactly the state before the fold, not merely "something similar".
        #expect(store.document.presentation == unfolded.presentation)
        #expect(store.document.content == before.content)
        #expect(store.document.decisions.isEmpty)
    }

    @Test("Folding is not undoable through the canvas as a decision")
    func foldingLeavesDecisionsAlone() throws {
        var store = DocumentStore(document: world())
        let frame = frame([one], in: store.document)
        try store.apply([.createFrame(.init(frame: frame))])
        // A branch a person really set aside is still set aside, and folding a frame
        // is not a way to reopen it behind their back.
        let aside = try store.apply([.recordDecision(.init(
            id: DecisionID("decision:aside"),
            kind: .setAside,
            targetObjectID: two,
            provenance: .human("local-user")
        ))])
        _ = try store.apply([.setFrameFolded(.init(id: frame.id, isFolded: true))])
        // The only thing that changed is the flag on the frame: the decision, the
        // branch it closed and the object it closed are exactly as they were.
        #expect(store.document.content == aside.content)
        #expect(store.document.decisions == aside.decisions)
        #expect(store.document.presentation.instances == aside.presentation.instances)
        #expect(store.document.presentation.frame(frame.id)?.isFolded == true)
        #expect(aside.object(two)?.isSetAside == true)
    }

    // MARK: AC02 moving preserves offsets

    @Test("Moving a frame moves its members by the same delta")
    func movingPreservesOffsets() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let frame = frame([one, two], in: document)
        try store.apply([.createFrame(.init(frame: frame))])

        let before = store.document.presentation
        let delta = Position(x: 60, y: -25)
        _ = try store.apply([.moveFrame(.init(id: frame.id, delta: delta))])
        let after = store.document.presentation

        // The distance between the two members is untouched, which is the whole of
        // AC02: a group is moved, not reassembled.
        let firstBefore = try #require(before.instance(for: one))
        let secondBefore = try #require(before.instance(for: two))
        let firstAfter = try #require(after.instance(for: one))
        let secondAfter = try #require(after.instance(for: two))
        #expect(firstAfter.position.x - secondAfter.position.x
                == firstBefore.position.x - secondBefore.position.x)
        #expect(firstAfter.position.y - secondAfter.position.y
                == firstBefore.position.y - secondBefore.position.y)
        // The frame travels with its contents, so it never has to be told twice.
        #expect(try #require(store.document.presentation.frame(frame.id)).position
                == frame.position.offset(dx: delta.x, dy: delta.y))
    }

    @Test("Moving a frame is presentation only")
    func movingIsNotSemantic() throws {
        var store = DocumentStore(document: world())
        let frame = frame([one, two], in: store.document)
        let semantic = store.document.semanticRevision
        try store.apply([.createFrame(.init(frame: frame))])
        let moved = try store.apply([.moveFrame(.init(id: frame.id, delta: Position(x: 10, y: 10)))])
        #expect(moved.semanticRevision == semantic)
    }

    // MARK: AC03 other occurrences stay independent

    @Test("A second drawing of a member's object does not travel with the frame")
    func otherOccurrencesStayPut() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let original = try instance(document, one)

        // The same idea drawn a second time, somewhere else entirely.
        let copy = InstanceID("instance:one-elsewhere")
        _ = try store.apply([.duplicateNodeInstance(.init(instanceID: original, id: copy))])
        let moved = try #require(store.document.presentation.instance(id: copy))
        let positionBefore = moved.position

        // The frame holds the *first* drawing only.
        let frame = frame([one], in: store.document)
        try store.apply([.createFrame(.init(frame: frame))])
        _ = try store.apply([.moveFrame(.init(id: frame.id, delta: Position(x: 200, y: 140)))])

        #expect(store.document.presentation.frame(frame.id)?.memberInstanceIDs == [original])
        #expect(store.document.presentation.instance(id: copy)?.position == positionBefore)
        #expect(store.document.presentation.instance(id: original)?.position
                != positionBefore)
    }

    @Test("An occurrence belongs to one frame only")
    func anOccurrenceIsInOneFrame() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let members = [try instance(document, one)]
        let first = Frame(id: "frame:a", name: LocalizedText("A"), position: .zero, memberInstanceIDs: members)
        let second = Frame(id: "frame:b", name: LocalizedText("B"), position: .zero)
        _ = try store.apply([.createFrame(.init(frame: first))])
        _ = try store.apply([.createFrame(.init(frame: second))])
        #expect(store.document.presentation.frame(containing: members[0])?.id == "frame:a")

        // Two overlapping frames are fine. A drawing in both is not, and it is
        // refused rather than resolved by a rule: a fold would have to hide it in one
        // and leave it visible in the other, and which one is the fold's business.
        #expect(throws: DocumentError.self) {
            try store.apply([.setFrameMembers(.init(id: "frame:b", memberInstanceIDs: members))])
        }
        #expect(store.document.presentation.frame("frame:b")?.memberInstanceIDs.isEmpty == true)
    }

    @Test("Overlapping frames do not cascade")
    func overlapCascadesNothing() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        // Two frames that overlap on the canvas and share no member: the overlap is
        // a coincidence of where a person drew them, not a statement about either.
        let first = Frame(
            id: "frame:a", name: LocalizedText("A"),
            position: document.presentation.instance(for: one)!.position,
            memberInstanceIDs: [try instance(document, one), try instance(document, two)]
        )
        let second = Frame(
            id: "frame:b", name: LocalizedText("B"),
            // Deliberately on top of the first frame's members.
            position: document.presentation.instance(for: one)!.position,
            memberInstanceIDs: [try instance(document, three)]
        )
        try store.apply([.createFrame(.init(frame: first)), .createFrame(.init(frame: second))])
        let before = store.document
        _ = try store.apply([.moveFrame(.init(id: "frame:a", delta: Position(x: 30, y: 30)))])

        // The second frame is byte-identical: its name, its member, and where it
        // sits. Nothing about the first frame's move reached it.
        #expect(store.document.presentation.frame("frame:b") == before.presentation.frame("frame:b"))
        // The members of the first frame moved once each, and the third did not move
        // at all even though it now overlaps the moved frame.
        #expect(store.document.presentation.instance(for: one)?.position
                == before.presentation.instance(for: one)?.position.offset(dx: 30, dy: 30))
        #expect(store.document.presentation.instance(for: two)?.position
                == before.presentation.instance(for: two)?.position.offset(dx: 30, dy: 30))
        #expect(store.document.presentation.instance(for: three)?.position
                == before.presentation.instance(for: three)?.position)
    }

    // MARK: Explicit members, and the refusals

    @Test("Membership is explicit and reversible")
    func membershipIsExplicit() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let frame = frame([one, two], in: document)
        try store.apply([.createFrame(.init(frame: frame))])
        #expect(store.document.presentation.frame(frame.id)?.memberInstanceIDs.count == 2)

        let keep = [try instance(document, one)]
        _ = try store.apply([.setFrameMembers(.init(id: frame.id, memberInstanceIDs: keep))])
        #expect(store.document.presentation.frame(frame.id)?.memberInstanceIDs == keep)
    }

    @Test("An empty frame is a state, not an error")
    func emptyFrameStays() throws {
        var store = DocumentStore(document: world())
        let frame = frame([one], in: store.document)
        try store.apply([.createFrame(.init(frame: frame))])
        let emptied = try store.apply([.setFrameMembers(.init(id: frame.id, memberInstanceIDs: []))])
        // "An empty frame stays until the user chooses": removing the contents is an
        // ordinary action, and the frame is still there afterwards.
        #expect(emptied.presentation.frame(frame.id)?.memberInstanceIDs.isEmpty == true)
        #expect(emptied.object(one) != nil)
    }

    @Test("A frame cannot hold a drawing that does not exist")
    func unknownMemberIsRefused() {
        var store = DocumentStore(document: world())
        let frame = Frame(
            id: "frame:bad", name: LocalizedText("Bad"), position: .zero,
            memberInstanceIDs: [InstanceID("instance:nope")]
        )
        #expect(throws: DocumentError.self) {
            try store.apply([.createFrame(.init(frame: frame))])
        }
        #expect(store.document.presentation.frames.isEmpty)
    }

    @Test("Moving an unknown frame changes nothing")
    func unknownFrameIsRefused() {
        var store = DocumentStore(document: world())
        let before = store.document
        #expect(throws: DocumentError.self) {
            try store.apply([.moveFrame(.init(id: "frame:nope", delta: Position(x: 5, y: 5)))])
        }
        #expect(store.document == before)
    }

    @Test("Renaming a branch does not rename its sources")
    func renamingTouchesNothingInside() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let frame = frame([one, two], in: document)
        try store.apply([.createFrame(.init(frame: frame))])
        let renamed = try store.apply([.renameFrame(.init(
            id: frame.id, name: LocalizedText("The group")
        ))])

        #expect(renamed.presentation.frame(frame.id)?.name.text == "The group")
        // The objects keep their own words, and so does the link between them.
        #expect(renamed.content == document.content)
        #expect(renamed.relationships == document.relationships)
    }

    @Test("Removing a frame leaves its members exactly where they were")
    func removingKeepsTheMembers() throws {
        var store = DocumentStore(document: world())
        let document = store.document
        let frame = frame([one, two], in: document)
        try store.apply([.createFrame(.init(frame: frame))])
        let removed = try store.apply([.removeFrame(.init(id: frame.id))])

        #expect(removed.presentation.frames.isEmpty)
        #expect(removed.presentation == document.presentation)
        #expect(removed.content == document.content)
    }

    // MARK: The format

    @Test("A document written before frames existed still opens")
    func legacyPayloadDecodes() throws {
        // Absent is a canvas with no frames on it, not a broken file. The same idiom
        // the rest of the format uses for a key added later.
        let legacy = """
        {
          "instances": [
            {"id":"instance:one","objectID":"object:one","position":{"x":0,"y":0},"hidden":false}
          ]
        }
        """
        let presentation = try JSONDecoder().decode(Presentation.self, from: Data(legacy.utf8))
        #expect(presentation.frames.isEmpty)
        #expect(presentation.instances.count == 1)
    }

    @Test("Frames survive a round trip")
    func framesRoundTrip() throws {
        var store = DocumentStore(document: world())
        let frame = frame([one, two], in: store.document)
        try store.apply([.createFrame(.init(frame: frame))])
        let data = try JSONEncoder().encode(store.document)
        let reloaded = try JSONDecoder().decode(KollioDocument.self, from: data)
        #expect(reloaded.presentation.frames == store.document.presentation.frames)
    }
}
