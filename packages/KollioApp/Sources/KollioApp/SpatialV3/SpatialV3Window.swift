import SwiftUI

/// An isolated native preview of the shared Spatial Ink contract.
/// Does not alter existing .kollio documents, app state or persistence.
struct SpatialV3WindowView: View {
    private let stressMode: Bool
    private let model: KollioModel?
    @State private var depth = 1
    @State private var selectedID: String?
    @State private var focusHistory: [String] = []
    @State private var search = ""
    @State private var focusedGroup: Int? = nil

    /// Demo-only initial state for deterministic Web/Mac screenshot comparisons.
    /// The actual native app continues to open with the initial three-node state.
    init(initialDepth: Int = 1, initialSelectedID: String? = nil, stressMode: Bool = false, model: KollioModel? = nil) {
        self.stressMode = stressMode
        self.model = model
        let boundedDepth = model != nil ? 2 : (initialDepth == 2 ? 2 : 1)
        _depth = State(initialValue: boundedDepth)
        _selectedID = State(initialValue: initialSelectedID)
    }

    private var realScene: SpatialDocumentScene? {
        model.map { SpatialDocumentScene(projection: SpatialDocumentProjection(document: $0.document)) }
    }
    private var allNodes: [SpatialV3Node] {
        if let realScene { return realScene.nodes }
        return stressMode ? SpatialV3StressFixture.nodes : SpatialV3Fixture.nodes
    }
    private var allEdges: [SpatialV3Edge] {
        if let realScene { return realScene.edges }
        return stressMode ? SpatialV3StressFixture.edges : SpatialV3Fixture.edges
    }
    private var groupCount: Int { (allNodes.count + 11) / 12 }
    private var focusedIDs: Set<String>? {
        guard let focusedGroup else { return nil }
        return Set(allNodes.dropFirst(focusedGroup * 12).prefix(12).map(\.id))
    }
    private var visibleNodes: [SpatialV3Node] {
        allNodes.filter { node in
            node.depth <= depth && (focusedIDs?.contains(node.id) ?? true)
        }
    }
    private var visibleEdges: [SpatialV3Edge] {
        allEdges.filter { edge in
            edge.depth <= depth && (focusedIDs.map { $0.contains(edge.source) && $0.contains(edge.target) } ?? true)
        }
    }
    private var matches: [SpatialV3Node] {
        guard !search.isEmpty else { return [] }
        return allNodes.filter { $0.label.localizedCaseInsensitiveContains(search) || $0.id.localizedCaseInsensitiveContains(search) }
    }
    private var focusedNeighbors: [SpatialV3Node] {
        guard let selectedID else { return [] }
        let ids = Set(allEdges.compactMap { edge -> String? in
            if edge.source == selectedID { return edge.target }
            if edge.target == selectedID { return edge.source }
            return nil
        })
        return allNodes.filter { ids.contains($0.id) }
    }
    private func navigate(to node: SpatialV3Node) {
        depth = 2
        focusedGroup = nil
        selectedID = node.id
        if focusHistory.last != node.id { focusHistory.append(node.id) }
        if focusHistory.count > 12 { focusHistory.removeFirst() }
    }
    private var spotlightIDs: Set<String>? {
        guard let selectedID else { return nil }
        var ids: Set<String> = [selectedID]
        for edge in allEdges {
            if edge.source == selectedID { ids.insert(edge.target) }
            if edge.target == selectedID { ids.insert(edge.source) }
        }
        return ids
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
                Text(model == nil ? "Native macOS preview · Shared fixture" : "Document .kollio · Lecture seule")
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
                        Text(model == nil ? (stressMode ? SpatialV3StressFixture.title : SpatialV3Fixture.title) : "Document actif")
                            .font(.system(size: 32, weight: .semibold, design: .default))
                            .tracking(-1.1)
                        Text(model == nil ? (stressMode ? SpatialV3StressFixture.subtitle : SpatialV3Fixture.subtitle) : "\(allNodes.count) objets · \(allEdges.count) relations · révision \(realScene?.revision ?? 0)")
                            .font(.system(size: 14))
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                    }
                    Spacer()
                    if model == nil {
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
                }
                if stressMode || model != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Rechercher un objet ou identifiant", text: $search)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 330)
                        if !search.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(Array(matches.prefix(8))) { item in
                                        Button(item.label) {
                                            navigate(to: item)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    if matches.isEmpty { Text("Aucun résultat").font(.caption) }
                                }
                            }
                        }
                        if stressMode || allNodes.count > 20 {
                            ScrollView(.horizontal) {
                                HStack {
                                    Button("Vue d'ensemble") { focusedGroup = nil }
                                    ForEach(0..<groupCount, id: \.self) { index in
                                        Button("Groupe \(index + 1)") {
                                            focusedGroup = index
                                            depth = 2
                                        }
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                if !focusHistory.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            Button("Vue d'ensemble") { selectedID = nil; focusHistory = []; focusedGroup = nil }
                            ForEach(Array(focusHistory.enumerated()), id: \.offset) { index, id in
                                Button(allNodes.first(where: { $0.id == id })?.label ?? id) {
                                    focusHistory = Array(focusHistory.prefix(index + 1))
                                    if let node = allNodes.first(where: { $0.id == id }) { navigate(to: node) }
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .accessibilityLabel("Parcours d'exploration")
                }
                if !focusedNeighbors.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(focusedNeighbors.prefix(12))) { node in
                                Button(node.label + " ↗") { navigate(to: node) }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .accessibilityLabel("Relations de l'objet")
                }
                if let spotlightIDs {
                    HStack {
                        Text("Focus · \(spotlightIDs.count) objets reliés")
                            .font(.caption)
                        Spacer()
                        Button("Revenir au contexte") {
                            selectedID = nil
                            focusHistory = []
                            focusedGroup = nil
                            depth = 2
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(10)
                    .background(KollioV3Tokens.Light.accentSoft, in: RoundedRectangle(cornerRadius: 10))
                }
                if model != nil && allNodes.isEmpty {
                    Text("Ce document est vide. Ajoute du contenu dans la fenêtre Kollio principale pour le voir ici.")
                        .font(.callout)
                        .foregroundStyle(KollioV3Tokens.Light.muted)
                        .accessibilityIdentifier("spatial-v3-empty-document")
                }
                ScrollView(.horizontal) {
                    SpatialV3Stage(
                        nodes: visibleNodes,
                        allNodes: focusedGroup == nil ? allNodes : visibleNodes,
                        edges: visibleEdges,
                        selectedID: $selectedID,
                        spotlightIDs: spotlightIDs
                    )
                    .frame(minWidth: 900, minHeight: 580)
                }
                .background(KollioV3Tokens.Light.paper)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(KollioV3Tokens.Light.border))
                .accessibilityIdentifier("spatial-v3-canvas")
                .onChange(of: selectedID) { _, id in
                    if let id, focusHistory.last != id {
                        focusHistory.append(id)
                        if focusHistory.count > 12 { focusHistory.removeFirst() }
                    }
                }
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
                Text(model == nil
                     ? "Prévisualisation uniquement · Aucune IA ni mutation de document activée."
                     : "Lecture seule du document actif · Aucun enregistrement ni modification depuis Spatial Ink.")
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
    let spotlightIDs: Set<String>?

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
                            .opacity(spotlightIDs == nil || edge.source == selectedID || edge.target == selectedID ? 1 : 0.09)
                    }
                    ForEach(nodes) { node in
                        SpatialV3MeaningNode(node: node, selected: selectedID == node.id) {
                            selectedID = selectedID == node.id ? nil : node.id
                        }
                        .opacity(spotlightIDs == nil || spotlightIDs?.contains(node.id) == true ? 1 : 0.17)
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
            .onChange(of: selectedID) { _, target in
                guard let target, let node = allNodes.first(where: { $0.id == target }) else { return }
                let zoom = max(0.8, min(1.2, camera.zoom))
                let x = node.x * SpatialV3Camera.world.width - contentOrigin.x
                let y = node.y * SpatialV3Camera.world.height - contentOrigin.y
                withAnimation(.easeInOut(duration: 0.22)) {
                    camera = SpatialV3Camera(
                        zoom: zoom,
                        x: geometry.size.width / 2 - x * zoom,
                        y: geometry.size.height / 2 - y * zoom
                    )
                }
                cameraEdited = true
            }
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
