import Foundation
import Testing
@testable import KollioCore

/// CAN-06 — link, select and edit a relation.
///
/// The three acceptance criteria:
///
/// - AC01 the line is clickable at several zooms
/// - AC02 the text explains the direction
/// - AC03 objects do not become true because they are linked
@Suite("Relations: reading and editing")
struct RelationshipReadingTests {
    /// `DocumentBuilder` mints the identifiers, so the ones the document actually
    /// uses are the ones the tests use. Guessing `"crm"` instead of the real
    /// `"object:crm"` is how the first version of this file failed to find its own
    /// objects.
    private let crm = KollioID.object("crm")
    private let csv = KollioID.object("csv")
    private let link = KollioID.relationship("l1")

    private func document() -> KollioDocument {
        var builder = DocumentBuilder()
        _ = builder.object("crm", kind: .hypothesis, "CRM connection", en: "CRM connection", at: .zero)
        _ = builder.object("csv", kind: .hypothesis, "CSV export", en: "CSV export", at: .zero)
        _ = builder.link("l1", from: crm, to: csv, .constrains)
        return builder.document
    }

    // MARK: AC02

    @Test("AC02: the text explains which way the link points")
    func textExplainsDirection() throws {
        let document = document()
        let sentence = try #require(
            document.relationship(link)?.sentence(in: document, languageCode: "en")
        )
        // The subject is the source. "CRM connection constrains CSV export" says
        // something an arrow does not.
        #expect(sentence.subject == "CRM connection")
        #expect(sentence.verb == "constrains")
        #expect(sentence.object == "CSV export")
        #expect(sentence.text == "CRM connection constrains CSV export")
        #expect(sentence.direction == .fromSubjectToObject)
    }

    @Test("The sentence is written in the interface's language")
    func sentenceIsLocalised() throws {
        let document = document()
        let french = try #require(
            document.relationship(link)?.sentence(in: document, languageCode: "fr")
        )
        #expect(french.verb == "contraint")
        #expect(french.text == "CRM connection contraint CSV export")
    }

    @Test("A link to something that is not there says no sentence at all")
    func missingEndpointHasNoSentence() {
        var document = document()
        // A half sentence naming an object the document does not have reads as a
        // fact about something absent, which is worse than saying nothing.
        document.relationships[link]?.to = "object:ghost"
        #expect(document.relationship(link)?.sentence(in: document, languageCode: "en") == nil)
    }

    @Test("A label is shown as a qualifier, not merged into the sentence")
    func labelIsAQualifier() throws {
        var document = document()
        document.relationships[link]?.label = LocalizedText("needs credentials")
        let sentence = try #require(
            document.relationship(link)?.sentence(in: document, languageCode: "en")
        )
        #expect(sentence.qualifier == "needs credentials")
        #expect(sentence.text == "CRM connection constrains CSV export (needs credentials)")
        // And the sentence without it is still the same claim.
        let bare = try #require(
            document.relationship(link)?.sentence(in: document, languageCode: "en", includeQualifier: false)
        )
        #expect(bare.qualifier == nil)
    }

    // MARK: AC01

    @Test("AC01: the hit area is wider than the stroke, and grows as the view shrinks")
    func hitAreaExceedsTheStroke() {
        let relationship = Relationship(
            id: link, from: crm, to: csv, kind: .constrains,
            provenance: .human("me")
        )
        // Wider than the 1.5-point line at every zoom, which is the whole point:
        // a hairline is not a target.
        for zoom in [0.2, 0.5, 1.0, 2.5, 4.0] {
            #expect(relationship.hitArea(zoom: zoom) > 1.5,
                    "at zoom \(zoom) the link is no easier to catch than the line it is drawn as")
        }
        // And the area grows as the view shrinks, so a distant link stays catchable.
        #expect(relationship.hitArea(zoom: 0.25) > relationship.hitArea(zoom: 2.0))
        // It does not become absurd at a pathological zoom, which would swallow the
        // objects around it.
        #expect(relationship.hitArea(zoom: 0.01) < 200)
    }

    // MARK: Duplicates

    @Test("A duplicate reveals the link that already says it")
    func duplicateRevealsTheExistingOne() {
        let document = document()
        let existing = document.existingRelationship(kind: .constrains, from: crm, to: csv)
        #expect(existing?.id == link)
        // A different direction, or a different kind, is a different claim.
        #expect(document.existingRelationship(kind: .supports, from: crm, to: csv) == nil)
        #expect(document.existingRelationship(kind: .constrains, from: csv, to: crm) == nil)
    }

    // MARK: Editing

    @Test("Reversing a link is a named edit that changes the sentence")
    func reversingChangesTheSentence() throws {
        var store = DocumentStore(document: document())
        let before = try #require(
            store.document.relationship(link)?.sentence(in: store.document, languageCode: "en")
        )
        #expect(before.text == "CRM connection constrains CSV export")

        try store.apply([.editRelationship(.init(
            id: link, edit: .reverse, provenance: .human("person:owner")
        ))])

        let after = try #require(
            store.document.relationship(link)?.sentence(in: store.document, languageCode: "en")
        )
        // The ends swapped and the sentence says so. This is why a reverse has to
        // be deliberate: nothing about the two looks different.
        #expect(after.text == "CSV export constrains CRM connection")
    }

    @Test("Retitling a link changes what it claims without moving anything")
    func retitlingDoesNotMove() throws {
        var store = DocumentStore(document: document())
        let fromBefore = store.document.relationship(link)?.from
        try store.apply([.editRelationship(.init(
            id: link, edit: .retitle(LocalizedText("until credentials exist")),
            provenance: .human("person:owner")
        ))])
        #expect(store.document.relationship(link)?.from == fromBefore)
        #expect(store.document.relationship(link)?.label?.text == "until credentials exist")
    }

    @Test("Editing a link that is not there is refused")
    func editingNothingIsRefused() {
        var store = DocumentStore(document: document())
        #expect(throws: DocumentError.unknownRelationship(KollioID.relationship("l9"))) {
            try store.apply([.editRelationship(.init(
                id: KollioID.relationship("l9"), edit: .reverse, provenance: .human("me")
            ))])
        }
    }

    // MARK: AC03

    @Test("AC03: being linked to something does not make an object true")
    func linkingDoesNotMakeSomethingTrue() throws {
        var store = DocumentStore(document: document())
        // "CSV export" is a hypothesis. A link that supports it, contradicts it, or
        // derives from it, leaves it exactly as unproven as it was: the vocabulary of
        // kinds has no member meaning "true", and linking is not one of them.
        let hypothesis = try #require(store.document.content[csv])
        #expect(hypothesis.kind == .hypothesis)
        try store.apply([.editRelationship(.init(
            id: link, edit: .changeKind(.supports), provenance: .human("person:owner")
        ))])
        #expect(store.document.content[csv]?.kind == .hypothesis)
        // And the object's own text is untouched by any of it.
        #expect(store.document.content[csv]?.text.text == "CSV export")
    }

    @Test("A self-relation is still refused")
    func selfRelationIsRefused() {
        var store = DocumentStore(document: document())
        #expect(throws: DocumentError.selfRelationship(KollioID.relationship("l2"))) {
            try store.apply([.addRelationship(.init(
                id: KollioID.relationship("l2"), from: crm, to: crm, kind: .supports, provenance: .human("me")
            ))])
        }
    }

    @Test("Intelligence may not rewrite what a link means")
    func intelligenceCannotEditRelations() throws {
        let document = document()
        for edit: RelationshipEdit in [.reverse, .changeKind(.supports), .retitle(LocalizedText("because"))] {
            let proposal = Proposal(
                proposalId: "proposal:edit",
                requestId: "request:edit",
                documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision,
                summary: LocalizedText("Rewriting a link"),
                operations: [.editRelationship(.init(
                    id: link, edit: edit,
                    provenance: .init(actor: "apple:on-device", kind: .localEngine)
                ))],
                generator: .init(name: "apple-on-device", deterministic: false)
            )
            // Reversing a link in particular inverts a claim while looking identical
            // before and after. That belongs to a person.
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(
                    proposal, against: document, scope: ProposalRequest.Scope()
                )
            }
        }
    }
}
