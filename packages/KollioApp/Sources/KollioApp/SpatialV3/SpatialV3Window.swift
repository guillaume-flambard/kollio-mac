import SwiftUI
import KollioCore

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
    @State private var newIdeaDraft = ""
    @State private var editingID: String?
    @State private var editDraft = ""
    @State private var editVersion: Int?
    @State private var relationTargetID = ""
    @State private var focusRequest = 0
    @State private var editFeedback: String?


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
        model.map { SpatialDocumentScene(projection: SpatialDocumentProjection(document: $0.document, languageCode: $0.languageCode)) }
    }
    private var allNodes: [SpatialV3Node] {
        if let realScene { return realScene.nodes }
        return stressMode ? SpatialV3StressFixture.nodes : SpatialV3Fixture.nodes
    }
    private var allEdges: [SpatialV3Edge] {
        if let realScene { return realScene.edges }
        return stressMode ? SpatialV3StressFixture.edges : SpatialV3Fixture.edges
    }
    /// Spatial IDs name drawings; Kollio commands always require semantic IDs.
    private func semanticID(_ visualID: String?) -> String? {
        guard let visualID else { return nil }
        return realScene?.objectID(for: visualID) ?? visualID
    }
    private struct RelationTargetChoice: Identifiable {
        let id: String  // Semantic object ID, never an occurrence ID.
        let label: String
    }
    private var relationTargets: [RelationTargetChoice] {
        // Compute the real scene only once, not once per menu item.
        let scene = realScene
        let candidates = scene?.nodes ?? (stressMode ? SpatialV3StressFixture.nodes : SpatialV3Fixture.nodes)
        let source = selectedID.flatMap { scene?.objectID(for: $0) } ?? selectedID
        var seen: Set<String> = []
        return candidates.compactMap { node in
            let identity = scene?.objectID(for: node.id) ?? node.id
            guard identity != source, seen.insert(identity).inserted else { return nil }
            return RelationTargetChoice(id: identity, label: node.label)
        }
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
        let scene = realScene
        let objectID = scene?.objectID(for: selectedID) ?? selectedID
        let appearances = Set(scene?.visualIDsByObjectID[objectID] ?? [selectedID])
        let ids = Set(allEdges.compactMap { edge -> String? in
            if appearances.contains(edge.source) { return edge.target }
            if appearances.contains(edge.target) { return edge.source }
            return nil
        })
        return allNodes.filter { ids.contains($0.id) && !appearances.contains($0.id) }
    }
    private func navigate(to node: SpatialV3Node) {
        depth = 2
        focusedGroup = nil
        selectedID = node.id
        // Navigation through search/history is an explicit request to see
        // another card. Clicking a card in place must never recenter the world.
        focusRequest += 1
        if focusHistory.last != node.id { focusHistory.append(node.id) }
        if focusHistory.count > 12 { focusHistory.removeFirst() }
    }
    private var spotlightIDs: Set<String>? {
        guard let selectedID else { return nil }
        let scene = realScene
        let objectID = scene?.objectID(for: selectedID) ?? selectedID
        var ids = Set(scene?.visualIDsByObjectID[objectID] ?? [selectedID])
        for edge in allEdges {
            if ids.contains(edge.source) { ids.insert(edge.target) }
            if ids.contains(edge.target) { ids.insert(edge.source) }
        }
        return ids
    }
    private var selected: SpatialV3Node? {
        visibleNodes.first { $0.id == selectedID }
    }

    private func addIdea() {
        guard let model else { return }
        let editor = SpatialDocumentEditor(model: model)
        if let created = editor.createIdea(newIdeaDraft, near: semanticID(selectedID)) {
            newIdeaDraft = ""
            depth = 2
            selectedID = created.rawValue
            focusedGroup = nil
            editFeedback = "Idée ajoutée au document. Pense à enregistrer."
        } else {
            editFeedback = "Impossible de créer cette idée. Saisis un texte non vide."
        }
    }

    private func beginEdit(_ id: String) {
        guard let model, let objectID = semanticID(id),
              let object = model.object(ObjectID(objectID)) else { return }
        editingID = id
        editVersion = object.objectVersion
        editDraft = object.text.resolve(languageCode: model.languageCode)
        editFeedback = nil
    }

    private func finishEdit() {
        guard let model, let editingID, let editVersion,
              let objectID = semanticID(editingID) else { return }
        let succeeded = SpatialDocumentEditor(model: model)
            .updateText(editDraft, of: objectID, expectedVersion: editVersion)
        if succeeded {
            self.editingID = nil
            self.editVersion = nil
            editFeedback = "Modification appliquée. Pense à enregistrer."
        } else {
            editFeedback = "Conflit ou texte invalide : la modification n'a pas été appliquée."
        }
    }

    private func addAssociation(from sourceID: String) {
        guard let model else { return }
        guard let objectID = semanticID(sourceID) else { return }
        let created = SpatialDocumentEditor(model: model)
            .associate(objectID, with: relationTargetID)
        editFeedback = created == nil
            ? "Relation refusée : vérifie la cible ou l'existence d'un lien identique."
            : "Association ajoutée. Pense à enregistrer."
        if created != nil { relationTargetID = "" }
    }

    private func moveSelectedOccurrence(_ instanceID: String, by delta: Position) {
        guard let model else { return }
        let applied = SpatialDocumentEditor(model: model)
            .moveOccurrence(instanceID, by: delta)
        editFeedback = L10n.callAsFunction(applied ? "spatial.drag.saved" : "spatial.drag.refused")
    }

    private func saveDocument() {
        guard let model else { return }
        editFeedback = SpatialDocumentEditor(model: model).save()
            ? "Document enregistré dans son fichier .kollio."
            : "Échec de l'enregistrement : vérifie le document et le stockage."
    }

    var body: some View {
        // The canvas plus its selected-card actions may exceed the window height.
        // Scroll the content instead of vertically centering and clipping the
        // header and inspector off-screen on smaller macOS windows.
        ScrollView(.vertical) {
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
                Text(model == nil ? "Native macOS preview · Shared fixture" : "Document .kollio · Édition locale")
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
                        Text(model == nil ? (stressMode ? SpatialV3StressFixture.subtitle : SpatialV3Fixture.subtitle) : "\(realScene?.semanticObjectCount ?? 0) objets · \(allNodes.count) représentations · \(allEdges.count) relations · révision \(realScene?.revision ?? 0)")
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
                if model != nil {
                    HStack(spacing: 10) {
                        TextField("Nouvelle idée…", text: $newIdeaDraft)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("spatial-v3-create-input")
                        Button("Ajouter l'idée") { addIdea() }
                            .disabled(newIdeaDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("spatial-v3-create")
                        Button("Enregistrer") { saveDocument() }
                            .accessibilityIdentifier("spatial-v3-save")
                        if let model {
                            Button("Annuler") { SpatialDocumentEditor(model: model).undo() }
                                .disabled(!model.canUndo)
                                .accessibilityIdentifier("spatial-v3-undo")
                            Button("Rétablir") { SpatialDocumentEditor(model: model).redo() }
                                .disabled(!model.canRedo)
                                .accessibilityIdentifier("spatial-v3-redo")
                        }
                    }
                    .buttonStyle(.bordered)
                    if let editFeedback {
                        Text(editFeedback)
                            .font(.caption)
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                            .accessibilityIdentifier("spatial-v3-edit-status")
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
                    Text("Ce document est vide. Saisis une idée dans le champ ci-dessus pour commencer.")
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
                        spotlightIDs: spotlightIDs,
                        focusRequest: focusRequest,
                        instanceIDByVisualID: realScene?.instanceIDByVisualID ?? [:],
                        onMoveOccurrence: { instanceID, delta in
                            moveSelectedOccurrence(instanceID, by: delta)
                        }
                    )
                    .frame(minWidth: 900, minHeight: 580)
                }
                .background(KollioV3Tokens.Light.paper)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(KollioV3Tokens.Light.border))
                .accessibilityIdentifier("spatial-v3-canvas")
                .onChange(of: selectedID) { _, id in
                    if editingID != id { editingID = nil; editVersion = nil }
                    relationTargetID = ""
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
                                if let id = semanticID(selected.id),
                                   let count = realScene?.occurrenceCount(for: id), count > 1 {
                                    Text(model?.languageCode == "en"
                                         ? "\(count) views of the same object"
                                         : "\(count) représentations de ce même objet")
                                        .font(.caption)
                                        .foregroundStyle(KollioV3Tokens.Light.muted)
                                        .accessibilityIdentifier("spatial-v3-occurrence-count")
                                }
                                Text(selected.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(KollioV3Tokens.Light.muted)
                            }
                            Spacer()
                            if model != nil {
                                VStack(alignment: .trailing, spacing: 9) {
                                    Button("Modifier") { beginEdit(selected.id) }
                                        .accessibilityIdentifier("spatial-v3-edit")
                                    Button(L10n.callAsFunction("spatial.camera.centerSelected")) {
                                        focusRequest += 1
                                    }
                                    .accessibilityIdentifier("spatial-v3-center-selected")
                                    if let instanceID = realScene?.instanceIDByVisualID[selected.id] {
                                        HStack(spacing: 5) {
                                            ForEach(SpatialNudgeDirection.allCases) { direction in
                                                Button {
                                                    moveSelectedOccurrence(instanceID, by: direction.delta)
                                                } label: {
                                                    Image(systemName: direction.symbol)
                                                }
                                                .accessibilityLabel(L10n.callAsFunction(direction.localizationKey))
                                                .help(L10n.callAsFunction(direction.localizationKey))
                                                .accessibilityIdentifier("spatial-v3-move-\(direction.rawValue)")
                                            }
                                        }
                                        .accessibilityElement(children: .contain)
                                        .accessibilityLabel(L10n.callAsFunction("spatial.move.controls"))
                                    }
                                    if !relationTargets.isEmpty {
                                        Picker("Associer à", selection: $relationTargetID) {
                                            Text("Choisir un objet").tag("")
                                            ForEach(relationTargets) { target in
                                                Text(target.label).tag(target.id)
                                            }
                                        }
                                        .frame(maxWidth: 245)
                                        .accessibilityIdentifier("spatial-v3-relation-target")
                                        Button("Créer l'association") { addAssociation(from: selected.id) }
                                            .disabled(relationTargetID.isEmpty || relationTargetID == semanticID(selected.id))
                                            .accessibilityIdentifier("spatial-v3-link")
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            Button("Fermer") { selectedID = nil }
                                .buttonStyle(.bordered)
                        }
                        .padding(14)
                        .background(KollioV3Tokens.Light.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(KollioV3Tokens.Light.border))
                        if model != nil && editingID == selected.id {
                            HStack(spacing: 8) {
                                TextField("Modifier le texte de l'objet", text: $editDraft)
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityIdentifier("spatial-v3-edit-input")
                                Button("Valider") { finishEdit() }
                                    .disabled(editDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    .accessibilityIdentifier("spatial-v3-edit-confirm")
                                Button("Annuler") { editingID = nil; editVersion = nil }
                                    .accessibilityIdentifier("spatial-v3-edit-cancel")
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text(model == nil
                             ? "Sélectionne un objet pour lire son sens et sa provenance. Replier ne supprime rien."
                             : L10n.callAsFunction("spatial.drag.hint"))
                            .font(.caption)
                            .foregroundStyle(KollioV3Tokens.Light.muted)
                    }
                }
                .frame(minHeight: 65, alignment: .topLeading)
                Text(model == nil
                     ? "Prévisualisation uniquement · Aucune IA ni mutation de document activée."
                     : "Édition locale via commandes Kollio · Enregistrer pour conserver les modifications.")
                    .font(.caption2)
                    .foregroundStyle(KollioV3Tokens.Light.muted)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .accessibilityIdentifier("spatial-v3-document-scroll")
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
    let focusRequest: Int
    /// Only real authored instances can move; fixture and derived cards cannot.
    let instanceIDByVisualID: [String: String]
    let onMoveOccurrence: (String, Position) -> Void

    // @GestureState clears itself on cancellation, view removal and completed
    // gestures. No document mutation can occur until onEnded fires.
    @GestureState private var activeDrag: SpatialActiveDrag?
    @GestureState private var panPreview = CGSize.zero
    @State private var camera = SpatialV3Camera()
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

    private var movingWorldDelta: CGSize {
        guard let activeDrag,
              let delta = SpatialOccurrenceDrag.worldDelta(
                screenTranslation: activeDrag.screenTranslation, zoom: camera.zoom
              ) else { return .zero }
        return CGSize(width: delta.x, height: delta.y)
    }

    @ViewBuilder
    private func drawing(_ node: SpatialV3Node) -> some View {
        let isMoving = activeDrag?.visualID == node.id
        SpatialV3MeaningNode(node: node, selected: selectedID == node.id) {
            selectedID = selectedID == node.id ? nil : node.id
        }
        .opacity(spotlightIDs == nil || spotlightIDs?.contains(node.id) == true ? 1 : 0.17)
        .position(x: SpatialV3Camera.world.width * node.x - contentOrigin.x,
                  y: SpatialV3Camera.world.height * node.y - contentOrigin.y)
        .offset(x: isMoving ? movingWorldDelta.width : 0,
                y: isMoving ? movingWorldDelta.height : 0)
        .zIndex(isMoving ? 10 : 0)
    }

    private func moveGesture(for visualID: String, instanceID: String) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("spatial-v3-screen"))
            .updating($activeDrag) { value, state, _ in
                // The preview is ephemeral. If the pointer gesture gets
                // cancelled, SwiftUI resets the state to nil automatically.
                state = SpatialActiveDrag(visualID: visualID,
                                          screenTranslation: value.translation)
            }
            .onEnded { value in
                guard let delta = SpatialOccurrenceDrag.worldDelta(
                    screenTranslation: value.translation, zoom: camera.zoom
                ), abs(delta.x) > 0.5 || abs(delta.y) > 0.5
                else { return }
                onMoveOccurrence(instanceID, delta)
            }
    }

    private func fit(_ size: CGSize) {
        camera = SpatialV3Camera.fitted(in: size, bounds: contentBounds.offsetBy(dx: -contentOrigin.x, dy: -contentOrigin.y))
        cameraEdited = false
    }
    private func zoom(_ factor: CGFloat, in size: CGSize) {
        camera = camera.zoomed(by: factor, around: CGPoint(x: size.width / 2, y: size.height / 2))
        cameraEdited = true
    }
    private func centerSelected(in size: CGSize) {
        guard let selectedID, let target = allNodes.first(where: { $0.id == selectedID }) else { return }
        let worldPosition = CGPoint(x: target.x * SpatialV3Camera.world.width - contentOrigin.x,
                                    y: target.y * SpatialV3Camera.world.height - contentOrigin.y)
        camera = camera.centered(on: worldPosition, in: size)
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
                                .updating($panPreview) { value, state, _ in
                                    // No persisted gesture delta. An interrupted background pan
                                    // snaps back cleanly, rather than leaking into the next pan.
                                    state = value.translation
                                }
                                .onEnded { value in
                                    camera = camera.panned(dx: value.translation.width,
                                                           dy: value.translation.height)
                                    cameraEdited = true
                                }
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
                        SpatialV3Branch(
                            edge: edge, origin: contentOrigin,
                            movingVisualID: activeDrag?.visualID, movingWorldDelta: movingWorldDelta
                        )
                        .opacity(spotlightIDs == nil || spotlightIDs?.contains(edge.source) == true
                            || spotlightIDs?.contains(edge.target) == true ? 1 : 0.09)
                    }
                    ForEach(nodes) { node in
                        if let instanceID = instanceIDByVisualID[node.id] {
                            drawing(node)
                                .highPriorityGesture(moveGesture(for: node.id, instanceID: instanceID))
                                .onMoveCommand { direction in
                                    guard let direction = SpatialNudgeDirection(direction) else { return }
                                    onMoveOccurrence(instanceID, direction.delta)
                                }
                                .accessibilityAction(named: Text(L10n.callAsFunction("spatial.move.up"))) {
                                    onMoveOccurrence(instanceID, SpatialNudgeDirection.up.delta)
                                }
                                .accessibilityAction(named: Text(L10n.callAsFunction("spatial.move.down"))) {
                                    onMoveOccurrence(instanceID, SpatialNudgeDirection.down.delta)
                                }
                                .accessibilityAction(named: Text(L10n.callAsFunction("spatial.move.left"))) {
                                    onMoveOccurrence(instanceID, SpatialNudgeDirection.left.delta)
                                }
                                .accessibilityAction(named: Text(L10n.callAsFunction("spatial.move.right"))) {
                                    onMoveOccurrence(instanceID, SpatialNudgeDirection.right.delta)
                                }
                        } else {
                            drawing(node)
                        }
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(camera.zoom, anchor: .topLeading)
                .offset(x: camera.x + panPreview.width,
                        y: camera.y + panPreview.height)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            guard activeDrag == nil, panPreview == .zero else { return }
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
            .coordinateSpace(name: "spatial-v3-screen")
            .onAppear { fit(geometry.size) }
            .onChange(of: focusRequest) { _, _ in
                // Camera follows only an explicit navigation or Center command.
                withAnimation(.easeInOut(duration: 0.22)) {
                    centerSelected(in: geometry.size)
                }
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
    let movingVisualID: String?
    let movingWorldDelta: CGSize

    var body: some View {
        Path { path in
            var points = edge.points
            guard !points.isEmpty else { return }
            // Keep both endpoints attached to the moving card in the live
            // preview. Reroute fully from the committed document on release.
            if edge.source == movingVisualID {
                points[0].x += movingWorldDelta.width
                points[0].y += movingWorldDelta.height
            }
            if edge.target == movingVisualID {
                let last = points.count - 1
                points[last].x += movingWorldDelta.width
                points[last].y += movingWorldDelta.height
            }
            path.move(to: CGPoint(x: points[0].x - origin.x, y: points[0].y - origin.y))
            for point in points.dropFirst() {
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

/// Immutable gesture preview: never persisted. SwiftUI resets @GestureState
/// on cancellation instead of waiting for an onEnded that will never fire.
struct SpatialActiveDrag: Equatable {
    let visualID: String
    let screenTranslation: CGSize
}

/// Same one-instance command from focused arrow keys, the inspector controls
/// and VoiceOver accessibility actions. Fixed world step, independent of zoom.
enum SpatialNudgeDirection: String, CaseIterable, Identifiable {
    case up, down, left, right

    var id: String { rawValue }
    var localizationKey: String { "spatial.move.\(rawValue)" }
    var symbol: String { "arrow.\(rawValue)" }
    var delta: Position {
        switch self {
        case .up: Position(x: 0, y: -16)
        case .down: Position(x: 0, y: 16)
        case .left: Position(x: -16, y: 0)
        case .right: Position(x: 16, y: 0)
        }
    }

    init?(_ command: MoveCommandDirection) {
        switch command {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        @unknown default: return nil
        }
    }
}

/// A drag happens in the viewport's screen coordinates. Persistence is in
/// document world coordinates: camera translation never enters this delta.
enum SpatialOccurrenceDrag {
    static func worldDelta(screenTranslation: CGSize, zoom: CGFloat) -> Position? {
        guard zoom.isFinite, zoom > 0,
              screenTranslation.width.isFinite, screenTranslation.height.isFinite else {
            return nil
        }
        return Position(x: screenTranslation.width / zoom, y: screenTranslation.height / zoom)
    }
}
