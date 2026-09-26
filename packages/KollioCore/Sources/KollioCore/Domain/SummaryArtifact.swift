import Foundation

/// A synthesis of part of the document, prepared to be handed to someone.
///
/// ## What a synthesis is, and what it is not
///
/// A `SummaryArtifact` is a **derivative**. It is a reading of the document, not
/// a piece of the document. Nothing here can replace the context it was built
/// from, and nothing here can change it: a synthesis is a projection, exactly
/// like a `Comparison`, and the two refuse the same moves for the same reason.
///
/// Three properties follow from that, and each of them is a refusal:
///
/// 1. **The initial text stays intact.** When a person edits a line, the text the
///    model first produced is kept beside the edit. Without it, "the initial text
///    stays intact" would be a claim nobody could check, and an edit would
///    quietly become indistinguishable from a generation.
/// 2. **An empty section says so.** A template with six headings invites a model
///    to fill six headings. A section with no evidence is recorded as absent
///    rather than padded, so an empty section is visible as a gap in the
///    document rather than hidden as a blank line.
/// 3. **Outdated is not the same as wrong.** When a decision in the read set
///    moves, the synthesis is marked outdated and keeps its text. It is not
///    rewritten, because a silent rewrite would destroy the record of what was
///    known when it was made.
public struct SummaryArtifact: Codable, Hashable, Sendable, Identifiable {
    public var id: SummaryID
    public var title: String

    /// Why this synthesis exists. Not generated: an objective is a purpose, and a
    /// purpose is the person's to state.
    public var objective: SummaryLine
    public var currentState: [SummarySection]
    public var reasons: [SummarySection]
    public var uncertainties: [SummarySection]
    public var nextVerifications: [SummarySection]
    /// The sources this synthesis rests on, with the revision of each. AC03: the
    /// export names the revision used.
    public var sourceRefs: [SummarySourceRef]
    /// What was read, so the synthesis can be checked rather than trusted.
    public var readSet: SummaryReadSet
    /// The document revision this was built from. A synthesis that does not say
    /// which revision it read cannot answer "is this still true?".
    public var baseSemanticRevision: Int
    public var isDraft: Bool
    /// Set when the selection was too wide to read honestly. The synthesis still
    /// exists, and it proposes the narrower scope it would have preferred rather
    /// than summarising everything badly.
    public var proposedNarrowerScope: NarrowerScope?
    public var createdAt: Date

    public init(
        id: SummaryID,
        title: String,
        objective: SummaryLine,
        currentState: [SummarySection] = [],
        reasons: [SummarySection] = [],
        uncertainties: [SummarySection] = [],
        nextVerifications: [SummarySection] = [],
        sourceRefs: [SummarySourceRef] = [],
        readSet: SummaryReadSet,
        baseSemanticRevision: Int,
        isDraft: Bool = true,
        proposedNarrowerScope: NarrowerScope? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.title = title
        self.objective = objective
        self.currentState = currentState
        self.reasons = reasons
        self.uncertainties = uncertainties
        self.nextVerifications = nextVerifications
        self.sourceRefs = sourceRefs
        self.readSet = readSet
        self.baseSemanticRevision = baseSemanticRevision
        self.isDraft = isDraft
        self.proposedNarrowerScope = proposedNarrowerScope
        self.createdAt = createdAt
    }

    public enum Section: String, Codable, Hashable, Sendable, CaseIterable {
        case currentState
        case reasons
        case uncertainties
        case nextVerifications

        public var title: String {
            switch self {
            case .currentState: return "Current state"
            case .reasons: return "Reasons"
            case .uncertainties: return "Uncertainties"
            case .nextVerifications: return "Next verifications"
            }
        }
    }

    public func sections(_ section: Section) -> [SummarySection] {
        switch section {
        case .currentState: return currentState
        case .reasons: return reasons
        case .uncertainties: return uncertainties
        case .nextVerifications: return nextVerifications
        }
    }

    public func settingSections(_ value: [SummarySection], for section: Section) -> SummaryArtifact {
        var copy = self
        switch section {
        case .currentState: copy.currentState = value
        case .reasons: copy.reasons = value
        case .uncertainties: copy.uncertainties = value
        case .nextVerifications: copy.nextVerifications = value
        }
        return copy
    }

    /// Every line, in a stable order, for editing and for export.
    public var allLines: [SummaryLine] {
        [objective] + currentState.flatMap(\.lines) + reasons.flatMap(\.lines)
            + uncertainties.flatMap(\.lines) + nextVerifications.flatMap(\.lines)
    }

    public func line(_ id: SummaryLineID) -> SummaryLine? {
        allLines.first { $0.id == id }
    }

    /// A section that is deliberately empty.
    ///
    /// The distinction is the whole point of AC02. A synthesis with nothing
    /// recorded in *uncertainties* is saying something true and useful: nobody
    /// wrote down what is not known. Collapsing that into an empty list would make
    /// the same state look like a rendering accident.
    public struct SummarySection: Codable, Hashable, Sendable, Identifiable {
        public var id: SummarySectionID
        public var title: String
        public var lines: [SummaryLine]
        /// True when the section is empty on purpose because the document had
        /// nothing to record, as opposed to being empty because nothing was
        /// written yet.
        public var isNothingRecorded: Bool

        public init(
            id: SummarySectionID,
            title: String,
            lines: [SummaryLine] = [],
            isNothingRecorded: Bool = false
        ) {
            self.id = id
            self.title = title
            self.lines = lines
            self.isNothingRecorded = isNothingRecorded
        }

        public init(_ section: SummaryArtifact.Section, lines: [SummaryLine] = [], isNothingRecorded: Bool = false) {
            self.init(
                id: SummarySectionID(rawValue: section.rawValue),
                title: section.title,
                lines: lines,
                isNothingRecorded: isNothingRecorded
            )
        }
    }

    /// One statement in the synthesis.
    public struct SummaryLine: Codable, Hashable, Sendable, Identifiable {
        public var id: SummaryLineID
        public var text: LocalizedText
        /// Where the line came from, and it is not overwritten by editing. A line
        /// the model drafted and the person corrected is *both*, and the record
        /// has to be able to say so.
        public var provenance: Provenance
        /// The text as first produced, kept when `text` is edited. This is what
        /// makes the "initial text stays intact" rule checkable.
        public var originalText: LocalizedText?
        /// Who edited it, when someone did.
        public var editedBy: ActorID?
        /// What the line rests on. A line with no reference is allowed, but only
        /// when it was written by a person: an unreferenced line from a model is
        /// an assertion with nothing behind it.
        public var references: [SummaryReference]

        public init(
            id: SummaryLineID,
            text: LocalizedText,
            provenance: Provenance,
            originalText: LocalizedText? = nil,
            editedBy: ActorID? = nil,
            references: [SummaryReference] = []
        ) {
            self.id = id
            self.text = text
            self.provenance = provenance
            self.originalText = originalText
            self.editedBy = editedBy
            self.references = references
        }

        public var wasEdited: Bool { originalText != nil || editedBy != nil }

        public var isAuthored: Bool { provenance.kind == .human }

        /// An engine line that asserts something and points at nothing. Refused at
        /// construction rather than filtered later, so it cannot be persisted.
        public var isUnsupportedAssertion: Bool {
            provenance.kind != .human && references.isEmpty
        }
    }

    /// A source the synthesis rests on, with the revision that was read.
    public struct SummarySourceRef: Codable, Hashable, Sendable, Identifiable {
        public var id: SummarySourceRefID
        public var sourceID: SourceID
        public var revisionID: SourceRevisionID
        public var isCurrent: Bool

        public init(id: SummarySourceRefID, sourceID: SourceID, revisionID: SourceRevisionID, isCurrent: Bool) {
            self.id = id
            self.sourceID = sourceID
            self.revisionID = revisionID
            self.isCurrent = isCurrent
        }
    }

    /// What was read, sorted before storage. An unsorted read set reshuffles
    /// between runs and makes two identical syntheses look like two different
    /// ones.
    public struct SummaryReadSet: Codable, Hashable, Sendable {
        public var objectIDs: [ObjectID]
        public var sourceRevisionIDs: [SourceRevisionID]
        public var citationIDs: [CitationID]
        public var decisionIDs: [DecisionID]
        /// True when the walk stopped at its bound rather than at the end of the
        /// graph. A truncated read says so instead of pretending to be complete.
        public var wasTruncated: Bool

        public init(
            objectIDs: [ObjectID] = [],
            sourceRevisionIDs: [SourceRevisionID] = [],
            citationIDs: [CitationID] = [],
            decisionIDs: [DecisionID] = [],
            wasTruncated: Bool = false
        ) {
            self.objectIDs = objectIDs
            self.sourceRevisionIDs = sourceRevisionIDs
            self.citationIDs = citationIDs
            self.decisionIDs = decisionIDs
            self.wasTruncated = wasTruncated
        }

        public var isEmpty: Bool {
            objectIDs.isEmpty && sourceRevisionIDs.isEmpty && citationIDs.isEmpty && decisionIDs.isEmpty
        }

        public func sorted() -> SummaryReadSet {
            SummaryReadSet(
                objectIDs: objectIDs.sorted { $0.rawValue < $1.rawValue },
                sourceRevisionIDs: sourceRevisionIDs.sorted { $0.rawValue < $1.rawValue },
                citationIDs: citationIDs.sorted { $0.rawValue < $1.rawValue },
                decisionIDs: decisionIDs.sorted { $0.rawValue < $1.rawValue },
                wasTruncated: wasTruncated
            )
        }
    }

    /// The scope the synthesis would have preferred.
    public struct NarrowerScope: Codable, Hashable, Sendable {
        public var objectIDs: [ObjectID]
        /// Why the wide selection was refused, in words a person can act on.
        public var reason: String

        public init(objectIDs: [ObjectID], reason: String) {
            self.objectIDs = objectIDs
            self.reason = reason
        }
    }
}

/// What a line of a synthesis rests on.
///
/// A synthesis that cites nothing is an essay. The reference is part of the line
/// rather than a property of the section, because a line that was checked
/// against a source and a line that was not are different claims, and a reader
/// has to be able to tell them apart.
public struct SummaryReference: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case object
        case source
        case citation
        case claim
        case decision
        /// A person's own remark. Named apart from `object` so the interface can
        /// say which references open something and which do not.
        case note
    }

    public var kind: Kind
    public var id: String

    public init(kind: Kind, id: String) {
        self.kind = kind
        self.id = id
    }
}

/// Why a synthesis can no longer be trusted to describe the document.
public enum SummaryStaleness: Hashable, Sendable {
    /// A decision in the read set moved: something was decided, revoked or
    /// reopened after this was written.
    case decisionMoved(DecisionID)
    /// The document moved and the read set does not explain by how much.
    case revisionMoved(from: Int, to: Int)
    /// A source it read has a newer revision.
    case sourceRevisionSuperseded(SourceID)
}

extension SummaryArtifact {
    /// Whether this synthesis is still a fair reading, and why not when it is not.
    ///
    /// A decision counts as moving when it touches an object that was read and it
    /// is not itself in the read set. That is the narrow, checkable version of
    /// "outdated when decisions move": a decision about something else entirely
    /// does not make this synthesis outdated, and a synthesis that went stale on
    /// every edit would be ignored.
    public func staleness(against document: KollioDocument) -> [SummaryStaleness] {
        var found: [SummaryStaleness] = []
        let readObjects = Set(readSet.objectIDs)
        let readDecisions = Set(readSet.decisionIDs)

        for decision in document.decisions.values.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            guard readObjects.contains(decision.targetObjectID) else { continue }
            guard !readDecisions.contains(decision.id) else { continue }
            found.append(.decisionMoved(decision.id))
        }

        let readRevisions = Set(readSet.sourceRevisionIDs)
        for source in document.sources.sources.values.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            let current = source.revisions.last?.id
            guard let current else { continue }
            if readRevisions.contains(current) { continue }
            // Only a source that was read can supersede one that was read.
            guard readRevisions.contains(where: { $0.rawValue.hasPrefix(source.id.rawValue) }) else { continue }
            found.append(.sourceRevisionSuperseded(source.id))
        }

        if document.semanticRevision != baseSemanticRevision, found.isEmpty {
            found.append(.revisionMoved(from: baseSemanticRevision, to: document.semanticRevision))
        }
        return found
    }

    /// Whether this synthesis is still a fair reading of the current document.
    ///
    /// A method taking the document rather than a stored flag, on purpose. A
    /// boolean that had to be recomputed and persisted is a boolean that will
    /// eventually be forgotten, and a synthesis that reports itself as current
    /// after a decision moved is worse than one that admits it is not.
    public func isOutdated(against document: KollioDocument) -> Bool {
        !staleness(against: document).isEmpty
    }
}

/// The syntheses held by one document.
///
/// Part of the document for the same reason the comparison ledger is: a
/// synthesis is a record of what was read and what was concluded from it, and it
/// has to outlive the session that produced it. A deliverable that evaporates on
/// quit is not a deliverable.
public struct SummaryLedger: Codable, Hashable, Sendable {
    public private(set) var summaries: [SummaryID: SummaryArtifact]

    public init(summaries: [SummaryArtifact] = []) {
        self.summaries = Dictionary(uniqueKeysWithValues: summaries.map { ($0.id, $0) })
    }

    public func summary(_ id: SummaryID) -> SummaryArtifact? { summaries[id] }
    public func all() -> [SummaryArtifact] {
        summaries.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public mutating func upsert(_ summary: SummaryArtifact) {
        summaries[summary.id] = summary
    }

    public mutating func remove(_ id: SummaryID) {
        summaries.removeValue(forKey: id)
    }
}

public struct SummaryID: Hashable, Sendable, Codable, CustomStringConvertible {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ seed: String) { self.rawValue = "summary_\(seed)" }
    public var idString: String { rawValue }
    public var description: String { rawValue }
}

public struct SummaryLineID: Hashable, Sendable, Codable, CustomStringConvertible {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ seed: String) { self.rawValue = "line_\(seed)" }
    public var idString: String { rawValue }
    public var description: String { rawValue }
}

public struct SummarySectionID: Hashable, Sendable, Codable, CustomStringConvertible {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var idString: String { rawValue }
    public var description: String { rawValue }
}

public struct SummarySourceRefID: Hashable, Sendable, Codable, CustomStringConvertible {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ seed: String) { self.rawValue = "summaryref_\(seed)" }
    public var idString: String { rawValue }
    public var description: String { rawValue }
}
