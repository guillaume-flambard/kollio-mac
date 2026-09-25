import SwiftUI
import KollioCore

/// The canvas. It is the application: no permanent sidebar, no toolbar, no
/// panel. Every meaningful interaction happens at the point being worked on.
struct CanvasView: View {
    let model: KollioModel

    @Environment(\.kollioTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appliedPan: CGSize = .zero
    @State private var magnificationBase: Double?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                theme.canvasBackground
                RelationshipLayer(model: model)
                worldLayer
                screenSpaceLayer(viewport: proxy.size)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(backgroundGesture)
            .simultaneousGesture(magnifyGesture)
            .onPreferenceChange(NodeSizeKey.self) { sizes in
                for (objectID, size) in sizes {
                    guard size.width > 1, size.height > 1,
                          let instance = model.document.presentation.instance(for: objectID) else { continue }
                    let origin = Position(x: instance.position.x + model.dragOffset(for: objectID).x, y: instance.position.y + model.dragOffset(for: objectID).y)
                    model.recordFrame(Rect(origin: origin, size: Size(width: size.width, height: size.height)), for: objectID)
                }
            }
            .onAppear {
                model.viewport = Size(width: proxy.size.width, height: proxy.size.height)
                if model.isEmpty == false { model.fitContent() }
            }
            .onChange(of: proxy.size) { _, newValue in
                model.viewport = Size(width: newValue.width, height: newValue.height)
            }
            .onExitCommand { model.clearContextualState() }
        }
    }

    // MARK: - World layer

    private var worldLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.visibleInstances, id: \.id) { instance in
                node(for: instance)
            }
            if let preview = model.preview {
                ForEach(preview.objectIDs, id: \.self) { objectID in
                    ghost(for: objectID, preview: preview)
                }
            }
        }
        .scaleEffect(model.camera.zoom, anchor: .topLeading)
        .offset(x: model.camera.translation.x, y: model.camera.translation.y)

    }

    @ViewBuilder
    private func node(for instance: NodeInstance) -> some View {
        if let object = model.object(instance.objectID) {
            let offset = model.dragOffset(for: instance.objectID)
            Group {
                if object.isSetAside {
                    CollapsedDirectionView(
                        text: model.text(of: object.id),
                        reason: model.setAsideReason(of: object.id),
                        width: instance.size?.width ?? NodeLayout.estimatedSize(for: object).width,
                        onReopen: { model.reopen(object.id) }
                    )
                } else {
                    ObjectNodeView(
                        object: object,
                        text: model.text(of: object.id),
                        detail: model.detail(of: object.id),
                        isSelected: model.selection.contains(object.id),
                        isHovered: model.hoveredObjectID == object.id,
                        isDragging: model.dragState?.id == object.id,
                        width: instance.size?.width ?? NodeLayout.estimatedSize(for: object).width,
                        onSelect: { extend in model.select(object.id, extending: extend) },
                        onHover: { hovering in
                            if hovering {
                                model.hoveredObjectID = object.id
                            } else if model.hoveredObjectID == object.id {
                                model.hoveredObjectID = nil
                            }
                        },
                        onDragChanged: { translation in
                            model.beginDrag(object.id, screenTranslation: translation)
                        },
                        onDragEnded: { model.endDrag() },
                        onDoubleClick: { Task { await model.explore(object.id) } }
                    )
                }
            }
            .offset(x: instance.position.x + offset.x, y: instance.position.y + offset.y)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: NodeSizeKey.self, value: [instance.objectID: geo.size])
                }
            )
            .zIndex(object.isSetAside ? 0 : (model.selection.contains(object.id) ? 3 : 1))
        }
    }

    /// Proposed objects are placed where they would really enter the graph.
    private func ghost(for objectID: ObjectID, preview: ProposalPreview) -> some View {
        let create = preview.proposal.operations.compactMap { operation -> CreateObject? in
            if case .createObject(let create) = operation, create.id == objectID { return create }
            return nil
        }.first
        let position = preview.placements[objectID] ?? .zero
        let size = create == nil ? nil : estimate(of: objectID, in: preview)
        return Group {
            if let create, let size {
                GhostNodeView(
                    kind: create.kind,
                    text: create.text.resolve(languageCode: model.languageCode),
                    width: size.width
                )
                .offset(x: position.x - size.width / 2, y: position.y)
                .transition(
                    .asymmetric(
                        insertion: .offset(y: reduceMotion ? 0 : Motion.branchEntranceOffset).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
    }

    // MARK: - Screen-space layer

    /// Controls that must not scale with the camera: contextual actions, the
    /// inline composer, and the proposal decision.
    @ViewBuilder
    private func screenSpaceLayer(viewport: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            if let id = model.primarySelection, model.selection.count == 1, model.preview == nil {
                ContextualActions(model: model, target: id)
            }
            if let preview = model.preview {
                ProposalDecisionView(model: model)
                    .position(proposalDecisionPosition(preview, viewport: viewport))
            }
            if let composer = model.composer {
                ComposerView(model: model, anchor: composer.anchorID)
            }
            if let status = model.status, status.isEmpty == false {
                StatusView(text: status)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: Motion.reveal), value: model.preview?.id)
        .animation(reduceMotion ? nil : .easeInOut(duration: Motion.reveal), value: model.composer?.id)
    }

    /// The decision sits beside the branch it is about, clear of the branch
    /// itself and inside the window.
    private func proposalDecisionPosition(_ preview: ProposalPreview, viewport: CGSize) -> CGPoint {
        let card = CGSize(width: 340, height: 150)
        // Bounds of the whole ghost branch, not just its anchor points.
        var left = Double.infinity
        var right = -Double.infinity
        var top = Double.infinity
        var bottom = -Double.infinity
        for id in preview.objectIDs {
            guard let position = preview.placements[id] else { continue }
            let size = estimate(of: id, in: preview)
            let screen = model.camera.toScreen(position)
            left = Swift.min(left, screen.x - size.width / 2)
            right = Swift.max(right, screen.x + size.width / 2)
            top = Swift.min(top, screen.y)
            bottom = Swift.max(bottom, screen.y + size.height)
        }
        guard left.isFinite else {
            return CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        }

        // Prefer the right of the branch, then the left, then below it.
        if right + card.width + Space.xxl < viewport.width {
            return CGPoint(x: right + card.width / 2 + Space.xl, y: (top + bottom) / 2)
        }
        if left - card.width - Space.xxl > 0 {
            return CGPoint(x: left - card.width / 2 - Space.xl, y: (top + bottom) / 2)
        }
        return CGPoint(
            x: min(max((left + right) / 2, card.width / 2), max(viewport.width - card.width / 2, card.width / 2)),
            y: min(bottom + card.height / 2 + Space.xl, max(viewport.height - card.height / 2, card.height / 2))
        )
    }

    private func estimate(of objectID: ObjectID, in preview: ProposalPreview) -> Size {
        guard let create = preview.proposal.operations.compactMap({ operation -> CreateObject? in
            if case .createObject(let create) = operation, create.id == objectID { return create }
            return nil
        }).first else { return Size(width: NodeLayout.minimumWidth, height: NodeLayout.thoughtHeight) }
        return NodeLayout.estimatedSize(
            for: ContentObject(id: objectID, kind: create.kind, text: create.text, provenance: .human("ghost"))
        )
    }

    // MARK: - Gestures

    /// Panning the surface is direct: the content follows the trackpad with no
    /// lag and no inertia.
    private var backgroundGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let delta = CGSize(
                    width: value.translation.width - appliedPan.width,
                    height: value.translation.height - appliedPan.height
                )
                appliedPan = value.translation
                model.camera.pan(byScreenDelta: Position(x: delta.width, y: delta.height))
            }
            .onEnded { _ in appliedPan = .zero }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let base = magnificationBase ?? model.camera.zoom
                if magnificationBase == nil { magnificationBase = base }
                model.camera.zoom(to: base * value.magnification, anchor: Position(x: value.startLocation.x, y: value.startLocation.y))
            }
            .onEnded { _ in magnificationBase = nil }
    }
}

private struct NodeSizeKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [ObjectID: CGSize] = [:]
    static func reduce(value: inout [ObjectID: CGSize], nextValue: () -> [ObjectID: CGSize]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// A quiet, self-effacing status line. No toast, no badge.
struct StatusView: View {
    let text: String
    @Environment(\.kollioTheme) private var theme

    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, Space.m)
                .padding(.vertical, Space.s)
                .background(
                    Capsule(style: .continuous)
                        .fill(theme.surfacePrimary.opacity(0.94))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                )
                .padding(.bottom, Space.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }
}
