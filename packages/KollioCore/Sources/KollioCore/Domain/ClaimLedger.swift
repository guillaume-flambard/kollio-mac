import Foundation

/// Where a claim applies, stated rather than assumed.
///
/// This type exists because of one rule in the specification: **a constraint only
/// blocks within its scope**. A constraint with no scope would be a law of the
/// universe, and a person who writes "no credentials available" about one export
/// would end up forbidding every other export too. The scope is therefore a
/// required part of the claim, not an optional annotation.
public struct ClaimScope: Codable, Hashable, Sendable, Identifiable {
    public var id: ScopeID
    public var title: String
    /// The objects the claim is about. Empty is refused by the command layer rather
    /// than treated as "everything": an unscoped claim cannot be reasoned about.
    public var objectIDs: Set<ObjectID>

    public init(id: ScopeID, title: String, objectIDs: Set<ObjectID>) {
        self.id = id
        self.title = title
        self.objectIDs = objectIDs
    }

    public func contains(_ object: ObjectID) -> Bool { objectIDs.contains(object) }
}

public struct ScopeID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

/// How a hypothesis stands.
///
/// Deliberately a different vocabulary from `ConstraintResolution`, because
/// assessing a hypothesis and resolving a constraint are different questions and
/// merging them is how "supported" ends up meaning "true".
///
/// Note what is missing: there is no `true`. `supported` says that something backs
/// the claim, which is not the same as the claim being correct, and the type is
/// built so that "supported is not absolute truth" is the only thing it can say.
public enum HypothesisAssessment: Codable, Hashable, Sendable {
    /// Nobody has said anything about it yet. The default, and the common case.
    case open
    /// Something backs it. Never a claim that it is correct.
    case supported(HypothesisEvidence)
    /// Something argues against it, and the argument is recorded.
    case contradicted(HypothesisEvidence)
    /// Refuted: the thing that would make it true is now known not to hold.
    case refuted(HypothesisEvidence)

    public var evidence: HypothesisEvidence? {
        switch self {
        case .open: return nil
        case .supported(let e), .contradicted(let e), .refuted(let e): return e
        }
    }

    public var isOpen: Bool { self == .open }
}

/// Why a hypothesis stands where it does.
///
/// An observation and an author, as everywhere else in this document. A bare
/// "supported" with nothing behind it is the thing this whole design refuses to
/// store.
public struct HypothesisEvidence: Codable, Hashable, Sendable {
    public var observation: String
    public var by: ActorID
    public var at: Date

    public init(observation: String, by: ActorID, at: Date = Date(timeIntervalSince1970: 0)) {
        self.observation = observation
        self.by = by
        self.at = at
    }
}

/// Whether a constraint is met.
///
/// `notApplicable` is not `satisfied`, and keeping them apart is the point: a
/// constraint that does not apply to this branch has not been met by it, and
/// collapsing the two would let a branch inherit credit it never earned.
public enum ConstraintResolution: Codable, Hashable, Sendable {
    case open
    case satisfied(ResolutionEvidence)
    /// Real, and specifically *not* satisfaction.
    case notApplicable(ResolutionEvidence)

    public var evidence: ResolutionEvidence? {
        switch self {
        case .open: return nil
        case .satisfied(let e), .notApplicable(let e): return e
        }
    }

    public var isSatisfied: Bool {
        if case .satisfied = self { return true }
        return false
    }
}

public struct ResolutionEvidence: Codable, Hashable, Sendable {
    public var observation: String
    public var by: ActorID
    public var at: Date

    public init(observation: String, by: ActorID, at: Date = Date(timeIntervalSince1970: 0)) {
        self.observation = observation
        self.by = by
        self.at = at
    }
}

/// A claim with a scope and a stance: what is asserted, where, and how it stands.
///
/// Hypotheses and constraints share the shape because they share the hard part,
/// which is the scope. They do not share a stance vocabulary, because assessing a
/// hypothesis and resolving a constraint are different acts.
public struct Claim: Codable, Hashable, Sendable, Identifiable {
    public enum Role: String, Codable, Sendable {
        case hypothesis
        case constraint
    }

    public var id: ClaimID
    public var objectID: ObjectID
    public var role: Role
    public var scope: ClaimScope
    /// How a hypothesis stands. Always `.open` for a constraint, which is why the
    /// two roles share a type and not a status.
    public var assessment: HypothesisAssessment
    /// Whether a constraint is met. Always `.open` for a hypothesis.
    public var resolution: ConstraintResolution
    /// Optional: what would count as settling it.
    public var criterion: String?
    /// The branch this claim was made on. Recorded so a claim cannot drift onto
    /// another branch by accident.
    public var branchObjectID: ObjectID?

    /// Whether anybody has taken a position on this claim yet.
    public var isAsserted: Bool {
        switch role {
        case .hypothesis: return assessment != .open
        case .constraint: return resolution != .open
        }
    }

    public init(
        id: ClaimID,
        objectID: ObjectID,
        role: Role,
        scope: ClaimScope,
        assessment: HypothesisAssessment = .open,
        resolution: ConstraintResolution = .open,
        criterion: String? = nil,
        branchObjectID: ObjectID? = nil
    ) {
        self.id = id
        self.objectID = objectID
        self.role = role
        self.scope = scope
        self.assessment = role == .hypothesis ? assessment : .open
        self.resolution = role == .constraint ? resolution : .open
        self.criterion = criterion
        self.branchObjectID = branchObjectID
    }
}

public struct ClaimID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

/// The claims of a document, and what can be concluded from them.
///
/// Every method here narrows. None of them answers "is this true?", because the
/// document cannot know that and the types say so.
public struct ClaimLedger: Codable, Hashable, Sendable {
    public private(set) var claims: [ClaimID: Claim]

    public init(claims: [Claim] = []) {
        self.claims = Dictionary(uniqueKeysWithValues: claims.map { ($0.id, $0) })
    }

    /// Replaces or adds a claim.
    ///
    /// The command layer has already checked the scope and the role, so this only
    /// stores. Keeping the checks out of here means the ledger cannot be talked
    /// into holding a claim the document would have refused.
    public mutating func upsert(_ claim: Claim) {
        claims[claim.id] = claim
    }

    public func claim(_ id: ClaimID) -> Claim? { claims[id] }
    public func allClaims() -> [Claim] { claims.values.sorted { $0.id.rawValue < $1.id.rawValue } }
    public func claims(role: Claim.Role) -> [Claim] {
        allClaims().filter { $0.role == role }
    }

    /// Whether a constraint blocks a given object.
    ///
    /// AC01: it only ever blocks inside its own scope. An open constraint outside
    /// the scope is not a block, it is a remark.
    public func blocks(_ constraint: Claim, object: ObjectID) -> Bool {
        guard constraint.role == .constraint else { return false }
        guard constraint.scope.contains(object) else { return false }
        switch constraint.resolution {
        case .open:
            // An unmet constraint inside its scope is the one case that blocks.
            return true
        case .satisfied, .notApplicable:
            // Met, or not applicable: either way it is not standing in the way.
            // The first version of this only excluded `notApplicable`, so a
            // satisfied constraint kept reporting itself as a block.
            return false
        }
    }

    /// The objects a constraint actually blocks, given what is known.
    public func blockedObjects(for constraint: Claim) -> Set<ObjectID> {
        guard constraint.role == .constraint else { return [] }
        var blocked = constraint.scope.objectIDs
        if case .satisfied = constraint.resolution { blocked = [] }
        return blocked
    }

    /// Claims whose scopes overlap but disagree, which need a person to say which
    /// one they meant.
    ///
    /// The specification asks for precision here rather than propagation. When two
    /// constraints cover partly the same ground and point different ways, the
    /// honest answer is a question, not a rule that silently applies one of them
    /// everywhere.
    public func overlappingScopes() -> [ScopeOverlap] {
        let all = allClaims()
        var found: [ScopeOverlap] = []
        for (i, first) in all.enumerated() {
            for second in all[(i + 1)...] {
                guard first.id != second.id else { continue }
                let shared = first.scope.objectIDs.intersection(second.scope.objectIDs)
                guard shared.isEmpty == false else { continue }
                // Two claims that both say nothing yet are not a conflict: nobody
                // has taken a position, so there is nothing to reconcile. Once
                // somebody has, an overlap needs a person to say which was meant.
                guard first.isAsserted || second.isAsserted else { continue }
                found.append(ScopeOverlap(
                    first: first.id,
                    second: second.id,
                    sharedObjects: shared
                ))
            }
        }
        return found
    }
}

public struct ScopeOverlap: Codable, Hashable, Sendable, Identifiable {
    public var first: ClaimID
    public var second: ClaimID
    public var sharedObjects: Set<ObjectID>

    public var id: String { "\(first.rawValue)|\(second.rawValue)" }

    public init(first: ClaimID, second: ClaimID, sharedObjects: Set<ObjectID>) {
        self.first = first
        self.second = second
        self.sharedObjects = sharedObjects
    }
}
