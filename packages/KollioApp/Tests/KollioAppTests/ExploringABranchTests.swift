import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// AI-03, "Explore a branch".
///
/// Three acceptance criteria and one argument running under all of them: exploration
/// is a **question asked of a document**, and a document that has already refused
/// something must not be asked to forget. The engine here is deterministic, so every
/// claim below is about the request that was made and about what the engine did with
/// what it was told, not about what a real model might say.
@Suite("AI-03: explore a branch")
@MainActor
struct ExploringABranchTests {
    private func isolatedStore() -> (DocumentFileStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-ai03-\(UUID().uuidString)")
        return (DocumentFileStore(directory: directory), directory)
    }

    private func makeModel(
        _ service: (any SuggestionService)? = nil,
        store: DocumentFileStore
    ) -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: service ?? KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
    }

    private let csv = KollioID.object("sarah-csv")
    private let crm = KollioID.object("sarah-crm")
    private let blocked = KollioID.object("sarah-blocked")

    // MARK: AC01, the exact instruction is transmitted

    @Test("AC01: the exact words a person typed reach the source")
    func theExactInstructionIsTransmitted() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = CapturingSuggestionService()
        let model = makeModel(service, store: store)
        // Chosen to be awkward: capitals, an accent, a question mark and a colon.
        let typed = "Surtout le B2B: est-ce que l'export suffit ?"

        model.startComposer(anchor: csv, intent: .explore)
        model.composer?.text = typed
        await model.submitComposer()

        let request = try #require(service.requests.last)
        // Exactly what was typed: not trimmed into a summary, not lowercased, not
        // reconstructed from the target.
        #expect(request.instruction == typed)
        #expect(request.intent == .explore)
    }

    @Test("A refused Explore leaves the typed words in the composer")
    func aRefusedExploreKeepsTheInstruction() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(RefusingSuggestionService(), store: store)
        let typed = "Une consigne que je ne veux pas perdre"

        model.startComposer(anchor: csv, intent: .explore)
        model.composer?.text = typed
        await model.submitComposer()

        // A steer that is silently ignored is worse than no steer at all, and this
        // used to be exactly what happened: the Explore intent cleared the composer
        // and dropped the sentence on the floor.
        #expect(model.composer?.text == typed)
    }

    // MARK: AC02, rejected directions are consulted

    @Test("AC02: a rejected direction travels with the request, and its reason")
    func rejectedDirectionsAreTransmitted() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.setAside(csv, reason: "Pas de budget pour l'export cette année")

        let readSet = model.readSet(for: crm)
        let rejected = try #require(readSet.first { $0.objectID == csv })

        // Sent, and marked as a rejection rather than as context to build on.
        #expect(rejected.lifecycle == .setAside)
        #expect(rejected.reason == "Pas de budget pour l'export cette année")
    }

    @Test("A rejection without a reason is still sent, without an invented one")
    func aReasonlessRejectionIsStillSent() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.setAside(csv, reason: nil)

        let rejected = try #require(model.readSet(for: crm).first { $0.objectID == csv })
        #expect(rejected.lifecycle == .setAside)
        // Inventing a reason would be worse than having none: intelligence would act
        // on a rationale the person never gave.
        #expect(rejected.reason == nil)
    }

    @Test("A reopened direction is not sent as a rejection any more")
    func aReopenedDirectionIsNotARejection() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.setAside(csv, reason: "Pas encore")
        model.reopen(csv)

        // The person changed their mind, and the read set has to show that. Sending it
        // as still rejected would make the engine refuse a door they just opened.
        let item = try #require(model.readSet(for: crm).first { $0.objectID == csv })
        #expect(item.lifecycle == .active)
    }

    @Test("The engine does not re-propose a direction the person refused")
    func theEngineDoesNotRepeatARejectedDirection() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        // Explore first, and keep what came back, so there is a real proposal to
        // reject rather than a fabricated one.
        await model.explore(csv)
        let firstProposal = try #require(model.preview).proposal
        let firstObjectID = try #require(firstProposal.operations.compactMap { operation -> ObjectID? in
            guard case .createObject(let create) = operation else { return nil }
            return create.id
        }.first)
        // Apply it, then set it aside with a reason: this is the ordinary path where a
        // dead end becomes a documented rejection.
        try model.keepPreview()
        let applied = try #require(model.document.object(firstObjectID))
        #expect(applied.kind != .note)
        model.setAside(firstObjectID, reason: "Déjà essayé en mars, ça n'a pas tenu")

        // Now explore the same target again. The engine is given the rejection, and
        // the rejection is what stops it offering the same words back.
        let readSet = model.readSet(for: csv)
        #expect(readSet.contains { $0.objectID == firstObjectID && $0.reason == "Déjà essayé en mars, ça n'a pas tenu" })

        await model.explore(csv)
        let secondTexts = Set(model.preview?.proposal.operations.compactMap { operation -> String? in
            guard case .createObject(let create) = operation else { return nil }
            return create.text.text
        } ?? [])
        #expect(secondTexts.isEmpty || secondTexts.contains(applied.text.text) == false)
    }

    @Test("A repetitive loop yields noChange, never a duplicate")
    func aRepetitiveLoopYieldsNoChange() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        // Exploring the same target repeatedly must converge rather than pile up
        // copies of itself. Each round can only offer what is not already there.
        for _ in 0..<4 {
            await model.explore(crm)
            if let preview = model.preview {
                try? model.keepPreview()
            }
        }

        // Whatever happened, no two objects in the document say the same thing.
        let texts = model.document.content.values.map(\.text.text)
        #expect(Set(texts).count == texts.count)
    }

    @Test("A rejected branch is not reopened by the engine")
    func aRejectedBranchIsNotReopened() async {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.setAside(crm, reason: "Le client ne veut pas du direct")

        // Exploring something the person set aside answers nothing at all. The
        // decision stands, and the engine does not argue with it by re-proposing.
        await model.explore(crm)
        #expect(model.preview == nil)
        #expect(model.status == L10n.statusNoChange)
        // The rejection is untouched.
        #expect(model.object(crm)?.isSetAside == true)
        #expect(model.canReopen(crm))
    }

    // MARK: The stable rejection signature

    @Test("The same read set always produces the same signature")
    func theSignatureIsStable() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.setAside(csv, reason: "Pas de budget")

        // Asked repeatedly, over an unchanged document, the signature must not move.
        // A fingerprint that changed on the same input would make every precondition
        // look stale and nothing would ever validate.
        let first = model.readSetFingerprint(for: crm)
        for _ in 0..<8 {
            #expect(model.readSetFingerprint(for: crm) == first)
        }
    }

    @Test("The signature does not depend on the order the set was built in")
    func theSignatureIgnoresOrder() {
        let items = [
            ProposalRequest.ContextItem(objectID: "a", kind: .hypothesis, text: "Un", lifecycle: .active),
            ProposalRequest.ContextItem(objectID: "b", kind: .constraint, text: "Deux", lifecycle: .setAside,
                                         reason: "essai"),
            ProposalRequest.ContextItem(objectID: "c", kind: .question, text: "Trois", lifecycle: .active),
        ]
        #expect(ProposalRequest.fingerprint(of: items)
                == ProposalRequest.fingerprint(of: items.reversed()))
    }

    @Test("A different reason is a different signature, even on identical text")
    func theReasonChangesTheSignature() {
        let noBudget = ProposalRequest.ContextItem(
            objectID: "a", kind: .hypothesis, text: "Même phrase", lifecycle: .setAside,
            reason: "Pas de budget"
        )
        let triedBefore = ProposalRequest.ContextItem(
            objectID: "a", kind: .hypothesis, text: "Même phrase", lifecycle: .setAside,
            reason: "Déjà essayé en mars"
        )
        // Same words, different reasoning, so a different instruction. A signature
        // that ignored the reason would treat two different closures as one.
        #expect(ProposalRequest.fingerprint(of: [noBudget])
                != ProposalRequest.fingerprint(of: [triedBefore]))
    }

    @Test("The signature travels as the request's precondition")
    func theSignatureTravelsWithTheRequest() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = CapturingSuggestionService()
        let model = makeModel(service, store: store)

        await model.explore(csv)
        let request = try #require(service.requests.last)
        // It was declared in the format and never set anywhere; now it says what was
        // read, which is the only thing a precondition over a read set is for.
        #expect(request.preconditions.readSetFingerprint
                == ProposalRequest.fingerprint(of: request.context))
        #expect(request.preconditions.readSetFingerprint?.isEmpty == false)
    }

    // MARK: AC03, a new exploration does not erase a previous proposal

    @Test("AC03: a new proposal does not erase the one before it")
    func aNewProposalDoesNotEraseThePrevious() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        await model.explore(crm)
        let first = try #require(model.preview)

        await model.explore(csv)
        let second = try #require(model.preview)

        #expect(first.id != second.id)
        // The new one is on the canvas; the old one was *offered*, not dropped.
        #expect(model.supersededProposal?.id == first.id)
        #expect(model.keptProposals.contains { $0.id == first.id })
        // And it is still readable, so a person who wants to compare can.
        let kept = try #require(model.keptProposals.first { $0.id == first.id })
        #expect(kept.proposal.proposalId == first.proposal.proposalId)
    }

    @Test("A proposal is offered exactly once, and the offer can be answered")
    func theOfferCanBeAnswered() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        await model.explore(crm)
        let first = try #require(model.preview)
        await model.explore(csv)
        #expect(model.supersededProposal?.id == first.id)

        // Answered, not left hanging.
        model.keepPreviousProposal()
        #expect(model.supersededProposal == nil)
        // Keeping it leaves it readable.
        #expect(model.keptProposals.contains { $0.id == first.id })
    }

    @Test("Hiding a previous proposal forgets it, and wrote nothing")
    func hidingAProposalForgetsIt() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let contentBefore = model.document.content.count

        await model.explore(crm)
        let first = try #require(model.preview)
        await model.explore(csv)
        model.hidePreviousProposal()

        #expect(model.supersededProposal == nil)
        #expect(model.keptProposals.contains { $0.id == first.id } == false)
        // Hiding is not deleting: a proposal that was never kept created nothing.
        #expect(model.document.content.count == contentBefore)
    }

    @Test("noChange never erases a proposal that is already on the canvas")
    func noChangeNeverErasesAPreview() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        await model.explore(crm)
        let onScreen = try #require(model.preview)

        // Something the engine has nothing new to say about: it declines.
        model.handle(.noChange(), anchor: csv)
        #expect(model.status == L10n.statusNoChange)
        // The branch is still there. Destroying a pending branch because a *later*
        // question produced no answer is the bug AC03 names.
        #expect(model.preview?.id == onScreen.id)
    }

    // MARK: Exploration does not change the parent

    @Test("Exploring a branch does not change the parent's status")
    func exploringDoesNotChangeTheParent() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let before = try #require(model.object(csv))
        let decisionsBefore = model.document.decisions.count

        await model.explore(csv)
        // A ghost branch is not a change of mind. The parent is exactly as it was.
        #expect(model.object(csv) == before)
        #expect(model.object(csv)?.isSetAside == false)
        #expect(model.document.decisions.count == decisionsBefore)
        // And nothing was written: a proposal is still only a proposal.
        #expect(model.preview != nil)
    }
}
