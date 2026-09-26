import Foundation

/// Every meaningful mutation goes through a validated command. A view never
/// mutates several pieces of state on its own.
public enum Command: Codable, Hashable, Sendable {
    case createObject(CreateObject)
    case updateObjectText(UpdateObjectText)
    case addRelationship(AddRelationship)
    case removeRelationship(RemoveRelationship)
    case moveNodeInstances(MoveNodeInstances)
    case duplicateObject(DuplicateObject)
    case duplicateNodeInstance(DuplicateNodeInstance)
    case removeObject(RemoveObject)
    case removeNodeInstance(RemoveNodeInstance)
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
        case .moveNodeInstances, .duplicateNodeInstance, .removeNodeInstance:
            // An occurrence is presentation. Putting a second one on the canvas, or
            // taking one away, changes where something is drawn and nothing about
            // what it means, so it must not move semanticRevision. A *variant* is a
            // new claim, and is deliberately not in this list.
            return false
        case .createObject, .updateObjectText, .addRelationship, .removeRelationship,
             .createScenario, .recordDecision, .revokeDecision,
             .addContributionToProduct, .applyProposal, .rejectProposal,
             .attachSource, .importSourceRevision, .addCitation, .recordVerification,
             .removeSource, .assertClaim, .assessHypothesis, .resolveConstraint,
             .duplicateObject, .removeObject:
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
        case .duplicateObject: return "undo.duplicateObject"
        case .duplicateNodeInstance: return "undo.duplicateNodeInstance"
        case .removeObject: return "undo.removeObject"
        case .removeNodeInstance: return "undo.removeNodeInstance"
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
    /// The version this text was written against, when the writer knows it.
    ///
    /// `nil` means "I did not look", which is allowed and is how a first edit of
    /// a freshly created object is expressed. A number means "I saw this version",
    /// and a mismatch is refused rather than merged. The distinction matters: a
    /// writer that never looked is asking to overwrite, and one that looked and is
    /// out of date is asking a question the interface should answer.
    public var expectedVersion: Int?

    public init(
        id: ObjectID,
        text: LocalizedText,
        detail: LocalizedText? = nil,
        provenance: Provenance,
        expectedVersion: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.detail = detail
        self.provenance = provenance
        self.expectedVersion = expectedVersion
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

/// A second appearance of the *same* object.
///
/// CAN-05 separates this from `DuplicateObject` in one sentence: "Duplicating an
/// occurrence keeps the referenced object." The person sees two of the same thing
/// on the canvas; the document still contains one object, one author, one
/// contribution and one share. Nothing semantic changes, which is why this is
/// presentation-only.
public struct DuplicateNodeInstance: Codable, Hashable, Sendable {
    public var instanceID: InstanceID
    /// The instance handed to the new one. Nil places the copy where the camera
    /// is looking rather than exactly on top of the original.
    public var id: InstanceID
    public var position: Position?

    public init(instanceID: InstanceID, id: InstanceID, position: Position? = nil) {
        self.instanceID = instanceID
        self.id = id
        self.position = position
    }
}

/// A new object that says the same thing differently.
///
/// This is a *variant*: a new claim, related to its origin by `derivedFrom` so
/// the reasoning stays readable. It is a new object rather than a second
/// occurrence precisely because a variant can be changed without changing the
/// thing it came from.
public struct DuplicateObject: Codable, Hashable, Sendable {
    public var sourceID: ObjectID
    public var id: ObjectID
    public var instanceID: InstanceID
    public var relationshipID: RelationshipID
    public var position: Position?
    public var provenance: Provenance

    public init(
        sourceID: ObjectID,
        id: ObjectID,
        instanceID: InstanceID,
        relationshipID: RelationshipID,
        position: Position? = nil,
        provenance: Provenance
    ) {
        self.sourceID = sourceID
        self.id = id
        self.instanceID = instanceID
        self.relationshipID = relationshipID
        self.position = position
        self.provenance = provenance
    }
}

/// Removes an object from the document: its relationships and its instances go
/// with it.
///
/// CAN-05 requires this to be a *distinct action* from removing an occurrence,
/// because they lose different things. Removing an occurrence leaves the idea;
/// this one does not, which is why the interface never offers it behind the same
/// gesture.
public struct RemoveObject: Codable, Hashable, Sendable {
    public var id: ObjectID

    // Written out rather than left to the memberwise initialiser, which Swift makes
    // internal even on a public struct. Without it this type is constructible only
    // inside KollioCore, and the next module to try gets `init(from:)` instead, with
    // an error about a Decoder rather than about visibility.
    public init(id: ObjectID) {
        self.id = id
    }
}

/// Removes one occurrence, and leaves the object it was drawing.
public struct RemoveNodeInstance: Codable, Hashable, Sendable {
    public var instanceID: InstanceID

    // Public for the reason given on RemoveObject.
    public init(instanceID: InstanceID) {
        self.instanceID = instanceID
    }
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
