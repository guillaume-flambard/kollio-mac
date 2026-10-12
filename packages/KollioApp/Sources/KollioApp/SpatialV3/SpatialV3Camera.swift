import Foundation
import CoreGraphics

/// Viewport state, deliberately independent from durable KollioDocument changes.
struct SpatialV3Camera: Equatable {
    var zoom: CGFloat = 1
    var x: CGFloat = 0
    var y: CGFloat = 0

    static let world = CGSize(width: 1000, height: 640)
    static let minZoom: CGFloat = 0.35
    static let maxZoom: CGFloat = 2.4

    static func fitted(in size: CGSize) -> SpatialV3Camera {
        guard size.width > 0, size.height > 0 else { return SpatialV3Camera() }
        let zoom = min(max(min(size.width / world.width, size.height / world.height), minZoom), maxZoom)
        return SpatialV3Camera(
            zoom: zoom,
            x: (size.width - world.width * zoom) / 2,
            y: (size.height - world.height * zoom) / 2
        )
    }

    func zoomed(by factor: CGFloat, around anchor: CGPoint) -> SpatialV3Camera {
        let next = min(max(zoom * factor, Self.minZoom), Self.maxZoom)
        let ratio = next / zoom
        return SpatialV3Camera(
            zoom: next,
            x: anchor.x - (anchor.x - x) * ratio,
            y: anchor.y - (anchor.y - y) * ratio
        )
    }

    func panned(dx: CGFloat, dy: CGFloat) -> SpatialV3Camera {
        SpatialV3Camera(zoom: zoom, x: x + dx, y: y + dy)
    }
}
