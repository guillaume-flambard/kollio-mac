import Foundation

/// A patch proposed by an intelligence source, never a replacement document.
public struct Proposal: Codable, Hashable, Sendable, Identifiable {
    public var id: String { proposalId }
    public var proposalId: String
    public var requestId: String
    public var documentId: String
    public var baseSemanticRevision: Int
    public var summary: LocalizedText
    public var rationale: LocalizedText?
    public var operations: [Command]
    public var placementHints: [PlacementHint]
    public var limitations: [LocalizedText]
    public var generator: Generator

    public struct Generator: Codable, Hashable, Sendable {
        public var name: String
        public var model: String?
        public var deterministic: Bool

        public init(name: String, model: String? = nil, deterministic: Bool) {
            self.name = name
            self.model = model
            self.deterministic = deterministic
        }
    }

    /// Where an object should appear, relative to its semantic parent. The
    /// generator expresses intent, never pixels.
    public struct PlacementHint: Codable, Hashable, Sendable {
        public var objectID: ObjectID
        public var relativeTo: ObjectID?
        public var offsetX: Double
        public var offsetY: Double

        public init(objectID: ObjectID, relativeTo: ObjectID? = nil, offsetX: Double = 0, offsetY: Double = 160) {
            self.objectID = objectID
            self.relativeTo = relativeTo
            self.offsetX = offsetX
            self.offsetY = offsetY
        }
    }

    public init(
        proposalId: String,
        requestId: String,
        documentId: String,
        baseSemanticRevision: Int,
        summary: LocalizedText,
        rationale: LocalizedText? = nil,
        operations: [Command] = [],
        placementHints: [PlacementHint] = [],
        limitations: [LocalizedText] = [],
        generator: Generator
    ) {
        self.proposalId = proposalId
        self.requestId = requestId
        self.documentId = documentId
        self.baseSemanticRevision = baseSemanticRevision
        self.summary = summary
        self.rationale = rationale
        self.operations = operations
        self.placementHints = placementHints
        self.limitations = limitations
        self.generator = generator
    }

    /// Object ids the proposal depends on. A document that changed any of them
    /// since `baseSemanticRevision` makes the proposal stale.
    public var readSet: Set<ObjectID> {
        var ids: Set<ObjectID> = []
        for operation in operations {
            switch operation {
            case .addRelationship(let add):
                ids.insert(add.from)
                ids.insert(add.to)
            case .removeRelationship(let remove):
                if let from = documentRelationshipTarget(remove.id) { ids.insert(from) }
            case .updateObjectText(let update):
                ids.insert(update.id)
            case .recordDecision(let decision):
                ids.insert(decision.targetObjectID)
            case .applyProposal(let nested):
                ids.formUnion(nested.proposal.readSet)
            default:
                break
            }
        }
        return ids
    }

    private func documentRelationshipTarget(_ id: RelationshipID) -> ObjectID? {
        // Relationship targets are resolved by ProposalValidator against the live
        // document; the static read set only covers object-level dependencies.
        nil
    }
}

public struct ProposalRequest: Codable, Hashable, Sendable, Identifiable {
    public var id: String { requestId }
    public var requestId: String
    public var documentId: String
    public var baseSemanticRevision: Int
    public var intent: Intent
    public var targetIds: [ObjectID]
    public var instruction: String?
    public var contentLocale: String
    public var context: [ContextItem]
    public var preconditions: Preconditions
    public var scope: Scope
    /// The slice of the client's document this request reasons about.
    ///
    /// The server is not authoritative and holds no store, so the document
    /// travels with the request. It is required: a request without it cannot be
    /// validated and is rejected rather than answered against a stand-in.
    /// `context` stays in the shape for compatibility but the server always
    /// rebuilds it from the snapshot.
    public var snapshot: DocumentSnapshot?

    public enum Intent: String, Codable, Sendable, CaseIterable {
        case explore
        case add
        case setAside
        case reopen
        case clarify
    }

    public struct ContextItem: Codable, Hashable, Sendable {
        public var objectID: ObjectID
        public var kind: ContentObject.Kind
        public var text: String
        public var lifecycle: ContentObject.Lifecycle

        public init(objectID: ObjectID, kind: ContentObject.Kind, text: String, lifecycle: ContentObject.Lifecycle) {
            self.objectID = objectID
            self.kind = kind
            self.text = text
            self.lifecycle = lifecycle
        }
    }

    public struct Preconditions: Codable, Hashable, Sendable {
        public var semanticRevision: Int
        public var readSetFingerprint: String?

        public init(semanticRevision: Int, readSetFingerprint: String? = nil) {
            self.semanticRevision = semanticRevision
            self.readSetFingerprint = readSetFingerprint
        }
    }

    public struct Scope: Codable, Hashable, Sendable {
        public var maxOperations: Int
        public var allowNewObjects: Bool

        public init(maxOperations: Int = 8, allowNewObjects: Bool = true) {
            self.maxOperations = maxOperations
            self.allowNewObjects = allowNewObjects
        }

        public static let conservative = Scope(maxOperations: 4, allowNewObjects: true)
    }

    public init(
        requestId: String,
        documentId: String,
        baseSemanticRevision: Int,
        intent: Intent,
        targetIds: [ObjectID] = [],
        instruction: String? = nil,
        contentLocale: String = "fr",
        context: [ContextItem] = [],
        preconditions: Preconditions? = nil,
        scope: Scope = Scope(),
        snapshot: DocumentSnapshot? = nil
    ) {
        self.requestId = requestId
        self.documentId = documentId
        self.baseSemanticRevision = baseSemanticRevision
        self.intent = intent
        self.targetIds = targetIds
        self.instruction = instruction
        self.contentLocale = contentLocale
        self.context = context
        self.preconditions = preconditions ?? Preconditions(semanticRevision: baseSemanticRevision)
        self.scope = scope
        self.snapshot = snapshot
    }
}

public enum ProposalStatus: String, Codable, Sendable {
    case proposed
    case needsInput
    case noChange
}

public struct ProposalResponse: Codable, Hashable, Sendable {
    public var status: ProposalStatus
    public var proposal: Proposal?
    /// Present when the status is `needsInput`.
    public var questions: [LocalizedText]

    public init(status: ProposalStatus, proposal: Proposal? = nil, questions: [LocalizedText] = []) {
        self.status = status
        self.proposal = proposal
        self.questions = questions
    }

    public static func noChange() -> ProposalResponse {
        ProposalResponse(status: .noChange)
    }

    public static func needsInput(_ questions: [LocalizedText]) -> ProposalResponse {
        ProposalResponse(status: .needsInput, questions: questions)
    }
}
