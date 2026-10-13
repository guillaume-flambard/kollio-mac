import Foundation
import Testing
import KollioCore
@testable import KollioApp

@Suite("Spatial Ink — real .kollio canvas scene")
struct SpatialDocumentSceneTests {
    @Test("Sarah renders all semantic objects and links without touching the document")
    func sarah() {
        let document = SarahFixture.document()
        let before = document
        let semantic = SpatialDocumentProjection(document: document)
        let rendered = SpatialDocumentScene(projection: semantic)
        #expect(rendered.documentID == document.documentId)
        #expect(rendered.revision == document.revision)
        #expect(rendered.semanticRevision == document.semanticRevision)
        #expect(rendered.nodes.count == document.content.count)
        #expect(rendered.edges.count == document.relationships.count)
        #expect(Set(rendered.nodes.map(\.id)) == Set(document.content.keys.map(\.rawValue)))
        #expect(Set(rendered.edges.map(\.id)) == Set(document.relationships.keys.map(\.rawValue)))
        #expect(document == before)
        for edge in rendered.edges {
            #expect(edge.points.count >= 2)
            #expect(edge.points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
        }
        for instance in document.presentation.instances {
            let visual = rendered.nodes.first { $0.id == instance.objectID.rawValue }
            #expect(visual != nil)
            if let visual {
                #expect(abs(visual.x * 1000 - instance.position.x) < 0.01)
                #expect(abs(visual.y * 640 - instance.position.y) < 0.01)
            }
        }
    }
    @Test("A real .kollio file can be reopened and displayed without writing it back")
    @MainActor
    func onDiskReopen() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("kollio-spatial-c2-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DocumentFileStore(directory: directory)
        let document = SarahFixture.document()
        let url = store.defaultDocumentURL
        try store.save(document, to: url)
        let originalBytes = try Data(contentsOf: url)

        // The same path taken by a normal app launch, but using an isolated
        // temporary document directory instead of the user's real files.
        let reopened = KollioModel.deterministicModel(fileStore: store)
        let view = SpatialDocumentScene(projection: SpatialDocumentProjection(document: reopened.document))
        #expect(reopened.document == document)
        #expect(view.nodes.count == document.content.count)
        #expect(view.edges.count == document.relationships.count)
        #expect(try Data(contentsOf: url) == originalBytes)
    }

    @Test("The same active KollioModel projects newly loaded and cleared documents")
    @MainActor
    func followsActiveModel() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("kollio-c2-live-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = KollioModel.deterministicModel(
            document: KollioDocument(),
            fileStore: DocumentFileStore(directory: directory)
        )
        #expect(SpatialDocumentScene(projection: SpatialDocumentProjection(document: model.document)).nodes.isEmpty)
        model.loadDemo()
        let sarah = SpatialDocumentScene(projection: SpatialDocumentProjection(document: model.document))
        #expect(sarah.nodes.count == model.document.content.count)
        #expect(sarah.edges.count == model.document.relationships.count)
        #expect(!sarah.nodes.isEmpty)
        model.newDocument()
        let cleared = SpatialDocumentScene(projection: SpatialDocumentProjection(document: model.document))
        #expect(cleared.nodes.isEmpty)
        #expect(cleared.edges.isEmpty)
    }

    @Test("Empty documents stay empty, without demo content")
    func emptyDocument() {
        let document = KollioDocument()
        let scene = SpatialDocumentScene(projection: SpatialDocumentProjection(document: document))
        #expect(scene.nodes.isEmpty)
        #expect(scene.edges.isEmpty)
    }
    @Test("Scene positioning and connector endpoints are deterministic")
    func stableScene() {
        let projection = SpatialDocumentProjection(document: SarahFixture.document())
        let first = SpatialDocumentScene(projection: projection)
        let second = SpatialDocumentScene(projection: projection)
        #expect(first.nodes == second.nodes)
        #expect(first.edges == second.edges)
    }

    @Test("C2.4 routes a real relationship around another real document object")
    func detoursRealDocumentObstacle() throws {
        var document = SarahFixture.document()
        let relation = try #require(document.relationships.values.first { $0.from != $0.to })
        let obstructingID = try #require(document.content.keys.first {
            $0 != relation.from && $0 != relation.to
        })
        document.presentation.instances = [
            NodeInstance(id: InstanceID("c24-source"), objectID: relation.from,
                         position: Position(x: 150, y: 200)),
            NodeInstance(id: InstanceID("c24-target"), objectID: relation.to,
                         position: Position(x: 850, y: 200)),
            NodeInstance(id: InstanceID("c24-obstacle"), objectID: obstructingID,
                         position: Position(x: 500, y: 200))
        ]
        let before = document
        let scene = SpatialDocumentScene(projection: SpatialDocumentProjection(document: document))
        let edge = try #require(scene.edges.first { $0.id == relation.id.rawValue })
        #expect(!edge.blocked)
        #expect(edge.crossings == 0)
        #expect(edge.points.count >= 3)
        let envelope = CGRect(x: 500 - 127, y: 200 - 82, width: 254, height: 164)
        for (start, end) in zip(edge.points, edge.points.dropFirst()) {
            #expect(!SpatialDocumentRouter.segmentHits(from: start, to: end, rect: envelope))
        }
        #expect(document == before)
    }

    @Test("C2.4 clear direct connections stay straight and stable")
    func straightConnectionStaysStraight() {
        let a = CGPoint(x: 100, y: 80)
        let b = CGPoint(x: 900, y: 80)
        let blocker = CGRect(x: 350, y: 350, width: 200, height: 100)
        let first = SpatialDocumentRouter.route(from: a, to: b, avoiding: [blocker])
        let second = SpatialDocumentRouter.route(from: a, to: b, avoiding: [blocker])
        #expect(first.points == [a, b])
        #expect(first.points == second.points)
        #expect(!first.blocked)
        #expect(first.crossings == 0)
    }

    @Test("C2.4 impossible route is identified as blocked")
    func routeFailClosed() {
        let a = CGPoint(x: 100, y: 100)
        let b = CGPoint(x: 900, y: 100)
        let surroundingCard = CGRect(x: 60, y: 60, width: 100, height: 100)
        let route = SpatialDocumentRouter.route(from: a, to: b, avoiding: [surroundingCard])
        #expect(route.blocked)
        #expect(route.crossings == 1)
    }
}
