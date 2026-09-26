import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// CTX-01, "Add information at a precise place".
///
/// The chapter is one sentence long and the sentence is the whole argument: **Add is
/// not a call that spends the sentence.** What a person typed is already theirs, so
/// it is written down locally, linked to its target, before anything is asked of a
/// model. Every test here is a different way of saying that.
@Suite("CTX-01: add information at a precise place")
@MainActor
struct AddingAtAPlaceTests {
    private func isolatedStore() -> (DocumentFileStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-ctx01-\(UUID().uuidString)")
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
    private let sentence = "Le client demande aussi les tags, pas seulement la liste."

    // MARK: One transaction, a note, and a link

    @Test("The sentence becomes an authored note linked to its target")
    func theSentenceBecomesANote() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        let note = try #require(model.addNote(sentence, to: csv))

        // It is a note, not a hypothesis: the person has said where this belongs, not
        // what it is. "No ontology knowledge required" is a requirement, not a default.
        #expect(model.object(note)?.kind == .note)
        #expect(model.object(note)?.text.text == sentence)
        // Authored, and by the person rather than by a model.
        #expect(model.object(note)?.provenance.kind == .human)

        // The link is what makes it "at a precise place" rather than merely present.
        let link = try #require(
            model.document.relationships.values.first { $0.from == note && $0.kind == .associatedWith }
        )
        #expect(link.to == csv)
    }

    @Test("The note and its link are written together or not at all")
    func theNoteAndItsLinkAreOneTransaction() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let relationshipsBefore = model.document.relationships.count

        let note = try #require(model.addNote(sentence, to: csv))
        #expect(model.document.relationships.count == relationshipsBefore + 1)

        // One undo removes both. A link left pointing at a note that was never written,
        // or a note nothing points at, are both states nobody asked for.
        model.undo()
        #expect(model.object(note) == nil)
        #expect(model.document.relationships.count == relationshipsBefore)
        #expect(model.document.relationships.values.allSatisfy { $0.from != note })
    }

    @Test("An empty sentence adds nothing")
    func anEmptySentenceAddsNothing() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let before = model.document.content.count
        #expect(model.addNote("  \n ", to: csv) == nil)
        #expect(model.document.content.count == before)
    }

    @Test("A sentence added to something absent is refused, not silently dropped")
    func aSentenceNeedsATarget() {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        #expect(model.addNote(sentence, to: ObjectID("object:nothing-here")) == nil)
    }

    // MARK: AC02, the target is kept

    @Test("AC02: adding information never disturbs the thing it is about")
    func theTargetIsKept() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let before = try #require(model.object(csv))
        let versionBefore = before.objectVersion
        let linksBefore = model.document.relationships.values.filter { $0.to == csv }.count

        let note = try #require(model.addNote(sentence, to: csv))

        // Same object, same words, same version, same kind: the target is untouched.
        #expect(model.object(csv) == before)
        #expect(model.object(csv)?.objectVersion == versionBefore)
        // It gained a neighbour and lost nothing.
        #expect(model.document.relationships.values.filter { $0.to == csv }.count == linksBefore + 1)
        // And the note is a separate object, not a rewrite of the target.
        #expect(note != csv)
    }

    // MARK: AC01, findable after a relaunch

    @Test("AC01: the sentence is findable after a relaunch")
    func theSentenceSurvivesARelaunch() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let note = try #require(model.addNote(sentence, to: csv))
        #expect(model.save())

        // A new process, reading only what was written to disk.
        let relaunched = KollioModel(
            document: nil,
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: store
        )
        #expect(relaunched.isEmpty == false)
        #expect(relaunched.object(note)?.text.text == sentence)
        #expect(relaunched.object(note)?.kind == .note)
        // Findable *as information about something*, not merely present: the link
        // survived too, which is what makes it findable from the target.
        #expect(relaunched.document.relationships.values.contains { $0.from == note && $0.to == csv })
        #expect(relaunched.text(of: note) == sentence)
    }

    // MARK: AC03, a model error does not delete the contribution

    @Test("AC03: a model error leaves the contribution in place")
    func aModelErrorDoesNotDeleteTheContribution() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        // Add never asks a model, so the contribution exists before anything can go
        // wrong. This service throws on every call, which is the harshest version of
        // "a later AI failure".
        let failing = FailingSuggestionService()
        let model = makeModel(failing, store: store)

        let note = try #require(model.addNote(sentence, to: csv))
        #expect(failing.callCount == 0)

        // Now the later, separate action fails.
        await model.revealConsequences(of: note)
        #expect(failing.callCount == 1)
        #expect(model.status != nil)

        // The sentence is untouched, still linked, still the person's.
        #expect(model.object(note)?.text.text == sentence)
        #expect(model.object(note)?.provenance.kind == .human)
        #expect(model.document.relationships.values.contains { $0.from == note && $0.to == csv })
    }

    @Test("A refusal and a timeout are both survivable, and both keep the note")
    func everyFailureKeepsTheNote() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        for failure in [
            FailingSuggestionService(),
            RefusingSuggestionService(),
            SlowSuggestionService()
        ] as [any SuggestionService] {
            let model = makeModel(failure, store: store)
            let note = try #require(model.addNote(sentence, to: csv))
            await model.revealConsequences(of: note)
            #expect(model.object(note)?.text.text == sentence)
        }
    }

    // MARK: A double submission is deduplicated

    @Test("A double submission is deduplicated")
    func aDoubleSubmissionIsDeduplicated() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let contentBefore = model.document.content.count
        let linksBefore = model.document.relationships.count

        let first = try #require(model.addNote(sentence, to: csv))
        let second = try #require(model.addNote(sentence, to: csv))

        // Pressing the key twice is a fact about the person, not two pieces of
        // information. Two identical notes would read as corroboration nobody gave.
        #expect(first == second)
        #expect(model.document.content.count == contentBefore + 1)
        #expect(model.document.relationships.count == linksBefore + 1)
    }

    @Test("Deduplication ignores stray whitespace but not different words")
    func deduplicationIsAboutTheWords() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)

        let first = try #require(model.addNote(sentence, to: csv))
        // The same sentence, retyped with a line break in it.
        let retyped = sentence.replacingOccurrences(of: "aussi", with: "aussi\n  ")
        #expect(model.addNote(retyped, to: csv) == first)

        // And what is stored is what was typed, not the folded form used to compare.
        #expect(model.object(first)?.text.text == sentence)
        // A different sentence at the same place is a different note.
        let other = try #require(model.addNote("Et le prénom du contact.", to: csv))
        #expect(other != first)
    }

    @Test("The same sentence about two different things is two notes")
    func theSameSentenceCanBeTrueTwice() throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        let crm = KollioID.object("sarah-crm")

        let aboutCSV = try #require(model.addNote(sentence, to: csv))
        let aboutCRM = try #require(model.addNote(sentence, to: crm))

        // Deduplication is per target, not global: the same remark about two
        // different objects is two remarks, and merging them would lose where each
        // was said.
        #expect(aboutCSV != aboutCRM)
    }

    // MARK: Add does not spend the sentence on a model

    @Test("The composer writes the note and does not call anything")
    func theComposerWritesLocally() async throws {
        let (store, directory) = isolatedStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = FailingSuggestionService()
        let model = makeModel(service, store: store)

        model.startComposer(anchor: csv, intent: .add)
        model.composer?.text = sentence
        await model.submitComposer()

        // The draft is closed, the note exists, and no intelligence was consulted.
        #expect(model.composer == nil)
        #expect(service.callCount == 0)
        #expect(model.document.content.values.contains { $0.text.text == sentence })
    }

    // MARK: A proposed type that changes the reasoning asks first

    @Test("A note is a type intelligence may choose on its own")
    func aNoteNeedsNoConfirmation() {
        #expect(KollioModel.kindNeedsConfirmation(.note) == false)
        #expect(KollioModel.kindNeedsConfirmation(.unclear) == false)
    }

    @Test("A type that argues something asks before it is applied")
    func anArgumentingTypeAsksFirst() {
        for kind in [ContentObject.Kind.hypothesis, .constraint, .evidence,
                     .question, .decision, .product] {
            #expect(KollioModel.kindNeedsConfirmation(kind))
        }
        let store = DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        let model = makeModel(store: store)
        let proposal = makeProposal(in: model.document, kind: .hypothesis)
        #expect(model.kindConfirmation(for: proposal) == [proposal.operations.compactMap { operation in
            guard case .createObject(let create) = operation else { return nil }
            return create.id
        }.first])
    }

    @Test("A note proposed by intelligence is applied without asking")
    func aProposedNoteIsAppliedWithoutAsking() {
        let store = DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        let model = makeModel(store: store)
        let proposal = makeProposal(in: model.document, kind: .note)
        #expect(model.kindConfirmation(for: proposal).isEmpty)
    }
}

// MARK: - Helpers

private func makeProposal(
    in document: KollioDocument,
    kind: ContentObject.Kind
) -> Proposal {
    let id = ObjectID("object:proposed")
    return Proposal(
        proposalId: UUID().uuidString,
        requestId: UUID().uuidString,
        documentId: document.documentId,
        baseSemanticRevision: document.semanticRevision,
        summary: LocalizedText("Une proposition"),
        operations: [.createObject(CreateObject(
            id: id, kind: kind, text: LocalizedText("Une chose proposée"),
            provenance: Provenance(actor: ActorID("local-engine"), kind: .localEngine)
        ))],
        generator: Proposal.Generator(name: "test", deterministic: true)
    )
}

/// Throws on every call, the way a quota or a transport fault does.
private final class FailingSuggestionService: SuggestionService, @unchecked Sendable {
    private(set) var callCount = 0
    let capabilities = SuggestionCapabilities.offline

    func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        callCount += 1
        throw DocumentError.forbiddenOperation("no intelligence available")
    }
}

/// Answers far too slowly, which is what a person actually experiences when the wait
/// is the problem. The delay is short enough to keep the suite fast and long enough
/// to be a real suspension rather than an immediate answer.
private final class SlowSuggestionService: SuggestionService, @unchecked Sendable {
    private(set) var callCount = 0
    let capabilities = SuggestionCapabilities.offline

    func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        callCount += 1
        try await Task.sleep(nanoseconds: 200_000_000)
        throw DocumentError.forbiddenOperation("answered too late to be useful")
    }
}
