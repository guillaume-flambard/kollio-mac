import Foundation

/// How far a proposal has got, while it is still being written.
///
/// On-device generation takes seconds. Without this, the person waits on a
/// spinner and cannot tell whether anything is happening. With it, the interface
/// can show the answer arriving.
///
/// One rule governs everything here: **a progress is never a proposal.** It has
/// no identifier, it has not been validated, and the model may still change its
/// mind about it. A progress may be displayed; it may never be kept, and it is
/// deliberately not convertible into anything the command system accepts. The
/// proposal is minted once, from the finished answer.
public struct ProposalProgress: Codable, Hashable, Sendable {
    /// What the model has said so far, if it has said anything yet.
    public var rationale: String?
    /// How many directions have arrived so far. A count, never their content:
    /// a half-written direction has no meaning to offer.
    public var directionsSoFar: Int
    /// Whether the model has committed to an outcome yet.
    public var hasOutcome: Bool

    public init(rationale: String? = nil, directionsSoFar: Int = 0, hasOutcome: Bool = false) {
        self.rationale = rationale
        self.directionsSoFar = directionsSoFar
        self.hasOutcome = hasOutcome
    }

    public var isEmpty: Bool { rationale == nil && directionsSoFar == 0 && hasOutcome == false }
}

/// A source that can report progress while it works.
///
/// This is an **additional** capability, never a replacement. The seam stays
/// `SuggestionService` and every existing implementation keeps working, because a
/// source that cannot stream simply does not conform to this protocol and the
/// caller falls back to waiting for the whole answer.
///
/// A conformer must honour the same contract as the non-streaming path: a
/// failure is a failure, an unavailable model is a refusal, and the final answer
/// goes through exactly the same validation and conversion as any other. Streaming
/// changes when the user hears about the answer, not what the answer is allowed to
/// be.
public protocol StreamingSuggestionService: SuggestionService {
    /// Streams progress as the answer is written, then returns the same response a
    /// non-streaming call would have returned.
    ///
    /// `onProgress` is called on an arbitrary task and must be safe to call from
    /// the main actor. It is never called after this function returns.
    func stream(
        to request: ProposalRequest,
        document: KollioDocument,
        onProgress: @Sendable (ProposalProgress) -> Void
    ) async throws -> ProposalResponse
}
