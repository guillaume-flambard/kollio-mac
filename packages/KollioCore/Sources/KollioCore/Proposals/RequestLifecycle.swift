import Foundation

/// Which generation of a request is current, and which answers are still wanted.
///
/// AI-09 requires that `generationNonce` be monotonic and that "a late response
/// after a switch, undo or close is ignored". That is not a nicety: a person who
/// asks a second question, or undoes, or closes the window, must not have the
/// first answer land on top of whatever replaced it.
///
/// A nonce is the cheapest thing that can express this. It only ever increases,
/// it is minted by the model rather than by the answer, and an answer that carries
/// a smaller one is stale by construction. No timestamp, because clocks move, and
/// no identity, because two requests can be otherwise identical.
public struct RequestLifecycle: Hashable, Sendable, Codable {
    /// Monotonically increasing. Never reused, never reset, even after a document
    /// is closed: a fresh lifecycle starts above the highest value this process has
    /// seen, not at zero.
    public private(set) var generationNonce: UInt64
    /// The request whose answer is currently wanted, if any.
    public private(set) var currentRequestId: String?
    /// The request a retry continues from, so a retry is a visible link rather than
    /// an invisible repeat. AC: "A retry creates a new linked request, never an
    /// invisible repeat."
    public private(set) var retryingRequestId: String?

    public init(generationNonce: UInt64 = 0, currentRequestId: String? = nil) {
        self.generationNonce = generationNonce
        self.currentRequestId = currentRequestId
    }

    /// Starts a generation and returns the nonce that answer must carry.
    @discardableResult
    public mutating func begin(requestId: String, retrying: String? = nil) -> UInt64 {
        generationNonce += 1
        currentRequestId = requestId
        retryingRequestId = retrying
        return generationNonce
    }

    /// Whether an answer minted for `nonce` is still wanted.
    ///
    /// The rule is deliberately strict: an answer is published only if it belongs to
    /// the request that is current *and* carries the newest nonce. A response from a
    /// closed window, a superseded question, or an undone one does not qualify, and
    /// neither does a response that somehow arrives without a nonce at all.
    public func accepts(nonce: UInt64, requestId: String) -> Bool {
        guard let currentRequestId else { return false }
        return currentRequestId == requestId && nonce == generationNonce
    }

    /// Ends the current generation, so anything still in flight is stale.
    ///
    /// Called on undo, on close, and whenever the person does something else. The
    /// nonce still advances rather than being cleared, so a late answer cannot match
    /// a later request that happens to reuse the identifier.
    public mutating func invalidate() {
        generationNonce += 1
        currentRequestId = nil
        retryingRequestId = nil
    }

    /// The request a new one continues from, if this generation is a retry.
    public var isRetry: Bool { retryingRequestId != nil }
}
