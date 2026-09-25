import SwiftUI
import KollioCore

/// Relationships are first-class: the reasoning must be readable from the
/// topology.
///
/// The layer is drawn in *screen* space, not world space. A connector therefore
/// keeps a constant stroke and a constant label at any zoom, the raster stays
/// the size of the window, and a connector can never be clipped by the extent of
/// the world content. Endpoints are world anchors projected through the camera,
/// so a connector still follows its objects while they move.
struct RelationshipLayer: View {
    let model: KollioModel

    @Environment(\.kollioTheme) private var theme

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            // Objects a connector may have to go around. Recomputed per draw so a
            // live drag moves the obstacles along with the dragged node.
            let nodeRects = obstacleRects()

            for relationship in model.relationshipsToRender() {
                guard let endpoints = screenEndpoints(for: relationship) else { continue }
                let isSelected = model.selection.contains(relationship.from)
                    || model.selection.contains(relationship.to)
                let color = isSelected ? theme.accent : theme.connector

                let route = RelationshipGeometry.routedRoute(
                    from: endpoints.start,
                    to: endpoints.end,
                    obstacles: obstacles(without: relationship.from, relationship.to, in: nodeRects)
                )
                context.stroke(
                    route.path(),
                    with: .color(color.opacity(isSelected ? 0.95 : 0.8)),
                    style: StrokeStyle(
                        lineWidth: isSelected ? 2 : 1.4,
                        lineCap: .round,
                        dash: model.preview?.relationshipIDs.contains(relationship.id) == true ? [6, 5] : []
                    )
                )
                drawLabel(for: relationship, at: route.midpoint, in: &context, emphasis: isSelected)
            }

            // Proposed relationships: dashed, lighter, cobalt, behind everything.
            for add in proposedRelationships {
                guard let endpoints = screenEndpointsForProposed(add) else { continue }
                context.stroke(
                    RelationshipGeometry.routedPath(
                        from: endpoints.start,
                        to: endpoints.end,
                        obstacles: obstacles(without: add.from, add.to, in: nodeRects)
                    ),
                    with: .color(theme.proposalAccent.opacity(0.65)),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [6, 5])
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Obstacles

    /// Every object rectangle the layer can route around, in screen space:
    /// committed objects with their measured or estimated frames, plus the ghost
    /// objects a preview is proposing.
    private func obstacleRects() -> [ObjectID: Rect] {
        var rects: [ObjectID: Rect] = [:]
        for instance in model.visibleInstances {
            guard let rect = rectFor(instance.objectID) else { continue }
            rects[instance.objectID] = model.camera.toScreen(rect)
        }
        if let preview = model.preview {
            for objectID in preview.objectIDs {
                guard let rect = rectFor(objectID) else { continue }
                rects[objectID] = model.camera.toScreen(rect)
            }
        }
        return rects
    }

    /// The obstacles that matter for one connector. Its own two ends are never
    /// obstacles: a connector is supposed to touch them.
    private func obstacles(without from: ObjectID, _ to: ObjectID, in all: [ObjectID: Rect]) -> [Rect] {
        all.compactMap { id, rect in id == from || id == to ? nil : rect }
    }

    // MARK: Endpoints

    private struct ScreenEndpoints {
        var start: AnchorPoint
        var end: AnchorPoint
        var midpoint: Position
    }

    private func screenEndpoints(for relationship: Relationship) -> ScreenEndpoints? {
        guard let from = model.frame(of: relationship.from),
              let to = model.frame(of: relationship.to) else { return nil }
        let fromRect = offsetRect(from, by: relationship.from)
        let toRect = offsetRect(to, by: relationship.to)
        let (start, end) = RelationshipGeometry.endpoints(of: relationship, from: fromRect, to: toRect)
        return project(start: start, end: end)
    }

    private func screenEndpointsForProposed(_ add: AddRelationship) -> ScreenEndpoints? {
        guard let from = rectFor(add.from), let to = rectFor(add.to) else { return nil }
        let proposed = Relationship(
            id: add.id,
            from: add.from,
            to: add.to,
            kind: add.kind,
            fromAnchor: add.fromAnchor,
            toAnchor: add.toAnchor,
            provenance: add.provenance
        )
        let (start, end) = RelationshipGeometry.endpoints(of: proposed, from: from, to: to)
        return project(start: start, end: end)
    }

    private func project(start: AnchorPoint, end: AnchorPoint) -> ScreenEndpoints {
        let screenStart = model.camera.toScreen(start.point)
        let screenEnd = model.camera.toScreen(end.point)
        return ScreenEndpoints(
            start: AnchorPoint(point: screenStart, direction: start.direction),
            end: AnchorPoint(point: screenEnd, direction: end.direction),
            midpoint: Position(x: (screenStart.x + screenEnd.x) / 2, y: (screenStart.y + screenEnd.y) / 2)
        )
    }

    /// A dragged object drags its connectors with it, before the transaction is
    /// committed.
    private func offsetRect(_ rect: Rect, by objectID: ObjectID) -> Rect {
        let offset = model.dragOffset(for: objectID)
        guard offset != .zero else { return rect }
        return Rect(origin: rect.origin.offset(dx: offset.x, dy: offset.y), size: rect.size)
    }

    private func rectFor(_ objectID: ObjectID) -> Rect? {
        if let frame = model.frame(of: objectID) {
            return offsetRect(frame, by: objectID)
        }
        // A proposed object has no frame yet: its placement and estimated size
        // are enough to draw a connector.
        guard let preview = model.preview,
              let position = preview.placements[objectID],
              let create = preview.proposal.operations.compactMap({ operation -> CreateObject? in
                  if case .createObject(let create) = operation, create.id == objectID { return create }
                  return nil
              }).first else { return nil }
        let size = NodeLayout.estimatedSize(
            for: ContentObject(id: objectID, kind: create.kind, text: create.text, provenance: .human("ghost"))
        )
        return Rect(origin: Position(x: position.x - size.width / 2, y: position.y), size: size)
    }

    private var proposedRelationships: [AddRelationship] {
        guard let preview = model.preview else { return [] }
        return preview.proposal.operations.compactMap { operation in
            guard case .addRelationship(let add) = operation,
                  preview.relationshipIDs.contains(add.id) else { return nil }
            return add
        }
    }

    // MARK: Labels

    private func drawLabel(for relationship: Relationship, at point: Position, in context: inout GraphicsContext, emphasis: Bool) {
        guard let label = model.label(of: relationship.id), !label.isEmpty else { return }
        let resolved = context.resolve(Text(label).font(TypeScale.metadata).foregroundColor(theme.textSecondary))
        let size = resolved.measure(in: CGSize(width: 220, height: 40))
        let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        // A small plate of canvas colour keeps the label readable where it
        // crosses a connector, without drawing a card around it.
        context.fill(
            Path(
                roundedRect: CGRect(x: origin.x - 5, y: origin.y - 1, width: size.width + 10, height: size.height + 2),
                cornerRadius: 4.0
            ),
            with: .color(theme.canvasBackground.opacity(emphasis ? 1 : 0.92))
        )
        context.draw(resolved, at: CGPoint(x: origin.x, y: origin.y), anchor: .leading)
    }
}
