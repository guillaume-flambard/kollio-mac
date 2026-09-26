import Foundation

/// A question intelligence asked, and the state of the answer.
///
/// AI-04 is explicit that this is "a local question and an attached input" and
/// "No chat". A transcript is not the source of truth here, so this type holds no
/// history of exchanges: it holds the question, the answer, and whether the
/// uncertainty is still standing.
///
/// Three states, and the third is the one that matters:
/// - `open`: asked, not answered.
/// - `answered`: a person said something.
/// - `unknown`: a person said they do not know.
///
/// `unknown` is not a weaker `answered`. Collapsing them is how uncertainty gets
/// quietly upgraded into a fact: the next reader sees text where there is none.
public struct Clarification: Codable, Hashable, Sendable, Identifiable {
    public var id: ClarificationID
    /// The request that asked. A question is always attributable to something, so it
    /// can be re-asked or superseded rather than floating.
    public var originatingRequestId: String
    /// The object the question is about. The answer is attached to this, so the
    /// document knows what the answer was about even if the question is later gone.
    public var objectID: ObjectID
    public var question: LocalizedText
    public var state: State
    public var askedAt: Date

    public enum State: Codable, Hashable, Sendable {
        case open
        case answered(ClarificationAnswer)
        /// "I don't know", said on purpose. Not an empty answer and not a failure.
        case unknown(String)

        public var isOpen: Bool { self == .open }

        /// The text of the answer, or nil when there is none. `unknown` returns nil
        /// on purpose: it is not an answer to anything.
        public var answerText: String? {
            switch self {
            case .open, .unknown: return nil
            case .answered(let answer): return answer.text
            }
        }
    }

    public init(
        id: ClarificationID,
        originatingRequestId: String,
        objectID: ObjectID,
        question: LocalizedText,
        state: State = .open,
        askedAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.originatingRequestId = originatingRequestId
        self.objectID = objectID
        self.question = question
        self.state = state
        self.askedAt = askedAt
    }

    /// A question asked against a document that has since changed.
    ///
    /// The question is not deleted and the answer is not discarded. It stops being
    /// the current thing to answer, which is a different and much smaller claim.
    public func superseded(because: String) -> Clarification {
        var copy = self
        copy.isObsolete = true
        copy.obsoleteReason = because
        return copy
    }

    /// Set when the document moved on. Kept as flags rather than as a fourth state
    /// so an obsolete question still carries whatever was already answered.
    public var isObsolete: Bool = false
    public var obsoleteReason: String?
}

public struct ClarificationID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
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

/// An answer a person gave, kept with its author and the moment it was given.
public struct ClarificationAnswer: Codable, Hashable, Sendable {
    public var text: String
    public var by: ActorID
    public var at: Date

    public init(text: String, by: ActorID, at: Date = Date(timeIntervalSince1970: 0)) {
        self.text = text
        self.by = by
        self.at = at
    }
}

/// The questions of a document.
public struct ClarificationLedger: Codable, Hashable, Sendable {
    public private(set) var clarifications: [ClarificationID: Clarification]

    public init(clarifications: [Clarification] = []) {
        self.clarifications = Dictionary(uniqueKeysWithValues: clarifications.map { ($0.id, $0) })
    }

    public func clarification(_ id: ClarificationID) -> Clarification? { clarifications[id] }

    public func all() -> [Clarification] {
        clarifications.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    /// The question attached to an object that still needs answering.
    public func open(for objectID: ObjectID) -> Clarification? {
        all().first { $0.objectID == objectID && $0.state.isOpen && $0.isObsolete == false }
    }

    public func all(for objectID: ObjectID) -> [Clarification] {
        all().filter { $0.objectID == objectID }
    }

    public mutating func upsert(_ clarification: Clarification) {
        clarifications[clarification.id] = clarification
    }
}
