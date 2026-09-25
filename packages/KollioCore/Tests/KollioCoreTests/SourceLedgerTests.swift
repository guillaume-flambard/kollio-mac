import Foundation
import Testing
@testable import KollioCore

/// Sources, citations and revisions.
///
/// The two rules this suite exists to hold:
///
/// - a citation is never silently moved when a source changes;
/// - losing a source never deletes the claim that was based on it.
@Suite("Source ledger")
struct SourceLedgerTests {
    private func source() -> SourceReference {
        SourceReference(
            id: "source:brief",
            kind: .text,
            title: "Product brief",
            locator: "file:///Users/someone/brief.md"
        )
    }

    private func revision(
        _ id: SourceRevisionID,
        _ sequence: Int,
        text: String = "Signup takes nine steps today."
    ) -> SourceRevision {
        SourceRevision(
            id: id,
            sequence: sequence,
            extraction: .ready(text: text),
            digest: "sha256:\(id.rawValue)"
        )
    }

    // MARK: A reference is not a copy

    @Test("Registering a link fetches nothing")
    func aLinkIsOnlyAPointer() {
        var ledger = SourceLedger()
        ledger.add(SourceReference(
            id: "source:link", kind: .link, title: "A page", locator: "https://example.invalid/page"
        ))
        // The locator is kept as written and no extraction is claimed. Fetching it
        // would be the app reaching out on its own initiative.
        #expect(ledger.source("source:link")?.extraction == .notAttempted)
        #expect(ledger.source("source:link")?.locator == "https://example.invalid/page")
    }

    @Test("An image is not understood until it is asked for")
    func anImageIsNotAutomaticallyRead() {
        let reference = SourceReference(
            id: "source:shot", kind: .image, title: "A screenshot", locator: "file:///tmp/shot.png"
        )
        #expect(reference.extraction == .notAttempted)
        #expect(reference.extraction.isUsable == false)
    }

    // MARK: Citations

    @Test("A citation towards something that is not there is refused")
    func citationTowardsNothingIsRefused() {
        var ledger = SourceLedger()
        ledger.add(source())

        // A missing source: creating this would look like evidence.
        let orphan = Citation(
            id: "citation:orphan", claimID: ObjectID("object:claim"),
            sourceID: "source:absent", revisionID: "rev:1",
            locator: SourceLocator(page: 1), quote: "Something"
        )
        if case .success = ledger.cite(orphan) {
            Issue.record("a citation towards an unknown source must be refused")
        }

        // A real source, but a revision that does not exist.
        let wrongRevision = Citation(
            id: "citation:wrong", claimID: ObjectID("object:claim"),
            sourceID: "source:brief", revisionID: "rev:9",
            locator: SourceLocator(page: 1), quote: "Something"
        )
        if case .success = ledger.cite(wrongRevision) {
            Issue.record("a citation towards an unknown revision must be refused")
        }
        #expect(ledger.allCitations().isEmpty)
    }

    @Test("A citation is unverified until a person checks it")
    func verificationNeedsAnObservation() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")

        let citation = Citation(
            id: "citation:1", claimID: ObjectID("object:ctx"), sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(lineRange: 1..<4), quote: "nine steps"
        )
        #expect((try? ledger.cite(citation).get()) != nil)
        #expect(ledger.citation("citation:1")?.status == .unverified)
        #expect(ledger.citation("citation:1")?.status.isVerified == false)

        // The type makes the honest path the only path: an observation and an
        // author are both required, and there is no "mark as verified" without them.
        _ = ledger.recordVerification(
            "citation:1", observation: "Confirmed against the brief, line 2.", by: "person:owner"
        )
        #expect(ledger.citation("citation:1")?.status.isVerified == true)
        if case .verified(let observation, let author, _) = ledger.citation("citation:1")!.status {
            #expect(observation.contains("line 2"))
            #expect(author == "person:owner")
        } else {
            Issue.record("the verification should carry its observation and its author")
        }
    }

    @Test("A citation opens the version it was read against")
    func citationKeepsItsRevision() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:1", claimID: ObjectID("object:ctx"), sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(page: 2), quote: "nine steps"
        ))
        _ = ledger.importRevision(revision("rev:2", 2, text: "Signup takes three steps."), for: "source:brief")

        // Two revisions exist, and the citation still opens the first one. This is
        // the whole point of keeping history.
        #expect(ledger.source("source:brief")?.revisions.count == 2)
        #expect(ledger.citation("citation:1")?.revisionID == "rev:1")
        #expect(ledger.source("source:brief")?.revision("rev:1")?.extraction.text == "Signup takes nine steps today.")
    }

    // MARK: Updating a source

    @Test("A new revision flags what depends on the old one, and never moves it")
    func newRevisionFlagsAndDoesNotMove() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:1", claimID: ObjectID("object:ctx"), sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(lineRange: 10..<14), quote: "nine steps"
        ))

        let outcome = ledger.importRevision(
            revision("rev:2", 2, text: "Signup takes three steps."), for: "source:brief"
        )
        if case .imported(_, _, let needsReview, _) = outcome {
            #expect(needsReview == ["citation:1"])
        } else {
            Issue.record("the second import should report what it affected")
        }

        // The locator is untouched, so opening the citation still lands on the
        // text the claim was actually based on. It is flagged, not relocated to
        // whatever line the sentence happens to sit on now.
        #expect(ledger.citation("citation:1")?.locator.lineRange == 10..<14)
        #expect(ledger.citation("citation:1")?.revisionID == "rev:1")
        if case .needsReview = ledger.citation("citation:1")!.status {} else {
            Issue.record("a citation on a superseded revision needs review")
        }
        #expect(ledger.citation("citation:1")?.status.isVerified == false)
    }

    @Test("A verified citation is flagged, not erased, when the source moves")
    func verificationSurvivesButIsFlagged() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:1", claimID: ObjectID("object:ctx"), sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(page: 1), quote: "nine steps"
        ).verified(observation: "Checked on Tuesday.", by: "person:owner"))

        _ = ledger.importRevision(revision("rev:2", 2, text: "Now three steps."), for: "source:brief")

        // The citation is still there, with its observation intact and pointing at
        // the revision it was read against.
        let citation = ledger.citation("citation:1")
        #expect(citation != nil)
        #expect(citation?.revisionID == "rev:1")
        // But it is no longer presented as a current check. The observation was of
        // revision 1, and revision 1 is no longer what the source says.
        if case .needsReview = citation!.status {
            #expect(citation!.status.isVerified == false)
        } else {
            Issue.record("a verified citation on a superseded revision must need review")
        }
    }

    @Test("A failed extraction is recorded, and the good version stays current")
    func failedExtractionKeepsThePreviousVersion() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:1", claimID: ObjectID("object:ctx"),
            sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(page: 1), quote: "nine steps"
        ))

        // An image-only PDF is the real case: the import runs, and gets no text.
        let scanned = SourceRevision(
            id: "rev:2", sequence: 2,
            extraction: .noText(reason: "the PDF has no text layer"),
            digest: "sha256:rev2"
        )
        let outcome = ledger.importRevision(scanned, for: "source:brief")

        // The attempt is kept, because "we read it and there is no text" is a fact
        // the chip has to be able to show.
        if case .imported(_, _, _, let becameCurrent) = outcome {
            #expect(becameCurrent == false)
        } else {
            Issue.record("a failed extraction must still be recorded")
        }
        #expect(ledger.source("source:brief")?.attempts.count == 2)
        // And the good version is still the one a new citation reads against, so a
        // broken import cannot replace the text a claim was based on.
        #expect(ledger.source("source:brief")?.latest?.id == "rev:1")
        #expect(ledger.source("source:brief")?.extraction.isUsable == true)
        // Nothing moved, so nothing is flagged.
        #expect(ledger.citation("citation:1")?.status == .unverified)
    }

    @Test("A first import that yields no text still becomes the current revision")
    func firstFailedExtractionIsCurrent() {
        var ledger = SourceLedger()
        ledger.add(source())
        // With nothing usable before it, the attempt is the best information there
        // is. The chip then says "no text" instead of "not read yet", which is the
        // difference between a fact and an absence.
        let scanned = SourceRevision(
            id: "rev:1", sequence: 1,
            extraction: .noText(reason: "the PDF has no text layer"),
            digest: "sha256:rev1"
        )
        let outcome = ledger.importRevision(scanned, for: "source:brief")
        if case .imported(_, _, _, let becameCurrent) = outcome {
            #expect(becameCurrent)
        } else {
            Issue.record("the first attempt should be recorded as the current one")
        }
        #expect(ledger.source("source:brief")?.latest?.id == "rev:1")
        #expect(ledger.source("source:brief")?.extraction.isUsable == false)
    }

    @Test("An image-only PDF says it has no text instead of pretending")
    func noTextIsSaidHonestly() {
        let extraction = SourceReference.Extraction.noText(reason: "scanned, no text layer")
        #expect(extraction.isUsable == false)
        #expect(extraction.text == nil)
    }

    // MARK: Losing a source

    @Test("A removed source does not make the claim vanish")
    func removedSourceKeepsTheClaim() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:1", claimID: ObjectID("object:ctx"), sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(page: 1), quote: "nine steps"
        ))

        ledger.removeSourceKeepingHistory("source:brief")

        // The citation, its quote and its locator are all still there, and it says
        // why it can no longer be checked. The conclusion the person drew is not
        // deleted because a file went missing.
        let citation = ledger.citation("citation:1")
        #expect(citation != nil)
        #expect(citation?.quote == "nine steps")
        #expect(citation?.locator.page == 1)
        if case .sourceMissing = citation!.status {} else {
            Issue.record("a citation whose source is gone must say so")
        }
    }

    @Test("A source that cannot be found flags its citations")
    func missingSourceFlagsCitations() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:a", claimID: ObjectID("object:claim"),
            sourceID: "source:brief", revisionID: "rev:1",
            locator: .init(page: 1), quote: "nine steps"
        ))

        let affected = ledger.markSourceUnavailable("source:brief", reason: "the file moved")
        #expect(affected == ["citation:a"])
        if case .sourceMissing(let reason) = ledger.citation("citation:a")!.status {
            #expect(reason.contains("moved"))
        } else {
            Issue.record("an unavailable source must be visible on its citations")
        }
    }

    @Test("A verified citation is flagged when its source disappears, not unverified")
    func verifiedCitationIsFlaggedNotUnverified() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        _ = ledger.cite(Citation(
            id: "citation:a", claimID: ObjectID("object:claim"),
            sourceID: "source:brief", revisionID: "rev:1",
            locator: .init(page: 1), quote: "nine steps"
        ).verified(observation: "Checked on Tuesday.", by: "person:owner"))

        _ = ledger.markSourceUnavailable("source:brief", reason: "the file moved")

        // The observation happened, so it is not rewritten into "never checked".
        // It is marked as needing a look, which is a different and honest claim.
        if case .needsReview = ledger.citation("citation:a")!.status {} else {
            Issue.record("a verified citation whose source vanished needs review")
        }
    }

    // MARK: Listing

    @Test("Citations are listed in a stable order")
    func listingIsStable() {
        var ledger = SourceLedger()
        ledger.add(source())
        _ = ledger.importRevision(revision("rev:1", 1), for: "source:brief")
        for id in ["citation:c", "citation:a", "citation:b"] {
            _ = ledger.cite(Citation(
                id: CitationID(id), claimID: ObjectID("object:ctx"), sourceID: "source:brief", revisionID: "rev:1",
                locator: .init(page: 1), quote: "x"
            ))
        }
        #expect(ledger.citations(of: "source:brief").map(\.id.rawValue)
            == ["citation:a", "citation:b", "citation:c"])
    }
}
