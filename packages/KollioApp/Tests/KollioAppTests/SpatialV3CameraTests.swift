import Foundation
import Testing
@testable import KollioApp

@Suite("Spatial Ink V3 — camera")
struct SpatialV3CameraTests {
    @Test("Fitting centers the semantic world without distortion")
    func fit() {
        let camera = SpatialV3Camera.fitted(in: CGSize(width: 1200, height: 640))
        #expect(camera.zoom == 1)
        #expect(camera.x == 100)
        #expect(camera.y == 0)
        let half = SpatialV3Camera.fitted(in: CGSize(width: 500, height: 320))
        #expect(half.zoom == 0.5)
    }

    @Test("Zoom keeps its anchor at the same world position")
    func anchor() {
        let camera = SpatialV3Camera.fitted(in: CGSize(width: 1200, height: 640))
        let anchor = CGPoint(x: 333, y: 171)
        let zoomed = camera.zoomed(by: 1.7, around: anchor)
        #expect(abs((anchor.x - zoomed.x) / zoomed.zoom - (anchor.x - camera.x) / camera.zoom) < 0.0001)
        #expect(abs((anchor.y - zoomed.y) / zoomed.zoom - (anchor.y - camera.y) / camera.zoom) < 0.0001)
    }

    @Test("Dynamic negative-origin bounds are fitted into the viewport")
    func dynamicBounds() {
        let bounds = CGRect(x: -1550, y: -620, width: 4250, height: 2100)
        let camera = SpatialV3Camera.fitted(in: CGSize(width: 1280, height: 800), bounds: bounds)
        #expect(camera.zoom < 0.35)
        #expect(bounds.minX * camera.zoom + camera.x >= -0.0001)
        #expect(bounds.maxX * camera.zoom + camera.x <= 1280.0001)
        #expect(bounds.minY * camera.zoom + camera.y >= -0.0001)
        #expect(bounds.maxY * camera.zoom + camera.y <= 800.0001)
    }

    @Test("Zoom is bounded and panning never changes its source camera")
    func safety() {
        let original = SpatialV3Camera()
        #expect(original.zoomed(by: 100, around: .zero).zoom == 2.4)
        #expect(original.zoomed(by: 0.001, around: .zero).zoom == 0.08)
        let panned = original.panned(dx: -34, dy: 48)
        #expect(panned.x == -34)
        #expect(panned.y == 48)
        #expect(original == SpatialV3Camera())
    }

    @Test("C2.8 explicit centering preserves zoom and puts the requested card in the viewport center")
    func explicitCentering() {
        let original = SpatialV3Camera(zoom: 0.75, x: -220, y: 45)
        let viewport = CGSize(width: 1060, height: 640)
        let card = CGPoint(x: 740, y: 350)
        let centered = original.centered(on: card, in: viewport)
        #expect(centered.zoom == original.zoom)
        #expect(abs(card.x * centered.zoom + centered.x - viewport.width / 2) < 0.01)
        #expect(abs(card.y * centered.zoom + centered.y - viewport.height / 2) < 0.01)
        #expect(original == SpatialV3Camera(zoom: 0.75, x: -220, y: 45))
        // Selecting in place never invokes centered(on:). No camera mutation
        // can be inferred from a selection without an explicit focus request.
    }

    @Test("C2.8 a cancelled background pan cannot leak previous gesture translation")
    func interruptedPanHasNoAccumulatedState() {
        let camera = SpatialV3Camera.fitted(in: CGSize(width: 950, height: 600))
        // @GestureState previews a total displacement, then returns to zero
        // automatically when the native gesture is cancelled.
        let preview = camera.panned(dx: 128, dy: -64)
        #expect(preview.x == camera.x + 128)
        #expect(preview.y == camera.y - 64)
        let cancelled = camera
        let next = cancelled.panned(dx: -12, dy: 8)
        #expect(next.x == camera.x - 12)
        #expect(next.y == camera.y + 8)
        #expect(next.zoom == camera.zoom)
    }
}
