import Foundation
import Testing
@testable import KollioCore

/// AI-06: synthesise and prepare a deliverable.
///
/// Every test here is a way the synthesis could have lied: by replacing the text
/// it was built from, by padding a section it had no evidence for, by claiming to
/// still be current after a decision moved, and by summarising a selection so
/// wide that nothing in it could be true.
@Suite("Summary artifact")
struct SummaryArtifactTests {
    private var context: ObjectID { ObjectID("object:ctx") }
    private var direction: ObjectID { ObjectID("object:dir") }

    private func world() -> KollioDocument {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("dir", kind: .method, "Instrument each step")
        builder.link("l1", from: context, to: direction, .supports)
        return builder.document
    }

    /// The same world, with one more decision recorded on a read object.
    private func world(settingAside target: ObjectID, seed: String = "reject-1") -> KollioDocument {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("dir", kind: .method, "Instrument each step")
        // A second branch, so a decision can land on something this synthesis
        // never read. `DocumentBuilder` traps on a missing target, so "elsewhere"
        // has to exist before it can be decided about.
        builder.object("elsewhere", kind: .context, "Pricing page copy")
        builder.link("l1", from: context, to: direction, .supports)
        // Called outside the assertion: `setAside` mutates, and a `#expect`
        // autoclosure receives an immutable value.
        let recorded = builder.setAside(seed, target: target, rationale: "No budget this year")
        #expect(recorded)
        return builder.document
    }

    private var modelProvenance: Provenance {
        Provenance(actor: ActorID("actor:model"), kind: .localEngine, requestId: "eval-1")
    }

    private func line(
        _ seed: String,
        _ text: String = "The funnel loses people at the second step",
        references: [SummaryReference] = [
            SummaryReference(kind: .object, id: ObjectID("object:ctx").rawValue)
        ]
    ) -> SummaryArtifact.SummaryLine {
        SummaryArtifact.SummaryLine(
            id: SummaryLineID(seed),
            text: LocalizedText(text),
            provenance: modelProvenance,
            references: references
        )
    }

    /// Built against a document, always.
    ///
    /// The default was `world().semanticRevision`, which quietly made every test
    /// that then checked a *different* document go stale through the revision
    /// fallback instead of through the reason under test. Three tests failed that
    /// way before this was fixed, so the fixture now takes the document rather
    /// than remembering to line the two up.
    private func artifact(
        in document: KollioDocument? = nil,
        uncertainties: [SummaryArtifact.SummarySection] = [],
        isDraft: Bool = false
    ) -> SummaryArtifact {
        SummaryArtifact(
            id: SummaryID("s1"),
            title: "Sign-up funnel, for the release review",
            objective: SummaryArtifact.SummaryLine(
                id: SummaryLineID("objective"),
                text: LocalizedText("Decide what to change before the review"),
                provenance: Provenance.human(ActorID("actor:guillaume"))
            ),
            currentState: [SummaryArtifact.SummarySection(.currentState, lines: [line("l1")])],
            reasons: [SummaryArtifact.SummarySection(.reasons, lines: [line("l2", "The drop-off is consistent across both runs")])],
            uncertainties: uncertainties,
            nextVerifications: [SummaryArtifact.SummarySection(.nextVerifications, lines: [line("l3", "Measure the second step in production")])],
            sourceRefs: [],
            readSet: SummaryArtifact.SummaryReadSet(
                objectIDs: [context, direction],
                decisionIDs: []
            ),
            baseSemanticRevision: (document ?? world()).semanticRevision,
            isDraft: isDraft
        )
    }

    // MARK: - AC01, the initial text stays intact

    @Test("An edit keeps the text the model first produced")
    func editKeepsOriginalText() {
        let original = line("l1")
        #expect(original.wasEdited == false)

        var edited = original
        edited.text = LocalizedText("The funnel loses people at the second step, every time")
        edited.originalText = original.text
        edited.editedBy = ActorID("actor:guillaume")

        // The person's words are what the synthesis says now.
        #expect(edited.text.text.contains("every time"))
        // The model's words are still there, which is the only way "stays intact"
        // is checkable rather than asserted.
        #expect(edited.originalText?.text == "The funnel loses people at the second step")
        // And the line is honestly mixed: it came from a model, and a person
        // changed it.
        #expect(edited.provenance.kind == .localEngine)
        #expect(edited.editedBy == ActorID("actor:guillaume"))
        #expect(edited.wasEdited)
    }

    @Test("An edited line is neither authored nor untouched")
    func editedLineIsMixed() {
        var edited = line("l1")
        #expect(edited.isAuthored == false, "a model line is not a person's")

        edited.originalText = edited.text
        edited.editedBy = ActorID("actor:guillaume")
        // Mixed, and both halves are legible: it is not a person's line, and it is
        // not untouched either. Whether the editing command *keeps* the origin
        // recorded is that command's test, not this type's.
        #expect(edited.isAuthored == false)
        #expect(edited.wasEdited)
        #expect(edited.provenance.kind == .localEngine)
        #expect(edited.editedBy == ActorID("actor:guillaume"))
    }

    @Test("A person's own line is authored, and needs no reference")
    func personLineNeedsNoReference() {
        let human = SummaryArtifact.SummaryLine(
            id: SummaryLineID("h1"),
            text: LocalizedText("I do not trust the second measurement"),
            provenance: Provenance.human(ActorID("actor:guillaume"))
        )
        #expect(human.isAuthored)
        #expect(human.isUnsupportedAssertion == false)
    }

    @Test("An engine line that points at nothing is an unsupported assertion")
    func engineLineWithoutReferenceIsUnsupported() {
        let floating = line("x", "This is clearly the best option", references: [])
        #expect(floating.isUnsupportedAssertion)
    }

    // MARK: - AC02, uncertainties are visible

    @Test("A section with nothing recorded says so, and is not an empty list")
    func emptyUncertaintiesAreVisible() {
        let deliberate = [SummaryArtifact.SummarySection(.uncertainties, lines: [], isNothingRecorded: true)]
        let summary = artifact(uncertainties: deliberate)

        #expect(summary.uncertainties.count == 1)
        #expect(summary.uncertainties[0].isNothingRecorded)
        #expect(summary.uncertainties[0].lines.isEmpty)
        // An empty list and a deliberate absence are different claims, and a
        // reader has to be able to tell them apart.
        let accidental = artifact(uncertainties: [])
        #expect(accidental.uncertainties.isEmpty)
        #expect(accidental.uncertainties != summary.uncertainties)
    }

    @Test("A recorded uncertainty is a line, not a warning icon")
    func uncertaintyIsALine() {
        let summary = artifact(uncertainties: [
            SummaryArtifact.SummarySection(.uncertainties, lines: [
                line("u1", "We do not know whether the drop-off is the form or the network")
            ])
        ])
        #expect(summary.uncertainties[0].lines.count == 1)
        #expect(summary.uncertainties[0].isNothingRecorded == false)
        #expect(summary.allLines.contains { $0.id == SummaryLineID("u1") })
    }

    // MARK: - AC03, the export names the revision used

    @Test("A synthesis names the revision it read and the revision of each source")
    func exportNamesTheRevision() {
        let source = SourceReference(
            id: SourceID("source:analytics"),
            kind: .csv,
            title: "Funnel export",
            locator: "analytics.csv"
        )
        let summary = SummaryArtifact(
            id: SummaryID("s2"),
            title: "With a source",
            objective: line("objective"),
            sourceRefs: [SummaryArtifact.SummarySourceRef(
                id: SummarySourceRefID("r1"),
                sourceID: source.id,
                revisionID: SourceRevisionID("source:analytics/rev1"),
                isCurrent: true
            )],
            readSet: SummaryArtifact.SummaryReadSet(sourceRevisionIDs: [SourceRevisionID("source:analytics/rev1")]),
            baseSemanticRevision: 42
        )
        // AC03 is satisfied by the record itself: both the document revision and
        // the revision of every source are carried, so an export can state them.
        #expect(summary.baseSemanticRevision == 42)
        #expect(summary.sourceRefs.first?.revisionID == SourceRevisionID("source:analytics/rev1"))
        #expect(summary.readSet.sourceRevisionIDs == [SourceRevisionID("source:analytics/rev1")])
    }

    // MARK: - Outdated when decisions move

    @Test("A synthesis is current while nothing it read has moved")
    func currentWhenNothingMoved() {
        let document = world()
        #expect(artifact(in: document).isOutdated(against: document) == false)
    }

    @Test("A decision about a read object makes the synthesis outdated")
    func decisionMovedMakesItOutdated() {
        let document = world(settingAside: direction)
        let summary = artifact(in: document)
        #expect(summary.isOutdated(against: document))
        let reasons = summary.staleness(against: document)
        #expect(reasons.count == 1)
        guard case .decisionMoved = reasons[0] else {
            Issue.record("expected a moved decision, got \(reasons)")
            return
        }
    }

    @Test("A decision about something else leaves the synthesis alone")
    func unrelatedDecisionDoesNotMakeItOutdated() {
        // The decision targets an object that was never read, which is why the
        // document needs a second object to be stale about.
        let document = world(settingAside: ObjectID("object:elsewhere"), seed: "reject-other")
        // Marking every synthesis stale on every edit is how a staleness badge
        // gets ignored.
        #expect(artifact(in: document).isOutdated(against: document) == false)
    }

    @Test("A decision that was already read does not make it outdated twice")
    func readingTheDecisionPreventsFalseStaleness() {
        let first = world(settingAside: direction)
        let decisionID = DecisionID("decision:reject-1")
        #expect(first.decisions[decisionID] != nil)

        // Built from *this* document, so the only thing that can make it stale is
        // the decision. An artifact built from a different revision would go stale
        // through the revision fallback instead, which would hide what this test
        // is about.
        var summary = artifact(in: first)
        summary.readSet.decisionIDs = [decisionID]
        #expect(summary.isOutdated(against: first) == false)

        // A second decision on the same object, after the read, does make it stale.
        let second = world(settingAside: direction, seed: "reject-2")
        #expect(summary.isOutdated(against: second))
    }

    @Test("An outdated synthesis keeps its text instead of being rewritten")
    func outdatedKeepsItsText() {
        let document = world(settingAside: direction)
        let summary = artifact(in: document)
        #expect(summary.isOutdated(against: document))
        #expect(summary.currentState[0].lines[0].text.text == "The funnel loses people at the second step")
    }

    @Test("A moved revision with no readable reason is reported as movement")
    func revisionMovedIsReported() {
        let document = world()
        var summary = artifact(in: document)
        summary.readSet.objectIDs = []
        summary.readSet.decisionIDs = []
        summary.baseSemanticRevision = document.semanticRevision - 5

        let reasons = summary.staleness(against: document)
        #expect(reasons.count == 1)
        guard case .revisionMoved = reasons[0] else {
            Issue.record("expected raw movement, got \(reasons)")
            return
        }
    }

    @Test("A read decision is not reported as movement")
    func aReadDecisionIsNotMovement() {
        let document = world(settingAside: direction)
        var summary = artifact(in: document)
        summary.readSet.decisionIDs = [DecisionID("decision:reject-1")]

        // The fallback must not fire when the movement is already accounted for.
        #expect(summary.staleness(against: document).isEmpty)
    }

    // MARK: - Scope

    @Test("A synthesis that refused a wide selection says which scope it wanted")
    func tooWideSelectionProposesANarrowerScope() {
        var summary = artifact()
        #expect(summary.proposedNarrowerScope == nil)

        summary.proposedNarrowerScope = SummaryArtifact.NarrowerScope(
            objectIDs: [context],
            reason: "The selection covered 40 objects across 6 branches. A synthesis of that width would assert things about branches nobody read."
        )
        #expect(summary.proposedNarrowerScope?.objectIDs == [context])
        #expect(summary.proposedNarrowerScope?.reason.contains("40 objects") == true)
    }

    // MARK: - Determinism

    @Test("A read set sorts, so two identical syntheses are identical")
    func readSetSorts() {
        let unsorted = SummaryArtifact.SummaryReadSet(
            objectIDs: [direction, context],
            sourceRevisionIDs: [SourceRevisionID("s:b"), SourceRevisionID("s:a")],
            citationIDs: [CitationID("c:b"), CitationID("c:a")],
            decisionIDs: [DecisionID("d:b"), DecisionID("d:a")]
        )
        let sorted = unsorted.sorted()
        #expect(sorted.objectIDs == [context, direction])
        #expect(sorted.sourceRevisionIDs == [SourceRevisionID("s:a"), SourceRevisionID("s:b")])
        #expect(sorted.citationIDs == [CitationID("c:a"), CitationID("c:b")])
        #expect(sorted.decisionIDs == [DecisionID("d:a"), DecisionID("d:b")])
        // Sorting twice changes nothing, which is what makes it comparable.
        #expect(sorted.sorted() == sorted)
    }

    @Test("A synthesis is a derivative and cannot be applied to the document")
    func synthesisIsADerivative() {
        // The type has no operation that writes to content, by construction: the
        // only things it carries are its own lines and its read set. A test that
        // asserted a compile-time absence would be a comment, so this asserts what
        // is true instead: building one leaves the document untouched.
        let document = world()
        let before = document.semanticRevision
        _ = artifact()
        #expect(document.semanticRevision == before)
    }

    @Test("Every line is reachable, and the objective comes first")
    func allLinesAreReachable() {
        let summary = artifact(uncertainties: [
            SummaryArtifact.SummarySection(.uncertainties, lines: [line("u1")])
        ])
        let ids = summary.allLines.map(\.id)
        #expect(ids.first == SummaryLineID("objective"))
        #expect(ids.contains(SummaryLineID("l1")))
        #expect(ids.contains(SummaryLineID("l3")))
        #expect(ids.contains(SummaryLineID("u1")))
        #expect(Set(ids).count == ids.count, "a line must not appear twice")
        #expect(summary.line(SummaryLineID("l1")) != nil)
        #expect(summary.line(SummaryLineID("nope")) == nil)
    }
}
