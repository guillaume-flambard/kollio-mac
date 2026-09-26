import Foundation

/// What new information touched, and what it left alone.
///
/// CTX-05, in one sentence: "Build the objects touched by explicit dependencies;
/// intelligence may propose interpretations, never apply them." This file is that
/// build, and it is a *pure function of the document*. There is no provider, no
/// session and no network anywhere in it, which is what "propagation rules do not
/// depend on the provider" has to mean if it is to be true rather than aspirational.
///
/// Four rules the type is built to make hard to violate:
///
/// 1. **An impact is never a verdict.** `ImpactReason` has no case meaning "refuted"
///    or "satisfied". The strongest thing this file can say about an object is that
///    the ground under it moved and a person should look again.
/// 2. **Only explicit dependencies propagate.** A link is followed when it says one
///    object relies on another. `alternativeTo` and `associatedWith` say something
///    real, but not that either end would collapse if the other moved, so they are
///    not followed and the other end is reported as unaffected with that reason.
/// 3. **Availability is not dependence.** A source being readable says nothing about
///    an object that never cited it, so the only direct impacts are the objects that
///    actually carry a citation of the source that moved.
/// 4. **A cycle terminates.** The walk carries a visited set, so a document that
///    points at itself is answered once rather than frozen.
public struct ImpactAssessment: Codable, Hashable, Sendable, Identifiable {
    public var id: ImpactID
    /// The information that started the question. Kept with the assessment so a
    /// person reading it later knows what "moved" was.
    public var trigger: ImpactTrigger
    /// What was read to produce this, so the answer can be checked rather than
    /// trusted. Sorted before storage, because a read set that reshuffles between
    /// runs makes two identical assessments look like two different ones.
    public var readSet: ImpactReadSet
    /// What needs another look, and why, in dependency order from the source.
    public var proposedChanges: [ImpactedObject]
    /// What was examined and stays valid. A list of what *not* to re-open, which is
    /// as much a part of the answer as the list of what to look at.
    public var unaffectedRefs: [UnaffectedRef]
    /// True when the walk stopped at its bound rather than at the end of the graph.
    /// A truncated assessment says so instead of pretending it is complete.
    public var wasTruncated: Bool
    public var createdAt: Date

    public init(
        id: ImpactID,
        trigger: ImpactTrigger,
        readSet: ImpactReadSet,
        proposedChanges: [ImpactedObject] = [],
        unaffectedRefs: [UnaffectedRef] = [],
        wasTruncated: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.trigger = trigger
        self.readSet = readSet
        self.proposedChanges = proposedChanges
        self.unaffectedRefs = unaffectedRefs
        self.wasTruncated = wasTruncated
        self.createdAt = createdAt
    }

    public var isEmpty: Bool { proposedChanges.isEmpty }

    /// The objects to mark, in the order the dependencies were walked.
    public var objectIDs: [ObjectID] { proposedChanges.map(\.objectID) }
}

public struct ImpactID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
    public init(stringLiteral value: String) { self.rawValue = value }
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var idString: String { rawValue }
    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// The information that started the question.
public struct ImpactTrigger: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        /// A newer revision of the source is the one being read now.
        case sourceRevisionSuperseded
        /// The source is gone, or was removed.
        case sourceUnavailable
    }

    public var kind: Kind
    public var sourceID: SourceID
    /// The revision that superseded the old one, when there is one.
    public var revisionID: SourceRevisionID?
    /// Why, in the document's own words. Recorded because "the file moved" and "the
    /// file is gone" ask different things of a person.
    public var reason: String

    public init(kind: Kind, sourceID: SourceID, revisionID: SourceRevisionID? = nil, reason: String) {
        self.kind = kind
        self.sourceID = sourceID
        self.revisionID = revisionID
        self.reason = reason
    }
}

/// Everything the assessment looked at.
public struct ImpactReadSet: Codable, Hashable, Sendable {
    public var sourceID: SourceID
    public var revisionIDs: [SourceRevisionID]
    /// The citations considered, whether or not they needed review.
    public var citationIDs: [CitationID]
    /// The objects walked, origin included.
    public var visitedObjectIDs: [ObjectID]
    /// The links followed as explicit dependencies.
    public var relationshipIDs: [RelationshipID]

    public init(
        sourceID: SourceID,
        revisionIDs: [SourceRevisionID] = [],
        citationIDs: [CitationID] = [],
        visitedObjectIDs: [ObjectID] = [],
        relationshipIDs: [RelationshipID] = []
    ) {
        self.sourceID = sourceID
        self.revisionIDs = revisionIDs
        self.citationIDs = citationIDs
        self.visitedObjectIDs = visitedObjectIDs
        self.relationshipIDs = relationshipIDs
    }
}

/// One object that needs another look.
public struct ImpactedObject: Codable, Hashable, Sendable, Identifiable {
    public var objectID: ObjectID
    public var reason: ImpactReason
    /// The explicit dependency path from where the evidence moved, the first element
    /// being the object that actually cited it. Recorded because "this needs review"
    /// is not an answer, and "this needs review *because* that moved" is.
    public var path: [ObjectID]

    public var id: ObjectID { objectID }

    public init(objectID: ObjectID, reason: ImpactReason, path: [ObjectID]) {
        self.objectID = objectID
        self.reason = reason
        self.path = path
    }

    public var depth: Int { max(path.count - 1, 0) }
}

public extension ImpactReason {
    /// The sentence the durable record carries.
    ///
    /// Written in the document rather than in the interface, because a decision
    /// outlives the interface language a person happened to be using. The interface
    /// shows its own translation of the same reason; the record keeps this one.
    var rationale: String {
        switch self {
        case .evidenceMoved: return "the source has a newer revision than the one this was read against"
        case .evidenceLost: return "the source behind this is no longer available"
        case .reliesOnImpactedObject: return "this relies on something whose own ground moved"
        }
    }
}

/// Why an object is in the assessment.
///
/// Note what is not here. There is no "refuted", no "no longer supported", no
/// "constraint no longer applies". A source moving under a claim makes the claim
/// worth looking at, and only a person can say what it means. That absence is the
/// specification's "without inverting the decision", expressed as a type.
public enum ImpactReason: String, Codable, Sendable, CaseIterable {
    /// A citation of this object points at a revision that is no longer the one
    /// being read.
    case evidenceMoved
    /// The source behind a citation of this object is gone.
    case evidenceLost
    /// This object relies on one that was itself impacted.
    case reliesOnImpactedObject
}

/// An object that was examined and stays as it is.
public struct UnaffectedRef: Codable, Hashable, Sendable, Identifiable {
    public enum Why: String, Codable, Sendable, CaseIterable {
        /// The citation is still on the revision being read, so nothing about it
        /// moved.
        case citationStillCurrent
        /// The link examined does not say the other end relies on this one. Two
        /// alternatives do not collapse because one of them changed, and that is
        /// exactly AC02.
        case linkIsNotADependence
        /// The object is on a decision-closed branch and was not walked further.
        case setAside
    }

    public var objectID: ObjectID
    public var why: Why

    public var id: ObjectID { objectID }

    public init(objectID: ObjectID, why: Why) {
        self.objectID = objectID
        self.why = why
    }
}

/// Which end of a link relies on the other, if either.
///
/// Derived from the documented direction of the verb: in `A supports B` the
/// subject A is what B stands on, and in `A dependsOn B` the subject is the one
/// doing the relying. Reading the direction out of the kind rather than out of
/// `from`/`to` is what keeps the two families of link from being silently
/// reversed relative to the sentence the canvas draws.
public enum ImpactDependence: Hashable, Sendable {
    /// `from` relies on `to`.
    case subjectReliesOnObject
    /// `to` relies on `from`.
    case objectReliesOnSubject
    /// The link says something real, but not that either end depends on the other.
    case notADependence

    public var propagatesImpact: Bool { self != .notADependence }
}

public extension Relationship.Kind {
    var impactDependence: ImpactDependence {
        switch self {
        case .dependsOn, .derivedFrom, .uses:
            // "A depends on B", "A comes from B", "A uses B": the subject relies.
            return .subjectReliesOnObject
        case .supports, .constrains, .contradicts:
            // "A supports B", "A constrains B", "A contradicts B": the object end
            // is the one that rests on the subject.
            return .objectReliesOnSubject
        case .alternativeTo, .addresses, .associatedWith:
            // A sibling, a topic and an association. Following these would be
            // guessing, and guessing is how a shared tool ends up unusable
            // somewhere else because something on another branch moved.
            return .notADependence
        }
    }
}

extension Relationship {
    /// The object that would be impacted if this end's ground moved, if the link is
    /// one of reliance.
    ///
    /// The direction matters and is easy to get backwards. In `A dependsOn B`, A is
    /// the one at risk when B moves, and B is *not* at risk when A moves: the
    /// person who wrote A already knew what A was standing on. An implementation
    /// that walks the link the other way marks the foundations whenever the thing
    /// built on them changes, which is how one branch's edit ends up flagged across
    /// the whole document.
    func dependant(of impacted: ObjectID) -> ObjectID? {
        switch kind.impactDependence {
        case .notADependence: return nil
        case .subjectReliesOnObject:
            // `from` relies on `to`.
            return to == impacted ? from : nil
        case .objectReliesOnSubject:
            // `to` relies on `from`.
            return from == impacted ? to : nil
        }
    }
}

/// The deterministic builder behind CTX-05.
///
/// A value type with no dependencies on purpose: it is pure, it is synchronous,
/// and it is called from the command layer, the interface and the tests with the
/// same answer. A model may later *interpret* one of these, and a proposal that
/// adds a different object to the list is a proposal like any other, refused
/// straight into the same command.
public struct ImpactAssessor: Sendable {
    /// The default bound on how much of the graph one assessment may walk.
    ///
    /// Bounded rather than exhaustive because a document is a graph a person drew
    /// and nothing stops it from being pathological. When the bound is hit the
    /// assessment says `wasTruncated` rather than silently reporting a smaller
    /// world as though it were the whole one.
    public static let defaultVisitLimit = 256

    public let visitLimit: Int

    public init(visitLimit: Int = ImpactAssessor.defaultVisitLimit) {
        self.visitLimit = max(1, visitLimit)
    }

    public func assess(
        _ document: KollioDocument,
        trigger: ImpactTrigger,
        id: ImpactID = ImpactID("impact:" + UUID().uuidString),
        at date: Date = Date(timeIntervalSince1970: 0)
    ) -> ImpactAssessment {
        var readSet = ImpactReadSet(sourceID: trigger.sourceID)
        if let source = document.sources.source(trigger.sourceID) {
            readSet.revisionIDs = source.revisions.map(\.id).sorted { $0.rawValue < $1.rawValue }
        }

        var impacted: [ImpactedObject] = []
        var pathsByObject: [ObjectID: [ObjectID]] = [:]
        var visited: Set<ObjectID> = []
        var queue: [ImpactedObject] = []
        var unaffected: [ObjectID: UnaffectedRef.Why] = [:]
        var truncated = false

        // The only direct impacts: the objects that actually cite this source, and
        // whose citation can no longer be checked as it was. An object that never
        // cited it is never touched, however readable the source has become.
        for citation in document.sources.citations(of: trigger.sourceID) {
            readSet.citationIDs.append(citation.id)
            guard let object = document.object(citation.claimID) else { continue }
            let reason: ImpactReason? = switch citation.status {
            case .needsReview: .evidenceMoved
            case .sourceMissing: .evidenceLost
            // Verified against the current revision, or simply not yet checked: in
            // both cases the evidence did not move.
            case .verified, .unverified: nil
            }
            guard let reason else {
                // The citation is on the revision being read, or has simply never
                // been checked. Nothing about it moved, and saying so is part of the
                // answer rather than an absence.
                if unaffected[object.id] == nil { unaffected[object.id] = .citationStillCurrent }
                continue
            }
            // Two citations of the same source on the same object are one impact,
            // not two: the second would otherwise list the object twice.
            guard visited.insert(object.id).inserted else { continue }
            let entry = ImpactedObject(objectID: object.id, reason: reason, path: [object.id])
            impacted.append(entry)
            pathsByObject[object.id] = entry.path
            queue.append(entry)
            readSet.visitedObjectIDs.append(object.id)
        }

        // Propagation along explicit dependencies, breadth first, with a visited
        // set. A cycle re-enters an object that is already queued or done, and the
        // walk stops there: no freeze, no second copy, no endless expansion.
        while let current = queue.first {
            queue.removeFirst()
            guard readSet.visitedObjectIDs.count < self.visitLimit else {
                truncated = true
                break
            }
            for relationship in document.incidents(of: current.objectID)
                .sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
                if let dependant = relationship.dependant(of: current.objectID) {
                    readSet.relationshipIDs.append(relationship.id)
                    guard let object = document.object(dependant) else { continue }
                    // A direction a person set aside is closed, not deleted. The
                    // walk stops at its border and says so, rather than reopening a
                    // decision to re-litigate something the person already settled.
                    guard object.isSetAside == false else {
                        if unaffected[dependant] == nil { unaffected[dependant] = .setAside }
                        continue
                    }
                    guard visited.insert(dependant).inserted else { continue }
                    guard readSet.visitedObjectIDs.count < self.visitLimit else {
                        truncated = true
                        break
                    }
                    // The reason is the parent's: this object is affected because of
                    // what it relies on, not because of anything read here.
                    let path = (pathsByObject[current.objectID] ?? [current.objectID]) + [dependant]
                    let entry = ImpactedObject(
                        objectID: dependant,
                        reason: .reliesOnImpactedObject,
                        path: path
                    )
                    impacted.append(entry)
                    pathsByObject[dependant] = path
                    queue.append(entry)
                    readSet.visitedObjectIDs.append(dependant)
                } else {
                    // Examined, and explicitly left alone. Recorded so the person
                    // reading the assessment can see the decision rather than
                    // infer it from an absence. An object already in the impacted
                    // list is never listed here: the two lists answer different
                    // questions and must not contradict each other.
                    let other = relationship.from == current.objectID ? relationship.to : relationship.from
                    guard document.object(other) != nil,
                          unaffected[other] == nil,
                          visited.contains(other) == false
                    else { continue }
                    // A closed direction is reported as closed rather than as merely
                    // unrelated, because the two call for different reading.
                    unaffected[other] = document.object(other)?.isSetAside == true
                        ? .setAside
                        : .linkIsNotADependence
                }
            }
        }

        readSet.visitedObjectIDs = readSet.visitedObjectIDs.sorted { $0.rawValue < $1.rawValue }
        readSet.citationIDs = readSet.citationIDs.sorted { $0.rawValue < $1.rawValue }
        readSet.relationshipIDs = readSet.relationshipIDs.sorted { $0.rawValue < $1.rawValue }

        return ImpactAssessment(
            id: id,
            trigger: trigger,
            readSet: readSet,
            proposedChanges: impacted,
            unaffectedRefs: unaffected
                .map { UnaffectedRef(objectID: $0.key, why: $0.value) }
                .sorted { $0.objectID.rawValue < $1.objectID.rawValue },
            wasTruncated: truncated,
            createdAt: date
        )
    }

    /// The trigger that a document's own citation states describe.
    ///
    /// Built from the ledger rather than from a caller's guess, so the reason the
    /// card shows and the reason the citation carries cannot disagree.
    public static func trigger(
        for citation: Citation,
        source: SourceReference
    ) -> ImpactTrigger? {
        switch citation.status {
        case .needsReview(let reason):
            return ImpactTrigger(
                kind: .sourceRevisionSuperseded,
                sourceID: citation.sourceID,
                revisionID: source.latest?.id,
                reason: reason
            )
        case .sourceMissing(let reason):
            return ImpactTrigger(
                kind: .sourceUnavailable,
                sourceID: citation.sourceID,
                reason: reason
            )
        case .unverified, .verified:
            // Nothing moved, so there is nothing to assess. Returning nil rather
            // than an assessment with an empty list is what keeps the interface
            // from offering a review of nothing.
            return nil
        }
    }
}

public extension KollioDocument {
    /// Builds the assessment for a citation that no longer checks as it was.
    ///
    /// Nil when the citation is still current, because "nothing moved" is not an
    /// impact assessment and should not be shown as one.
    func impactAssessment(
        for citation: Citation,
        id: ImpactID = ImpactID("impact:" + UUID().uuidString),
        limit: Int = ImpactAssessor.defaultVisitLimit
    ) -> ImpactAssessment? {
        guard let source = sources.source(citation.sourceID),
              let trigger = ImpactAssessor.trigger(for: citation, source: source)
        else { return nil }
        return ImpactAssessor(visitLimit: limit).assess(self, trigger: trigger, id: id)
    }

    /// The active decision saying this object needs another look, if there is one.
    ///
    /// Derived from the decisions rather than stored twice: a second copy of
    /// "needs review" would be a second truth free to disagree with the first.
    func pendingImpactReview(for objectID: ObjectID) -> Decision? {
        decisions.values
            .filter { $0.status == .active && $0.kind == .impacted && $0.targetObjectID == objectID }
            .sorted { $0.createdAt < $1.createdAt }
            .last
    }

    /// Whether a person should be offered the review. True when the object cites
    /// evidence that moved, or when a previous assessment was applied and has not
    /// been looked at.
    func needsImpactReview(_ objectID: ObjectID) -> Bool {
        if pendingImpactReview(for: objectID) != nil { return true }
        return sources.citations(supporting: objectID).contains { citation in
            switch citation.status {
            case .needsReview, .sourceMissing: return true
            case .unverified, .verified: return false
            }
        }
    }
}
