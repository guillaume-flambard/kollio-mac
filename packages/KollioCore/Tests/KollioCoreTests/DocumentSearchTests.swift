import Foundation
import Testing
@testable import KollioCore

/// CAN-09: find something in the document, including the things nobody would
/// think to look for.
///
/// The three criteria are AC01 a rejection reason is findable, AC02 returning
/// alters no status, and AC03 a private result is absent from a shared search.
/// The tests below are named after them, and the ones after them are the ways this
/// kind of search usually goes quietly wrong.
@Suite("Document search")
struct DocumentSearchTests {
    private let csv = KollioID.object("sarah-csv")
    private let crm = KollioID.object("sarah-crm")

    /// Sarah, with the CRM direction set aside for a reason nobody typed into a
    /// body, and a source attached so the "not searched" line has something to say.
    private func store() throws -> DocumentStore {
        var store = DocumentStore(document: Fixture.sarah())
        try store.apply([.recordDecision(.init(
            id: "decision:crm",
            kind: .setAside,
            targetObjectID: crm,
            rationale: LocalizedText(
                "Pas de budget pour l'API avant mars",
                variants: ["en": "No budget for the API before March"]
            ),
            provenance: .human("me")
        ))])
        try store.apply([.attachSource(.init(
            source: SourceReference(
                id: SourceID("source:brief"), kind: .text,
                title: "Brief signup", locator: "file:///tmp/brief.md"
            ),
            attachedTo: crm,
            provenance: .human("me")
        ))])
        return store
    }

    private func outcome(
        _ text: String,
        permitted: Set<ObjectID>? = nil,
        languageCode: String = "fr",
        document: KollioDocument
    ) -> DocumentSearch.Outcome {
        DocumentSearch().search(text, in: document, permitted: permitted, languageCode: languageCode)
    }

    // MARK: - AC01, a rejection reason is findable

    @Test("AC01: the reason a direction was set aside for is found by its own words")
    func aRejectionReasonIsFindable() throws {
        let document = try store().document
        let found = outcome("budget", document: document)
        let result = try #require(found.results.first { $0.objectID == crm })
        // The words are in the decision, not in any body, so a search that only
        // read objects would report nothing at all here.
        #expect(result.field == .reason)
        #expect(result.state == .setAside)
        #expect(result.excerpt.contains("budget"))
        // And the decision is named, so a person can see which one this is rather
        // than being handed a bare sentence.
        #expect(result.decisionID == DecisionID("decision:crm"))
    }

    @Test("The reason is searched in the language being read, not only in the source one")
    func aReasonIsSearchableInBothLanguages() throws {
        let document = try store().document
        // The same decision, in English, with a different word. A person who
        // switched the interface language and then searched for what they read
        // must find it.
        let found = outcome("March", languageCode: "en", document: document)
        #expect(found.results.contains { $0.objectID == crm && $0.field == .reason })
    }

    @Test("Accents and case are ignored, because a search that misses looks broken")
    func accentsAndCaseAreIgnored() {
        let document = Fixture.sarah()
        // "reduction" against "Récupérer" is the shape of the mistake a French
        // person makes with an unaccented keyboard.
        #expect(outcome("recuperer", document: document).results.isEmpty == false)
        #expect(outcome("RÉCUPÉRER", document: document).results.isEmpty == false)
    }

    @Test("A title match outranks a body match, and a reason outranks a body")
    func resultsAreOrderedByWhatWasMatched() {
        let document = Fixture.sarah()
        // "export" is a title in "Export CSV depuis l'outil source" and a body in
        // the CRM detail as well as in the evidence.
        let found = outcome("export", document: document)
        #expect(found.results.first?.objectID == KollioID.object("sarah-csv"))
        #expect(found.results.first?.field == .title)
        let ranks = found.results.map(\.field.rank)
        #expect(ranks == ranks.sorted(), "a body match must not come before a title match")
    }

    @Test("One object is one result, even when it matches in three places")
    func oneObjectIsOneResult() {
        let document = Fixture.sarah()
        let found = outcome("CRM", document: document)
        let ids = found.results.map(\.objectID)
        #expect(Set(ids).count == ids.count, "the same object appeared twice: \(ids)")
    }

    @Test("The same query on the same document gives the same list")
    func searchIsDeterministic() {
        let document = Fixture.sarah()
        let first = outcome("e", document: document).results.map(\.id)
        for _ in 0..<5 {
            #expect(outcome("e", document: document).results.map(\.id) == first)
        }
    }

    @Test("An empty query searches nothing, and says nothing was found either")
    func anEmptyQueryIsNotAnEmptyAnswer() {
        let document = Fixture.sarah()
        for empty in ["", "   ", "\n"] {
            let found = outcome(empty, document: document)
            // Not a result set of zero from a real search: no search ran, so
            // nothing was left out to report.
            #expect(found.results.isEmpty)
            #expect(found.notSearched.isEmpty)
            #expect(found.isPartial == false)
        }
    }

    // MARK: - AC02, returning alters no status

    @Test("AC02: searching changes nothing in the document")
    func searchingAltersNoStatus() throws {
        let store = try store()
        let before = store.document
        let revision = store.revision
        let semantic = store.semanticRevision
        for query in ["export", "budget", "CRM", "identifiants", "rien de tout cela"] {
            _ = outcome(query, document: store.document)
        }
        #expect(store.document == before)
        #expect(store.revision == revision)
        #expect(store.semanticRevision == semantic)
    }

    @Test("AC02: finding a set-aside direction does not bring it back")
    func findingASetAsideDirectionDoesNotReopenIt() throws {
        let store = try store()
        #expect(store.document.object(crm)?.isSetAside == true)
        let found = outcome("budget", document: store.document)
        #expect(found.results.contains { $0.objectID == crm && $0.state == .setAside })
        // The result is a reading. Reading it is not deciding anything.
        #expect(store.document.object(crm)?.lifecycle == .setAside)
        #expect(store.document.object(crm)?.setAsideByDecision == DecisionID("decision:crm"))
    }

    @Test("A reason whose decision no longer stands is history, and is labelled so")
    func aSupersededReasonIsArchived() throws {
        var store = try store()
        // Reopening supersedes the decision. The reason stays in the document,
        // because the history is the point, and a search must not offer it as a
        // reason that still holds.
        try store.apply([.recordDecision(.init(
            id: "decision:crm-back",
            kind: .reopened,
            targetObjectID: crm,
            provenance: .human("me")
        ))])
        let found = outcome("budget", document: store.document)
        let result = try #require(found.results.first { $0.objectID == crm && $0.field == .reason })
        #expect(result.state == .archived)
        // One reason, one row. The reason belonged to the branch, and repeating it
        // once per member would be a list about the search rather than about the
        // document: two identical labels with no way to tell them apart.
        #expect(found.results.filter { $0.field == .reason }.count == 1)
        // It is filed under the root of the decided direction, which is the object
        // a person wants to see.
        #expect(result.objectID == crm)
        // The direction itself is back on the canvas, so its own text is visible.
        let visible = outcome("CRM", document: store.document)
        #expect(visible.results.contains { $0.objectID == crm && $0.state == .visible })
    }

    // MARK: - AC03, a private result is absent from a shared search

    @Test("AC03: an object outside the permitted set is absent, and named as not searched")
    func aPrivateResultIsAbsent() throws {
        let document = try store().document
        let permitted: Set<ObjectID> = [csv]
        let found = outcome("CRM", permitted: permitted, document: document)
        // The CRM direction would match in the unfiltered search, and does not
        // here. Rights are applied before the search, not filtered out of its
        // results afterwards, so the word never entered the answer.
        #expect(found.results.contains { $0.objectID == crm } == false)
        #expect(found.results.allSatisfy { permitted.contains($0.objectID) })
        // And the result set says it is narrower than the document, so a person is
        // not left to wonder why a term they can see elsewhere is missing.
        #expect(found.notSearched.contains(.outsideScope(crm)))
        #expect(found.isPartial)
    }

    @Test("AC03: the reason of a private direction is private too")
    func aPrivateReasonIsAbsent() throws {
        let document = try store().document
        let found = outcome("budget", permitted: [csv], document: document)
        // A leaked reason is a worse leak than a leaked title: it is the reasoning
        // behind somebody's decision.
        #expect(found.results.isEmpty)
    }

    @Test("An unfiltered search of a local document reports no scope")
    func aLocalDocumentIsNotPartial() {
        let document = Fixture.sarah()
        let found = outcome("export", document: document)
        #expect(found.notSearched.isEmpty)
        #expect(found.isPartial == false)
    }

    // MARK: - What was not searched is named

    @Test("Source content is never pretended to have been searched")
    func sourceContentIsNamedAsNotSearched() throws {
        let document = try store().document
        let found = outcome("export", document: document)
        // Kollio does not read inside a file to look for words, and a result list
        // that appeared to cover a person's evidence without having read it would
        // be a lie with a count on it.
        #expect(found.notSearched.contains(.sourceContent(count: 1)))
        #expect(found.isPartial)
    }

    @Test("A document with no source reports nothing about sources")
    func noSourceNoLine() {
        let found = outcome("export", document: Fixture.sarah())
        #expect(found.notSearched.isEmpty)
    }

    // MARK: - Excerpts

    @Test("An excerpt is the words around the match, not the top of the object")
    func theExcerptSurroundsTheMatch() {
        let padding = String(repeating: "rempli ", count: 40)
        let text = padding + "le mot recherché ici" + padding
        let excerpt = DocumentSearch.excerpt(text, around: "recherché")
        #expect(excerpt.contains("recherché"))
        // The match is not at the start, so the excerpt must have opened itself.
        #expect(excerpt.hasPrefix("…"))
    }

    @Test("A short object is excerpted in full, accents and all")
    func aShortObjectIsNotTruncated() {
        let text = "Réduire l'inscription"
        #expect(DocumentSearch.excerpt(text, around: "réduire") == text)
    }

    @Test("An excerpt never carries more than the limit")
    func excerptsAreBounded() {
        let long = String(repeating: "averylongword ", count: 200)
        let excerpt = DocumentSearch.excerpt(long, around: "averylongword")
        #expect(excerpt.count <= DocumentSearch.excerptLimit + 2)
    }
}
