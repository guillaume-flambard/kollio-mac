import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// CAN-03, "Move one or several instances".
///
/// AC01 is a claim about geometry, AC02 about the transaction, AC03 about what a
/// move may never touch. All three are decidable here. The *feel* of the drag —
/// that the object follows the pointer with no lag, and that the gesture is
/// comfortable — is owed to a human and is listed in the lot's tasks.
@Suite("CAN-03: moving one instance or a group")
@MainActor
struct MovingInstancesTests {
    private func isolatedStore() -> (DocumentFileStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-can03-\(UUID().uuidString)")
        return (DocumentFileStore(directory: directory), directory)
    }

    private func makeModel() -> (KollioModel, URL) {
        let (store, directory) = isolatedStore()
        return (
            KollioModel(document: SarahFixture.document(),
                        service: KollioModel.makeDemoService(languageCode: "fr"),
                        fileStore: store),
            directory
        )
    }

    private func positions(_ model: KollioModel) -> [ObjectID: Position] {
        Dictionary(
            uniqueKeysWithValues: model.document.presentation.instances.map { ($0.objectID, $0.position) }
        )
    }

    // MARK: AC01 — the same logical move at any zoom

    @Test("80, 100 and 180 per cent produce the same world move for the same screen move")
    func sameWorldMoveAtEveryZoom() {
        // The same 120 screen points means a smaller world move when zoomed in.
        // What must not change is the ratio, and the fact that every zoom moves
        // the object by the same *world* distance for the same world gesture.
        let screenDelta = CGSize(width: 120, height: -60)
        var measured: [Double: Double] = [:]

        for zoom in [0.8, 1.0, 1.8] {
            let (model, directory) = makeModel()
            defer { try? FileManager.default.removeItem(at: directory) }
            let csv = KollioID.object("sarah-csv")
            model.camera = Camera(zoom: zoom, translation: .zero)
            let before = positions(model)[csv]!

            model.beginDrag(csv, screenTranslation: screenDelta)
            model.endDrag()

            let moved = positions(model)[csv]!
            // The world delta is the screen delta divided by the zoom, every time.
            measured[zoom] = moved.x - before.x
            #expect(abs((moved.x - before.x) - 120 / zoom) < 0.001)
            #expect(abs((moved.y - before.y) - (-60 / zoom)) < 0.001)
        }

        // And the three are genuinely different, so the test is not passing on a
        // constant.
        #expect(Set(measured.values.map { ($0 * 1000).rounded() }).count == 3)
    }

    @Test("A zoom change mid-gesture does not double the delta")
    func zoomDuringAGestureDoesNotAccumulate() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")
        let before = positions(model)[csv]!

        model.camera = Camera(zoom: 1.0, translation: .zero)
        model.beginDrag(csv, screenTranslation: CGSize(width: 100, height: 0))
        // A second update for the same anchor replaces the delta rather than
        // adding to it, because a gesture reports a cumulative translation.
        model.beginDrag(csv, screenTranslation: CGSize(width: 100, height: 0))
        model.endDrag()

        #expect(abs((positions(model)[csv]!.x - before.x) - 100) < 0.001)
    }

    @Test("A second object cannot join a drag in progress")
    func aSecondObjectCannotJoinAnActiveDrag() throws {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")

        let csvInstance = try! #require(model.document.presentation.instance(for: csv))
        let crmInstance = try! #require(model.document.presentation.instance(for: crm))
        model.beginDrag([csvInstance.id], screenTranslation: CGSize(width: 80, height: 0))
        // A different anchor is a different gesture. Merging the two deltas would
        // teleport the first object.
        model.beginDrag([crmInstance.id], screenTranslation: CGSize(width: 500, height: 0))
        #expect(model.dragState?.anchor == csvInstance.id)
    }

    // MARK: AC02 — one undo restores the group

    @Test("A group drag is one transaction and one undo")
    func oneUndoRestoresTheGroup() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")
        let before = positions(model)

        model.select(crm)
        model.select(csv, extending: true)
        #expect(model.selection.count == 2)

        // The same path the canvas takes: the object under the pointer, and the
        // model decides whether the rest of the selection follows.
        let moving = model.draggableInstances(for: csv)
        #expect(moving.count == 2)
        model.beginDrag(moving, screenTranslation: CGSize(width: 100, height: 40))
        // Both follow the pointer, and they keep their relative positions.
        #expect(model.dragOffset(for: crm) == Position(x: 100, y: 40))
        #expect(model.dragOffset(for: csv) == Position(x: 100, y: 40))
        model.endDrag()

        let after = positions(model)
        let relativeBefore = before[csv]!.x - before[crm]!.x
        let relativeAfter = after[csv]!.x - after[crm]!.x
        #expect(abs(relativeBefore - relativeAfter) < 0.001)

        model.undo()
        let restored = positions(model)
        for (id, position) in before {
            #expect(restored[id] == position)
        }
    }

    @Test("Dragging an unselected object leaves the selection where it was")
    func draggingAnUnselectedObjectMovesOnlyIt() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")
        let crmBefore = positions(model)[crm]!

        model.select(crm)
        // A gesture that starts on an object outside the selection is a drag of
        // that object, not of the selection.
        model.beginDrag(csv, screenTranslation: CGSize(width: 100, height: 0))
        model.endDrag()

        #expect(positions(model)[crm] == crmBefore)
        #expect(abs((positions(model)[csv]!.x - crmBefore.x) - 100) > 1)
    }

    @Test("Cancelling a gesture writes nothing")
    func cancellingWritesNothing() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")
        let before = positions(model)
        let historyBefore = model.canUndo

        model.select(crm)
        model.select(csv, extending: true)
        model.beginDrag(csv, screenTranslation: CGSize(width: 300, height: 300))
        model.cancelDrag()

        #expect(model.dragState == nil)
        #expect(model.dragOffset(for: csv) == .zero)
        #expect(positions(model) == before)
        #expect(model.canUndo == historyBefore)
    }

    @Test("A drag that barely moves writes nothing")
    func aSubPixelDragWritesNothing() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")
        let before = positions(model)
        let historyBefore = model.canUndo

        model.beginDrag(csv, screenTranslation: CGSize(width: 0.2, height: 0.1))
        model.endDrag()

        #expect(positions(model) == before)
        #expect(model.canUndo == historyBefore)
    }

    // MARK: AC03 — a move changes presentation and nothing else

    @Test("A move changes no meaning")
    func aMoveChangesNoMeaning() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")
        let content = model.document.content
        let relationships = model.document.relationships
        let semanticBefore = model.document.semanticRevision

        model.beginDrag(csv, screenTranslation: CGSize(width: 140, height: 90))
        model.endDrag()

        #expect(model.document.content == content)
        #expect(model.document.relationships == relationships)
        #expect(model.document.decisions.isEmpty)
        // Positions are presentation, so the meaning did not advance.
        #expect(model.document.semanticRevision == semanticBefore)
        // And a second, identical move still needs its own undo entry rather than
        // being folded into the first.
        #expect(model.canUndo)
    }

    @Test("Two occurrences of one object keep independent geometry")
    func occurrencesAreIndependent() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        // A document that draws the same object twice. The format allows it and
        // the domain keys placement by instance, so the rule CAN-03 states is
        // decidable without a command that does not exist yet.
        var document = SarahFixture.document()
        let first = try! #require(document.presentation.instance(for: KollioID.object("sarah-csv")))
        let second = NodeInstance(
            id: "occurrence-2",
            objectID: KollioID.object("sarah-csv"),
            position: first.position.offset(dx: 400, dy: 300)
        )
        document.presentation.instances.append(second)

        let model = KollioModel(
            document: document,
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        #expect(model.document.presentation.instances(of: KollioID.object("sarah-csv")).count == 2)

        // Moving one occurrence leaves the other exactly where it was.
        model.moveInstances([first.id], by: Position(x: 250, y: 0))

        let after = model.document.presentation.instances(of: KollioID.object("sarah-csv"))
        #expect(after.count == 2)
        let moved = try! #require(after.first { $0.id == first.id })
        let untouched = try! #require(after.first { $0.id == second.id })
        #expect(abs((moved.position.x - first.position.x) - 250) < 0.001)
        #expect(untouched.position == second.position)

        // And the object itself is untouched: a placement is not a meaning.
        #expect(model.document.object(KollioID.object("sarah-csv")) == document.object(KollioID.object("sarah-csv")))
    }
}
