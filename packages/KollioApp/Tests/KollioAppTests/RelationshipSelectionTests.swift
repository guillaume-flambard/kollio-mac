import Foundation
import Testing
import SwiftUI
@testable import KollioApp
import KollioCore

/// CAN-06 in the interface: the line is catchable, and a link reads as a sentence.
///
/// The Core suite proves the sentence and the edit. These prove the part a person
/// actually touches: a pointer finds the line at several zooms, a link takes its
/// own selection rather than dragging two nodes into it, and objects still win.
@MainActor
@Suite("Relations: catching and selecting")
struct RelationshipSelectionTests {
    private func makeModel(zoom: Double = 1.0) -> KollioModel {
        var builder = DocumentBuilder()
        _ = builder.object("a", kind: .hypothesis, "Left", en: "Left", at: Position(x: 120, y: 400))
        _ = builder.object("b", kind: .hypothesis, "Right", en: "Right", at: Position(x: 520, y: 400))
        _ = builder.link("l1", from: KollioID.object("a"), to: KollioID.object("b"), .constrains)
        let model = KollioModel(document: builder.document, languageCode: "en")
        model.viewport = Size(width: 900, height: 700)
        model.camera.zoom = zoom
        return model
    }

    // MARK: AC01

    @Test("AC01: a point on the line finds the line, at every zoom")
    func aPointOnTheLineFindsIt() {
        for zoom in [0.35, 0.5, 1.0, 2.0, 3.0] {
            let model = makeModel(zoom: zoom)
            let link = KollioID.relationship("l1")
            // The middle of the straight run between the two frames, in world space
            // and then through the same camera the layer draws with.
            let from = model.frame(of: KollioID.object("a"))!
            let to = model.frame(of: KollioID.object("b"))!
            let middle = Position(x: (from.center.x + to.center.x) / 2, y: (from.center.y + to.center.y) / 2)
            let screen = model.camera.toScreen(middle)
            #expect(model.relationship(near: screen) == link,
                    "at zoom \(zoom) the connector is not catchable where it is drawn")
        }
    }

    @Test("A point far from the line finds nothing")
    func aPointFarAwayFindsNothing() {
        let model = makeModel()
        #expect(model.relationship(near: Position(x: 40, y: 40)) == nil)
        #expect(model.relationship(near: Position(x: 860, y: 660)) == nil)
    }

    @Test("The line is catchable from further away than it is wide")
    func theLineIsWiderThanItLooks() {
        let model = makeModel()
        let from = model.frame(of: KollioID.object("a"))!
        let to = model.frame(of: KollioID.object("b"))!
        let middle = Position(x: (from.center.x + to.center.x) / 2, y: (from.center.y + to.center.y) / 2)
        let screen = model.camera.toScreen(middle)
        // 6 points above the line: nothing is drawn there, and the link is still
        // found. A 1.4-point stroke would not be.
        #expect(model.relationship(near: Position(x: screen.x, y: screen.y - 6)) != nil)
        // 40 points above it: past the catch area, so it is not found. A tolerance
        // with no upper bound would swallow the canvas around every link.
        #expect(model.relationship(near: Position(x: screen.x, y: screen.y - 40)) == nil)
    }

    @Test("Zoomed out, a link is still catchable at the same screen distance")
    func zoomingOutWidensTheCatchArea() {
        // The whole point of a zoom-dependent tolerance: the further away the view,
        // the more forgiving the target, so a distant link stays as easy to reach as
        // a near one.
        let near = makeModel(zoom: 3.0)
        let far = makeModel(zoom: 0.4)
        func missDistance(_ model: KollioModel) -> Double {
            let from = model.frame(of: KollioID.object("a"))!
            let to = model.frame(of: KollioID.object("b"))!
            let middle = Position(x: (from.center.x + to.center.x) / 2, y: (from.center.y + to.center.y) / 2)
            let screen = model.camera.toScreen(middle)
            // Walk outward until the link is no longer found.
            for offset in stride(from: 1.0, through: 60.0, by: 1.0) {
                if model.relationship(near: Position(x: screen.x, y: screen.y - offset)) == nil {
                    return offset
                }
            }
            return 60
        }
        #expect(missDistance(far) > missDistance(near))
    }

    // MARK: Selecting

    @Test("Selecting a link does not select its two ends")
    func selectingALinkIsNotSelectingTwoObjects() {
        let model = makeModel()
        model.select(KollioID.object("a"))
        #expect(model.selection == [KollioID.object("a")])

        model.selectRelationship(KollioID.relationship("l1"))
        // A link is not an object. Putting its two ends in the selection would show
        // the object inspector for two things the person did not pick.
        #expect(model.selection.isEmpty)
        #expect(model.selectedRelationshipID == KollioID.relationship("l1"))
    }

    @Test("Choosing an object puts the link selection down")
    func choosingAnObjectClearsTheLink() {
        let model = makeModel()
        model.selectRelationship(KollioID.relationship("l1"))
        model.select(KollioID.object("b"))
        // Both at once would be two different things selected with one click and
        // two inspectors on screen.
        #expect(model.selectedRelationshipID == nil)
        #expect(model.selection == [KollioID.object("b")])
    }

    @Test("Clearing the link selection selects nothing")
    func clearingTheLinkSelectsNothing() {
        let model = makeModel()
        model.selectRelationship(KollioID.relationship("l1"))
        model.selectRelationship(nil)
        #expect(model.selectedRelationshipID == nil)
        #expect(model.selection.isEmpty)
    }

    @Test("A selected link that is removed elsewhere does not linger")
    func aRemovedLinkIsForgotten() {
        let model = makeModel()
        model.selectRelationship(KollioID.relationship("l1"))
        #expect(model.selectedRelationship != nil)
        // Removing an end takes the link with it, since a link to nothing is not
        // stored. The selection must not outlive what it selected.
        _ = model.perform([.removeObject(.init(id: KollioID.object("b")))], label: "test")
        model.pruneSelection()
        #expect(model.document.relationship(KollioID.relationship("l1")) == nil)
        #expect(model.sentence(for: KollioID.relationship("l1")) == nil)
    }

    // MARK: Editing from the interface

    @Test("Reversing from the interface changes the sentence the card shows")
    func reversingFromTheInterface() {
        let model = makeModel()
        let link = KollioID.relationship("l1")
        #expect(model.sentence(for: link)?.text == "Left constrains Right")

        #expect(model.editRelationship(link, .reverse))
        #expect(model.sentence(for: link)?.text == "Right constrains Left")
    }

    @Test("The card has a sentence to show, and an incomplete one when it cannot")
    func theSentenceIsThereWhenItCanBe() {
        var builder = DocumentBuilder()
        _ = builder.object("a", kind: .hypothesis, "Left", en: "Left", at: Position(x: 100, y: 300))
        _ = builder.object("b", kind: .hypothesis, "Right", en: "Right", at: Position(x: 500, y: 300))
        _ = builder.link("l1", from: KollioID.object("a"), to: KollioID.object("b"), .constrains)
        var document = builder.document
        let complete = KollioModel(document: document, languageCode: "en")
        #expect(complete.sentence(for: KollioID.relationship("l1")) != nil)

        // One end removed elsewhere: the sentence is nil, so the card says the link
        // is incomplete instead of printing a claim about something absent.
        document.relationships[KollioID.relationship("l1")]?.to = KollioID.object("ghost")
        let broken = KollioModel(document: document, languageCode: "en")
        #expect(broken.sentence(for: KollioID.relationship("l1")) == nil)
    }
}
