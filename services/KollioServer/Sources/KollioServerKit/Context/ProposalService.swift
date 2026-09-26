import Foundation
import Vapor
import KollioCore

/// Builds the scoped context the provider is allowed to see.
///
/// The client owns the document, so the server never holds it. It receives a
/// slice: the requested targets, their neighbourhood, and nothing else.
public struct ContextBuilder: Sendable {
    public init() {}

    public func context(
        for request: ProposalRequest,
        document: KollioDocument,
        radius: Int = 1
    ) -> [ProposalRequest.ContextItem] {
        var ids: Set<ObjectID> = []
        for target in request.targetIds {
            ids.insert(target)
            ids.formUnion(document.incidents(of: target).flatMap { [$0.from, $0.to] })
        }
        // One more hop, so a provider can see why a target is blocked. The counter
        // is a repeat count and nothing else: each pass widens `ids`, and the pass
        // itself is the same work every time. Naming it `hop` and then not reading
        // it was a warning the compiler had been right about for a while.
        for _ in 1..<Swift.max(radius, 1) {
            var discovered: Set<ObjectID> = []
            for id in ids {
                for relationship in document.incidents(of: id) {
                    discovered.insert(relationship.from)
                    discovered.insert(relationship.to)
                }
            }
            ids.formUnion(discovered)
        }
        return ids.compactMap { id in
            guard let object = document.object(id) else { return nil }
            return .init(
                objectID: object.id,
                kind: object.kind,
                text: object.text.text,
                lifecycle: object.lifecycle
            )
        }
        .sorted { $0.objectID.rawValue < $1.objectID.rawValue }
    }
}

/// Turns a request into an answer, with every safeguard applied.
public struct ProposalService: Sendable {
    public let provider: any LLMProvider
    public let validator: ProposalValidator
    public let contextBuilder: ContextBuilder
    public let timeout: Duration

    public init(
        provider: any LLMProvider,
        timeout: Duration = .seconds(20),
        validator: ProposalValidator = ProposalValidator()
    ) {
        self.provider = provider
        self.timeout = timeout
        self.validator = validator
        self.contextBuilder = ContextBuilder()
    }

    public enum Rejection: Error, Sendable {
        case unknownTarget(ObjectID)
        case stale(revision: Int, expected: Int)
        case providerMalformed(String)
        case providerRefused(String)
        case providerUnavailable
        case timedOut
        case invalidSnapshot(String)
    }

    /// Returns a copy of the request whose context the server built itself.
    /// A pure function, so the result can be handed to any task safely.
    static func scoping(
        _ request: ProposalRequest,
        document: KollioDocument,
        builder: ContextBuilder
    ) -> ProposalRequest {
        ProposalRequest(
            requestId: request.requestId,
            documentId: request.documentId,
            baseSemanticRevision: request.baseSemanticRevision,
            intent: request.intent,
            targetIds: request.targetIds,
            instruction: request.instruction,
            contentLocale: request.contentLocale,
            context: builder.context(for: request, document: document),
            preconditions: request.preconditions,
            scope: request.scope,
            snapshot: request.snapshot
        )
    }

    /// Answers a request whose document arrived with it.
    ///
    /// The snapshot is client-authored and untrusted. It is checked for structure
    /// and reference integrity first, and only then turned into the narrow
    /// document everything below reasons about. The server holds no state between
    /// calls and never becomes authoritative.
    public func respond(to request: ProposalRequest, snapshot: DocumentSnapshot) async throws -> ProposalResponse {
        guard snapshot.documentId == request.documentId else {
            throw Rejection.invalidSnapshot("snapshot belongs to document \(snapshot.documentId), request to \(request.documentId)")
        }
        guard snapshot.semanticRevision == request.baseSemanticRevision else {
            throw Rejection.stale(revision: snapshot.semanticRevision, expected: request.baseSemanticRevision)
        }
        do {
            try snapshot.validate(targets: request.targetIds)
        } catch let error as DocumentSnapshot.SnapshotError {
            // Reported as such, never silently repaired: a partial snapshot must
            // not pass as a whole document.
            throw Rejection.invalidSnapshot(error.description)
        }
        return try await respond(to: request, document: snapshot.makeDocument())
    }

    public func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        for target in request.targetIds where document.object(target) == nil {
            throw Rejection.unknownTarget(target)
        }
        if request.baseSemanticRevision != document.semanticRevision {
            throw Rejection.stale(revision: document.semanticRevision, expected: request.baseSemanticRevision)
        }
        // The context is scoped by the server, never taken on trust from the
        // client.
        let scoped = Self.scoping(request, document: document, builder: contextBuilder)

        // Everything the two tasks need is captured as a value first: the
        // provider is a Sendable value, and no request state is shared.
        let provider = self.provider
        let deadline = self.timeout
        let result: ProviderResult
        do {
            result = try await withThrowingTaskGroup(of: ProviderResult.self) { group in
                group.addTask { try await provider.complete(scoped, document: document) }
                group.addTask {
                    try await Task.sleep(for: deadline)
                    throw Rejection.timedOut
                }
                guard let first = try await group.next() else { throw Rejection.timedOut }
                group.cancelAll()
                return first
            }
        } catch let error as Rejection {
            throw error
        } catch {
            throw Rejection.providerUnavailable
        }

        switch result {
        case .proposal(let proposal):
            // The server validates the model exactly like the client will.
            guard proposal.documentId == document.documentId,
                  proposal.baseSemanticRevision == document.semanticRevision else {
                throw Rejection.stale(revision: document.semanticRevision, expected: proposal.baseSemanticRevision)
            }
            do {
                try validator.validate(proposal, against: document, scope: scoped.scope)
            } catch let error as DocumentError {
                throw Rejection.providerMalformed(error.description)
            }
            return .init(status: .proposed, proposal: proposal)
        case .noChange:
            return .noChange()
        case .needsInput(let questions):
            return .needsInput(questions.map { LocalizedText($0) })
        case .refused(let reason):
            throw Rejection.providerRefused(reason)
        case .malformed(let detail):
            throw Rejection.providerMalformed(detail)
        }
    }
}
