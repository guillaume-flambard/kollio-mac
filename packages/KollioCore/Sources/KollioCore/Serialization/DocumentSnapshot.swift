import Foundation

/// The slice of a document the client sends with a proposal request.
///
/// The macOS client owns its document. The server is not authoritative and holds
/// no store: it reasons transiently about exactly what arrived in the request.
/// This type is therefore the transport contract, not a database row.
///
/// Three rules shape it:
///
/// - **Bounded.** Only what is needed to validate the requested operation and
///   understand it. Visual layout is excluded: the server must never place
///   anything, and a position is not needed to decide whether a patch is valid.
/// - **Complete enough to be honest.** A snapshot that cannot support the
///   validation being asked for is rejected explicitly, rather than validated
///   against a hole and reported as sound.
/// - **Client-authored input.** Every field is untrusted. Reference integrity is
///   checked on arrival, and the client revalidates against its own full,
///   current document before previewing and again before applying.
public struct DocumentSnapshot: Codable, Hashable, Sendable {
    /// Bumped only when the shape of this contract changes.
    public static let currentVersion = 1

    /// Hard ceiling, so a hostile or buggy client cannot make the server allocate
    /// without limit. Exceeding it is a rejection, never a truncation.
    public static let maximumObjects = 500
    public static let maximumRelationships = 1_000

    public var snapshotVersion: Int
    public var documentId: String
    public var semanticRevision: Int

    /// The objects the operation can reach, with their meaning. No positions.
    public var objects: [ObjectID: SnapshotObject]
    /// Only the relationships whose two ends are both present in `objects`.
    public var relationships: [RelationshipID: SnapshotRelationship]
    /// The durable decisions in force, so a provider can see that a direction
    /// was already rejected rather than re-proposing it.
    public var decisions: [DecisionID: SnapshotDecision]

    public init(
        snapshotVersion: Int = DocumentSnapshot.currentVersion,
        documentId: String,
        semanticRevision: Int,
        objects: [ObjectID: SnapshotObject],
        relationships: [RelationshipID: SnapshotRelationship],
        decisions: [DecisionID: SnapshotDecision] = [:]
    ) {
        self.snapshotVersion = snapshotVersion
        self.documentId = documentId
        self.semanticRevision = semanticRevision
        self.objects = objects
        self.relationships = relationships
        self.decisions = decisions
    }

    public struct SnapshotObject: Codable, Hashable, Sendable {
        public var id: ObjectID
        public var kind: ContentObject.Kind
        /// The authored text, and its translations. The client's words, never a
        /// summary written by anyone else.
        public var text: LocalizedText
        public var detail: LocalizedText?
        public var lifecycle: ContentObject.Lifecycle
        public var setAsideByDecision: DecisionID?
        public var provenance: Provenance

        public init(
            id: ObjectID,
            kind: ContentObject.Kind,
            text: LocalizedText,
            detail: LocalizedText? = nil,
            lifecycle: ContentObject.Lifecycle = .active,
            setAsideByDecision: DecisionID? = nil,
            provenance: Provenance
        ) {
            self.id = id
            self.kind = kind
            self.text = text
            self.detail = detail
            self.lifecycle = lifecycle
            self.setAsideByDecision = setAsideByDecision
            self.provenance = provenance
        }
    }

    public struct SnapshotRelationship: Codable, Hashable, Sendable {
        public var id: RelationshipID
        public var from: ObjectID
        public var to: ObjectID
        public var kind: Relationship.Kind
        public var label: LocalizedText?
        public var provenance: Provenance

        public init(
            id: RelationshipID,
            from: ObjectID,
            to: ObjectID,
            kind: Relationship.Kind,
            label: LocalizedText? = nil,
            provenance: Provenance
        ) {
            self.id = id
            self.from = from
            self.to = to
            self.kind = kind
            self.label = label
            self.provenance = provenance
        }
    }

    public struct SnapshotDecision: Codable, Hashable, Sendable {
        public var id: DecisionID
        public var kind: Decision.Kind
        public var targetObjectID: ObjectID
        /// Which objects the decision covered. Needed because a reopen has to
        /// restore exactly that branch, so the scope cannot be dropped.
        public var branchObjectIDs: [ObjectID]
        public var rationale: LocalizedText?
        public var status: Decision.Status

        public init(
            id: DecisionID,
            kind: Decision.Kind,
            targetObjectID: ObjectID,
            branchObjectIDs: [ObjectID],
            rationale: LocalizedText? = nil,
            status: Decision.Status
        ) {
            self.id = id
            self.kind = kind
            self.targetObjectID = targetObjectID
            self.branchObjectIDs = branchObjectIDs
            self.rationale = rationale
            self.status = status
        }
    }

    // MARK: Wire format

    private enum CodingKeys: String, CodingKey {
        case snapshotVersion, documentId, semanticRevision
        case objects, relationships, decisions
    }

    /// A map keyed by a stable id, written as a JSON object.
    ///
    /// A synthesised `[ObjectID: Value]` encodes as an alternating
    /// key/value *array*, because `ObjectID` is not a string-keyed type. That
    /// shape is unreadable for a human and differs from the `.kollio` file,
    /// which writes the same maps as objects. The client and the server are
    /// separate processes, so the payload is made explicit here rather than left
    /// to the compiler's default.
    struct KeyedMap<Value: Codable & Sendable>: Codable, Sendable {
        var values: [String: Value]

        init(_ values: [String: Value]) { self.values = values }

        init(from decoder: any Decoder) throws {
            values = try decoder.singleValueContainer().decode([String: Value].self)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(values)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        snapshotVersion = try container.decode(Int.self, forKey: .snapshotVersion)
        documentId = try container.decode(String.self, forKey: .documentId)
        semanticRevision = try container.decode(Int.self, forKey: .semanticRevision)
        let objectMap = try container.decode(KeyedMap<SnapshotObject>.self, forKey: .objects)
        objects = Dictionary(uniqueKeysWithValues: objectMap.values.map { (ObjectID($0.key), $0.value) })
        let relationshipMap = try container.decode(KeyedMap<SnapshotRelationship>.self, forKey: .relationships)
        relationships = Dictionary(uniqueKeysWithValues: relationshipMap.values.map { (RelationshipID($0.key), $0.value) })
        let decisionMap = try container.decode(KeyedMap<SnapshotDecision>.self, forKey: .decisions)
        decisions = Dictionary(uniqueKeysWithValues: decisionMap.values.map { (DecisionID($0.key), $0.value) })
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(snapshotVersion, forKey: .snapshotVersion)
        try container.encode(documentId, forKey: .documentId)
        try container.encode(semanticRevision, forKey: .semanticRevision)
        try container.encode(
            KeyedMap(Dictionary(uniqueKeysWithValues: objects.map { ($0.key.rawValue, $0.value) })),
            forKey: .objects
        )
        try container.encode(
            KeyedMap(Dictionary(uniqueKeysWithValues: relationships.map { ($0.key.rawValue, $0.value) })),
            forKey: .relationships
        )
        try container.encode(
            KeyedMap(Dictionary(uniqueKeysWithValues: decisions.map { ($0.key.rawValue, $0.value) })),
            forKey: .decisions
        )
    }

    // MARK: Structure and reference integrity

    public enum SnapshotError: Error, Hashable, Sendable, CustomStringConvertible {
        case unsupportedVersion(found: Int, expected: Int)
        case tooManyObjects(count: Int, limit: Int)
        case tooManyRelationships(count: Int, limit: Int)
        /// A relationship names an object the snapshot does not carry.
        case danglingReference(relationship: RelationshipID, object: ObjectID)
        /// An object is marked as set aside by a decision that was not sent.
        case unknownDecision(object: ObjectID, decision: DecisionID)
        /// A decision targets an object the snapshot does not carry.
        case decisionWithoutTarget(decision: DecisionID, object: ObjectID)
        /// The request asked about something the snapshot cannot describe.
        case targetOutsideSnapshot(ObjectID)

        public var description: String {
            switch self {
            case .unsupportedVersion(let found, let expected):
                return "Snapshot version \(found) is not supported, expected \(expected)"
            case .tooManyObjects(let count, let limit):
                return "Snapshot carries \(count) objects, the limit is \(limit)"
            case .tooManyRelationships(let count, let limit):
                return "Snapshot carries \(count) relationships, the limit is \(limit)"
            case .danglingReference(let relationship, let object):
                return "Relationship \(relationship) names unknown object \(object)"
            case .unknownDecision(let object, let decision):
                return "Object \(object) is set aside by unknown decision \(decision)"
            case .decisionWithoutTarget(let decision, let object):
                return "Decision \(decision) targets unknown object \(object)"
            case .targetOutsideSnapshot(let object):
                return "Requested target \(object) is not in the snapshot"
            }
        }
    }

    /// Structural checks and reference integrity. Run before anything reasons
    /// about the snapshot, so a malformed one is a rejection and not a wrong
    /// answer.
    public func validate(targets: [ObjectID] = []) throws {
        guard snapshotVersion == Self.currentVersion else {
            throw SnapshotError.unsupportedVersion(found: snapshotVersion, expected: Self.currentVersion)
        }
        guard objects.count <= Self.maximumObjects else {
            throw SnapshotError.tooManyObjects(count: objects.count, limit: Self.maximumObjects)
        }
        guard relationships.count <= Self.maximumRelationships else {
            throw SnapshotError.tooManyRelationships(count: relationships.count, limit: Self.maximumRelationships)
        }
        for relationship in relationships.values {
            guard objects[relationship.from] != nil else {
                throw SnapshotError.danglingReference(relationship: relationship.id, object: relationship.from)
            }
            guard objects[relationship.to] != nil else {
                throw SnapshotError.danglingReference(relationship: relationship.id, object: relationship.to)
            }
        }
        for object in objects.values {
            if let decisionID = object.setAsideByDecision {
                guard decisions[decisionID] != nil else {
                    throw SnapshotError.unknownDecision(object: object.id, decision: decisionID)
                }
            }
        }
        for decision in decisions.values {
            guard objects[decision.targetObjectID] != nil else {
                throw SnapshotError.decisionWithoutTarget(decision: decision.id, object: decision.targetObjectID)
            }
        }
        for target in targets where objects[target] == nil {
            throw SnapshotError.targetOutsideSnapshot(target)
        }
    }

    /// A narrow, real `KollioDocument` built from exactly what was sent.
    ///
    /// The server validates and reasons against this. It is never a fixture, never
    /// a fresh empty document, and it carries no layout: positions are the
    /// client's decision, and a validator that cannot see them must not pretend
    /// it checked them.
    public func makeDocument() -> KollioDocument {
        var document = KollioDocument()
        document.documentId = documentId
        document.semanticRevision = semanticRevision
        document.revision = semanticRevision
        document.content = objects.reduce(into: [:]) { result, pair in
            result[pair.key] = ContentObject(
                id: pair.value.id,
                kind: pair.value.kind,
                text: pair.value.text,
                detail: pair.value.detail,
                lifecycle: pair.value.lifecycle,
                setAsideByDecision: pair.value.setAsideByDecision,
                provenance: pair.value.provenance
            )
        }
        document.relationships = relationships.reduce(into: [:]) { result, pair in
            result[pair.key] = Relationship(
                id: pair.value.id,
                from: pair.value.from,
                to: pair.value.to,
                kind: pair.value.kind,
                label: pair.value.label,
                provenance: pair.value.provenance
            )
        }
        document.decisions = decisions.reduce(into: [:]) { result, pair in
            result[pair.key] = Decision(
                id: pair.value.id,
                kind: pair.value.kind,
                targetObjectID: pair.value.targetObjectID,
                branchObjectIDs: pair.value.branchObjectIDs,
                rationale: pair.value.rationale,
                status: pair.value.status,
                createdAt: document.createdAt,
                provenance: .human("snapshot")
            )
        }
        return document
    }
}

extension KollioDocument {
    /// The snapshot a client sends for a request about `targets`.
    ///
    /// The slice is the targets, everything incident to them, and one more hop,
    /// which is the same neighbourhood the server scopes its context from. Layout
    /// is not carried: the server never places anything.
    ///
    /// - Throws: `DocumentSnapshot.SnapshotError` when the neighbourhood is
    ///   larger than the transport allows. The client then knows it must not
    ///   pretend the server saw the whole document.
    public func snapshot(targeting targets: [ObjectID], radius: Int = 1) throws -> DocumentSnapshot {
        var ids: Set<ObjectID> = []
        for target in targets {
            ids.insert(target)
            ids.formUnion(incidents(of: target).flatMap { [$0.from, $0.to] })
        }
        for _ in 1..<Swift.max(radius, 1) {
            var discovered: Set<ObjectID> = []
            for id in ids {
                for relationship in incidents(of: id) {
                    discovered.insert(relationship.from)
                    discovered.insert(relationship.to)
                }
            }
            ids.formUnion(discovered)
        }
        // A target that does not exist is a client bug, surfaced rather than
        // silently dropped: the request would fail validation further down with a
        // far less useful message.
        for target in targets where object(target) == nil {
            throw DocumentSnapshot.SnapshotError.targetOutsideSnapshot(target)
        }
        ids = ids.filter { object($0) != nil }
        guard ids.count <= DocumentSnapshot.maximumObjects else {
            throw DocumentSnapshot.SnapshotError.tooManyObjects(
                count: ids.count,
                limit: DocumentSnapshot.maximumObjects
            )
        }

        let included = relationships.values.filter { ids.contains($0.from) && ids.contains($0.to) }
        guard included.count <= DocumentSnapshot.maximumRelationships else {
            throw DocumentSnapshot.SnapshotError.tooManyRelationships(
                count: included.count,
                limit: DocumentSnapshot.maximumRelationships
            )
        }

        let snapshotObjects = ids.reduce(into: [ObjectID: DocumentSnapshot.SnapshotObject]()) { result, id in
            guard let object = object(id) else { return }
            result[id] = .init(
                id: object.id,
                kind: object.kind,
                text: object.text,
                detail: object.detail,
                lifecycle: object.lifecycle,
                setAsideByDecision: object.setAsideByDecision,
                provenance: object.provenance
            )
        }
        let snapshotRelationships = included.reduce(into: [RelationshipID: DocumentSnapshot.SnapshotRelationship]()) { result, relationship in
            result[relationship.id] = .init(
                id: relationship.id,
                from: relationship.from,
                to: relationship.to,
                kind: relationship.kind,
                label: relationship.label,
                provenance: relationship.provenance
            )
        }
        // Only the decisions that explain something inside the slice, so the
        // provider can see a rejected direction without seeing the whole history.
        let snapshotDecisions = decisions.values.reduce(into: [DecisionID: DocumentSnapshot.SnapshotDecision]()) { result, decision in
            guard ids.contains(decision.targetObjectID) else { return }
            result[decision.id] = .init(
                id: decision.id,
                kind: decision.kind,
                targetObjectID: decision.targetObjectID,
                branchObjectIDs: decision.branchObjectIDs,
                rationale: decision.rationale,
                status: decision.status
            )
        }

        return DocumentSnapshot(
            documentId: documentId,
            semanticRevision: semanticRevision,
            objects: snapshotObjects,
            relationships: snapshotRelationships,
            decisions: snapshotDecisions
        )
    }
}
