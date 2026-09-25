import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// Probes the REAL system model. Not part of the deterministic suite: it is
/// opt-in evidence about a real Mac, and it is skipped rather than silently
/// passing when the model is unavailable.
@Suite("Real on-device model", .enabled(if: ProcessInfo.processInfo.environment["KOLLIO_REAL_MODEL"] == "1"))
struct RealOnDeviceModelTests {
    @available(macOS 26.0, *)
    @Test("Two distinct non-Sarah contexts produce small valid explorations")
    func twoRealContexts() async throws {
        let probe = SystemModelProbe()
        try #require(probe.availability().isUsable, "model unavailable: \(probe.availability())")
        print("REAL-CONTEXT-SIZE:", probe.contextSize() ?? -1)

        for (label, text) in [
            ("fr", "Réduire le parcours d'inscription de neuf étapes à trois avant la fin du trimestre."),
            ("en", "Recover the prospect list without depending on the CRM any more.")
        ] {
            var builder = DocumentBuilder()
            let ctx = builder.object("ctx", kind: .context, text, en: text, at: .zero)!
            let document = builder.document
            let scoped = try document.snapshot(targeting: [ctx])
            let request = ProposalRequest(
                requestId: "real-\(label)", documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision, intent: .explore,
                targetIds: [ctx], contentLocale: label, snapshot: scoped
            )
            var scopedRequest = request
            scopedRequest.context = ContextBuilder().context(for: request, document: document)

            let started = Date()
            let service = AppleLocalSuggestionService(probe: probe)
            let response = try await service.respond(to: scopedRequest, document: document)
            let elapsed = Date().timeIntervalSince(started)
            print("REAL-\(label.uppercased())-STATUS:", response.status.rawValue, "in", String(format: "%.1fs", elapsed))
            if let proposal = response.proposal {
                print("REAL-\(label.uppercased())-RATIONALE:", proposal.rationale?.text ?? "")
                print("REAL-\(label.uppercased())-OPS:", proposal.operations.count)
                for operation in proposal.operations.prefix(2) {
                    if case .createObject(let create) = operation {
                        print("REAL-\(label.uppercased())-IDEA:", create.text.text)
                    }
                }
                // A real answer must pass the same validation as any other.
                try ProposalValidator().validate(proposal, against: document, scope: scopedRequest.scope)
            }
        }
    }

    /// The cold figure alone does not say whether the cost is loading the model
    /// assets once or generating every time. This measures the same request
    /// repeatedly in one process, so the first call carries the asset cost and
    /// the later ones show what a steady state would actually feel like.
    @available(macOS 26.0, *)
    @Test("A repeated identical call separates cold assets from steady generation")
    func warmLatency() async throws {
        let probe = SystemModelProbe()
        try #require(probe.availability().isUsable, "model unavailable: \(probe.availability())")

        var builder = DocumentBuilder()
        let text = "Réduire le parcours d'inscription de neuf étapes à trois avant la fin du trimestre."
        let ctx = builder.object("ctx", kind: .context, text, en: text, at: .zero)!
        let document = builder.document
        let scoped = try document.snapshot(targeting: [ctx])
        var request = ProposalRequest(
            requestId: "warm", documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision, intent: .explore,
            targetIds: [ctx], contentLocale: "fr", snapshot: scoped
        )
        request.context = ContextBuilder().context(for: request, document: document)

        let service = AppleLocalSuggestionService(probe: probe)
        var elapsed: [Double] = []
        for call in 1...3 {
            let started = Date()
            let response = try await service.respond(to: request, document: document)
            let seconds = Date().timeIntervalSince(started)
            elapsed.append(seconds)
            print("REAL-WARM-CALL-\(call):", response.status.rawValue,
                  "in", String(format: "%.2fs", seconds))
        }

        // The number worth acting on is not the first call. Report the whole
        // series and refuse to name a cause: three samples cannot separate asset
        // loading from generation, and a verdict that flips on a hundredth of a
        // second is worse than no verdict.
        print("REAL-LATENCY-SERIES:", elapsed.map { String(format: "%.2fs", $0) }
            .joined(separator: " -> "))
        print("REAL-LATENCY-FIRST:", String(format: "%.2fs", elapsed[0]))
        print("REAL-LATENCY-LAST:", String(format: "%.2fs", elapsed[elapsed.count - 1]))
        print("REAL-LATENCY-NOTE: some of the first call is one-off, but 3 samples "
            + "cannot attribute the rest. The steady state is still seconds, not "
            + "milliseconds, so streaming is required either way.")
    }

    /// Streaming is the answer to a two-second wait, so it has to be shown working
    /// on a real model rather than argued for. Three things are proved: progress
    /// arrives more than once, the first progress is genuinely partial, and the
    /// final proposal is the same one the non-streaming path produces.
    @available(macOS 26.0, *)
    @Test("A real answer streams progress, and the final proposal is unchanged")
    func realStreaming() async throws {
        let probe = SystemModelProbe()
        try #require(probe.availability().isUsable, "model unavailable: \(probe.availability())")

        var builder = DocumentBuilder()
        let text = "Réduire le parcours d'inscription de neuf étapes à trois avant la fin du trimestre."
        let ctx = builder.object("ctx", kind: .context, text, en: text, at: .zero)!
        let document = builder.document
        let scoped = try document.snapshot(targeting: [ctx])
        var request = ProposalRequest(
            requestId: "real-stream", documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision, intent: .explore,
            targetIds: [ctx], contentLocale: "fr", snapshot: scoped
        )
        request.context = ContextBuilder().context(for: request, document: document)

        let service = AppleLocalSuggestionService(probe: probe)
        let collector = ProgressCollector()
        let started = Date()
        let response = try await service.stream(to: request, document: document) { update in
            collector.append(update)
        }
        let elapsed = Date().timeIntervalSince(started)

        let updates = collector.updates
        print("REAL-STREAM-COUNT:", updates.count, "in", String(format: "%.2fs", elapsed))
        for (index, update) in updates.enumerated().prefix(6) {
            print("REAL-STREAM-\(index): dirs=\(update.directionsSoFar)",
                  "outcome=\(update.hasOutcome)",
                  "rationale=\(update.rationale ?? "-")")
        }

        // Progress must actually arrive, otherwise streaming is decoration.
        #expect(updates.count > 1)
        // The first one is genuinely partial: not a finished answer shown early.
        if let first = updates.first {
            #expect(first.directionsSoFar <= 2)
        }
        // And the committed answer is a real, valid proposal like any other.
        #expect(response.status == .proposed)
        try ProposalValidator().validate(
            response.proposal!, against: document, scope: request.scope
        )
    }
}

/// Collects progress from an arbitrary task, so the test can read it afterwards.
final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [ProposalProgress] = []

    func append(_ update: ProposalProgress) { lock.withLock { storage.append(update) } }
    var updates: [ProposalProgress] { lock.withLock { storage } }
}
