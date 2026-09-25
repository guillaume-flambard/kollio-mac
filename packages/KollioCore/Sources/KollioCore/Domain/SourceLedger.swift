import Foundation

/// A resource the person brought, held as a **reference** rather than a copy.
///
/// The bytes stay where the person put them. Kollio records how to find them, what
/// was extracted, and which revision a claim was read against, so that a claim can
/// be re-checked later against the thing it was actually based on. Copying the
/// file into the document would duplicate the user's data and create a second copy
/// free to disagree with the first.
public struct SourceReference: Codable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case text
        case markdown
        case pdf
        case csv
        case image
        /// A pasted link. Creating one fetches nothing: a URL typed by a person is
        /// a pointer, and quietly downloading it would be the app reaching out
        /// without being asked.
        case link
        case other
    }

    /// What the app could actually get out of the resource. This is deliberately
    /// not a promise: an image-only PDF is `noText`, and saying so is more useful
    /// than an empty document pretending to be a successful import.
    public enum Extraction: Codable, Hashable, Sendable {
        case notAttempted
        case pending
        case ready(text: String)
        case partial(text: String, reason: String)
        case noText(reason: String)
        case unsupported(reason: String)
        case missing(reason: String)

        public var text: String? {
            switch self {
            case .ready(let text), .partial(let text, _): return text
            default: return nil
            }
        }

        public var isUsable: Bool { text != nil }
    }

    public var id: SourceID
    public var kind: Kind
    public var title: String
    /// Where the resource actually is. Never a copy of it.
    public var locator: String
    public var revisions: [SourceRevision]
    public var createdAt: Date

    public init(
        id: SourceID,
        kind: Kind,
        title: String,
        locator: String,
        revisions: [SourceRevision] = [],
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.locator = locator
        self.revisions = revisions
        self.createdAt = createdAt
    }

    /// The revision a new citation should be read against.
    ///
    /// This is the last *usable* revision when there is one, and the last recorded
    /// attempt otherwise. A failed import is kept in the history and is not this, so
    /// "read against the current version" and "the most recent thing that happened"
    /// do not quietly become the same thing.
    public var latest: SourceRevision? {
        revisions.last(where: { $0.extraction.isUsable }) ?? revisions.last
    }

    /// Every attempt, including the ones that produced nothing.
    public var attempts: [SourceRevision] { revisions }

    /// What the chip on the canvas says about this source: importing, ready,
    /// partial, unsupported, missing, or simply not read yet. A source with no
    /// revision is `notAttempted`, which is the honest state for a link or an
    /// image that nobody has asked to be understood.
    public var extraction: Extraction { latest?.extraction ?? .notAttempted }

    /// The revision a pinned object stays on. A source can be pinned to an older
    /// revision on purpose, and an update to the source does not move it.
    public func revision(_ id: SourceRevisionID) -> SourceRevision? {
        revisions.first { $0.id == id }
    }
}

public struct SourceID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

public struct SourceRevisionID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

/// One state of a source, as it was read.
///
/// History is kept rather than overwritten, because a claim that was based on an
/// earlier version of a file must stay checkable against that version even after
/// the file changes. This is the difference between "the source was updated" and
/// "we quietly moved your citation to a new line number".
public struct SourceRevision: Codable, Hashable, Sendable, Identifiable {
    public var id: SourceRevisionID
    public var sequence: Int
    public var importedAt: Date
    public var extraction: SourceReference.Extraction
    /// A digest of what was read. It is how a person is told "this is not the text
    /// your claim was based on" without the app claiming to understand the file.
    public var digest: String

    public init(
        id: SourceRevisionID,
        sequence: Int,
        importedAt: Date = Date(timeIntervalSince1970: 0),
        extraction: SourceReference.Extraction,
        digest: String
    ) {
        self.id = id
        self.sequence = sequence
        self.importedAt = importedAt
        self.extraction = extraction
        self.digest = digest
    }
}

/// A place inside a revision: page, line, or a range.
public struct SourceLocator: Codable, Hashable, Sendable {
    public var page: Int?
    public var lineRange: Range<Int>?

    public init(page: Int? = nil, lineRange: Range<Int>? = nil) {
        self.page = page
        self.lineRange = lineRange
    }

    public var isEmpty: Bool { page == nil && lineRange == nil }
}

/// What checking a claim produced.
///
/// There is no case for "verified" without an observation and an author. A badge
/// that a program can set by itself is a badge that means nothing, so the type
/// makes the honest states expressible and the dishonest one awkward.
public enum VerificationStatus: Codable, Hashable, Sendable {
    /// Nobody has checked it. This is the default and the most common state.
    case unverified
    /// Checked, with what was observed and by whom.
    case verified(observation: String, by: ActorID, at: Date)
    /// The source moved under it: the citation still points at the revision it was
    /// made against, and the claim now needs looking at again.
    case needsReview(reason: String)
    /// The source is gone. The claim stays, marked, rather than disappearing with
    /// the file.
    case sourceMissing(reason: String)

    public var isVerified: Bool {
        if case .verified = self { return true }
        return false
    }
}

/// A claim attached to an exact place in an exact revision.
public struct Citation: Codable, Hashable, Sendable, Identifiable {
    public var id: CitationID
    /// The claim in the document this citation supports. It is part of the citation
    /// rather than of the command that created it, because the pairing has to
    /// survive: a citation whose claim is only known at the moment it is made cannot
    /// later answer "what is this object based on".
    public var claimID: ObjectID
    public var sourceID: SourceID
    /// The revision this was read against. Immutable on purpose: see `SourceRevision`.
    public var revisionID: SourceRevisionID
    public var locator: SourceLocator
    public var quote: String
    public var status: VerificationStatus
    public var recordedAt: Date

    public init(
        id: CitationID,
        claimID: ObjectID,
        sourceID: SourceID,
        revisionID: SourceRevisionID,
        locator: SourceLocator,
        quote: String,
        status: VerificationStatus = .unverified,
        recordedAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.claimID = claimID
        self.sourceID = sourceID
        self.revisionID = revisionID
        self.locator = locator
        self.quote = quote
        self.status = status
        self.recordedAt = recordedAt
    }

    /// Verification is a claim about an observation, so it needs one.
    public func verified(observation: String, by: ActorID, at: Date = Date(timeIntervalSince1970: 0)) -> Citation {
        var copy = self
        copy.status = .verified(observation: observation, by: by, at: at)
        return copy
    }
}

public struct CitationID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

/// The sources of a document, and the citations made from them.
///
/// This is the whole of CTX-02, CTX-03 and CTX-07 as far as the domain is
/// concerned. Two rules are enforced here rather than left to the interface:
///
/// - **A citation is never silently moved.** A new revision marks what depends on
///   the old one as needing review; it does not re-point the citation.
/// - **Losing a source does not lose the claim.** A removed or missing source
///   changes a citation's status, and the object that carried the claim keeps it.
public struct SourceLedger: Codable, Hashable, Sendable {
    public private(set) var sources: [SourceID: SourceReference]
    public private(set) var citations: [CitationID: Citation]

    public init(
        sources: [SourceReference] = [],
        citations: [Citation] = []
    ) {
        self.sources = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })
        self.citations = Dictionary(uniqueKeysWithValues: citations.map { ($0.id, $0) })
    }

    // MARK: Adding and importing

    /// Registers a reference. Nothing is read: a link stays a link, and an image
    /// is not understood until a person asks for it to be.
    public mutating func add(_ source: SourceReference) {
        sources[source.id] = source
    }

    /// Records a newly imported revision and marks what it affects.
    ///
    /// Two rules pull in opposite directions here, and both come from the
    /// specification:
    ///
    /// - CTX-02 wants a chip that can say `noText` or `unsupported`, which means the
    ///   attempt has to be **recorded**. Refusing to store it would leave the chip
    ///   with nothing honest to show.
    /// - CTX-07 wants a failed extraction to leave the good version active, so a
    ///   broken import cannot quietly replace the text a claim was based on.
    ///
    /// Both hold if the attempt is always kept and only *currentness* is decided
    /// separately: a revision that produced no text becomes the current one only
    /// when there is nothing usable before it. On a source read once successfully,
    /// a later scan replaces nothing.
    @discardableResult
    public mutating func importRevision(
        _ revision: SourceRevision,
        for sourceID: SourceID
    ) -> SourceImportOutcome {
        guard var source = sources[sourceID] else {
            return .rejected(.unknownSource)
        }
        let previousLatest = source.latest
        let previousUsable = previousLatest?.extraction.isUsable ?? false
        let becomesCurrent = revision.extraction.isUsable || previousUsable == false

        source.revisions.append(revision)
        sources[sourceID] = source

        // Citations made against a revision that is no longer the one being read now
        // keep pointing where they always pointed, and are flagged instead of moved.
        // Only a revision that actually became current can supersede another.
        var flagged: [CitationID] = []
        if becomesCurrent, let previousLatest, previousUsable {
            for (id, citation) in citations
            where citation.sourceID == sourceID
                && citation.revisionID == previousLatest.id {
                var updated = citation
                updated.status = .needsReview(
                    reason: "the source has a newer revision (\(revision.id.rawValue))"
                )
                citations[id] = updated
                flagged.append(id)
            }
        }
        return .imported(
            revision: revision,
            previousLatest: previousLatest,
            needsReview: flagged,
            becameCurrent: becomesCurrent
        )
    }

    public enum SourceImportOutcome: Hashable, Sendable {
        case imported(
            revision: SourceRevision,
            previousLatest: SourceRevision?,
            needsReview: [CitationID],
            /// False when the attempt was recorded but a usable earlier revision
            /// stays the one being read.
            becameCurrent: Bool
        )
        case rejected(SourceImportRejection)
    }

    /// The only way an import is refused is a source that is not there. A file that
    /// could not be read is not a rejection: it is a recorded attempt that did not
    /// become the current version, which is a different and more useful thing.
    public enum SourceImportRejection: Hashable, Sendable {
        case unknownSource
    }

    // MARK: Citing

    /// Attaches a claim to a place in a revision.
    ///
    /// A citation towards a source or a revision that is not there is refused
    /// rather than created broken: a reference to nothing is worse than no
    /// reference, because it looks like evidence.
    public mutating func cite(_ citation: Citation) -> Result<CitationID, CitationRejection> {
        guard let source = sources[citation.sourceID] else {
            return .failure(.unknownSource(citation.sourceID))
        }
        guard source.revision(citation.revisionID) != nil else {
            return .failure(.unknownRevision(citation.revisionID))
        }
        citations[citation.id] = citation
        return .success(citation.id)
    }

    public enum CitationRejection: Error, Hashable, Sendable {
        case unknownSource(SourceID)
        case unknownRevision(SourceRevisionID)
        case unknownCitation(CitationID)
    }

    // MARK: Losing a source

    /// Marks every citation of a source as needing review, without deleting any of
    /// them. The claim a person wrote stays in the document; what changes is that
    /// it can no longer be checked silently.
    @discardableResult
    public mutating func markSourceUnavailable(_ sourceID: SourceID, reason: String) -> [CitationID] {
        var affected: [CitationID] = []
        for (id, citation) in citations where citation.sourceID == sourceID {
            var updated = citation
            if case .verified = citation.status {
                // A verification is a record of an observation that really happened.
                // It is not erased by a file moving; it is flagged as needing a
                // look, because the thing observed may no longer be there.
                updated.status = .needsReview(reason: reason)
            } else {
                updated.status = .sourceMissing(reason: reason)
            }
            citations[id] = updated
            affected.append(id)
        }
        return affected
    }

    /// Removing a source keeps its revisions. The history of what a claim was based
    /// on is the point; deleting it would leave a citation pointing at nothing.
    public mutating func removeSourceKeepingHistory(_ sourceID: SourceID) {
        citations = citations.mapValues { citation in
            guard citation.sourceID == sourceID else { return citation }
            var updated = citation
            updated.status = .sourceMissing(reason: "the source was removed")
            return updated
        }
    }

    // MARK: Reading

    /// Records that a person checked a citation, with what they saw.
    ///
    /// This is a method rather than a settable field because verification is a
    /// claim about an observation. Making it something any caller can write also
    /// makes it something any caller can write carelessly, and a badge with no
    /// observation behind it is exactly the thing this whole type refuses to
    /// express.
    @discardableResult
    public mutating func recordVerification(
        _ citationID: CitationID,
        observation: String,
        by: ActorID,
        at: Date = Date(timeIntervalSince1970: 0)
    ) -> Result<CitationID, CitationRejection> {
        guard var citation = citations[citationID] else {
            return .failure(.unknownCitation(citationID))
        }
        citation = citation.verified(observation: observation, by: by, at: at)
        citations[citationID] = citation
        return .success(citationID)
    }

    public func source(_ id: SourceID) -> SourceReference? { sources[id] }
    public func citation(_ id: CitationID) -> Citation? { citations[id] }
    /// Sorted by identifier so that a listing is stable between runs. A dictionary
    /// has no order, and an interface that reshuffles a list of citations on every
    /// redraw makes the list impossible to read.
    /// The citations that support one claim, which is what an object shows.
    public func citations(supporting claim: ObjectID) -> [Citation] {
        citations.values
            .filter { $0.claimID == claim }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func citations(of source: SourceID) -> [Citation] {
        citations.values
            .filter { $0.sourceID == source }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func allCitations() -> [Citation] {
        citations.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }
}
