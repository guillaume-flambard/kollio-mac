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
}
