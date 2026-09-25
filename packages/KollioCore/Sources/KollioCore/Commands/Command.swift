import Foundation

/// Every meaningful mutation goes through a validated command. A view never
/// mutates several pieces of state on its own.
public enum Command: Codable, Hashable, Sendable {
    case createObject(CreateObject)
    case updateObjectText(UpdateObjectText)
    case addRelationship(AddRelationship)
    case removeRelationship(RemoveRelationship)
    case moveNodeInstances(MoveNodeInstances)
    case createScenario(CreateScenario)
    case recordDecision(RecordDecision)
    case revokeDecision(RevokeDecision)
    case addContributionToProduct(AddContributionToProduct)
    case applyProposal(ApplyProposal)
    case rejectProposal(RejectProposal)

    /// Presentation-only commands never change the meaning of the document.
    public var isSemantic: Bool {
        switch self {
        case .moveNodeInstances:
            return false
        case .createObject, .updateObjectText, .addRelationship, .removeRelationship,
             .createScenario, .recordDecision, .revokeDecision,
             .addContributionToProduct, .applyProposal, .rejectProposal:
            return true
        }
    }

    /// A short label used as the undo label.
    public var undoLabel: String {
        switch self {
        case .createObject: return "undo.createObject"
        case .updateObjectText: return "undo.updateObjectText"
        case .addRelationship: return "undo.addRelationship"
        case .removeRelationship: return "undo.removeRelationship"
        case .moveNodeInstances: return "undo.move"
        case .createScenario: return "undo.createScenario"
        case .recordDecision: return "undo.recordDecision"
        case .revokeDecision: return "undo.revokeDecision"
        case .addContributionToProduct: return "undo.addContribution"
        case .applyProposal: return "undo.applyProposal"
        case .rejectProposal: return "undo.rejectProposal"
        }
    }
}

public struct CreateObject: Codable, Hashable, Sendable {
    public var id: ObjectID
    public var kind: ContentObject.Kind
    public var text: LocalizedText
    public var detail: LocalizedText?
    public var contributionID: ActorID?
    public var position: Position?
    public var size: Size?
    public var provenance: Provenance

    public init(
        id: ObjectID,
        kind: ContentObject.Kind,
        text: LocalizedText,
        detail: LocalizedText? = nil,
        contributionID: ActorID? = nil,
        position: Position? = nil,
        size: Size? = nil,
        provenance: Provenance
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.detail = detail
        self.contributionID = contributionID
        self.position = position
        self.size = size
        self.provenance = provenance
    }
}

public struct UpdateObjectText: Codable, Hashable, Sendable {
    public var id: ObjectID
    public var text: LocalizedText
    public var detail: LocalizedText?
    public var provenance: Provenance

    public init(id: ObjectID, text: LocalizedText, detail: LocalizedText? = nil, provenance: Provenance) {
        self.id = id
        self.text = text
        self.detail = detail
        self.provenance = provenance
    }
}

public struct AddRelationship: Codable, Hashable, Sendable {
    public var id: RelationshipID
    public var from: ObjectID
    public var to: ObjectID
    public var kind: Relationship.Kind
    public var label: LocalizedText?
    public var fromAnchor: Relationship.Anchor
    public var toAnchor: Relationship.Anchor
    public var provenance: Provenance

    public init(
        id: RelationshipID,
        from: ObjectID,
        to: ObjectID,
        kind: Relationship.Kind,
        label: LocalizedText? = nil,
        fromAnchor: Relationship.Anchor = .bottom,
        toAnchor: Relationship.Anchor = .top,
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

public struct RemoveRelationship: Codable, Hashable, Sendable {
    public var id: RelationshipID
}

public struct MoveNodeInstance: Codable, Hashable, Sendable {
    public var instanceID: InstanceID
    public var position: Position

    public init(instanceID: InstanceID, position: Position) {
        self.instanceID = instanceID
        self.position = position
    }
}

public struct MoveNodeInstances: Codable, Hashable, Sendable {
    public var moves: [MoveNodeInstance]

    public init(moves: [MoveNodeInstance]) {
        self.moves = moves
    }
}

/// Creates a scenario with its initial context. Used by the first experience and
/// by fixtures; it stays a plain transaction so it is undoable as one action.
public struct CreateScenario: Codable, Hashable, Sendable {
    public var context: CreateObject
    public var children: [CreateObject]
    public var links: [AddRelationship]
    public var rootPosition: Position

    public init(context: CreateObject, children: [CreateObject], links: [AddRelationship], rootPosition: Position) {
        self.context = context
        self.children = children
        self.links = links
        self.rootPosition = rootPosition
    }
}

public struct RecordDecision: Codable, Hashable, Sendable {
    public var id: DecisionID
    public var kind: Decision.Kind
    public var targetObjectID: ObjectID
    public var rationale: LocalizedText?
    public var provenance: Provenance

    public init(id: DecisionID, kind: Decision.Kind, targetObjectID: ObjectID, rationale: LocalizedText? = nil, provenance: Provenance) {
        self.id = id
        self.kind = kind
        self.targetObjectID = targetObjectID
        self.rationale = rationale
        self.provenance = provenance
    }
}

public struct RevokeDecision: Codable, Hashable, Sendable {
    public var id: DecisionID
}

public struct AddContributionToProduct: Codable, Hashable, Sendable {
    public var productID: ObjectID
    public var contributionID: ActorID
    public var share: Double
    public var provenance: Provenance

    public init(productID: ObjectID, contributionID: ActorID, share: Double = 0, provenance: Provenance) {
        self.productID = productID
        self.contributionID = contributionID
        self.share = share
        self.provenance = provenance
    }
}

/// Applying a proposal is a single transaction: it either fully succeeds or
/// leaves the document untouched, and it is undone as one coherent action.
public struct ApplyProposal: Codable, Hashable, Sendable {
    public var proposal: Proposal
    public var placements: [ObjectID: Position]
    public var provenance: Provenance

    public init(proposal: Proposal, placements: [ObjectID: Position], provenance: Provenance) {
        self.proposal = proposal
        self.placements = placements
        self.provenance = provenance
    }
}

public struct RejectProposal: Codable, Hashable, Sendable {
    public var proposalId: String
    public var reason: RejectReason
    public var provenance: Provenance

    public enum RejectReason: String, Codable, Sendable {
        case setAside
        case declined
    }

    public init(proposalId: String, reason: RejectReason, provenance: Provenance) {
        self.proposalId = proposalId
        self.reason = reason
        self.provenance = provenance
    }
}
