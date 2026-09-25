import Foundation
import Testing
import KollioCore
@testable import KollioApp

@Suite("Canvas geometry")
struct CameraTests {
    @Test("World and screen round-trip")
    func roundTrip() {
        let camera = Camera(zoom: 1.7, translation: Position(x: -240, y: 88))
        let world = Position(x: 512, y: 300)
        let back = camera.toWorld(camera.toScreen(world))
        #expect(abs(back.x - world.x) < 0.0001)
        #expect(abs(back.y - world.y) < 0.0001)
    }

    @Test("Screen = world * zoom + translation")
    func transform() {
        let camera = Camera(zoom: 2, translation: Position(x: 10, y: -20))
        #expect(camera.toScreen(Position(x: 5, y: 7)) == Position(x: 20, y: -6))
        #expect(camera.toWorld(Position(x: 20, y: -6)) == Position(x: 5, y: 7))
    }

    @Test("Panning moves the world by the same screen delta")
    func panning() {
        var camera = Camera.identity
        camera.pan(byScreenDelta: Position(x: 40, y: -15))
        #expect(camera.translation == Position(x: 40, y: -15))
        #expect(camera.zoom == 1)
    }

    @Test("Zooming keeps the anchor visually still")
    func zoomAroundAnchor() {
        var camera = Camera(zoom: 1, translation: Position(x: 100, y: 60))
        let anchor = Position(x: 420, y: 260)
        let worldBefore = camera.toWorld(anchor)
        camera.zoom(to: 2.4, anchor: anchor)
        #expect(abs(camera.toWorld(anchor).x - worldBefore.x) < 0.0001)
        #expect(abs(camera.toWorld(anchor).y - worldBefore.y) < 0.0001)
    }

    @Test("Zoom is clamped to the usable range")
    func zoomClamping() {
        var camera = Camera(zoom: 1, translation: .zero)
        camera.zoom(to: 99, anchor: .zero)
        #expect(camera.zoom == Camera.maximumZoom)
        camera.zoom(to: 0.0001, anchor: .zero)
        #expect(camera.zoom == Camera.minimumZoom)
    }

    @Test("Dragging follows the cursor at any zoom level")
    func dragAtZoom() {
        for zoom in [0.35, 1.0, 2.6] {
            let camera = Camera(zoom: zoom, translation: Position(x: 12, y: -30))
            let screenDelta = Position(x: 120, y: 60)
            let worldDelta = camera.worldDelta(forScreenDelta: screenDelta)
            // A round-trip through the screen must land back on the cursor.
            let start = Position(x: 400, y: 400)
            let dragged = start.offset(dx: worldDelta.x, dy: worldDelta.y)
            let backToScreen = camera.toScreen(dragged)
            let expected = camera.toScreen(start).offset(dx: screenDelta.x, dy: screenDelta.y)
            #expect(abs(backToScreen.x - expected.x) < 0.0001)
            #expect(abs(backToScreen.y - expected.y) < 0.0001)
        }
    }

    @Test("Fitting centres the content with breathing room")
    func fitting() {
        let content = Rect(x: -400, y: -300, width: 800, height: 600)
        let viewport = Size(width: 1200, height: 800)
        let camera = Camera.fitting(content: content, viewport: viewport, padding: 100)
        #expect(camera.zoom <= 1)
        let topLeft = camera.toScreen(content.origin)
        let bottomRight = camera.toScreen(Position(x: content.maxX, y: content.maxY))
        #expect(topLeft.x > 0)
        #expect(bottomRight.x < viewport.width)
        #expect(topLeft.y > 0)
        #expect(bottomRight.y < viewport.height)
        // Content is centred, not crammed into a corner.
        let centre = camera.toScreen(content.center)
        #expect(abs(centre.x - viewport.width / 2) < 0.001)
        #expect(abs(centre.y - viewport.height / 2) < 0.001)
    }

    @Test("The visible world rectangle follows the camera")
    func cullingRect() {
        let camera = Camera(zoom: 2, translation: Position(x: -200, y: -100))
        let visible = camera.visibleWorldRect(viewport: Size(width: 1000, height: 600))
        #expect(visible.origin == Position(x: 100, y: 50))
        #expect(visible.size == Size(width: 500, height: 300))
    }

    @Test("Rect union covers every object")
    func selectionBounds() {
        let a = Rect(x: 10, y: 20, width: 100, height: 40)
        let b = Rect(x: -30, y: 90, width: 60, height: 60)
        let bounds = a.union(b)
        #expect(bounds == Rect(x: -30, y: 20, width: 140, height: 130))
        #expect(bounds.contains(a.center))
        #expect(bounds.contains(b.center))
    }
}

@Suite("Relationship geometry")
struct RelationshipGeometryTests {
    private let relationship = Relationship(
        id: "r",
        from: "a",
        to: "b",
        kind: .supports,
        provenance: .human("test")
    )

    @Test("Connectors attach to the bottom of the source and the top of the target")
    func anchors() {
        let from = Rect(x: 0, y: 0, width: 200, height: 60)
        let to = Rect(x: 100, y: 200, width: 200, height: 60)
        let (start, end) = RelationshipGeometry.endpoints(of: relationship, from: from, to: to)
        #expect(start.point == Position(x: 100, y: 60))
        #expect(start.direction == Position(x: 0, y: 1))
        #expect(end.point == Position(x: 200, y: 200))
        #expect(end.direction == Position(x: 0, y: -1))
    }

    @Test("Connectors follow their objects when one moves")
    func followsMovement() {
        let from = Rect(x: 0, y: 0, width: 200, height: 60)
        let to = Rect(x: 100, y: 200, width: 200, height: 60)
        let before = RelationshipGeometry.endpoints(of: relationship, from: from, to: to)
        let movedFrom = Rect(x: 60, y: 30, width: 200, height: 60)
        let after = RelationshipGeometry.endpoints(of: relationship, from: movedFrom, to: to)
        #expect(after.start.point.x - before.start.point.x == 60)
        #expect(after.start.point.y - before.start.point.y == 30)
        #expect(after.end == before.end)
    }

    @Test("A connector is a real path, not a straight jump")
    func pathShape() {
        let start = AnchorPoint(point: Position(x: 0, y: 0), direction: Position(x: 0, y: 1))
        let end = AnchorPoint(point: Position(x: 120, y: 300), direction: Position(x: 0, y: -1))
        let path = RelationshipGeometry.path(from: start, to: end)
        let box = path.boundingRect
        #expect(box.minX <= 0)
        #expect(box.maxX >= 120)
        #expect(box.height >= 300)
    }
}

@Suite("Connector obstacle avoidance")
struct ConnectorRoutingTests {
    private let start = AnchorPoint(point: Position(x: 0, y: 100), direction: Position(x: 0, y: 1))
    private let end = AnchorPoint(point: Position(x: 600, y: 700), direction: Position(x: 0, y: -1))

    /// An obstacle sitting squarely between the two endpoints.
    private let between = Rect(x: 240, y: 330, width: 160, height: 120)

    @Test("Nothing in the way leaves the connector exactly as it was")
    func unobstructedIsUnchanged() {
        let direct = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [])
        #expect(direct.segments.count == 1)
        #expect(direct.path() == RelationshipGeometry.path(from: start, to: end))
    }

    @Test("An obstacle beside the chord does not move the connector")
    func obstacleOffTheChordIsIgnored() {
        let beside = Rect(x: -400, y: 300, width: 120, height: 120)
        let direct = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [])
        let routed = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [beside])
        #expect(routed == direct)
    }

    @Test("A connector stops crossing the object between its ends")
    func detoursAroundAnObstacle() {
        let direct = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [])
        #expect(direct.intersects(between))

        let routed = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [between])
        #expect(routed.intersects(between) == false)
        // The ends never move: a connector still attaches to both objects.
        #expect(routed.start == start.point)
        #expect(routed.end == end.point)
        // And it really did go round, rather than through, the object.
        #expect(routed.segments.count == 2)
    }

    @Test("The connector keeps its clearance, not just its freedom")
    func keepsClearance() {
        let padded = between.insetBy(dx: -RelationshipGeometry.clearance, dy: -RelationshipGeometry.clearance)
        let routed = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [between])
        #expect(routed.intersects(padded) == false)
    }

    @Test("The side with the smaller excursion is the one taken")
    func takesTheCheaperSide() {
        // A wide obstacle pushed well to the left of the chord: going left would
        // be a long way round, so the connector must go right.
        let left = Rect(x: -300, y: 300, width: 560, height: 200)
        let side = RelationshipGeometry.detourSide(for: [left.insetBy(dx: -RelationshipGeometry.clearance, dy: -RelationshipGeometry.clearance)], start: start.point, end: end.point)
        #expect(side?.direction == -1)
    }

    @Test("The widest obstacle dictates how far the detour goes")
    func widestObstacleDecides() {
        let narrow = Rect(x: 240, y: 330, width: 160, height: 120)
        let wide = Rect(x: 120, y: 600, width: 420, height: 120)
        let near = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [narrow])
        let both = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [narrow, wide])

        #expect(near.intersects([wide].map { $0.insetBy(dx: -RelationshipGeometry.clearance, dy: -RelationshipGeometry.clearance) }))
        // Routing around the wide object as well clears both.
        #expect(both.intersects([narrow, wide]) == false)
        // And it had to travel further from the chord to do it.
        #expect(both.midpoint != near.midpoint)
    }

    @Test("A connector detours around a node the way the canvas lays them out")
    func detoursInARealisticLayout() {
        // The shape seen on screen: a node to the right and lower, with a third
        // node sitting between the two.
        let source = AnchorPoint(point: Position(x: 900, y: 300), direction: Position(x: 0, y: 1))
        let target = AnchorPoint(point: Position(x: 1180, y: 900), direction: Position(x: 0, y: -1))
        let inTheWay = Rect(x: 1000, y: 560, width: 260, height: 90)
        let direct = RelationshipGeometry.routedRoute(from: source, to: target, obstacles: [])
        #expect(direct.intersects(inTheWay))
        let routed = RelationshipGeometry.routedRoute(from: source, to: target, obstacles: [inTheWay])
        #expect(routed.intersects(inTheWay) == false)
        #expect(routed.start == source.point)
        #expect(routed.end == target.point)
    }

    @Test("The label sits on the curve, wherever the curve went")
    func labelSitsOnTheRoute() {
        let route = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: [between])
        let samples = route.samples(count: 400)
        let label = route.midpoint
        // The label is on the path, not floating beside it.
        #expect(samples.contains { abs($0.x - label.x) < 2 && abs($0.y - label.y) < 2 })
    }
}

@Suite("Document view state")
@MainActor
struct KollioModelTests {
    @Test("A new document is empty and asks one question")
    func firstExperience() {
        let model = KollioModel(document: KollioDocument(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        #expect(model.isEmpty)
    }

    @Test("The initial statement becomes the context, not a chat message")
    func startWithStatement() {
        let model = KollioModel(document: KollioDocument(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        model.start(with: "Recover our prospect list without the CRM")
        #expect(model.document.content.count == 3)
        #expect(model.document.objects.first { $0.kind == .context }?.text.text == "Recover our prospect list without the CRM")
        #expect(model.relationshipsToRender().count == 2)
    }

    @Test("The demo document shows Sarah and nothing else")
    func sarahFixture() {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        #expect(model.document.content.count == 6)
        #expect(model.visibleInstances.count == 6)
        #expect(model.relationshipsToRender().count == 5)
    }

    @Test("Explore previews a ghost branch without touching the document")
    func explorePreviewsWithoutMutating() async {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        let before = model.document
        await model.explore(KollioID.object("sarah-csv"))
        #expect(model.preview != nil)
        #expect(model.document == before)
        #expect(model.preview?.objectIDs.isEmpty == false)
    }

    @Test("Keep applies the proposal as one transaction, undo restores everything")
    func keepAndUndo() async {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        let before = model.document
        await model.explore(KollioID.object("sarah-csv"))
        model.keepPreview()
        #expect(model.document != before)
        #expect(model.preview == nil)
        model.undo()
        #expect(model.document == before)
    }

    @Test("Set aside collapses the branch and keeps the reason")
    func setAside() {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        model.setAside(KollioID.object("sarah-csv"), reason: "Pas maintenant")
        #expect(model.canReopen(KollioID.object("sarah-csv")))
        // The direction stays on the canvas, compact; its two children collapse.
        #expect(model.visibleInstances.count == 4)
        #expect(model.collapsedRoots == [KollioID.object("sarah-csv")])
        #expect(model.setAsideReason(of: KollioID.object("sarah-csv")) == "Pas maintenant")
        // Nothing was deleted.
        #expect(model.document.content.count == 6)
    }

    @Test("Reopen restores the branch exactly where it was")
    func reopen() {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        let positions = Dictionary(uniqueKeysWithValues: model.document.presentation.instances.map { ($0.objectID, $0.position) })
        model.setAside(KollioID.object("sarah-csv"), reason: "Pas maintenant")
        model.reopen(KollioID.object("sarah-csv"))
        #expect(model.visibleInstances.count == 6)
        for instance in model.document.presentation.instances {
            #expect(instance.position == positions[instance.objectID])
        }
    }

    @Test("A drag is applied once, on release")
    func dragCommitsOnce() {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())))
        let id = KollioID.object("sarah-csv")
        let start = model.document.presentation.instance(for: id)?.position
        model.beginDrag(id, screenTranslation: CGSize(width: 0, height: 0))
        model.beginDrag(id, screenTranslation: CGSize(width: 40, height: 40))
        #expect(model.document.presentation.instance(for: id)?.position == start)
        model.endDrag()
        #expect(model.document.presentation.instance(for: id)?.position != start)
        #expect(model.canUndo)
    }

    @Test("Save, quit and reopen preserves accepted state")
    func saveAndReopen() async {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kollio-tests-\(UUID().uuidString)")
        let store = DocumentFileStore(directory: directory)
        let model = KollioModel(document: SarahFixture.document(), fileStore: store)
        await model.explore(KollioID.object("sarah-csv"))
        model.keepPreview()
        model.save()

        let reopened = KollioModel(document: nil, fileStore: store)
        #expect(reopened.document.content.count == model.document.content.count)
        #expect(reopened.document.semanticRevision == model.document.semanticRevision)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test("Interface language does not rewrite the document")
    func languageChangeIsNotTranslation() {
        let model = KollioModel(document: SarahFixture.document(), fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())), languageCode: "fr")
        let french = model.text(of: KollioID.object("sarah-csv"))
        let revision = model.document.semanticRevision
        model.languageCode = "en"
        let english = model.text(of: KollioID.object("sarah-csv"))
        #expect(french == "Export CSV depuis l’outil source")
        #expect(english == "CSV export from the source tool")
        #expect(model.document.semanticRevision == revision)
    }
}
