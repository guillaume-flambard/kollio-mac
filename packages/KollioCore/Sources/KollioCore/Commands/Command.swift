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
    case attachSource(AttachSource)
    case importSourceRevision(ImportSourceRevision)
    case addCitation(AddCitation)
    case recordVerification(RecordVerification)
    case removeSource(RemoveSource)
    case assertClaim(AssertClaim)
    case assessHypothesis(AssessHypothesis)
    case resolveConstraint(ResolveConstraint)

    /// Presentation-only commands never change the meaning of the document.
    public var isSemantic: Bool {
        switch self {
        case .moveNodeInstances:
            return false
        case .createObject, .updateObjectText, .addRelationship, .removeRelationship,
             .createScenario, .recordDecision, .revokeDecision,
             .addContributionToProduct, .applyProposal, .rejectProposal,
             .attachSource, .importSourceRevision, .addCitation, .recordVerification,
             .removeSource, .assertClaim, .assessHypothesis, .resolveConstraint:
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
        case .attachSource: return "undo.attachSource"
        case .importSourceRevision: return "undo.importSourceRevision"
        case .addCitation: return "undo.addCitation"
        case .recordVerification: return "undo.recordVerification"
        case .removeSource: return "undo.removeSource"
        case .assertClaim: return "undo.assertClaim"
        case .assessHypothesis: return "undo.assessHypothesis"
        case .resolveConstraint: return "undo.resolveConstraint"
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

// MARK: - Sources and citations
//
// Every one of these is a validated command like any other, so attaching a source
// is undoable, transactional and versioned with the rest of the document rather
// than being a side effect a view performs.

public struct AttachSource: Codable, Hashable, Sendable {
    public var source: SourceReference
    /// The object this source belongs to, when it was brought for a particular
    /// piece of the document rather than for the whole of it.
    public var attachedTo: ObjectID?
    public var provenance: Provenance

    public init(source: SourceReference, attachedTo: ObjectID? = nil, provenance: Provenance) {
        self.source = source
        self.attachedTo = attachedTo
        self.provenance = provenance
    }
}

public struct ImportSourceRevision: Codable, Hashable, Sendable {
    public var sourceID: SourceID
    public var revision: SourceRevision
    public var provenance: Provenance

    public init(sourceID: SourceID, revision: SourceRevision, provenance: Provenance) {
        self.sourceID = sourceID
        self.revision = revision
        self.provenance = provenance
    }
}

public struct AddCitation: Codable, Hashable, Sendable {
    public var citation: Citation
    /// The claim being supported. Required: a citation with nothing to attach to is
    /// evidence for no one.
    public var claimID: ObjectID
    public var provenance: Provenance

    public init(citation: Citation, claimID: ObjectID, provenance: Provenance) {
        self.citation = citation
        self.claimID = claimID
        self.provenance = provenance
    }
}

/// Recording a check. The observation and the author are both required by the
/// type, so there is no command that can mark something verified on its own.
public struct RecordVerification: Codable, Hashable, Sendable {
    public var citationID: CitationID
    public var observation: String
    public var author: ActorID
    public var at: Date

    public init(citationID: CitationID, observation: String, author: ActorID, at: Date = Date()) {
        self.citationID = citationID
        self.observation = observation
        self.author = author
        self.at = at
    }
}

public struct RemoveSource: Codable, Hashable, Sendable {
    public var sourceID: SourceID
    public var reason: String

    public init(sourceID: SourceID, reason: String) {
        self.sourceID = sourceID
        self.reason = reason
    }
}


// MARK: - Claims
//
// A claim needs a scope. The command layer refuses one without, because an
// unscoped constraint would behave as a law of the universe and quietly forbid
// everything a person did not mean it to.

public struct AssertClaim: Codable, Hashable, Sendable {
    public var claim: Claim
    public var provenance: Provenance

    public init(claim: Claim, provenance: Provenance) {
        self.claim = claim
        self.provenance = provenance
    }
}

public struct AssessHypothesis: Codable, Hashable, Sendable {
    public var claimID: ClaimID
    /// The new standing. Carries its own evidence, so a bare "supported" is not
    /// expressible.
    public var assessment: HypothesisAssessment
    public var provenance: Provenance

    public init(claimID: ClaimID, assessment: HypothesisAssessment, provenance: Provenance) {
        self.claimID = claimID
        self.assessment = assessment
        self.provenance = provenance
    }
}

public struct ResolveConstraint: Codable, Hashable, Sendable {
    public var claimID: ClaimID
    /// `notApplicable` is a real answer and is not satisfaction.
    public var resolution: ConstraintResolution
    public var provenance: Provenance

    public init(claimID: ClaimID, resolution: ConstraintResolution, provenance: Provenance) {
        self.claimID = claimID
        self.resolution = resolution
        self.provenance = provenance
    }
}
