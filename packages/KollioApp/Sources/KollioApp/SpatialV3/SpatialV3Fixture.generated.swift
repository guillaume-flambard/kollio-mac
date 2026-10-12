// GENERATED — scripts/generate-spatial.mjs. Do not edit by hand.
import Foundation

struct SpatialV3Node: Identifiable, Hashable {
    let id: String
    let kind: String
    let label: String
    let eyebrow: String
    let detail: String
    let status: String
    let depth: Int
    let x: Double
    let y: Double
}

struct SpatialV3Edge: Identifiable, Hashable {
    let id: String
    let source: String
    let target: String
    let type: String
    let label: String
    let depth: Int
}

enum SpatialV3Fixture {
    static let schemaVersion = 1
    static let id = "kollio-spatial-intro-v1"
    static let title = "Lancement produit"
    static let subtitle = "Explorer les options avant de décider"
    static let description = "Préparer le lancement sans perdre les décisions ni les preuves."

    static let nodes: [SpatialV3Node] = [
        SpatialV3Node(id: "mission", kind: "mission", label: "Lancement produit", eyebrow: "CONTEXTE CENTRAL", detail: "Notre intention durable et le point de départ du raisonnement.", status: "saved", depth: 1, x: 0.5, y: 0.54),
        SpatialV3Node(id: "context", kind: "idea", label: "Comprendre le besoin", eyebrow: "CONTEXTE", detail: "Les hypothèses et deux références associées à la situation.", status: "saved", depth: 1, x: 0.22, y: 0.25),
        SpatialV3Node(id: "goal", kind: "goal", label: "Choisir une direction claire", eyebrow: "OBJECTIF", detail: "Définir le résultat souhaité sans créer une action exécutable.", status: "saved", depth: 1, x: 0.78, y: 0.25),
        SpatialV3Node(id: "evidence", kind: "source", label: "Étude de marché", eyebrow: "SOURCE", detail: "Référence présente mais non vérifiée par un humain.", status: "unverified", depth: 2, x: 0.2, y: 0.77),
        SpatialV3Node(id: "proposal", kind: "proposal", label: "Lancement progressif", eyebrow: "PROPOSITION", detail: "Modification proposée, sans application automatique.", status: "pending", depth: 2, x: 0.78, y: 0.77),
        SpatialV3Node(id: "question", kind: "question", label: "Que manque-t-il ?", eyebrow: "QUESTION", detail: "Point encore ouvert qui nécessite une exploration.", status: "open", depth: 2, x: 0.84, y: 0.49)
    ]
    static let edges: [SpatialV3Edge] = [
        SpatialV3Edge(id: "rel-context", source: "mission", target: "context", type: "relates", label: "contexte", depth: 1),
        SpatialV3Edge(id: "rel-goal", source: "mission", target: "goal", type: "supports", label: "oriente", depth: 1),
        SpatialV3Edge(id: "rel-evidence", source: "mission", target: "evidence", type: "evidence", label: "documente", depth: 2),
        SpatialV3Edge(id: "rel-proposal", source: "mission", target: "proposal", type: "proposes", label: "propose", depth: 2),
        SpatialV3Edge(id: "rel-question", source: "goal", target: "question", type: "questions", label: "interroge", depth: 2)
    ]
}
