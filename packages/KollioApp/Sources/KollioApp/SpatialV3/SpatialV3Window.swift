import SwiftUI

/// An isolated native preview of the shared Spatial Ink contract.
/// Does not alter existing .kollio documents, app state or persistence.
struct SpatialV3WindowView: View {
    @State private var depth = 1
    @State private var selectedID: String?

    /// Demo-only initial state for deterministic Web/Mac screenshot comparisons.
    /// The actual native app continues to open with the initial three-node state.
    init(initialDepth: Int = 1, initialSelectedID: String? = nil) {
        let boundedDepth = initialDepth == 2 ? 2 : 1
        _depth = State(initialValue: boundedDepth)
        _selectedID = State(initialValue: initialSelectedID)
    }

    private var visibleNodes: [SpatialV3Node] {
        SpatialV3Fixture.nodes.filter { $0.depth <= depth }
    }
    private var visibleEdges: [SpatialV3Edge] {
        SpatialV3Fixture.edges.filter { $0.depth <= depth }
    }
    private var selected: SpatialV3Node? {
        visibleNodes.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("◇  Kollio")
                    .font(.system(size: 17, weight: .bold))
                Text("Spatial Ink V3")
                    .font(.caption)
                    .foregroundStyle(KollioV3Tokens.Light.muted)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(KollioV3Tokens.Light.accentSoft, in: RoundedRectangle(cornerRadius: 7))
                Spacer()
                Text("Native macOS preview · Shared fixture")
                    .font(.caption)
                    .foregroundStyle(KollioV3Tokens.Light.muted)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 17)
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("SPATIAL INK · EXPLORATION")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.6)
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                        Text(SpatialV3Fixture.title)
                            .font(.system(size: 32, weight: .semibold, design: .default))
                            .tracking(-1.1)
                        Text(SpatialV3Fixture.subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                    }
                    Spacer()
                    Button(depth == 1 ? "+ Explorer 3 relations" : "− Replier les branches") {
                        depth = depth == 1 ? 2 : 1
                        if let selectedID, !visibleNodes.contains(where: { $0.id == selectedID }) {
                            self.selectedID = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(KollioV3Tokens.Light.accent)
                    .accessibilityIdentifier("spatial-v3-expand")
                }
                ScrollView(.horizontal) {
                    SpatialV3Stage(
                        nodes: visibleNodes,
                        edges: visibleEdges,
                        selectedID: $selectedID
                    )
                    .frame(minWidth: 900, minHeight: 580)
                }
                .background(KollioV3Tokens.Light.paper)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(KollioV3Tokens.Light.border))
                .accessibilityIdentifier("spatial-v3-canvas")
                Group {
                    if let selected {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(selected.eyebrow) · \(selected.status)")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(KollioV3Tokens.Light.muted)
                                Text(selected.label)
                                    .font(.headline)
                                Text(selected.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(KollioV3Tokens.Light.muted)
                            }
                            Spacer()
                            Button("Fermer") { selectedID = nil }
                                .buttonStyle(.bordered)
                        }
                        .padding(14)
                        .background(KollioV3Tokens.Light.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(KollioV3Tokens.Light.border))
                    } else {
                        Text("Sélectionne un objet pour lire son sens et sa provenance. Replier ne supprime rien.")
                            .font(.caption)
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                    }
                }
                .frame(minHeight: 65, alignment: .topLeading)
                Text("Prévisualisation uniquement · Aucune IA ni mutation de document activée.")
                    .font(.caption2)
                    .foregroundStyle(KollioV3Tokens.Light.muted)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            Spacer(minLength: 0)
        }
        .background(KollioV3Tokens.Light.paper)
        .foregroundStyle(KollioV3Tokens.Light.ink)
        .preferredColorScheme(.light)
    }
}

struct SpatialV3Stage: View {
    let nodes: [SpatialV3Node]
    let edges: [SpatialV3Edge]
    @Binding var selectedID: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    let step: CGFloat = 26
                    for x in stride(from: CGFloat(12), through: size.width, by: step) {
                        for y in stride(from: CGFloat(12), through: size.height, by: step) {
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                                with: .color(KollioV3Tokens.Light.border)
                            )
                        }
                    }
                }
                ForEach(edges) { edge in
                    if let from = nodes.first(where: { $0.id == edge.source }),
                       let to = nodes.first(where: { $0.id == edge.target }) {
                        SpatialV3Branch(edge: edge, from: from, to: to, canvasSize: geometry.size)
                    }
                }
                ForEach(nodes) { node in
                    SpatialV3MeaningNode(node: node, selected: selectedID == node.id) {
                        selectedID = selectedID == node.id ? nil : node.id
                    }
                    .position(x: geometry.size.width * node.x, y: geometry.size.height * node.y)
                }
                VStack {
                    HStack {
                        Text("ESPACE 01 / EXPLORATION")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("─ Relation établie  ·  ┄ Changement proposé  ·  \(nodes.count) objets")
                            .font(.caption2)
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                            .padding(10)
                            .background(KollioV3Tokens.Light.surface, in: RoundedRectangle(cornerRadius: 9))
                        Spacer()
                    }
                }
                .padding(20)
                .allowsHitTesting(false)
            }
        }
    }
}

private struct SpatialV3Branch: View {
    let edge: SpatialV3Edge
    let from: SpatialV3Node
    let to: SpatialV3Node
    let canvasSize: CGSize

    var body: some View {
        let start = CGPoint(x: canvasSize.width * from.x, y: canvasSize.height * from.y)
        let end = CGPoint(x: canvasSize.width * to.x, y: canvasSize.height * to.y)
        let bend = min(CGFloat(120), max(CGFloat(45), abs(end.y - start.y) * 0.35))
        let direction: CGFloat = end.y < start.y ? -1 : 1
        Path { path in
            path.move(to: start)
            path.addCurve(
                to: end,
                control1: CGPoint(x: start.x, y: start.y + direction * bend),
                control2: CGPoint(x: end.x, y: end.y - direction * bend)
            )
        }
        .stroke(
            edge.type == "proposes" ? KollioV3Tokens.Light.accent
            : edge.type == "evidence" ? KollioV3Tokens.Light.verified
            : edge.type == "questions" ? KollioV3Tokens.Light.question
            : KollioV3Tokens.Light.muted.opacity(0.55),
            style: StrokeStyle(lineWidth: 1.8, dash: (edge.type == "proposes" || edge.type == "questions") ? [5, 7] : [])
        )
        .accessibilityHidden(true)
    }
}

private struct SpatialV3MeaningNode: View {
    let node: SpatialV3Node
    let selected: Bool
    let onSelect: () -> Void

    private var background: Color {
        if node.kind == "mission" { return KollioV3Tokens.Light.accent }
        if node.kind == "proposal" { return KollioV3Tokens.Light.accentSoft }
        if node.kind == "source" { return KollioV3Tokens.Light.surface }
        return KollioV3Tokens.Light.paper
    }
    private var foreground: Color {
        node.kind == "mission" ? .white : KollioV3Tokens.Light.ink
    }
    private var stroke: Color {
        if selected { return KollioV3Tokens.Light.accent }
        if node.kind == "proposal" { return KollioV3Tokens.Light.accent }
        if node.kind == "source" { return KollioV3Tokens.Light.verified.opacity(0.55) }
        if node.kind == "mission" { return KollioV3Tokens.Light.accent }
        return .clear
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: node.kind == "mission" ? .center : .leading, spacing: 6) {
                Text(node.eyebrow.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(node.kind == "mission" ? Color.white.opacity(0.8) : KollioV3Tokens.Light.muted)
                Text(node.label)
                    .font(.system(size: node.kind == "mission" ? 19 : 15, weight: .semibold))
                    .multilineTextAlignment(node.kind == "mission" ? .center : .leading)
                if node.kind == "mission" {
                    Text("Ce qui nous rassemble")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .frame(width: node.kind == "mission" ? 235 : node.kind == "question" ? 175 : 195,
                   alignment: node.kind == "mission" ? .center : .leading)
            .frame(minHeight: node.kind == "mission" ? 88 : 65, alignment: .center)
            .padding(12)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13)
                .stroke(stroke, style: StrokeStyle(lineWidth: selected ? 2.5 : 1.5, dash: node.kind == "proposal" ? [5, 5] : [])))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(node.eyebrow) : \(node.label). \(node.status). Afficher les détails.")
        .accessibilityIdentifier("spatial-v3-node-\(node.id)")
    }
}
