import Foundation
import Testing
@testable import KollioCore

/// AI-06's AC03, and the compact block: what a person actually receives.
///
/// An export is the last step before a document leaves the app, and it is the
/// easiest place for the product's rules to quietly stop applying. Every test here
/// is a way the export could have lied to the person receiving it.
@Suite("Summary export")
struct SummaryExportTests {
    private var context: ObjectID { ObjectID("object:ctx") }
    private var direction: ObjectID { ObjectID("object:dir") }

    private func world(settingAside: Bool = false) -> KollioDocument {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("dir", kind: .method, "Instrument each step")
        builder.object("elsewhere", kind: .context, "Pricing page copy")
        if settingAside {
            let recorded = builder.setAside("reject-1", target: direction, rationale: "No budget")
            #expect(recorded)
        }
        return builder.document
    }

    private var human: Provenance { .human(ActorID("actor:guillaume")) }
    private var engine: Provenance {
        Provenance(actor: ActorID("actor:model"), kind: .localEngine, requestId: "r1")
    }

    private func line(
        _ seed: String,
        _ text: String,
        provenance: Provenance? = nil,
        original: String? = nil,
        editedBy: ActorID? = nil,
        references: [SummaryReference] = [SummaryReference(kind: .object, id: ObjectID("object:ctx").rawValue)]
    ) -> SummaryArtifact.SummaryLine {
        SummaryArtifact.SummaryLine(
            id: SummaryLineID(seed),
            text: LocalizedText(text),
            provenance: provenance ?? engine,
            originalText: original.map { LocalizedText($0, variants: [:]) },
            editedBy: editedBy,
            references: references
        )
    }

    /// A confirmed synthesis where every section has said something.
    private func complete(
        in document: KollioDocument,
        uncertainties: [SummaryArtifact.SummarySection] = [],
        sourceRefs: [SummaryArtifact.SummarySourceRef] = []
    ) -> SummaryArtifact {
        SummaryArtifact(
            id: SummaryID("s1"),
            title: "Sign-up funnel, for the release review",
            objective: SummaryArtifact.SummaryLine(
                id: SummaryLineID("objective"),
                text: LocalizedText("Decide what to change before the review"),
                provenance: human
            ),
            currentState: [SummaryArtifact.SummarySection(.currentState, lines: [
                line("l1", "The funnel loses people at the second step")
            ])],
            reasons: [SummaryArtifact.SummarySection(.reasons, lines: [
                line("l2", "The drop-off is the same in both runs")
            ])],
            uncertainties: uncertainties.isEmpty
                ? [SummaryArtifact.SummarySection(.uncertainties, lines: [], isNothingRecorded: true)]
                : uncertainties,
            nextVerifications: [SummaryArtifact.SummarySection(.nextVerifications, lines: [
                line("l3", "Measure the second step in production")
            ])],
            sourceRefs: sourceRefs,
            readSet: SummaryArtifact.SummaryReadSet(
                objectIDs: [context, direction],
                sourceRevisionIDs: sourceRefs.map(\.revisionID)
            ),
            baseSemanticRevision: document.semanticRevision,
            isDraft: false
        )
    }

    // MARK: - AC03, the export names the revision used

    @Test("The export names the revision it read, in the header")
    func namesTheRevision() {
        let document = world()
        let summary = complete(in: document)
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")

        #expect(exported.usedRevision == document.semanticRevision)
        #expect(exported.text.contains("Document revision read: **\(document.semanticRevision)**"))
        // Named up front rather than in a footnote, because a reader who has to
        // hunt for it will not check it.
        let header = exported.text.prefix(600)
        #expect(header.contains("Document revision now"))
    }

    @Test("The filename carries the revision, so two exports are not the same file")
    func filenameCarriesTheRevision() {
        let document = world()
        var older = complete(in: document)
        older.baseSemanticRevision = 3
        let a = SummaryExport.markdown(older, against: document, languageCode: "en")
        older.baseSemanticRevision = 4
        let b = SummaryExport.markdown(older, against: document, languageCode: "en")
        #expect(a.filename != b.filename)
        #expect(a.filename.contains("-r3-"))
        #expect(b.filename.contains("-r4-"))
    }

    @Test("The export says a draft is a draft")
    func draftIsMarked() {
        let document = world()
        var summary = complete(in: document)
        summary.isDraft = true
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("draft, not yet handed over"))
    }

    @Test("The export says when it has moved, and says what moved")
    func saysWhenOutdated() {
        let fresh = world()
        let summary = complete(in: fresh)
        let moved = world(settingAside: true)
        let exported = SummaryExport.markdown(summary, against: moved, languageCode: "en")

        #expect(exported.isOutdated)
        #expect(exported.text.contains("**Outdated.**"))
        #expect(exported.text.contains("a decision moved since this was written"))
        // And it is honest when nothing moved.
        let current = SummaryExport.markdown(summary, against: fresh, languageCode: "en")
        #expect(current.isOutdated == false)
        #expect(current.text.contains("every decision in the read set still stands"))
    }

    // MARK: - The export does not fill gaps

    @Test("A section that recorded nothing is exported as exactly that")
    func nothingRecordedStaysNothing() {
        let document = world()
        let summary = complete(in: document)
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("## Uncertainties"))
        #expect(exported.text.contains("_Nothing was recorded here._"))
    }

    @Test("A recorded uncertainty is exported as a line, not as absence")
    func recordedUncertaintyIsALine() {
        let document = world()
        let summary = complete(in: document, uncertainties: [
            SummaryArtifact.SummarySection(.uncertainties, lines: [
                line("u1", "We do not know whether the form or the network is at fault")
            ])
        ])
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("form or the network"))
        #expect(exported.text.contains("_Nothing was recorded here._") == false)
    }

    @Test("A draft does not print an empty heading as if it were finished")
    func draftDoesNotFakeCompletion() {
        let document = world()
        // A draft with a section nobody has written, which is what a draft is.
        let summary = SummaryArtifact(
            id: SummaryID("s2"),
            title: "Unfinished",
            objective: SummaryArtifact.SummaryLine(
                id: SummaryLineID("objective"), text: LocalizedText("Work it out"), provenance: human),
            readSet: SummaryArtifact.SummaryReadSet(objectIDs: [context]),
            baseSemanticRevision: document.semanticRevision
        )
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("## Reasons"))
        #expect(exported.text.contains("_Not written yet. This synthesis is a draft._"))
    }

    // MARK: - A correction is never misattributed

    @Test("A corrected line is marked in place and keeps its original in an appendix")
    func correctionIsVisible() {
        let document = world()
        var summary = complete(in: document)
        summary.currentState[0].lines[0] = line(
            "l1",
            "The funnel loses people at the second step, every time",
            original: "The funnel loses people at the second step",
            editedBy: ActorID("actor:guillaume")
        )
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")

        // Marked where it is read, and not quietly presented as the model's words.
        #expect(exported.text.contains("_(corrected by actor:guillaume)_"))
        #expect(exported.text.contains("## Corrections"))
        #expect(exported.text.contains("**was** The funnel loses people at the second step"))
        #expect(exported.text.contains("**kept** The funnel loses people at the second step, every time"))
    }

    @Test("An untouched line carries no correction note")
    func untouchedLinesAreNotMarked() {
        let document = world()
        let exported = SummaryExport.markdown(complete(in: document), against: document, languageCode: "en")
        #expect(exported.text.contains("corrected") == false)
        #expect(exported.text.contains("## Corrections") == false)
    }

    // MARK: - Sources

    private func source() -> SourceReference {
        SourceReference(
            id: SourceID("source:analytics"), kind: .csv,
            title: "Funnel export", locator: "analytics.csv"
        )
    }

    private func revision() -> SourceRevision {
        SourceRevision(
            id: SourceRevisionID("source:analytics/rev1"),
            sequence: 1,
            extraction: .ready(text: "9, 3, 7"),
            digest: "sha256:abc"
        )
    }

    @Test("A source is exported with the revision that was read")
    func sourceNamesItsRevision() throws {
        var store = DocumentStore(document: world())
        try store.apply([
            .attachSource(.init(source: source(), provenance: human)),
            .importSourceRevision(.init(sourceID: source().id, revision: revision(), provenance: human)),
        ])

        var summary = complete(in: store.document, sourceRefs: [
            SummaryArtifact.SummarySourceRef(
                id: SummarySourceRefID("r1"),
                sourceID: source().id,
                revisionID: revision().id,
                isCurrent: true
            )
        ])
        summary.baseSemanticRevision = store.document.semanticRevision
        let exported = SummaryExport.markdown(summary, against: store.document, languageCode: "en")
        #expect(exported.text.contains("Funnel export"))
        #expect(exported.text.contains("source:analytics/rev1"))
        // The revision that was read is the one named, not merely that a source
        // was used.
        #expect(exported.text.contains("revision `source:analytics/rev1`"))
    }

    @Test("A synthesis with no source says so rather than omitting the heading")
    func noSourceIsStated() {
        let document = world()
        let exported = SummaryExport.markdown(complete(in: document), against: document, languageCode: "en")
        #expect(exported.text.contains("_No source was cited._"))
    }

    // MARK: - The read set travels

    @Test("The export states what was read")
    func statesTheReadSet() {
        let document = world()
        var summary = complete(in: document)
        summary.readSet.citationIDs = [CitationID("c1"), CitationID("c2")]
        summary.readSet.decisionIDs = [DecisionID("d1")]
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("## What was read"))
        #expect(exported.text.contains("- Objects: 2"))
        #expect(exported.text.contains("- Citations: 2"))
        #expect(exported.text.contains("- Decisions: 1"))
    }

    @Test("A truncated read says the list is not the whole document")
    func truncatedReadIsStated() {
        let document = world()
        var summary = complete(in: document)
        summary.readSet.wasTruncated = true
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("The walk stopped at its bound"))
    }

    @Test("A refused wider scope is stated in the export too")
    func narrowerScopeIsStated() {
        let document = world()
        var summary = complete(in: document)
        summary.proposedNarrowerScope = SummaryArtifact.NarrowerScope(
            objectIDs: [context],
            reason: "The selection covered 40 objects across 6 branches."
        )
        let exported = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(exported.text.contains("narrower scope than the one it was asked for"))
        #expect(exported.text.contains("40 objects"))
    }

    // MARK: - The compact block

    @Test("The compact block shows the first line, not a shortened section")
    func compactIsNotAShortExport() {
        let document = world()
        let block = SummaryExport.compact(complete(in: document), against: document, languageCode: "en")
        #expect(block.stateHeadline == "The funnel loses people at the second step")
        // A headline is one line. Three would read as a summary of the section.
        #expect(block.stateHeadline.contains("\n") == false)
        #expect(block.objective == "Decide what to change before the review")
    }

    @Test("The compact block distinguishes 'nothing uncertain' from 'not asked yet'")
    func compactDistinguishesAbsence() {
        let document = world()
        let nothingUncertain = SummaryExport.compact(complete(in: document), against: document, languageCode: "en")
        #expect(nothingUncertain.statesNothingIsUncertain)
        #expect(nothingUncertain.uncertaintyCount == 0)

        var unfilled = complete(in: document)
        unfilled.uncertainties = []
        let blank = SummaryExport.compact(unfilled, against: document, languageCode: "en")
        #expect(blank.uncertaintyCount == 0)
        // The same count, a different claim, and the block has to say which.
        #expect(blank.statesNothingIsUncertain == false)
    }

    @Test("The compact block carries the revision and the outdated state")
    func compactCarriesRevisionAndStaleness() {
        let fresh = world()
        let summary = complete(in: fresh)
        let block = SummaryExport.compact(summary, against: fresh, languageCode: "en")
        #expect(block.usedRevision == fresh.semanticRevision)
        #expect(block.isOutdated == false)

        let moved = world(settingAside: true)
        #expect(SummaryExport.compact(summary, against: moved, languageCode: "en").isOutdated)
    }

    // MARK: - Language

    @Test("The export writes the variant it was asked for")
    func writesTheChosenLanguage() {
        let document = world()
        var summary = complete(in: document)
        summary.objective = SummaryArtifact.SummaryLine(
            id: SummaryLineID("objective"),
            text: LocalizedText("Décider quoi changer avant la revue", variants: ["en": "Decide what to change before the review"]),
            provenance: human
        )
        #expect(SummaryExport.markdown(summary, against: document, languageCode: "en").text.contains("Decide what to change"))
        #expect(SummaryExport.markdown(summary, against: document, languageCode: "fr").text.contains("Décider quoi changer"))
    }

    @Test("Two exports of the same synthesis are identical")
    func exportIsDeterministic() {
        let document = world()
        let summary = complete(in: document)
        let a = SummaryExport.markdown(summary, against: document, languageCode: "en")
        let b = SummaryExport.markdown(summary, against: document, languageCode: "en")
        #expect(a.text == b.text)
        #expect(a.filename == b.filename)
    }
}
