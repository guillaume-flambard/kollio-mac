import Foundation
import CoreGraphics
import KollioCore

/// Translates a lossless read projection of a real .kollio v7 document to
/// the existing native spatial renderer. No write, file IO, or model mutation.
/// The renderer's simplified visual kinds are never written back to .kollio.
struct SpatialDocumentScene {
    let documentID: String
    let revision: Int
    let semanticRevision: Int
    let nodes: [SpatialV3Node]
    let edges: [SpatialV3Edge]

    init(projection: SpatialDocumentProjection) {
        documentID = projection.documentID
        revision = projection.revision
        semanticRevision = projection.semanticRevision

        // Authored positions retain their original world coordinates; only
        // missing positions get deterministic, visual-only grid slots.
        let columns = max(1, Int(ceil(sqrt(Double(projection.nodes.count) * 1.5))))
        var occupied: [CGPoint] = projection.nodes.compactMap { node in
            node.authoredPositions.first.map { CGPoint(x: $0.x, y: $0.y) }
        }
        var positioned: [String: CGPoint] = [:]
        for node in projection.nodes {
            if let saved = node.authoredPositions.first {
                positioned[node.id] = CGPoint(x: saved.x, y: saved.y)
                continue
            }
            var slot = 0
            while true {
                let proposal = CGPoint(x: CGFloat(slot % columns) * 270 + 150,
                                       y: CGFloat(slot / columns) * 160 + 115)
                if occupied.allSatisfy({ abs($0.x - proposal.x) >= 250 || abs($0.y - proposal.y) >= 145 }) {
                    positioned[node.id] = proposal
                    occupied.append(proposal)
                    break
                }
                slot += 1
            }
        }

        nodes = projection.nodes.map { node in
            let position = positioned[node.id] ?? .zero
            let family: String
            switch node.kind {
            case "evidence", "contribution": family = "source"
            case "question": family = "question"
            default: family = "idea"
            }
            return SpatialV3Node(
                id: node.id,
                kind: family,
                label: node.label,
                eyebrow: node.kind.uppercased(),
                detail: node.detail ?? "",
                status: node.isSetAside ? "set-aside" : "active",
                depth: 2,
                x: Double(position.x) / 1000,
                y: Double(position.y) / 640
            )
        }

        // Spatial routing is display-only. We never persist generated bends,
        // alter authored positions or change the semantic relationship IDs.
        edges = projection.edges.compactMap { relation in
            guard let start = positioned[relation.source],
                  let end = positioned[relation.target] else { return nil }
            let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
            let a = Self.border(from: start, toward: delta)
            let b = Self.border(from: end, toward: CGPoint(x: -delta.x, y: -delta.y))
            let obstacles = positioned
                .filter { $0.key != relation.source && $0.key != relation.target }
                .map { _, center in
                    // Conservative card envelope in stage/world coordinates.
                    // Source/target cards are excluded; this protects intermediate
                    // cards from paths without changing their saved geometry.
                    CGRect(x: center.x - 115, y: center.y - 70,
                           width: 230, height: 140)
                }
            let route = SpatialDocumentRouter.route(from: a, to: b, avoiding: obstacles)
            let style: String
            switch relation.kind {
            case "supports": style = "supports"
            case "contradicts": style = "questions"
            case "alternativeTo": style = "proposes"
            default: style = "relates"
            }
            return SpatialV3Edge(
                id: relation.id,
                source: relation.source,
                target: relation.target,
                type: style,
                label: relation.label ?? relation.kind,
                depth: 2,
                points: route.points,
                blocked: route.blocked,
                crossings: route.crossings
            )
        }
    }

    private static func border(from center: CGPoint, toward delta: CGPoint) -> CGPoint {
        let dx = abs(delta.x), dy = abs(delta.y)
        if dx < 0.001 && dy < 0.001 { return center }
        let factor = min(dx < 0.001 ? .infinity : 110 / dx,
                         dy < 0.001 ? .infinity : 52 / dy)
        return CGPoint(x: center.x + delta.x * factor, y: center.y + delta.y * factor)
    }
}


/// A deterministic, bounded presentation-only corridor router. It tests
/// unobstructed direct/L routes first, then scans lanes immediately outside
/// neighbouring card envelopes. If none is safe, it reports a *blocked*
/// fallback rather than claiming a line through a card was routed.
enum SpatialDocumentRouter {
    struct Result {
        let points: [CGPoint]
        let blocked: Bool
        let crossings: Int
    }

    private static let clearance: CGFloat = 12

    static func route(from start: CGPoint, to end: CGPoint, avoiding cards: [CGRect]) -> Result {
        let blockers = cards.map { $0.insetBy(dx: -clearance, dy: -clearance) }
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite,
              start != end else {
            return Result(points: [start, end], blocked: true, crossings: 0)
        }

        func clean(_ candidate: [CGPoint]) -> [CGPoint] {
            var path: [CGPoint] = []
            for point in candidate where path.last != point {
                path.append(point)
            }
            return path
        }
        func isClear(_ path: [CGPoint]) -> Bool {
            zip(path, path.dropFirst()).allSatisfy { from, to in
                blockers.allSatisfy { !segmentHits(from: from, to: to, rect: $0) }
            }
        }
        // Preserve the original native straight-line treatment where safe.
        let direct = [start, end]
        if isClear(direct) { return Result(points: direct, blocked: false, crossings: 0) }

        let horizontalFirst = clean([start, CGPoint(x: end.x, y: start.y), end])
        let verticalFirst = clean([start, CGPoint(x: start.x, y: end.y), end])
        var winner: [CGPoint]?
        var bestLength = CGFloat.infinity
        func consider(_ path: [CGPoint]) {
            guard isClear(path) else { return }
            let length = zip(path, path.dropFirst()).reduce(CGFloat.zero) { sum, pair in
                sum + hypot(pair.1.x - pair.0.x, pair.1.y - pair.0.y)
            } + CGFloat(max(0, path.count - 2)) * 12
            if length < bestLength {
                bestLength = length
                winner = path
            }
        }
        consider(horizontalFirst)
        consider(verticalFirst)

        // Candidate lanes are deterministic even if the dictionary iteration
        // ordering changes; routes with equal length keep their first winner.
        let ys = Array(Set(blockers.flatMap { [$0.minY - clearance, $0.maxY + clearance] })).sorted()
        let xs = Array(Set(blockers.flatMap { [$0.minX - clearance, $0.maxX + clearance] })).sorted()
        for y in ys {
            consider(clean([start, CGPoint(x: start.x, y: y), CGPoint(x: end.x, y: y), end]))
        }
        for x in xs {
            consider(clean([start, CGPoint(x: x, y: start.y), CGPoint(x: x, y: end.y), end]))
        }

        if let winner { return Result(points: winner, blocked: false, crossings: 0) }
        let collisions = blockers.filter { segmentHits(from: start, to: end, rect: $0) }.count
        return Result(points: direct, blocked: true, crossings: collisions)
    }

    /// Closed-rectangle intersection via Liang–Barsky clipping. A segment
    /// touching the clearance envelope is unsafe, including diagonal lines.
    static func segmentHits(from start: CGPoint, to end: CGPoint, rect: CGRect) -> Bool {
        guard !rect.isNull, !rect.isEmpty else { return false }
        let dx = end.x - start.x
        let dy = end.y - start.y
        var low: CGFloat = 0
        var high: CGFloat = 1
        for (p, q) in [
            (-dx, start.x - rect.minX),
            (dx, rect.maxX - start.x),
            (-dy, start.y - rect.minY),
            (dy, rect.maxY - start.y)
        ] {
            if abs(p) < 0.000001 {
                if q < 0 { return false }
            } else {
                let t = q / p
                if p < 0 { low = max(low, t) } else { high = min(high, t) }
                if low > high { return false }
            }
        }
        return true
    }
}
