import Foundation
import KollioCore

/// Lossless *reference* to an existing .kollio v7 semantic document for
/// Spatial Ink. This is a read model, never a replacement file format.
/// Full kinds and relationship kinds remain unchanged, even when the V3
/// renderer cannot yet display their richer meanings.
struct SpatialDocumentProjection {
    struct Node: Identifiable, Equatable {
        let id: String
        let kind: String
        let label: String
        let detail: String?
        let isSetAside: Bool
        let authoredPositions: [Position]
    }
    struct Edge: Identifiable, Equatable {
        let id: String
        let source: String
        let target: String
        let kind: String
        let label: String?
    }
    let documentID: String
    let revision: Int
    let semanticRevision: Int
    let nodes: [Node]
    let edges: [Edge]

    init(document: KollioDocument, languageCode: String = "fr") {
        documentID = document.documentId
        revision = document.revision
        semanticRevision = document.semanticRevision
        nodes = document.content.values.sorted { $0.id.rawValue < $1.id.rawValue }.map { object in
            Node(
                id: object.id.rawValue,
                kind: object.kind.rawValue,
                label: object.text.resolve(languageCode: languageCode),
                detail: object.detail?.resolve(languageCode: languageCode),
                isSetAside: object.isSetAside,
                authoredPositions: document.presentation.instances
                    .filter { $0.objectID == object.id }
                    .map(\.position)
            )
        }
        edges = document.relationships.values.sorted { $0.id.rawValue < $1.id.rawValue }.map { relation in
            Edge(
                id: relation.id.rawValue,
                source: relation.from.rawValue,
                target: relation.to.rawValue,
                kind: relation.kind.rawValue,
                label: relation.label?.resolve(languageCode: languageCode)
            )
        }
    }
}
