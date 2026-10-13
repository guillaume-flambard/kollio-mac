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

        // Native v3 currently supports edge endpoints and straight lines.
        // Preserve source/target/label/kind in the semantic projection; do
        // not pretend these display-only routes are obstacle-free.
        edges = projection.edges.compactMap { relation in
            guard let start = positioned[relation.source],
                  let end = positioned[relation.target] else { return nil }
            let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
            let a = Self.border(from: start, toward: delta)
            let b = Self.border(from: end, toward: CGPoint(x: -delta.x, y: -delta.y))
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
                points: [a, b],
                blocked: false, // Unknown: native fallback routes are not obstacle checked.
                crossings: 0
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
