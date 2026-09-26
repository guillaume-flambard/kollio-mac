import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// AI-09 — cancel, retry, and understand errors.
///
/// The part worth proving is the race: a person asks, then asks again, or undoes,
/// or closes. The first answer is still on its way, and it must not land on top of
/// whatever replaced it. That is what the nonce is for, and it is invisible until
/// it is wrong.
@Suite("AI-09: cancel, retry, late answers")
struct RequestLifecycleTests {
    // MARK: The lifecycle on its own

    @Test("A nonce only ever goes up")
    func nonceIsMonotonic() {
        var lifecycle = RequestLifecycle()
        let first = lifecycle.begin(requestId: "a")
        let second = lifecycle.begin(requestId: "b")
        #expect(second > first)
    }

    @Test("The newest answer is accepted, an older one is not")
    func onlyTheCurrentGenerationIsAccepted() {
        var lifecycle = RequestLifecycle()
        let first = lifecycle.begin(requestId: "a")
        let second = lifecycle.begin(requestId: "b")

        #expect(lifecycle.accepts(nonce: second, requestId: "b"))
        // The first answer is still in flight and is now stale. It is dropped, not
        // delayed: publishing it would put it under the wrong question.
        #expect(lifecycle.accepts(nonce: first, requestId: "a") == false)
    }

    @Test("After undo, close or any change, nothing in flight is still wanted")
    func invalidatingDropsEverythingInFlight() {
        var lifecycle = RequestLifecycle()
        let nonce = lifecycle.begin(requestId: "a")
        #expect(lifecycle.accepts(nonce: nonce, requestId: "a"))

        lifecycle.invalidate()
        #expect(lifecycle.accepts(nonce: nonce, requestId: "a") == false)
        // And the identifier cannot be reused to sneak an old answer back in: the
        // nonce moved on even though the request id could look familiar again.
        let next = lifecycle.begin(requestId: "a")
        #expect(lifecycle.accepts(nonce: nonce, requestId: "a") == false)
        #expect(lifecycle.accepts(nonce: next, requestId: "a"))
    }

    @Test("An answer carrying no nonce is never accepted")
    func aResponseWithoutANonceIsRefused() {
        var lifecycle = RequestLifecycle()
        _ = lifecycle.begin(requestId: "a")
        // There is no sensible default here. Guessing that an unlabelled answer
        // belongs to the current request is exactly the bug the nonce removes.
        #expect(lifecycle.accepts(nonce: 0, requestId: "a") == false)
    }

    @Test("A retry is a new request linked to the one before it")
    func retryIsALinkNotARepeat() {
        var lifecycle = RequestLifecycle()
        _ = lifecycle.begin(requestId: "a")
        _ = lifecycle.begin(requestId: "b", retrying: "a")
        // The new request has its own identity, so the two cannot be confused, and
        // it points back at what it continues.
        #expect(lifecycle.isRetry)
        #expect(lifecycle.retryingRequestId == "a")
        #expect(lifecycle.currentRequestId == "b")
    }
}

/// The same race, through the model and a service that answers late on demand.
@Suite("AI-09: a late answer changes nothing", .serialized)
@MainActor
struct LateAnswerTests {
    /// A service that answers each call from a queue, and parks only the first one
    /// so the test decides the ordering rather than the machine's speed.
    ///
    /// Answering per call matters: two requests that received the *same* answer
    /// could not tell a stale publication from a current one, and the first version
    /// of this test failed for exactly that reason.
    private final class DeferredService: SuggestionService, @unchecked Sendable {
        private let responses: [ProposalResponse]
        private let gate: Gate
        private let counter = Counter()

        final class Counter: @unchecked Sendable {
            private let lock = NSLock()
            private var calls = 0
            /// `withLock` hands back whatever the closure returns, and `calls += 1`
            /// is a Void expression, so the value is read back explicitly. Writing
            /// it as a one-liner made the compiler give up and ask for a bug report.
            func bump() -> Int {
                lock.withLock { calls += 1 }
                return lock.withLock { calls }
            }
        }

        init(responses: [ProposalResponse], gate: Gate) {
            self.responses = responses
            self.gate = gate
        }

        var capabilities: SuggestionCapabilities {
            SuggestionCapabilities(intents: [.explore, .add], deterministic: true, requiresNetwork: false)
        }

        func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
            let index = counter.bump()
            // Only the first call waits, so the second overtakes it.
            if index == 1 { try await gate.wait() }
            return responses[min(index, responses.count) - 1]
        }

        final class Gate: @unchecked Sendable {
            private let lock = NSLock()
            private var open = false
            private var waiters: [CheckedContinuation<Void, Never>] = []

            func wait() async throws {
                try await withTaskCancellationHandler {
                    await withCheckedContinuation { continuation in
                        lock.withLock {
                            if open { continuation.resume() } else { waiters.append(continuation) }
                        }
                    }
                } onCancel: {
                    self.open = true
                    self.lock.withLock {
                        let pending = self.waiters
                        self.waiters = []
                        for waiter in pending { waiter.resume() }
                    }
                }
            }

            func release() {
                lock.withLock {
                    open = true
                    let pending = waiters
                    waiters = []
                    for waiter in pending { waiter.resume() }
                }
            }
        }
    }

    private func model(service: any SuggestionService) -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: service,
            fileStore: DocumentFileStore(
                directory: URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("kollio-ai09-\(UUID().uuidString)")
            )
        )
    }

    private var csv: ObjectID { "object:sarah-csv" }

    @Test("A late answer is dropped, and what replaced it is untouched")
    func lateAnswerIsDropped() async throws {
        let gate = DeferredService.Gate()
        // The first answer asks a question. If it were published, this question
        // would exist in the document. It must not.
        let service = DeferredService(
            responses: [
                ProposalResponse.needsInput([LocalizedText("The stale question")]),
                ProposalResponse.needsInput([LocalizedText("The current question")])
            ],
            gate: gate
        )
        let model = model(service: service)
        model.select(csv, extending: false)

        let first = Task { await model.explore(csv) }
        while model.lifecycle.currentRequestId == nil { await Task.yield() }

        // The person changes their mind before the answer arrives.
        let second = Task { await model.explore(csv, intent: .add, instruction: "Something else") }
        while model.lifecycle.generationNonce < 2 { await Task.yield() }

        gate.release()
        #expect(await first.value == false)
        _ = await second.value

        // The late answer published nothing: the question it carried is nowhere in
        // the document. The first version of this test asserted a condition that
        // was true either way, which is not an assertion.
        let questions = model.document.clarifications.all().map(\.question.text)
        #expect(questions.contains("The stale question") == false)
        // The answer that *was* wanted arrived and was published.
        #expect(questions.contains("The current question"))
    }

    @Test("Cancelling the work in flight keeps the draft and drops the answer")
    func cancellingKeepsTheDraft() async throws {
        let gate = DeferredService.Gate()
        let service = DeferredService(
            responses: [ProposalResponse.needsInput([LocalizedText("A question")])],
            gate: gate
        )
        let model = model(service: service)
        model.startComposer(anchor: csv, intent: .add)
        model.composer?.text = "half a sentence"

        let asking = Task { await model.explore(csv, intent: .add, instruction: "half a sentence") }
        while model.lifecycle.currentRequestId == nil { await Task.yield() }

        // The person cancels. The work stops being wanted, and the words stay.
        model.invalidateInFlightAnswer()
        gate.release()
        _ = await asking.value

        #expect(model.composer?.text == "half a sentence")
        #expect(model.progress == nil)
    }

    @Test("A refusal does not start a loop of its own")
    func refusalDoesNotLoop() async throws {
        // A service that refuses every call. If the model retried, this would never
        // return; the assertion is that one call is one call.
        final class Refusing: SuggestionService, @unchecked Sendable {
            let counter = Counter()
            final class Counter: @unchecked Sendable {
                private let lock = NSLock()
                private var calls = 0
                func bump() { lock.withLock { calls += 1 } }
                var count: Int { lock.withLock { calls } }
            }
            var capabilities: SuggestionCapabilities {
                SuggestionCapabilities(intents: [.explore], deterministic: true, requiresNetwork: false)
            }
            func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
                counter.bump()
                throw AppleModelError.unavailable(.intelligenceDisabled)
            }
        }

        let service = Refusing()
        let model = model(service: service)
        #expect(await model.explore(csv) == false)
        // Exactly one attempt. A refusal is an answer, not an obstacle to be retried
        // until it gives way.
        #expect(service.counter.count == 1)
        // And the reason is the real one, not a retry's worth of noise.
        #expect(model.status != nil)
    }
}
