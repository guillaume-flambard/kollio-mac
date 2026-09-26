import Foundation

/// A comparison of several directions, criterion by criterion.
///
/// AI-05, in one sentence: "Compare directions **without inventing scores**." The
/// whole design of this file is what that costs when you refuse to let a program
/// have an opinion:
///
/// - **A number needs a measure.** `Criterion.measure` is required for a cell to
///   hold a number, and the command layer refuses one that does not. A rating
///   without a measure is an opinion wearing a decimal point.
/// - **A missing value is a value.** `Cell.Value.notRecorded` is a first-class
///   state, so "we do not know" is never rendered as a zero, and a column of
///   unknowns can never be mistaken for a column of bad results.
/// - **A total is arithmetic or it is nothing.** `total(for:)` returns a number
///   only when *every* criterion that could contribute has both a measure and a
///   weight the person typed. There is no default weight, no averaging of whatever
///   happens to be present, and no global score to compare across comparisons.
/// - **Every cell keeps what it rests on.** `Cell.references` is part of the cell,
///   so a comparison cannot be read without also being able to check it, which is
///   AC02.
/// - **Keeping one direction deletes nothing.** `keptDirectionIDs` is a list, not a
///   pointer, and the other directions stay in the comparison with their cells
///   intact, which is AC03.
public struct Comparison: Codable, Hashable, Sendable, Identifiable {
    public var id: ComparisonID
    public var title: String
    /// The directions being compared, in the order the person put them in.
    public var directionIDs: [ObjectID]
    public var criteria: [Criterion]
    public var cells: [Cell]
    /// Explicit, cumulative and reversible. Never a single pointer: a comparison
    /// that could only remember one kept direction would make the act of keeping
    /// destructive, which is precisely what AC03 forbids.
    public var keptDirectionIDs: [ObjectID]
    /// True until the person confirms the criteria.
    ///
    /// A draft is a proposal *inside* the document rather than a ghost branch,
    /// because criteria are not new objects: they are the question the comparison
    /// asks. A draft accepts no cell at all, so a criterion nobody has agreed to
    /// can never hold a value.
    public var isDraft: Bool
    public var createdAt: Date

    public init(
        id: ComparisonID,
        title: String,
        directionIDs: [ObjectID],
        criteria: [Criterion] = [],
        cells: [Cell] = [],
        keptDirectionIDs: [ObjectID] = [],
        isDraft: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.title = title
        self.directionIDs = directionIDs
        self.criteria = criteria
        self.cells = cells
        self.keptDirectionIDs = keptDirectionIDs
        self.isDraft = isDraft
        self.createdAt = createdAt
    }

    public func criterion(_ id: CriterionID) -> Criterion? {
        criteria.first { $0.id == id }
    }

    /// The cell for one criterion and one direction, if one has been recorded.
    public func cell(criterion: CriterionID, direction: ObjectID) -> Cell? {
        cells.first { $0.criterionID == criterion && $0.directionID == direction }
    }

    public func cells(for direction: ObjectID) -> [Cell] {
        criteria.compactMap { cell(criterion: $0.id, direction: direction) }
    }

    public func isKept(_ direction: ObjectID) -> Bool {
        keptDirectionIDs.contains(direction)
    }

    /// The total for one direction, or nil when the comparison does not define one.
    ///
    /// A number appears only when every criterion that could contribute carries
    /// both a measure and a weight, and the direction has a recorded number for
    /// each of them. A single missing cell, a single unweighted criterion or a
    /// single unconfirmed criterion is enough to make the answer "not defined",
    /// because a total over a subset of the criteria is a different claim from a
    /// total over the criteria.
    public func total(for direction: ObjectID) -> Double? {
        guard isDraft == false, criteria.isEmpty == false else { return nil }
        var sum = 0.0
        for criterion in criteria {
            guard let measure = criterion.measure, let weight = criterion.weight else { return nil }
            // The sign is the measure's own: comparing on "lower is better" by
            // adding a bigger number would reward the worse direction.
            let raw: Double
            switch cell(criterion: criterion.id, direction: direction)?.value {
            case .number(let value): raw = value
            default: return nil
            }
            sum += (measure.higherIsBetter ? raw : -raw) * weight
        }
        return sum
    }

    /// Whether a total is defined for every direction, which is the only state in
    /// which showing one row of totals is honest.
    public var hasDefinedTotals: Bool {
        criteria.isEmpty == false && directionIDs.allSatisfy { total(for: $0) != nil }
    }

    /// What has changed underneath this comparison since a cell was recorded.
    ///
    /// Derived rather than flagged, because a flag can only be set by something
    /// remembering to set it. This walks the references the cells actually carry
    /// and reports what moved, so a comparison cannot quietly present a check that
    /// was made against a different object than the one now on the canvas.
    public func reviewFindings(in document: KollioDocument) -> [ComparisonReviewFinding] {
        var findings: [ComparisonReviewFinding] = []
        for cell in cells {
            for reference in cell.references {
                switch reference.kind {
                case .object:
                    // Handled by `movedReferences`, which compares the fingerprint
                    // this cell recorded rather than guessing what "changed" means.
                    continue
                case .citation:
                    guard let citation = document.sources.citation(CitationID(reference.id)) else {
                        findings.append(.init(cell: cell, reason: .referenceGone, detail: reference.id))
                        continue
                    }
                    if !citation.status.isVerified {
                        findings.append(.init(cell: cell, reason: .evidenceMoved, detail: reference.id))
                    }
                case .source:
                    let source = document.sources.source(SourceID(reference.id))
                    if source == nil {
                        findings.append(.init(cell: cell, reason: .referenceGone, detail: reference.id))
                    } else if let recorded = cell.referenceRevisions[reference.id],
                              source?.latest?.id != recorded {
                        findings.append(.init(cell: cell, reason: .evidenceMoved, detail: reference.id))
                    }
                case .claim, .note:
                    break
                }
            }
            if let moved = cell.movedReferences(in: document) {
                findings.append(contentsOf: moved)
            }
        }
        return findings
    }

    /// The single reason to look again, or nil.
    public func needsReview(in document: KollioDocument) -> ComparisonReviewReason? {
        let first: ComparisonReviewFinding? = reviewFindings(in: document).first
        guard let first else { return nil }
        return ComparisonReviewReason(rawValue: first.reason.rawValue)
    }
}

public struct ComparisonID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

public struct CriterionID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

/// What a number would have to be measured against.
///
/// Required before a criterion may hold a number, and never inferred. `unit` is a
/// word the person wrote, not a conversion: this document does not know that a
/// "day" is a fifth of a "week", and pretending otherwise is how two directions end
/// up compared on numbers that were never the same number.
public struct Measure: Codable, Hashable, Sendable {
    public var unit: String
    /// Which direction of the number is better. Stated rather than guessed: a
    /// criterion called "cost" with `higherIsBetter` left out is the most common way
    /// a comparison ends up recommending the expensive option.
    public var higherIsBetter: Bool

    public init(unit: String, higherIsBetter: Bool) {
        self.unit = unit
        self.higherIsBetter = higherIsBetter
    }
}

public struct Criterion: Codable, Hashable, Sendable, Identifiable {
    public var id: CriterionID
    public var title: String
    /// Nil means this criterion is judged in words, not in numbers. A cell for it
    /// may hold text and may **not** hold a number.
    public var measure: Measure?
    /// Nil means "unweighted". There is no default: a weight nobody typed is not a
    /// weight of one, it is an absent one, and `total(for:)` refuses to add it up.
    public var weight: Double?

    public init(id: CriterionID, title: String, measure: Measure? = nil, weight: Double? = nil) {
        self.id = id
        self.title = title
        self.measure = measure
        self.weight = weight
    }
}

/// What one cell of the comparison says, and what it rests on.
public struct Cell: Codable, Hashable, Sendable, Identifiable {
    /// Written by hand rather than synthesised, because the synthesised form for an
    /// enum with associated values is `{"number":{"_0":3}}`, and the whole point of
    /// this format is that a person can read it. The file says which kind of value
    /// it is and what it is:
    ///
    ///     "value": { "kind": "number", "value": 3 }
    ///     "value": { "kind": "text", "value": "brittle" }
    ///     "value": { "kind": "notRecorded" }
    public enum Value: Codable, Hashable, Sendable {
        /// Nobody has recorded this. A real state, not an error and not a zero.
        case notRecorded
        /// Only reachable when the criterion has a measure.
        case number(Double)
        case text(String)

        public enum Kind: String, Codable, Sendable {
            case notRecorded
            case number
            case text
        }

        public var kind: Kind {
            switch self {
            case .notRecorded: return .notRecorded
            case .number: return .number
            case .text: return .text
            }
        }

        private enum CodingKeys: String, CodingKey {
            case kind, value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch try container.decode(Kind.self, forKey: .kind) {
            case .notRecorded:
                self = .notRecorded
            case .number:
                self = .number(try container.decode(Double.self, forKey: .value))
            case .text:
                self = .text(try container.decode(String.self, forKey: .value))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            switch self {
            case .notRecorded: break
            case .number(let value): try container.encode(value, forKey: .value)
            case .text(let value): try container.encode(value, forKey: .value)
            }
        }

        public var number: Double? {
            if case .number(let value) = self { return value }
            return nil
        }

        public var text: String? {
            if case .text(let value) = self { return value }
            return nil
        }

        public var isRecorded: Bool {
            if case .notRecorded = self { return false }
            return true
        }
    }

    public var criterionID: CriterionID
    public var directionID: ObjectID
    public var value: Value
    /// What this cell rests on. Part of the cell, not beside it, so a comparison
    /// cannot be read without also being able to check it.
    public var references: [ComparisonReference]
    /// The revision each source reference was read against, so a cell whose source
    /// has moved on is detectable without re-reading anything.
    public var referenceRevisions: [String: SourceRevisionID]
    public var note: String?
    public var recordedBy: ActorID
    public var recordedAt: Date
    /// The semantic fingerprint of each referenced object at the moment the cell was
    /// recorded. A cell that referenced text which has since been edited is a cell
    /// about a different sentence, and that is what "a change marks the comparison
    /// needsReview" is really about.
    public var referenceFingerprints: [String: String]

    public var id: String { "\(criterionID.rawValue)|\(directionID.rawValue)" }

    public init(
        criterionID: CriterionID,
        directionID: ObjectID,
        value: Value,
        references: [ComparisonReference] = [],
        referenceRevisions: [String: SourceRevisionID] = [:],
        note: String? = nil,
        recordedBy: ActorID,
        recordedAt: Date = Date(timeIntervalSince1970: 0),
        referenceFingerprints: [String: String] = [:]
    ) {
        self.criterionID = criterionID
        self.directionID = directionID
        self.value = value
        self.references = references
        self.referenceRevisions = referenceRevisions
        self.note = note
        self.recordedBy = recordedBy
        self.recordedAt = recordedAt
        self.referenceFingerprints = referenceFingerprints
    }

    /// The references whose object has changed since this cell was recorded.
    func movedReferences(in document: KollioDocument) -> [ComparisonReviewFinding]? {
        var findings: [ComparisonReviewFinding] = []
        for (id, fingerprint) in referenceFingerprints {
            let object = document.object(ObjectID(id))
            if object == nil {
                findings.append(.init(cell: self, reason: .referenceGone, detail: id))
            } else if document.semanticFingerprint(for: [ObjectID(id)]) != fingerprint {
                findings.append(.init(cell: self, reason: .referencedObjectChanged, detail: id))
            }
        }
        return findings.isEmpty ? nil : findings
    }
}

/// One thing a cell rests on.
public struct ComparisonReference: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case citation
        case claim
        case source
        case object
        /// A person's own remark, recorded as text. Named apart from `object` so
        /// the interface can say which references can be opened and which cannot.
        case note
    }

    public var kind: Kind
    public var id: String

    public init(kind: Kind, id: String) {
        self.kind = kind
        self.id = id
    }
}

public struct ComparisonReviewFinding: Hashable, Sendable {
    public enum Reason: String, Sendable {
        /// The object a cell was recorded against is not in the document.
        case referenceGone
        /// The object a cell was recorded against has been edited since.
        case referencedObjectChanged
        /// The source behind a cell has a newer revision, or its citation is no
        /// longer verified.
        case evidenceMoved
    }

    public var cell: Cell
    public var reason: Reason
    /// The identifier the finding is about, so the interface can say which one.
    public var detail: String

    public init(cell: Cell, reason: Reason, detail: String) {
        self.cell = cell
        self.reason = reason
        self.detail = detail
    }
}

public enum ComparisonReviewReason: String, Hashable, Sendable {
    case referenceGone
    case referencedObjectChanged
    case evidenceMoved

    public init?(_ finding: ComparisonReviewFinding) {
        self.init(rawValue: finding.reason.rawValue)
    }
}

/// The comparisons of a document.
public struct ComparisonLedger: Codable, Hashable, Sendable {
    public private(set) var comparisons: [ComparisonID: Comparison]

    public init(comparisons: [Comparison] = []) {
        self.comparisons = Dictionary(uniqueKeysWithValues: comparisons.map { ($0.id, $0) })
    }

    public func comparison(_ id: ComparisonID) -> Comparison? { comparisons[id] }
    public func all() -> [Comparison] {
        comparisons.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public mutating func upsert(_ comparison: Comparison) {
        comparisons[comparison.id] = comparison
    }
}
