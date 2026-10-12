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

    @Test("Zoom is bounded and panning never changes its source camera")
    func safety() {
        let original = SpatialV3Camera()
        #expect(original.zoomed(by: 100, around: .zero).zoom == 2.4)
        #expect(original.zoomed(by: 0.001, around: .zero).zoom == 0.35)
        let panned = original.panned(dx: -34, dy: 48)
        #expect(panned.x == -34)
        #expect(panned.y == 48)
        #expect(original == SpatialV3Camera())
    }
}
