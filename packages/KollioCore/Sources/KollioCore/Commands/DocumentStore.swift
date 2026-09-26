import Foundation

public enum DocumentError: Error, Equatable, CustomStringConvertible {
    case unknownObject(ObjectID)
    case unknownRelationship(RelationshipID)
    case unknownInstance(InstanceID)
    case unknownContribution(ActorID)
    case duplicateObject(ObjectID)
    case duplicateRelationship(RelationshipID)
    case duplicateInstance(InstanceID)
    case selfRelationship(RelationshipID)
    case missingInstanceForObject(ObjectID)
    case emptyText(ObjectID)
    case unknownDecision(DecisionID)
    case decisionTargetNotFound(ObjectID)
    case staleProposal(reason: String)
    /// Someone else changed this object's text after the writer last looked.
    /// Named apart from a stale proposal because the recovery is different: a
    /// person has to choose between two texts, not recalculate a branch.
    case staleObjectText(id: ObjectID, expected: Int, actual: Int)
    /// The last drawing of an object was removed, which would leave the idea
    /// invisible rather than gone. Removing the idea is a different decision
    /// and has to be taken as one.
    case lastOccurrence(ObjectID)
    /// A decision still points at this object, so removing it would orphan a
    /// durable record. The decision is revoked first, never silently dropped.
    case objectHasDecision(ObjectID, DecisionID)
    case tooManyOperations(Int)
    case forbiddenOperation(String)
    case unknownContributionReference(ObjectID, ActorID)
    case invalidShareRange(Double)
    case duplicateSource(SourceID)
    case unknownSource(SourceID)
    case unknownSourceRevision(SourceID, SourceRevisionID)
    case unknownCitation(CitationID)
    /// The import ran and produced nothing usable, so the previous version stays
    /// active. Named rather than folded into a generic failure because "your file
    /// has no text layer" and "that file is gone" call for different reactions.
    case sourceExtractionFailed(SourceID)
    /// A claim with nothing in its scope. Refused rather than treated as
    /// "everything", because that reading would make a constraint a law of the
    /// universe.
    case emptyScope(ClaimID)
    case unknownClaim(ClaimID)
    /// An assessment on something that is not a hypothesis, or a resolution on
    /// something that is not a constraint.
    case wrongClaimRole(ClaimID, expected: String)
    case duplicateClaim(ClaimID)
    case duplicateClarification(ClarificationID)
    case emptyClarification(ClarificationID)
    case alreadyAnswered(ClarificationID)
    case unknownClarification(ClarificationID)

    public var description: String {
        switch self {
        case .unknownObject(let id): return "Unknown object \(id)"
        case .unknownRelationship(let id): return "Unknown relationship \(id)"
        case .unknownInstance(let id): return "Unknown instance \(id)"
        case .unknownContribution(let id): return "Unknown contribution \(id)"
        case .duplicateObject(let id): return "Duplicate object \(id)"
        case .duplicateRelationship(let id): return "Duplicate relationship \(id)"
        case .duplicateInstance(let id): return "Duplicate instance \(id)"
        case .selfRelationship(let id): return "Relationship \(id) points at itself"
        case .missingInstanceForObject(let id): return "No visual instance for object \(id)"
        case .emptyText(let id): return "Object \(id) has empty text"
        case .unknownDecision(let id): return "Unknown decision \(id)"
        case .decisionTargetNotFound(let id): return "Decision target \(id) not found"
        case .staleProposal(let reason): return "Stale proposal: \(reason)"
        case .objectHasDecision(let object, let decision):
            return "Object \(object) is the target of decision \(decision); revoke or reopen it first"
        case .lastOccurrence(let id):
            return "Object \(id) has only one occurrence left; removing it would hide the idea rather than remove it"
        case .staleObjectText(let id, let expected, let actual):
            return "Object \(id) was edited by someone else: expected version \(expected), found \(actual)"
        case .tooManyOperations(let n): return "Too many operations: \(n)"
        case .forbiddenOperation(let name): return "Forbidden operation \(name)"
        case .unknownContributionReference(let object, let contribution): return "Object \(object) references unknown contribution \(contribution)"
        case .invalidShareRange(let value): return "Invalid share \(value)"
        case .duplicateSource(let id): return "Duplicate source \(id)"
        case .unknownSource(let id): return "Unknown source \(id)"
        case .unknownSourceRevision(let source, let revision): return "Source \(source) has no revision \(revision)"
        case .unknownCitation(let id): return "Unknown citation \(id)"
        case .sourceExtractionFailed(let id): return "Source \(id) produced no readable text; the previous version stays active"
        case .emptyScope(let id): return "Claim \(id) has an empty scope, so it would apply to everything"
        case .unknownClaim(let id): return "Unknown claim \(id)"
        case .wrongClaimRole(let id, let expected): return "Claim \(id) is not a \(expected)"
        case .duplicateClaim(let id): return "Duplicate claim \(id)"
        case .duplicateClarification(let id): return "Duplicate clarification \(id)"
        case .emptyClarification(let id): return "Clarification \(id) has no question"
        case .alreadyAnswered(let id): return "Clarification \(id) already has an answer"
        case .unknownClarification(let id): return "Unknown clarification \(id)"
        }
    }
}

/// The only way a document changes.
///
/// A transaction either fully succeeds or fails: the store mutates a value copy
/// and only publishes it when every command has been applied.
public struct DocumentStore: Sendable {
    public private(set) var document: KollioDocument

    public init(document: KollioDocument = KollioDocument()) {
        self.document = document
    }

    public var revision: Int { document.revision }
    public var semanticRevision: Int { document.semanticRevision }

    @discardableResult
    public mutating func apply(
        _ commands: [Command],
        at date: Date = Date(),
        undoLabel: String? = nil
    ) throws -> KollioDocument {
        guard !commands.isEmpty else { return document }
        _ = undoLabel
        let date = date.kollioNormalized
        var candidate = document
        var changedSemantics = false

        for command in commands {
            try Self.applyCommand(command, to: &candidate, at: date)
            changedSemantics = changedSemantics || command.isSemantic
        }

        candidate.revision += 1
        if changedSemantics {
            candidate.semanticRevision += 1
        }
        candidate.updatedAt = date
        document = candidate
        return document
    }

    public mutating func replace(with newDocument: KollioDocument) {
        document = newDocument
    }

    // MARK: - Command application

    private static func applyCommand(_ command: Command, to document: inout KollioDocument, at date: Date) throws {
        switch command {
        case .createObject(let create):
            try createObject(create, in: &document)
        case .updateObjectText(let update):
            try updateObjectText(update, in: &document)
        case .addRelationship(let add):
            try addRelationship(add, in: &document)
        case .removeRelationship(let remove):
            try removeRelationship(remove, from: &document)
        case .moveNodeInstances(let moves):
            try move(moves, in: &document)
        case .duplicateObject(let duplicate):
            try duplicateObject(duplicate, in: &document)
        case .duplicateNodeInstance(let duplicate):
            try duplicateNodeInstance(duplicate, in: &document)
        case .removeObject(let remove):
            try removeObject(remove, from: &document)
        case .removeNodeInstance(let remove):
            try removeNodeInstance(remove, from: &document)
        case .createScenario(let scenario):
            try createScenario(scenario, in: &document, at: date)
        case .recordDecision(let decision):
            try recordDecision(decision, in: &document, at: date)
        case .revokeDecision(let revoke):
            try revokeDecision(revoke, in: &document)
        case .addContributionToProduct(let add):
            try addContribution(add, in: &document)
        case .applyProposal(let apply):
            try applyProposal(apply, in: &document, at: date)
        case .rejectProposal(let reject):
            // see note in applyCommand
            _ = reject
        case .attachSource(let attach):
            try attachSource(attach, in: &document)
        case .importSourceRevision(let importRevision):
            try importSourceRevision(importRevision, in: &document)
        case .addCitation(let citation):
            try addCitation(citation, in: &document)
        case .recordVerification(let verification):
            try recordVerification(verification, in: &document)
        case .removeSource(let remove):
            try removeSource(remove, in: &document)
        case .assertClaim(let assertion):
            try assertClaim(assertion, in: &document)
        case .assessHypothesis(let assessment):
            try assessHypothesis(assessment, in: &document)
        case .resolveConstraint(let resolution):
            try resolveConstraint(resolution, in: &document)
        case .askClarification(let ask):
            try askClarification(ask, in: &document)
        case .answerClarification(let answer):
            try answerClarification(answer, in: &document)
        case .markClarificationUnknown(let unknown):
            try markClarificationUnknown(unknown, in: &document)
        }
    }

    private static func createObject(_ create: CreateObject, in document: inout KollioDocument) throws {
        guard document.content[create.id] == nil else { throw DocumentError.duplicateObject(create.id) }
        guard !create.text.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.emptyText(create.id)
        }
        if let contributionID = create.contributionID, document.contributions[contributionID] == nil {
            throw DocumentError.unknownContributionReference(create.id, contributionID)
        }
        let object = ContentObject(
            id: create.id,
            kind: create.kind,
            text: create.text,
            detail: create.detail,
            contributionID: create.contributionID,
            provenance: create.provenance
        )
        document.content[create.id] = object
        document.presentation.instances.append(
            NodeInstance(
                id: InstanceID("instance:\(create.id.rawValue)"),
                objectID: create.id,
                position: create.position ?? .zero,
                size: create.size
            )
        )
    }

    private static func updateObjectText(_ update: UpdateObjectText, in document: inout KollioDocument) throws {
        guard var object = document.content[update.id] else { throw DocumentError.unknownObject(update.id) }
        guard !update.text.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.emptyText(update.id)
        }
        // The version check is what makes a concurrent edit a question instead of a
        // silent overwrite. It runs before anything is written, so a refusal leaves
        // the object exactly as it was.
        if let expected = update.expectedVersion, expected != object.objectVersion {
            throw DocumentError.staleObjectText(id: update.id, expected: expected, actual: object.objectVersion)
        }
        guard object.text != update.text || object.detail != update.detail else {
            // Nothing actually changed, so the version does not move. A version that
            // rises on a no-op would make every writer look stale for no reason.
            return
        }
        object.text = update.text
        object.detail = update.detail
        object.provenance = update.provenance
        object.objectVersion += 1
        document.content[update.id] = object
    }

    private static func addRelationship(_ add: AddRelationship, in document: inout KollioDocument) throws {
        guard document.content[add.from] != nil else { throw DocumentError.unknownObject(add.from) }
        guard document.content[add.to] != nil else { throw DocumentError.unknownObject(add.to) }
        guard add.from != add.to else { throw DocumentError.selfRelationship(add.id) }
        guard document.relationships[add.id] == nil else { throw DocumentError.duplicateRelationship(add.id) }
        document.relationships[add.id] = Relationship(
            id: add.id,
            from: add.from,
            to: add.to,
            kind: add.kind,
            label: add.label,
            fromAnchor: add.fromAnchor,
            toAnchor: add.toAnchor,
            provenance: add.provenance
        )
    }

    private static func removeRelationship(_ remove: RemoveRelationship, from document: inout KollioDocument) throws {
        guard document.relationships.removeValue(forKey: remove.id) != nil else {
            throw DocumentError.unknownRelationship(remove.id)
        }
    }

    private static func move(_ move: MoveNodeInstances, in document: inout KollioDocument) throws {
        for one in move.moves {
            guard let index = document.presentation.instances.firstIndex(where: { $0.id == one.instanceID }) else {
                throw DocumentError.unknownInstance(one.instanceID)
            }
            document.presentation.instances[index].position = one.position
        }
    }

    /// A second occurrence of one object.
    ///
    /// Nothing here copies an object, a contribution or a share, and that is the
    /// whole of AC01: a person who puts the same thing in two places has not
    /// created a second author or a second claim. If the source is a reference to
    /// somebody else's contribution, the copy is a reference to the *same*
    /// contribution id, which is what makes the share count stay at one.
    private static func duplicateNodeInstance(
        _ duplicate: DuplicateNodeInstance,
        in document: inout KollioDocument
    ) throws {
        guard let source = document.presentation.instance(id: duplicate.instanceID) else {
            throw DocumentError.unknownInstance(duplicate.instanceID)
        }
        guard document.presentation.instance(id: duplicate.id) == nil else {
            throw DocumentError.duplicateInstance(duplicate.id)
        }
        document.presentation.instances.append(
            NodeInstance(
                id: duplicate.id,
                objectID: source.objectID,
                position: duplicate.position ?? source.position,
                size: source.size,
                hidden: source.hidden
            )
        )
    }

    /// A variant: a new object, related to the one it came from.
    ///
    /// The text is copied because a variant starts as the same thought, and the
    /// `contributionID` is copied as a *reference*. The contribution record itself
    /// is never touched, so two variants of a contributed object still owe the
    /// original owner one share between them, not two.
    private static func duplicateObject(
        _ duplicate: DuplicateObject,
        in document: inout KollioDocument
    ) throws {
        guard let source = document.content[duplicate.sourceID] else {
            throw DocumentError.unknownObject(duplicate.sourceID)
        }
        guard document.content[duplicate.id] == nil else {
            throw DocumentError.duplicateObject(duplicate.id)
        }
        guard document.relationships[duplicate.relationshipID] == nil else {
            throw DocumentError.duplicateRelationship(duplicate.relationshipID)
        }
        var copy = source
        copy.id = duplicate.id
        copy.provenance = duplicate.provenance
        // A fresh object has never been edited, so it starts at zero rather than
        // inheriting the version of the thing it was copied from.
        copy.objectVersion = 0
        document.content[duplicate.id] = copy

        if let contributionID = source.contributionID, document.contributions[contributionID] == nil {
            throw DocumentError.unknownContributionReference(duplicate.id, contributionID)
        }

        let origin = document.presentation.instance(for: duplicate.sourceID)
        document.presentation.instances.append(
            NodeInstance(
                id: duplicate.instanceID,
                objectID: duplicate.id,
                position: duplicate.position ?? origin?.position ?? .zero,
                size: origin?.size
            )
        )
        try addRelationship(
            AddRelationship(
                id: duplicate.relationshipID,
                from: duplicate.id,
                to: duplicate.sourceID,
                kind: .derivedFrom,
                provenance: duplicate.provenance
            ),
            in: &document
        )
    }

    /// Removes one occurrence and keeps the idea.
    private static func removeNodeInstance(
        _ remove: RemoveNodeInstance,
        from document: inout KollioDocument
    ) throws {
        guard let index = document.presentation.instances.firstIndex(where: { $0.id == remove.instanceID }) else {
            throw DocumentError.unknownInstance(remove.instanceID)
        }
        // The last occurrence of an object is not an occurrence any more: removing
        // it would leave a node with nothing drawing it, and the next save would
        // write a document nobody can see. That is a decision to remove the idea,
        // so it is refused here and has to be asked for as `removeObject`.
        let objectID = document.presentation.instances[index].objectID
        let remaining = document.presentation.instances.filter { $0.objectID == objectID }.count
        guard remaining > 1 else {
            throw DocumentError.lastOccurrence(objectID)
        }
        document.presentation.instances.remove(at: index)
    }

    /// Removes an object from the document, with everything that pointed at it.
    ///
    /// A decision that set an object aside keeps its memory, so a decision pointing
    /// here is a reason to refuse rather than to clean up: removing the object would
    /// leave a durable record about something that no longer exists, and deciding
    /// what that record meant is the owner's call, not a side effect. Revoke or
    /// reopen the decision first.
    private static func removeObject(
        _ remove: RemoveObject,
        from document: inout KollioDocument
    ) throws {
        guard document.content[remove.id] != nil else {
            throw DocumentError.unknownObject(remove.id)
        }
        if let decision = document.decisions.values.first(where: { $0.targetObjectID == remove.id }) {
            throw DocumentError.objectHasDecision(remove.id, decision.id)
        }
        document.content[remove.id] = nil
        for (id, relationship) in document.relationships where
            relationship.from == remove.id || relationship.to == remove.id {
            document.relationships[id] = nil
        }
        document.presentation.instances.removeAll { $0.objectID == remove.id }
    }

    private static func createScenario(_ scenario: CreateScenario, in document: inout KollioDocument, at date: Date) throws {
        var context = scenario.context
        context.position = scenario.rootPosition
        try createObject(context, in: &document)
        for child in scenario.children {
            try createObject(child, in: &document)
        }
        for link in scenario.links {
            try addRelationship(link, in: &document)
        }
        _ = date
    }

    /// Records a durable decision. `setAside` collapses the branch without
    /// deleting anything; `reopened` restores it exactly as it was, positions
    /// included.
    private static func recordDecision(_ command: RecordDecision, in document: inout KollioDocument, at date: Date) throws {
        guard let target = document.content[command.targetObjectID] else {
            throw DocumentError.decisionTargetNotFound(command.targetObjectID)
        }

        var branch: Set<ObjectID> = []
        switch command.kind {
        case .setAside, .kept:
            branch = document.exclusiveDescendants(of: command.targetObjectID)
        case .reopened:
            branch = Set(
                document.decisions.values
                    .filter { $0.targetObjectID == command.targetObjectID && $0.kind == .setAside }
                    .flatMap(\.branchObjectIDs)
                    .map { ObjectID($0.rawValue) }
            )
            if branch.isEmpty { branch = [command.targetObjectID] }
        }

        // A new decision supersedes the previous active decision on the same target.
        for (id, decision) in document.decisions
        where decision.targetObjectID == command.targetObjectID && decision.status == .active {
            var superseded = decision
            superseded.status = .superseded
            document.decisions[id] = superseded
        }

        let decision = Decision(
            id: command.id,
            kind: command.kind,
            targetObjectID: command.targetObjectID,
            branchObjectIDs: branch.sorted { $0.rawValue < $1.rawValue },
            rationale: command.rationale,
            createdAt: date,
            provenance: command.provenance
        )
        document.decisions[command.id] = decision

        switch command.kind {
        case .setAside:
            for id in branch {
                guard var object = document.content[id] else { continue }
                object.lifecycle = .setAside
                object.setAsideByDecision = command.id
                document.content[id] = object
            }
        case .reopened:
            for id in branch {
                guard var object = document.content[id] else { continue }
                // Only restore what this decision actually closed.
                guard object.setAsideByDecision != nil else { continue }
                object.lifecycle = .active
                object.setAsideByDecision = nil
                document.content[id] = object
            }
        case .kept:
            break
        }
        _ = target
    }

    private static func revokeDecision(_ revoke: RevokeDecision, in document: inout KollioDocument) throws {
        guard var decision = document.decisions[revoke.id] else { throw DocumentError.unknownDecision(revoke.id) }
        decision.status = .superseded
        document.decisions[revoke.id] = decision
        if decision.kind == .setAside {
            for id in decision.branchObjectIDs.map { ObjectID($0.rawValue) } {
                guard var object = document.content[id] else { continue }
                guard object.setAsideByDecision == revoke.id else { continue }
                object.lifecycle = .active
                object.setAsideByDecision = nil
                document.content[id] = object
            }
        }
    }

    private static func addContribution(_ add: AddContributionToProduct, in document: inout KollioDocument) throws {
        guard document.contributions[add.contributionID] != nil else {
            throw DocumentError.unknownContribution(add.contributionID)
        }
        guard (0...1).contains(add.share) else { throw DocumentError.invalidShareRange(add.share) }
        var product = document.products[add.productID] ?? ProductComposition(
            id: add.productID,
            name: document.content[add.productID]?.text ?? LocalizedText(add.productID.rawValue)
        )
        if !product.memberContributionIDs.contains(add.contributionID) {
            product.memberContributionIDs.append(add.contributionID)
        }
        product.shares[add.contributionID.rawValue] = add.share
        document.products[add.productID] = product
    }

    private static func applyProposal(_ apply: ApplyProposal, in document: inout KollioDocument, at date: Date) throws {
        let validator = ProposalValidator()
        try validator.validate(apply.proposal, against: document, scope: .init(maxOperations: 32, allowNewObjects: true))

        for operation in apply.proposal.operations {
            try applyCommand(operation, to: &document, at: date)
        }
        for (objectID, position) in apply.placements {
            guard let instance = document.presentation.instance(for: objectID) else { continue }
            if let index = document.presentation.instances.firstIndex(where: { $0.id == instance.id }) {
                document.presentation.instances[index].position = position
            }
        }
        _ = apply.provenance
    }

    private static func createdObjectID(_ command: Command) -> ObjectID? {
        if case .createObject(let create) = command { return create.id }
        return nil
    }
}

/// Rejecting a proposal never touches the document: a proposal that was never
/// kept has no branch on the canvas. Setting a *kept* branch aside is a durable
/// decision, expressed with `RecordDecision`, so it keeps its rationale and can be
/// reopened.
extension DocumentStore {
    public static func setAsideProposalReason(for reject: RejectProposal) -> RejectProposal.RejectReason {
        reject.reason
    }

    // MARK: - Sources and citations

    private static func attachSource(_ attach: AttachSource, in document: inout KollioDocument) throws {
        guard document.sources.source(attach.source.id) == nil else {
            throw DocumentError.duplicateSource(attach.source.id)
        }
        if let target = attach.attachedTo, document.content[target] == nil {
            // A source attached to nothing in particular is legitimate, so this is
            // only refused when an attachment was named and does not exist.
            throw DocumentError.unknownObject(target)
        }
        document.sources.add(attach.source)
    }

    private static func importSourceRevision(
        _ importRevision: ImportSourceRevision,
        in document: inout KollioDocument
    ) throws {
        // The attempt is recorded even when it produced nothing, because "we read it
        // and there is no text" is a fact a person needs. What must not happen is a
        // broken import replacing a good earlier version, and the ledger decides
        // that rather than this function.
        switch document.sources.importRevision(importRevision.revision, for: importRevision.sourceID) {
        case .imported:
            return
        case .rejected(.unknownSource):
            throw DocumentError.unknownSource(importRevision.sourceID)
        }
    }

    private static func addCitation(_ add: AddCitation, in document: inout KollioDocument) throws {
        guard document.content[add.claimID] != nil else {
            throw DocumentError.unknownObject(add.claimID)
        }
        // The claim named by the command is the claim recorded on the citation. Two
        // places to state one thing would be two places to disagree.
        var citation = add.citation
        citation.claimID = add.claimID
        switch document.sources.cite(citation) {
        case .success:
            return
        case .failure(.unknownSource):
            throw DocumentError.unknownSource(citation.sourceID)
        case .failure(.unknownRevision(let revision)):
            throw DocumentError.unknownSourceRevision(citation.sourceID, revision)
        case .failure(.unknownCitation(let citation)):
            throw DocumentError.unknownCitation(citation)
        }
    }

    private static func recordVerification(
        _ verification: RecordVerification,
        in document: inout KollioDocument
    ) throws {
        guard verification.observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            // A verification with nothing to say is not a verification.
            throw DocumentError.forbiddenOperation("a verification needs an observation")
        }
        switch document.sources.recordVerification(
            verification.citationID,
            observation: verification.observation,
            by: verification.author,
            at: verification.at
        ) {
        case .success:
            return
        case .failure:
            throw DocumentError.unknownCitation(verification.citationID)
        }
    }

    private static func removeSource(_ remove: RemoveSource, in document: inout KollioDocument) throws {
        guard document.sources.source(remove.sourceID) != nil else {
            throw DocumentError.unknownSource(remove.sourceID)
        }
        // The history stays. What is lost is the ability to check quietly, and every
        // citation says so.
        document.sources.removeSourceKeepingHistory(remove.sourceID)
    }

    // MARK: - Claims

    private static func assertClaim(_ assertion: AssertClaim, in document: inout KollioDocument) throws {
        let claim = assertion.claim
        guard document.content[claim.objectID] != nil else {
            throw DocumentError.unknownObject(claim.objectID)
        }
        // Every object the claim is about has to exist, or the scope names things
        // the document has never heard of.
        for object in claim.scope.objectIDs where document.content[object] == nil {
            throw DocumentError.unknownObject(object)
        }
        guard claim.scope.objectIDs.isEmpty == false else {
            throw DocumentError.emptyScope(claim.id)
        }
        guard document.claims.claim(claim.id) == nil else {
            throw DocumentError.duplicateClaim(claim.id)
        }
        var ledger = document.claims
        ledger.upsert(claim)
        document.claims = ledger
    }

    private static func assessHypothesis(
        _ assessment: AssessHypothesis,
        in document: inout KollioDocument
    ) throws {
        guard var claim = document.claims.claim(assessment.claimID) else {
            throw DocumentError.unknownClaim(assessment.claimID)
        }
        guard claim.role == .hypothesis else {
            throw DocumentError.wrongClaimRole(assessment.claimID, expected: "hypothesis")
        }
        // The evidence is required here rather than in the type alone, because a
        // caller can build the enum by hand and `.supported` needs an observation.
        if let evidence = assessment.assessment.evidence {
            guard evidence.observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                throw DocumentError.forbiddenOperation("an assessment needs an observation")
            }
        }
        claim.assessment = assessment.assessment
        // Assessing a hypothesis never resolves a constraint: the two stay apart.
        var ledger = document.claims
        ledger.upsert(claim)
        document.claims = ledger
    }

    private static func resolveConstraint(
        _ resolution: ResolveConstraint,
        in document: inout KollioDocument
    ) throws {
        guard var claim = document.claims.claim(resolution.claimID) else {
            throw DocumentError.unknownClaim(resolution.claimID)
        }
        guard claim.role == .constraint else {
            throw DocumentError.wrongClaimRole(resolution.claimID, expected: "constraint")
        }
        if let evidence = resolution.resolution.evidence {
            guard evidence.observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                throw DocumentError.forbiddenOperation("a resolution needs an observation")
            }
        }
        claim.resolution = resolution.resolution
        var ledger = document.claims
        ledger.upsert(claim)
        document.claims = ledger
    }

    // MARK: - Clarifications

    private static func askClarification(_ ask: AskClarification, in document: inout KollioDocument) throws {
        let clarification = ask.clarification
        guard document.content[clarification.objectID] != nil else {
            throw DocumentError.unknownObject(clarification.objectID)
        }
        guard !clarification.question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DocumentError.emptyClarification(clarification.id)
        }
        guard document.clarifications.clarification(clarification.id) == nil else {
            throw DocumentError.duplicateClarification(clarification.id)
        }
        var ledger = document.clarifications
        ledger.upsert(clarification)
        document.clarifications = ledger
    }

    private static func answerClarification(
        _ answer: AnswerClarification,
        in document: inout KollioDocument
    ) throws {
        guard var clarification = document.clarifications.clarification(answer.clarificationID) else {
            throw DocumentError.unknownClarification(answer.clarificationID)
        }
        let text = answer.text.trimmingCharacters(in: .whitespacesAndNewlines)
        // An empty field is not sent as a fact. It is refused here rather than
        // stored as a blank answer, because a blank answer in the document reads as
        // something a person considered and had nothing to say about.
        guard text.isEmpty == false else {
            throw DocumentError.emptyClarification(answer.clarificationID)
        }
        clarification.state = .answered(.init(
            text: text,
            by: answer.provenance.actor,
            at: answer.provenance.kind == .human ? Date() : Date(timeIntervalSince1970: 0)
        ))
        var ledger = document.clarifications
        ledger.upsert(clarification)
        document.clarifications = ledger
    }

    private static func markClarificationUnknown(
        _ unknown: MarkClarificationUnknown,
        in document: inout KollioDocument
    ) throws {
        guard var clarification = document.clarifications.clarification(unknown.clarificationID) else {
            throw DocumentError.unknownClarification(unknown.clarificationID)
        }
        // A reason is optional here. "I do not know" is a complete answer; being
        // pressed for a reason would turn an honest gap back into a task.
        clarification.state = .unknown(unknown.reason ?? "")
        var ledger = document.clarifications
        ledger.upsert(clarification)
        document.clarifications = ledger
    }
}
