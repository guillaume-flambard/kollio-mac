import Foundation

/// A syntactically valid JSON answer is not a valid proposal. The client runs
/// these checks before showing a ghost branch, and the server runs them again
/// before answering.
public struct ProposalValidator: Sendable {
    public struct Limits: Codable, Hashable, Sendable {
        public var maxOperations: Int
        public var maxNewObjects: Int
        public var maxRationaleLength: Int

        public init(maxOperations: Int = 8, maxNewObjects: Int = 6, maxRationaleLength: Int = 400) {
            self.maxOperations = maxOperations
            self.maxNewObjects = maxNewObjects
            self.maxRationaleLength = maxRationaleLength
        }
    }

    public init() {}

    public func validate(
        _ proposal: Proposal,
        against document: KollioDocument,
        scope: ProposalRequest.Scope,
        limits: Limits = Limits()
    ) throws {
        guard proposal.documentId == document.documentId else {
            throw DocumentError.staleProposal(reason: "documentId mismatch")
        }
        guard proposal.baseSemanticRevision == document.semanticRevision else {
            throw DocumentError.staleProposal(
                reason: "baseSemanticRevision \(proposal.baseSemanticRevision) != \(document.semanticRevision)"
            )
        }
        guard proposal.operations.count <= min(limits.maxOperations, scope.maxOperations) else {
            throw DocumentError.tooManyOperations(proposal.operations.count)
        }
        guard proposal.rationale?.text.count ?? 0 <= limits.maxRationaleLength else {
            throw DocumentError.forbiddenOperation("rationale too long")
        }

        var newObjectCount = 0
        var virtual: Set<ObjectID> = []
        for operation in proposal.operations {
            switch operation {
            case .createObject(let create):
                guard scope.allowNewObjects else {
                    throw DocumentError.forbiddenOperation("createObject outside scope")
                }
                newObjectCount += 1
                guard newObjectCount <= limits.maxNewObjects else {
                    throw DocumentError.tooManyOperations(proposal.operations.count)
                }
                guard document.content[create.id] == nil else {
                    throw DocumentError.duplicateObject(create.id)
                }
                guard !create.text.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw DocumentError.emptyText(create.id)
                }
                virtual.insert(create.id)
            case .updateObjectText(let update):
                guard document.content[update.id] != nil || virtual.contains(update.id) else {
                    throw DocumentError.unknownObject(update.id)
                }
            case .addRelationship(let add):
                guard add.from != add.to else { throw DocumentError.selfRelationship(add.id) }
                for endpoint in [add.from, add.to] {
                    guard document.content[endpoint] != nil || virtual.contains(endpoint) else {
                        throw DocumentError.unknownObject(endpoint)
                    }
                }
                guard document.relationships[add.id] == nil else {
                    throw DocumentError.duplicateRelationship(add.id)
                }
            case .removeRelationship(let remove):
                guard document.relationships[remove.id] != nil else {
                    throw DocumentError.unknownRelationship(remove.id)
                }
            case .moveNodeInstances(let move):
                for one in move.moves where document.presentation.instance(id: one.instanceID) == nil {
                    throw DocumentError.unknownInstance(one.instanceID)
                }
            case .recordDecision(let decision):
                guard document.content[decision.targetObjectID] != nil || virtual.contains(decision.targetObjectID) else {
                    throw DocumentError.decisionTargetNotFound(decision.targetObjectID)
                }
            case .revokeDecision(let revoke):
                guard document.decisions[revoke.id] != nil else {
                    throw DocumentError.unknownDecision(revoke.id)
                }
            case .addContributionToProduct(let add):
                guard document.contributions[add.contributionID] != nil else {
                    throw DocumentError.unknownContribution(add.contributionID)
                }
                guard (0...1).contains(add.share) else {
                    throw DocumentError.invalidShareRange(add.share)
                }
            case .createScenario:
                throw DocumentError.forbiddenOperation("createScenario from a proposal")
            case .applyProposal:
                throw DocumentError.forbiddenOperation("nested applyProposal")
            case .rejectProposal:
                throw DocumentError.forbiddenOperation("rejectProposal")
            case .assessHypothesis, .resolveConstraint:
                // Intelligence may suggest a claim and the role it plays, and the
                // person corrects it. It may not record how the claim stands: a
                // model that could mark its own hypothesis supported would be
                // grading its own work, and one that could mark a constraint
                // satisfied would be removing the obstacles to its own proposal.
                // Both are a person's to say.
                throw DocumentError.forbiddenOperation("assessing a claim is the user's to do")
            case .assertClaim(let assertion):
                // A suggested claim is allowed, but only as an open one. The
                // standing is dropped rather than refused, so a proposal can carry
                // "this looks like a constraint" without being able to assert that
                // the constraint is met.
                guard assertion.claim.assessment.isOpen,
                      assertion.claim.resolution.evidence == nil else {
                    throw DocumentError.forbiddenOperation("a proposed claim arrives open")
                }
            case .attachSource, .importSourceRevision, .addCitation,
                 .recordVerification, .removeSource:
                // Intelligence may propose an idea, never attach evidence to it and
                // never mark it verified. A model that could add a citation would be
                // able to manufacture the appearance of support, and one that could
                // record a verification could award itself a badge. Both are a
                // person's to do.
                throw DocumentError.forbiddenOperation("sources and citations are the user's to manage")
            }
        }

        for hint in proposal.placementHints {
            guard document.content[hint.objectID] != nil || virtual.contains(hint.objectID) else {
                throw DocumentError.unknownObject(hint.objectID)
            }
            if let relative = hint.relativeTo {
                guard document.content[relative] != nil || virtual.contains(relative) else {
                    throw DocumentError.unknownObject(relative)
                }
            }
        }
    }
}
