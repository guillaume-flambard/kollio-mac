import Foundation

/// Text authored by a human. Kollio never machine-translates user content when the
/// interface language changes: `variants` holds only explicit authored variants
/// (used by fixtures such as Sarah, which are authored in both languages).
public struct LocalizedText: Codable, Hashable, Sendable {
    public var text: String
    public var variants: [String: String]

    public init(_ text: String, variants: [String: String] = [:]) {
        self.text = text
        self.variants = variants
    }

    public func resolve(languageCode: String) -> String {
        variants[languageCode] ?? text
    }
}

/// A semantic object of the document.
///
/// The domain kind is meaningful and stable. The visual *form* is derived from it
/// so the renderer can apply a very small visual vocabulary (thought, reference,
/// rich result) without hiding the semantics from the system.
public struct ContentObject: Codable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// An idea whose meaning has not been settled yet.
        ///
        /// CAN-05: "Create an idea without choosing a category, then clarify its
        /// meaning." A person who knows they have an idea usually does not yet
        /// know what kind it is, and forcing a choice at creation time either
        /// blocks them or makes them guess. The kind is corrected later, or never,
        /// and neither is a failure.
        case unclear
        case context
        case need
        case method
        case technicalBlock
        case product
        case hypothesis
        case constraint
        case question
        case evidence
        case scenario
        case decision
        case note
        case contribution
    }

    /// The three visual families of the grammar.
    public enum Form: String, Codable, Sendable {
        case thought
        case reference
        case richResult
    }

    public enum Lifecycle: String, Codable, Sendable {
        case active
        case setAside
    }

    public var id: ObjectID
    public var kind: Kind
    public var text: LocalizedText
    public var detail: LocalizedText?
    public var lifecycle: Lifecycle
    /// Set when the object was set aside: the durable decision that explains why.
    public var setAsideByDecision: DecisionID?
    /// When set, the object is a reference to a reusable contribution rather than an
    /// inline piece of content. Duplicating its visual instances never duplicates
    /// the contribution, its owner, or any royalty claim.
    public var contributionID: ActorID?
    public var provenance: Provenance
    /// Increments on every change to this object's own content.
    ///
    /// CAN-04: "`UpdateObjectText` checks the object version." Without it two
    /// people editing the same title both succeed and the second one silently
    /// wins, which is the one outcome the product forbids. A presentation move
    /// does not touch it: a position is not content.
    public var objectVersion: Int

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, kind, text, detail, lifecycle, setAsideByDecision
        case contributionID, provenance, objectVersion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ObjectID.self, forKey: .id)
        kind = try container.decode(Kind.self, forKey: .kind)
        text = try container.decode(LocalizedText.self, forKey: .text)
        detail = try container.decodeIfPresent(LocalizedText.self, forKey: .detail)
        lifecycle = try container.decode(Lifecycle.self, forKey: .lifecycle)
        setAsideByDecision = try container.decodeIfPresent(DecisionID.self, forKey: .setAsideByDecision)
        contributionID = try container.decodeIfPresent(ActorID.self, forKey: .contributionID)
        provenance = try container.decode(Provenance.self, forKey: .provenance)
        // Absent in a file written before object versions existed, which is an
        // object nobody has edited yet rather than a broken one. Zero is the
        // honest reading: no edit has happened, so there is nothing to be stale
        // against.
        objectVersion = try container.decodeIfPresent(Int.self, forKey: .objectVersion) ?? 0
    }

    public init(
        id: ObjectID,
        kind: Kind,
        text: LocalizedText,
        detail: LocalizedText? = nil,
        lifecycle: Lifecycle = .active,
        setAsideByDecision: DecisionID? = nil,
        contributionID: ActorID? = nil,
        provenance: Provenance,
        objectVersion: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.detail = detail
        self.lifecycle = lifecycle
        self.setAsideByDecision = setAsideByDecision
        self.contributionID = contributionID
        self.provenance = provenance
        self.objectVersion = objectVersion
    }

    /// Derived presentation family. A product, method or technical block is an
    /// assembled result; evidence and reusable contributions are references;
    /// everything else is a thought.
    public var form: Form {
        switch kind {
        case .product, .method, .technicalBlock:
            return .richResult
        case .evidence, .contribution:
            return .reference
        case .unclear, .context, .need, .hypothesis, .constraint, .question,
             .scenario, .decision, .note:
            return .thought
        }
    }

    public var isSetAside: Bool { lifecycle == .setAside }
}

/// A first-class relationship between two objects.
///
/// The reasoning of a document must be readable from its topology, so a
/// relationship can carry a short readable statement. The existence of a
/// connector never implies truth.
public struct Relationship: Codable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case addresses
        case uses
        case dependsOn
        case constrains
        case supports
        case contradicts
        case alternativeTo
        case derivedFrom
        case associatedWith
    }

    /// Stable attachment point on the source object, expressed in object-local
    /// unit space (0...1) so the connector follows the object while it moves.
    public struct Anchor: Codable, Hashable, Sendable {
        public var unitX: Double
        public var unitY: Double

        public init(unitX: Double, unitY: Double) {
            self.unitX = unitX
            self.unitY = unitY
        }

        public static let bottom = Anchor(unitX: 0.5, unitY: 1.0)
        public static let top = Anchor(unitX: 0.5, unitY: 0.0)
    }

    public var id: RelationshipID
    public var from: ObjectID
    public var to: ObjectID
    public var kind: Kind
    public var label: LocalizedText?
    public var fromAnchor: Anchor
    public var toAnchor: Anchor
    public var provenance: Provenance

    public init(
        id: RelationshipID,
        from: ObjectID,
        to: ObjectID,
        kind: Kind,
        label: LocalizedText? = nil,
        fromAnchor: Anchor = .bottom,
        toAnchor: Anchor = .top,
        provenance: Provenance
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.kind = kind
        self.label = label
        self.fromAnchor = fromAnchor
        self.toAnchor = toAnchor
        self.provenance = provenance
    }
}

/// A durable decision about a direction in the document. This is project memory,
/// not editing history: it survives quitting, reloading, and undo-stack loss.
public struct Decision: Codable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case setAside
        case reopened
        case kept
    }

    public enum Status: String, Codable, Sendable {
        case active
        case superseded
    }

    public var id: DecisionID
    public var kind: Kind
    /// The object that anchors the decided direction (the root of a branch).
    public var targetObjectID: ObjectID
    /// Object ids that belonged to the direction when the decision was recorded.
    public var branchObjectIDs: [ObjectID]
    public var rationale: LocalizedText?
    public var status: Status
    public var supersedes: DecisionID?
    public var createdAt: Date
    public var provenance: Provenance

    public init(
        id: DecisionID,
        kind: Kind,
        targetObjectID: ObjectID,
        branchObjectIDs: [ObjectID],
        rationale: LocalizedText? = nil,
        status: Status = .active,
        supersedes: DecisionID? = nil,
        createdAt: Date,
        provenance: Provenance
    ) {
        self.id = id
        self.kind = kind
        self.targetObjectID = targetObjectID
        self.branchObjectIDs = branchObjectIDs
        self.rationale = rationale
        self.status = status
        self.supersedes = supersedes
        self.createdAt = createdAt
        self.provenance = provenance
    }
}
