import Foundation

/// The versioned `.kollio` document.
///
/// Everything in this type is portable, renderer independent data. No SwiftUI
/// type, no CGPoint, no class name, no platform callback object is ever stored.
public struct KollioDocument: Codable, Hashable, Sendable {
    public var schemaVersion: Int
    public var documentId: String
    /// Bumped on every accepted mutation, presentation included.
    public var revision: Int
    /// Bumped only when the meaning of the document changed.
    public var semanticRevision: Int
    public var createdAt: Date
    public var updatedAt: Date

    public var content: [ObjectID: ContentObject]
    public var relationships: [RelationshipID: Relationship]
    public var decisions: [DecisionID: Decision]
    public var contributions: [ActorID: ContributionRecord]
    public var products: [ObjectID: ProductComposition]
    public var presentation: Presentation

    public init(
        schemaVersion: Int = KollioDocument.currentSchemaVersion,
        documentId: String = UUID().uuidString,
        revision: Int = 0,
        semanticRevision: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        content: [ObjectID: ContentObject] = [:],
        relationships: [RelationshipID: Relationship] = [:],
        decisions: [DecisionID: Decision] = [:],
        contributions: [ActorID: ContributionRecord] = [:],
        products: [ObjectID: ProductComposition] = [:],
        presentation: Presentation = Presentation()
    ) {
        self.schemaVersion = schemaVersion
        self.documentId = documentId
        self.revision = revision
        self.semanticRevision = semanticRevision
        self.createdAt = createdAt.kollioNormalized
        self.updatedAt = updatedAt.kollioNormalized
        self.content = content
        self.relationships = relationships
        self.decisions = decisions
        self.contributions = contributions
        self.products = products
        self.presentation = presentation
    }

    public static let currentSchemaVersion = 1

    // MARK: - Codable

    /// Ids are encoded as JSON object keys rather than as an array of
    /// alternating values, so a `.kollio` file stays greppable and reviewable by
    /// a human, which is the whole point of the format.
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, documentId, revision, semanticRevision, createdAt, updatedAt
        case content, relationships, decisions, contributions, products
        case presentation
    }

    private struct IdKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(_ value: String) { self.stringValue = value }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        documentId = try container.decode(String.self, forKey: .documentId)
        revision = try container.decode(Int.self, forKey: .revision)
        semanticRevision = try container.decode(Int.self, forKey: .semanticRevision)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        content = try Self.decodeMap(ObjectID.self, from: container, forKey: .content, of: ContentObject.self)
        relationships = try Self.decodeMap(RelationshipID.self, from: container, forKey: .relationships, of: Relationship.self)
        decisions = try Self.decodeMap(DecisionID.self, from: container, forKey: .decisions, of: Decision.self)
        contributions = try Self.decodeMap(ActorID.self, from: container, forKey: .contributions, of: ContributionRecord.self)
        products = try Self.decodeMap(ObjectID.self, from: container, forKey: .products, of: ProductComposition.self)
        presentation = try container.decode(Presentation.self, forKey: .presentation)
    }

    private static func decodeMap<Key: KollioIdentifier, Value: Decodable>(
        _ type: Key.Type,
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys,
        of valueType: Value.Type
    ) throws -> [Key: Value] {
        let nested = try container.nestedContainer(keyedBy: IdKey.self, forKey: key)
        var result: [Key: Value] = [:]
        for idKey in nested.allKeys {
            let key = Key(idKey.stringValue)
            result[key] = try nested.decode(Value.self, forKey: idKey)
        }
        return result
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(documentId, forKey: .documentId)
        try container.encode(revision, forKey: .revision)
        try container.encode(semanticRevision, forKey: .semanticRevision)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try Self.encodeMap(content, into: &container, forKey: .content)
        try Self.encodeMap(relationships, into: &container, forKey: .relationships)
        try Self.encodeMap(decisions, into: &container, forKey: .decisions)
        try Self.encodeMap(contributions, into: &container, forKey: .contributions)
        try Self.encodeMap(products, into: &container, forKey: .products)
        try container.encode(presentation, forKey: .presentation)
    }

    private static func encodeMap<Key: KollioIdentifier, Value: Encodable>(
        _ map: [Key: Value],
        into container: inout KeyedEncodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws {
        var nested = container.nestedContainer(keyedBy: IdKey.self, forKey: key)
        for (id, value) in map {
            try nested.encode(value, forKey: IdKey(id.idString))
        }
    }

    // MARK: - Read helpers

    public var objects: [ContentObject] {
        content.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public var activeObjects: [ContentObject] {
        objects.filter { $0.lifecycle == .active }
    }

    public func object(_ id: ObjectID) -> ContentObject? { content[id] }
    public func relationship(_ id: RelationshipID) -> Relationship? { relationships[id] }

    public func relationships(from id: ObjectID) -> [Relationship] {
        relationships.values.filter { $0.from == id }.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func relationships(to id: ObjectID) -> [Relationship] {
        relationships.values.filter { $0.to == id }.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func incidents(of id: ObjectID) -> [Relationship] {
        relationships(from: id) + relationships(to: id)
    }

    /// Object ids reachable from `root` by following relationships, `root` included.
    /// Used to decide what a decision about a direction covers.
    public func descendants(of root: ObjectID) -> Set<ObjectID> {
        var visited: Set<ObjectID> = [root]
        var queue: [ObjectID] = [root]
        while let current = queue.popLast() {
            for rel in relationships.values where rel.from == current {
                guard !visited.contains(rel.to) else { continue }
                visited.insert(rel.to)
                queue.append(rel.to)
            }
        }
        return visited
    }

    /// Objects of a branch that are *only* reachable through `root`: closing the
    /// branch therefore hides them, while shared objects stay visible.
    public func exclusiveDescendants(of root: ObjectID) -> Set<ObjectID> {
        let reachable = descendants(of: root)
        var exclusive: Set<ObjectID> = [root]
        for id in reachable where id != root {
            let shared = relationships.values.contains { $0.to == id && !reachable.contains($0.from) }
            if !shared { exclusive.insert(id) }
        }
        return exclusive
    }

    public func activeDecisions(targeting id: ObjectID) -> [Decision] {
        decisions.values
            .filter { $0.status == .active && $0.targetObjectID == id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    public func contribution(_ id: ActorID) -> ContributionRecord? { contributions[id] }

    /// Lightweight fingerprint of the semantics an AI request depended on. Used
    /// to reject a proposal computed against a document that has since changed.
    public func semanticFingerprint(for ids: Set<ObjectID>) -> String {
        var parts: [String] = []
        for id in ids.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let object = content[id] else { continue }
            parts.append("\(id.rawValue):\(object.kind.rawValue):\(object.lifecycle.rawValue):\(object.text.text.hashValue)")
        }
        return String(parts.joined(separator: "|").hashValue, radix: 16)
    }
}
