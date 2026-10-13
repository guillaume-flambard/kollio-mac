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

@Suite("Spatial C2.15 — interruptible pinch without stale zoom")
struct SpatialPinchTransactionTests {
    private let viewport = CGSize(width: 900, height: 700)

    @Test("A changed gesture previews without mutating the baseline")
    func previewIsEphemeral() {
        let baseline = SpatialV3Camera(zoom: 0.75, x: -100, y: 42)
        let preview = SpatialPinchTransaction.camera(
            from: baseline, magnification: 1.8, viewport: viewport, allowed: true
        )
        #expect(preview.zoom > baseline.zoom)
        #expect(baseline == SpatialV3Camera(zoom: 0.75, x: -100, y: 42))
        // @GestureState resets to 1 when cancelled: the rendered value returns
        // to the untouched baseline, and a new gesture starts with a fresh 1.
        let cancelled = SpatialPinchTransaction.camera(
            from: baseline, magnification: 1, viewport: viewport, allowed: true
        )
        #expect(cancelled == baseline)
        let next = SpatialPinchTransaction.camera(
            from: baseline, magnification: 1.15, viewport: viewport, allowed: true
        )
        #expect(abs(next.zoom - baseline.zoom * 1.15) < 0.00001)
    }

    @Test("A completed gesture applies total magnification just once")
    func commitsOnceWithAnchor() {
        let initial = SpatialV3Camera(zoom: 0.8, x: -30, y: 80)
        let committed = SpatialPinchTransaction.camera(
            from: initial, magnification: 1.5, viewport: viewport, allowed: true
        )
        #expect(abs(committed.zoom - 1.2) < 0.00001)
        let center = CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        #expect(abs((center.x - initial.x) / initial.zoom
                    - (center.x - committed.x) / committed.zoom) < 0.00001)
        #expect(abs((center.y - initial.y) / initial.zoom
                    - (center.y - committed.y) / committed.zoom) < 0.00001)
    }

    @Test("A card drag or background pan disallows an overlapping pinch")
    func competingGestures() {
        let baseline = SpatialV3Camera(zoom: 1.1, x: 16, y: -44)
        #expect(SpatialPinchTransaction.camera(
            from: baseline, magnification: 2, viewport: viewport, allowed: false
        ) == baseline)
    }

    @Test("Invalid magnification or viewport cannot poison camera state")
    func invalidInput() {
        let baseline = SpatialV3Camera()
        for factor: CGFloat in [0, -1, .nan, .infinity] {
            #expect(SpatialPinchTransaction.camera(
                from: baseline, magnification: factor, viewport: viewport, allowed: true
            ) == baseline)
        }
        #expect(SpatialPinchTransaction.camera(
            from: baseline, magnification: 2,
            viewport: .zero, allowed: true
        ) == baseline)
    }

    @Test("Preview and final camera obey the same zoom limits")
    func limits() {
        let baseline = SpatialV3Camera()
        #expect(SpatialPinchTransaction.camera(
            from: baseline, magnification: 100, viewport: viewport, allowed: true
        ).zoom == SpatialV3Camera.maxZoom)
        #expect(SpatialPinchTransaction.camera(
            from: baseline, magnification: 0.001, viewport: viewport, allowed: true
        ).zoom == SpatialV3Camera.minZoom)
    }
}
