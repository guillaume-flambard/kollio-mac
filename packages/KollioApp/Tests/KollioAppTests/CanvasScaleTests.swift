import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// The canvas measured, not guessed (roadmap item 5).
///
/// The device: a document of 100 objects and 200 relationships, the shape the
/// roadmap names, laid out on a grid so the frame is dense rather than spread.
/// Everything timed here is the *hot path of one frame*, called repeatedly so
/// the per-call cost is above the clock's resolution: the visible-instance
/// filter, the relationship render pass with its obstacle routing, the hit
/// test, and the ground scale decision. A drag calls all of these per frame.
///
/// What this suite deliberately does not claim: anything about SwiftUI's
/// rendering. `Canvas` draw time is measured as the cost of building the paths,
/// which is the part the code owns. The render tree's own cost needs
/// Instruments on the real app, and the numbers here are the baseline that
/// makes such a run interpretable.
@Suite("The canvas at scale")
@MainActor
struct CanvasScaleTests {
    /// 100 objects, 200 relationships, on a 10 by 10 grid of 200-pt cells.
    ///
    /// Half the relationships are `supports` so the marker path runs too: a
    /// benchmark that measured only the plain kinds would miss the vocabulary
    /// added this session.
    private func denseModel(columns: Int = 10) -> KollioModel {
        var builder = DocumentBuilder()
        var ids: [ObjectID] = []
        for row in 0..<10 {
            for column in 0..<columns {
                let id = ObjectID("object:bench-\(row)-\(column)")
                builder.object(
                    "bench-\(row)-\(column)", kind: .hypothesis,
                    "Objet \(row) \(column)",
                    en: "Object \(row) \(column)",
                    at: Position(x: Double(column) * 200, y: Double(row) * 160)
                )
                ids.append(id)
            }
        }
        // Each object linked to the one right of it and the one below it, except
        // on the last row and column. At ten columns that is 180 relationships.
        for row in 0..<10 {
            for column in 0..<columns {
                let index = row * columns + column
                if column < columns - 1 {
                    builder.link("bench-lr-\(index)", from: ids[index], to: ids[index + 1], .supports)
                }
                if row < 9 {
                    builder.link("bench-tb-\(index)", from: ids[index], to: ids[index + columns], .dependsOn)
                }
            }
        }
        var document = builder.document
        for (index, id) in ids.enumerated() {
            document.presentation.instances[index].size = Size(width: 160, height: 120)
        }
        return KollioModel(
            document: document,
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    private func perCallMicroseconds(_ calls: Int = 50, _ body: () -> Void) -> Double {
        // Warm first: the first call allocates and fills caches the steady
        // state never sees, and the steady state is what a pan or a drag pays.
        _ = body()
        let start = DispatchTime.now()
        for _ in 0..<calls { body() }
        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds)
        return elapsed / Double(calls) / 1000.0
    }

    @Test("100 objects: the visible filter stays trivial")
    func visibleFilter() {
        let model = denseModel()
        let perCall = perCallMicroseconds { _ = model.visibleInstances }
        // Measured 0.15 ms on an idle machine; the ceiling is roughly twenty
        // times that, so it catches an accidental linear rescan rather than a
        // busy build machine. The shape of this cost is pinned by the scaling
        // test below, which does not depend on how fast the machine is.
        #expect(perCall < 3000, "the visible-instance filter costs \(String(format: "%.1f", perCall)) µs per call at 100 objects")
    }

    /// What one render pass actually costs, the way the layer pays it: project
    /// every obstacle, take the relationship list, then route each connector.
    ///
    /// This is a separate function on purpose. An earlier version of this test
    /// carried six `DispatchTime.now()` calls per relationship *inside* the
    /// measured closure to attribute the cost to a phase, which meant the number
    /// the assertion read was not the number a frame pays.
    private func renderPassOnce(_ model: KollioModel) {
        var rects: [(id: ObjectID, rect: Rect)] = []
        rects.reserveCapacity(model.document.presentation.instances.count)
        for instance in model.visibleInstances {
            guard let frame = model.frame(of: instance.objectID) else { continue }
            rects.append((instance.objectID, model.camera.toScreen(frame)))
        }
        let obstacles = RelationshipGeometry.ObstacleSet(rects)
        for relationship in model.relationshipsToRender() {
            guard let fromFrame = model.frame(of: relationship.from),
                  let toFrame = model.frame(of: relationship.to) else { continue }
            let others = obstacles.excluding(relationship.from, relationship.to)
            let (worldStart, worldEnd) = RelationshipGeometry.endpoints(
                of: relationship, from: fromFrame, to: toFrame
            )
            let start = AnchorPoint(point: model.camera.toScreen(worldStart.point), direction: worldStart.direction)
            let end = AnchorPoint(point: model.camera.toScreen(worldEnd.point), direction: worldEnd.direction)
            _ = RelationshipGeometry.routedRoute(from: start, to: end, obstacles: others)
        }
    }

    /// A model whose canvas has already been laid out, which is the state a drag
    /// frame sees. A cold frame cache measured a linear scan of every instance
    /// per lookup and reported it as routing cost.
    private func warmed(_ model: KollioModel) -> KollioModel {
        for instance in model.visibleInstances {
            if let frame = model.frame(of: instance.objectID) {
                model.recordFrame(frame, for: instance.objectID)
            }
        }
        return model
    }

    @Test("100 objects, 180 relationships: one full render pass fits a frame")
    func renderPass() {
        let model = warmed(denseModel())
        // Pan first, so the measured pass is the steady state a drag sees and
        // not the fit-on-open state.
        model.camera.pan(byScreenDelta: Position(x: 40, y: 30))
        let perCall = perCallMicroseconds { renderPassOnce(model) }
        // Measured 5.6 ms on an idle machine, against a 16 ms frame. The ceiling
        // is roughly double that: high enough that a busy build machine does not
        // fail it, low enough that a return to the shape which cost 149 ms is a
        // failure. The shape itself is pinned by `routingCostDoesNotFollowTheObjectCount`.
        #expect(perCall < 12000, "a render pass over 100 objects and 180 relationships costs \(String(format: "%.0f", perCall)) µs")
    }

    /// The invariant that separates a working router from a broken one, and the
    /// reason the first one did not catch the 149 ms regression.
    ///
    /// Quadrupling the number of objects while holding the number of connectors
    /// fixed must not quadruple the cost *per connector*. A router that tests
    /// every obstacle against the curve pays 49 samples for each of them, so its
    /// per-connector cost grows with the object count. A router that rejects an
    /// obstacle by comparing two rectangles first pays four comparisons for the
    /// ones it discards, and its per-connector cost barely moves.
    ///
    /// The ratio is what makes this a real test: it does not care how fast the
    /// machine is, only how the cost responds to the shape of the document.
    @Test("Routing cost does not follow the object count")
    func routingCostDoesNotFollowTheObjectCount() {
        func perConnectorCost(columns: Int) -> Double {
            let model = warmed(denseModel(columns: columns))
            model.camera.pan(byScreenDelta: Position(x: 40, y: 30))
            let count = Double(model.relationshipsToRender().count)
            return perCallMicroseconds(20) { renderPassOnce(model) } / count
        }
        let narrow = perConnectorCost(columns: 10)   // 100 objects
        let wide = perConnectorCost(columns: 40)     // 400 objects, same 180 links
        let growth = wide / narrow
        #expect(
            growth < 2.5,
            "quadrupling the objects grew the per-connector cost by \(String(format: "%.1f", growth))x, which means obstacles are still being sampled one by one"
        )
    }

    @Test("The hit test at 180 relationships stays interactive")
    func hitTest() {
        let model = warmed(denseModel())
        let corner = Position(x: 10, y: 10)
        let center = Position(x: 900, y: 720)
        // The two ends of the honest range: a corner, where the corridor rejects
        // nearly every link before routing it, and the middle of the document,
        // where it does not. The centre is the one asserted.
        let cornerCost = perCallMicroseconds { _ = model.relationship(near: corner) }
        let centerCost = perCallMicroseconds { _ = model.relationship(near: center) }
        // A click pays this once, not per frame, so the budget is generous: it
        // is a share of the 100 ms below which an interface still reads as
        // instant. Measured 2.9 ms in the middle on an idle machine.
        #expect(
            centerCost < 15000,
            "a hit test over 180 relationships costs \(String(format: "%.0f", centerCost)) µs in the middle of the document, \(String(format: "%.0f", cornerCost)) µs at a corner"
        )
    }

}
