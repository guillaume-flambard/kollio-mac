import Foundation
import KollioCore

/// The world-to-screen transform, and nothing else.
///
/// All canvas geometry goes through this type: `screen = world * zoom + translation`.
/// It works in logical points, never in Retina pixels, and it is pure so it can
/// be tested without a window.
public struct Camera: Equatable, Sendable {
    public static let minimumZoom: Double = 0.2
    public static let maximumZoom: Double = 3.0

    public var zoom: Double
    public var translation: Position

    public init(zoom: Double = 1, translation: Position = .zero) {
        self.zoom = zoom
        self.translation = translation
    }

    public static let identity = Camera()

    // MARK: - Transforms

    public func toScreen(_ point: Position) -> Position {
        Position(x: point.x * zoom + translation.x, y: point.y * zoom + translation.y)
    }

    public func toWorld(_ point: Position) -> Position {
        Position(x: (point.x - translation.x) / zoom, y: (point.y - translation.y) / zoom)
    }

    public func toScreen(_ rect: Rect) -> Rect {
        let origin = toScreen(rect.origin)
        return Rect(origin: origin, size: Size(width: rect.size.width * zoom, height: rect.size.height * zoom))
    }

    public func toWorld(_ rect: Rect) -> Rect {
        let origin = toWorld(rect.origin)
        return Rect(origin: origin, size: Size(width: rect.size.width / zoom, height: rect.size.height / zoom))
    }

    // MARK: - Gestures

    /// Pans by a screen-space delta (trackpad scroll, space + drag).
    public mutating func pan(byScreenDelta delta: Position) {
        translation = translation.offset(dx: delta.x, dy: delta.y)
    }

    /// Zooms while keeping `anchor` (given in screen space) visually still.
    public mutating func zoom(to newZoom: Double, anchor: Position) {
        let clamped = min(max(newZoom, Self.minimumZoom), Self.maximumZoom)
        let worldAnchor = toWorld(anchor)
        zoom = clamped
        translation = Position(
            x: anchor.x - worldAnchor.x * clamped,
            y: anchor.y - worldAnchor.y * clamped
        )
    }

    public mutating func zoom(by factor: Double, anchor: Position) {
        zoom(to: zoom * factor, anchor: anchor)
    }

    /// Drag delta conversion: a screen-space drag becomes a world-space move, so
    /// the object follows the cursor exactly at any zoom level.
    public func worldDelta(forScreenDelta delta: Position) -> Position {
        Position(x: delta.x / zoom, y: delta.y / zoom)
    }

    public mutating func move(toScreen point: Position) {
        translation = point
    }

    // MARK: - Framing

    /// Frames `content` in `viewport`, centred, with breathing room.
    public static func fitting(content: Rect, viewport: Size, padding: Double = 96) -> Camera {
        guard content.size.width > 0, content.size.height > 0, viewport.width > 0, viewport.height > 0 else {
            return Camera()
        }
        let available = Size(
            width: max(viewport.width - padding * 2, 1),
            height: max(viewport.height - padding * 2, 1)
        )
        let zoom = min(
            available.width / content.size.width,
            available.height / content.size.height,
            Self.maximumZoom
        )
        let clampedZoom = max(min(zoom, Self.maximumZoom), Self.minimumZoom)
        let center = content.center
        let translation = Position(
            x: viewport.width / 2 - center.x * clampedZoom,
            y: viewport.height / 2 - center.y * clampedZoom
        )
        return Camera(zoom: clampedZoom, translation: translation)
    }

    public func fitting(_ content: Rect, viewport: Size, padding: Double = 96) -> Camera {
        Camera.fitting(content: content, viewport: viewport, padding: padding)
    }

    /// The world rectangle currently visible: used to cull off-screen objects.
    public func visibleWorldRect(viewport: Size) -> Rect {
        let topLeft = toWorld(.zero)
        return Rect(
            x: topLeft.x,
            y: topLeft.y,
            width: viewport.width / zoom,
            height: viewport.height / zoom
        )
    }
}
