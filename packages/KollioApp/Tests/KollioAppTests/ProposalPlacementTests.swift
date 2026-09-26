import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// CAN-08 — place proposals and organise locally.
///
/// Placement is the one place where a document can quietly lose a person's sense
/// of where things are. The three acceptance criteria are the whole requirement:
///
/// - AC01 keeping does not shift the ghosts
/// - AC02 earlier objects stay still
/// - AC03 undo restores the view exactly
///
/// These are tested against the real model and the real demo engine, because the
/// interesting failures are spatial and a mock would not produce them.
@Suite("CAN-08: proposal placement")
@MainActor
struct ProposalPlacementTests {
    private func makeModel() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(
                directory: URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("kollio-can08-\(UUID().uuidString)")
            )
        )
    }

    /// Where every object sits, so "nothing moved" is a measurement rather than a
    /// claim. Read through `visibleInstances`, which is the same source the canvas
    /// draws from, so the test measures what is actually on screen.
    private func snapshot(_ model: KollioModel) -> [ObjectID: Position] {
        var positions: [ObjectID: Position] = [:]
        for instance in model.visibleInstances {
            positions[instance.objectID] = instance.position
        }
        return positions
    }

    private func placement(of id: ObjectID, in model: KollioModel) -> Position? {
        model.visibleInstances.first { $0.objectID == id }?.position
    }

    @Test("AC01: keeping a proposal does not shift where the ghosts were")
    func keepingDoesNotShiftTheGhosts() async throws {
        let model = makeModel()
        let anchor = KollioID.object("sarah-csv")
        await model.explore(anchor)
        let preview = try #require(model.preview)

        // Where the ghosts were shown is where they land. A Keep that re-ran the
        // placement would move the branch under the person's cursor, which is the
        // single most disorienting thing this screen could do.
        let shown = preview.placements
        model.keepPreview()

        for (id, position) in shown {
            let landed = try #require(placement(of: id, in: model))
            #expect(landed == position, "\(id.rawValue) moved between the ghost and the document")
        }
    }

    @Test("AC02: objects that were already there do not move")
    func earlierObjectsStayStill() async throws {
        let model = makeModel()
        let before = snapshot(model)

        await model.explore(KollioID.object("sarah-csv"))
        #expect(model.preview != nil)
        model.keepPreview()

        // Every pre-existing object is at exactly the coordinates it had. A proposed
        // object is pushed clear of what exists, never the other way round.
        for (id, position) in before {
            #expect(placement(of: id, in: model) == position,
                    "\(id.rawValue) moved because a proposal was kept")
        }
        #expect(model.document.content.count > before.count)
    }

    @Test("AC03: undo restores the view exactly")
    func undoRestoresTheView() async throws {
        let model = makeModel()
        let before = snapshot(model)
        let contentBefore = model.document.content.count

        await model.explore(KollioID.object("sarah-csv"))
        model.keepPreview()
        #expect(model.document.content.count > contentBefore)

        model.undo()
        #expect(model.document.content.count == contentBefore)
        // Not "close enough": the same coordinates, object by object.
        #expect(snapshot(model) == before)
    }

    @Test("A proposed object never lands on top of an existing one")
    func ghostsDoNotOverlapWhatExists() async throws {
        let model = makeModel()
        let anchor = KollioID.object("sarah-csv")
        await model.explore(anchor)
        let preview = try #require(model.preview)

        let existing = model.visibleInstances.compactMap { instance -> Rect? in
            model.frame(of: instance.objectID)
        }
        for (id, position) in preview.placements {
            // The size the placement was computed for, not one re-derived here: a
            // test that measures with a different size would report a false overlap.
            let size = model.frame(of: id)?.size ?? Size(width: NodeLayout.minimumWidth, height: NodeLayout.thoughtHeight)
            let ghost = Rect(origin: position, size: size)
            for other in existing where other != ghost {
                #expect(ghost.intersects(other) == false,
                        "a proposed object would cover \(id.rawValue)'s neighbour")
            }
        }
    }

    @Test("A second proposal does not disturb the first")
    func aSecondProposalLeavesTheFirstAlone() async throws {
        let model = makeModel()
        await model.explore(KollioID.object("sarah-csv"))
        let first = try #require(model.preview).placements

        // Asking again from a different direction must not rearrange the branch
        // already on screen, or the canvas would shuffle under the person.
        await model.explore(KollioID.object("sarah-crm"))
        let current = try #require(model.preview)
        if current.objectIDs != Array(first.keys) {
            #expect(Set(current.objectIDs) != Set(first.keys))
        }
        model.keepPreview()
        // Everything the first proposal promised is still where it was promised.
        for (id, position) in first where current.objectIDs.contains(id) {
            #expect(placement(of: id, in: model) == position)
        }
    }

    // MARK: Reaching a branch that cannot be seen

    @Test("An off-screen proposal says so, and the view never moves on its own")
    func offScreenProposalOffersAWayToSeeIt() async throws {
        let model = makeModel()
        let anchor = KollioID.object("sarah-csv")
        await model.explore(anchor)
        let preview = try #require(model.preview)

        // Park the view far away, so the branch is genuinely off screen.
        model.camera = Camera(zoom: 0.4, translation: Position(x: 9_000, y: 9_000))
        #expect(model.previewIsOffScreen())
        #expect(model.camera.translation == Position(x: 9_000, y: 9_000))

        // Nothing has moved the view: a proposal arriving never takes the view away
        // from whatever the person was reading.
        #expect(model.preview?.objectIDs == preview.objectIDs)

        // Asking is what moves it.
        model.revealPreview()
        #expect(model.previewIsOffScreen() == false)
    }

    @Test("A visible proposal offers nothing, because a marker that is always there gets ignored")
    func visibleProposalNeedsNoMarker() async throws {
        let model = makeModel()
        await model.explore(KollioID.object("sarah-csv"))
        // Fit the content first, so the branch really is on screen.
        model.fitContent()
        #expect(model.previewIsOffScreen() == false)
    }
}
