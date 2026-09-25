import Foundation

/// A point in world (document) coordinates. Stored in the `.kollio` file as `{ "x": .., "y": .. }`.
public struct Position: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = Position(x: 0, y: 0)

    public func offset(dx: Double, dy: Double) -> Position {
        Position(x: x + dx, y: y + dy)
    }
}

/// A size in world (document) units, measured in logical points.
public struct Size: Codable, Hashable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct Rect: Codable, Hashable, Sendable {
    public var origin: Position
    public var size: Size

    public init(origin: Position, size: Size) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: Position(x: x, y: y), size: Size(width: width, height: height))
    }

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var center: Position {
        Position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }

    public func contains(_ point: Position) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    public func union(_ other: Rect) -> Rect {
        let x = Swift.min(minX, other.minX)
        let y = Swift.min(minY, other.minY)
        let w = Swift.max(maxX, other.maxX) - x
        let h = Swift.max(maxY, other.maxY) - y
        return Rect(x: x, y: y, width: w, height: h)
    }

    public func intersects(_ other: Rect) -> Bool {
        minX < other.maxX && maxX > other.minX && minY < other.maxY && maxY > other.minY
    }

    public func insetBy(dx: Double, dy: Double) -> Rect {
        Rect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: Swift.max(0, size.width - dx * 2),
            height: Swift.max(0, size.height - dy * 2)
        )
    }
}

extension Date {
    /// The `.kollio` format stores timestamps with millisecond precision. Dates
    /// are normalised on the way in so a save / reopen cycle is an exact
    /// round-trip rather than a near-equality.
    public var kollioNormalized: Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1000).rounded() / 1000)
    }
}
