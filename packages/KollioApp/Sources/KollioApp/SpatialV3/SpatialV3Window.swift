import SwiftUI

/// An isolated native preview of the shared Spatial Ink contract.
/// Does not alter existing .kollio documents, app state or persistence.
struct SpatialV3WindowView: View {
    private let stressMode: Bool
    @State private var depth = 1
    @State private var selectedID: String?

    /// Demo-only initial state for deterministic Web/Mac screenshot comparisons.
    /// The actual native app continues to open with the initial three-node state.
    init(initialDepth: Int = 1, initialSelectedID: String? = nil, stressMode: Bool = false) {
        self.stressMode = stressMode
        let boundedDepth = initialDepth == 2 ? 2 : 1
        _depth = State(initialValue: boundedDepth)
        _selectedID = State(initialValue: initialSelectedID)
    }

    private var visibleNodes: [SpatialV3Node] {
        (stressMode ? SpatialV3StressFixture.nodes : SpatialV3Fixture.nodes).filter { $0.depth <= depth }
    }
    private var visibleEdges: [SpatialV3Edge] {
        (stressMode ? SpatialV3StressFixture.edges : SpatialV3Fixture.edges).filter { $0.depth <= depth }
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
                        Text(stressMode ? SpatialV3StressFixture.title : SpatialV3Fixture.title)
                            .font(.system(size: 32, weight: .semibold, design: .default))
                            .tracking(-1.1)
                        Text(stressMode ? SpatialV3StressFixture.subtitle : SpatialV3Fixture.subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                    }
                    Spacer()
                    Button(depth == 1 ? "+ Explorer les relations" : "− Replier les branches") {
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
                        allNodes: stressMode ? SpatialV3StressFixture.nodes : SpatialV3Fixture.nodes,
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
    let allNodes: [SpatialV3Node]
    let edges: [SpatialV3Edge]
    @Binding var selectedID: String?

    @State private var camera = SpatialV3Camera()
    @State private var lastDrag = CGSize.zero
    @State private var lastPinch: CGFloat = 1
    @State private var cameraEdited = false

    private func bounds(for nodes: [SpatialV3Node]) -> CGRect {
        guard !nodes.isEmpty else {
            return CGRect(origin: .zero, size: SpatialV3Camera.world)
        }
        var left = CGFloat.infinity
        var top = CGFloat.infinity
        var right = -CGFloat.infinity
        var bottom = -CGFloat.infinity
        for node in nodes {
            let w: CGFloat = node.kind == "mission" ? 247 : node.kind == "question" ? 170 : 210
            let h: CGFloat = node.kind == "mission" ? 115 : node.kind == "question" ? 60 : 96
            let x = node.x * SpatialV3Camera.world.width
            let y = node.y * SpatialV3Camera.world.height
            left = min(left, x - w / 2)
            top = min(top, y - h / 2)
            right = max(right, x + w / 2)
            bottom = max(bottom, y + h / 2)
        }
        return CGRect(x: left - 30, y: top - 30,
                      width: right - left + 60, height: bottom - top + 60)
    }
    private var contentBounds: CGRect { bounds(for: nodes) }
    private var fullBounds: CGRect { bounds(for: allNodes) }
    private var contentOrigin: CGPoint {
        CGPoint(x: min(0, fullBounds.minX), y: min(0, fullBounds.minY))
    }
    private var canvasSize: CGSize {
        CGSize(width: max(SpatialV3Camera.world.width, fullBounds.maxX - contentOrigin.x),
               height: max(SpatialV3Camera.world.height, fullBounds.maxY - contentOrigin.y))
    }

    private func fit(_ size: CGSize) {
        camera = SpatialV3Camera.fitted(in: size, bounds: contentBounds.offsetBy(dx: -contentOrigin.x, dy: -contentOrigin.y))
        cameraEdited = false
    }
    private func zoom(_ factor: CGFloat, in size: CGSize) {
        camera = camera.zoomed(by: factor, around: CGPoint(x: size.width / 2, y: size.height / 2))
        cameraEdited = true
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    let deltaX = value.translation.width - lastDrag.width
                                    let deltaY = value.translation.height - lastDrag.height
                                    camera = camera.panned(dx: deltaX, dy: deltaY)
                                    lastDrag = value.translation
                                    cameraEdited = true
                                }
                                .onEnded { _ in lastDrag = .zero }
                        )
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
                    .allowsHitTesting(false)
                    ForEach(edges) { edge in
                        SpatialV3Branch(edge: edge, origin: contentOrigin)
                    }
                    ForEach(nodes) { node in
                        SpatialV3MeaningNode(node: node, selected: selectedID == node.id) {
                            selectedID = selectedID == node.id ? nil : node.id
                        }
                        .position(x: SpatialV3Camera.world.width * node.x - contentOrigin.x,
                                  y: SpatialV3Camera.world.height * node.y - contentOrigin.y)
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(camera.zoom, anchor: .topLeading)
                .offset(x: camera.x, y: camera.y)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            let delta = value.magnification / lastPinch
                            camera = camera.zoomed(by: delta, around: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                            lastPinch = value.magnification
                            cameraEdited = true
                        }
                        .onEnded { _ in lastPinch = 1 }
                )

                HStack(spacing: 5) {
                    Button("−") { zoom(1 / 1.2, in: geometry.size) }
                        .accessibilityLabel("Dézoomer")
                    Text("\(Int((camera.zoom * 100).rounded())) %")
                        .monospacedDigit()
                        .font(.caption2)
                        .frame(minWidth: 40)
                    Button("+") { zoom(1.2, in: geometry.size) }
                        .accessibilityLabel("Zoomer")
                    Button("Recentrer") { fit(geometry.size) }
                        .accessibilityIdentifier("spatial-v3-fit")
                }
                .buttonStyle(.bordered)
                .padding(8)
                .background(KollioV3Tokens.Light.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(KollioV3Tokens.Light.border))
                .padding(18)
                .accessibilityIdentifier("spatial-v3-camera")

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
            .onAppear { fit(geometry.size) }
            .onChange(of: nodes.count) { _, _ in
                if !cameraEdited { fit(geometry.size) }
            }
            .onChange(of: geometry.size) { _, next in
                if !cameraEdited { fit(next) }
            }
        }
    }
}

private struct SpatialV3Branch: View {
    let edge: SpatialV3Edge
    let origin: CGPoint

    var body: some View {
        Path { path in
            guard let first = edge.points.first else { return }
            path.move(to: CGPoint(x: first.x - origin.x, y: first.y - origin.y))
            for point in edge.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x - origin.x, y: point.y - origin.y))
            }
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
