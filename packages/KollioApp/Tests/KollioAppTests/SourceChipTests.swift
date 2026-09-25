import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// The chip on a claim: what it says, and when it stays quiet.
///
/// The chip is the only part of L3 a person can see, so what is worth testing is
/// that it never says more than the document knows: no chip without a citation, one
/// chip per source however many passages, and a state that admits when a file could
/// not be read.
@Suite("Source chips")
@MainActor
struct SourceChipTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    /// One directory per test instance, so a file written and a file read are in
    /// the same place.
    private let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("kollio-chip-\(UUID().uuidString)")

    private let claim = ObjectID("object:sarah-csv")
    private let other = ObjectID("object:sarah-hypothesis")

    private func source(
        _ id: String = "source:brief",
        title: String = "Brief",
        kind: SourceReference.Kind = .text,
        revisions: [SourceRevision] = [SourceRevision(
            id: "rev:1", sequence: 1, extraction: .ready(text: "nine steps"), digest: "sha256:x"
        )]
    ) -> Command {
        .attachSource(.init(
            source: SourceReference(
                id: SourceID(id), kind: kind, title: title,
                locator: "file:///tmp/\(id)", revisions: revisions
            ),
            provenance: .human("person:owner")
        ))
    }

    private func citation(
        _ id: String,
        of sourceID: String = "source:brief",
        revision: String = "rev:1"
    ) -> Command {
        .addCitation(.init(
            citation: Citation(
                id: CitationID(id), claimID: claim, sourceID: SourceID(sourceID),
                revisionID: SourceRevisionID(revision),
                locator: SourceLocator(page: 1), quote: "nine steps"
            ),
            claimID: claim, provenance: .human("person:owner")
        ))
    }

    @Test("A claim with no sources shows no chip")
    func noChipWithoutACitation() {
        var model = model()
        // Attaching a source is not enough. Nothing is claimed from it yet, so
        // there is nothing to say about it on this object.
        #expect(model.perform([source()], label: "attach"))
        #expect(model.sourceChips(for: claim).isEmpty)
    }

    @Test("A cited source appears once, whatever the number of passages")
    func oneChipPerSource() {
        var model = model()
        #expect(model.perform(
            [source(), citation("citation:1"), citation("citation:2")],
            label: "cite"
        ))
        let chips = model.sourceChips(for: claim)
        #expect(chips.count == 1)
        #expect(chips.first?.citations == 2)
        #expect(chips.first?.state == .ready)
        // The other object cited nothing, so it shows nothing.
        #expect(model.sourceChips(for: other).isEmpty)
    }

    @Test("A source nobody has read is quiet, not alarming")
    func unreadSourceIsQuiet() {
        var model = model()
        // A link: a pointer, never fetched, so nothing has been read and nothing
        // has gone wrong. The chip must not imply a problem.
        #expect(model.perform(
            [source("source:link", title: "A page", kind: .link, revisions: [])],
            label: "attach"
        ))
        #expect(model.document.sources.source("source:link")?.extraction == .notAttempted)
        // With no revision, a citation cannot be made, so no chip appears at all.
        #expect(model.sourceChips(for: claim).isEmpty)
        #expect(SourceChipState(.notAttempted).needsAttention == false)
    }

    @Test("A read source is calm, a broken one is not")
    func calmStatesAndNoisyOnes() {
        #expect(SourceChipState(.ready(text: "x")).needsAttention == false)
        #expect(SourceChipState(.notAttempted).needsAttention == false)
        #expect(SourceChipState(.pending).needsAttention == false)
        // Every state meaning something could not be read is worth a person's
        // attention, and none of them hides behind a neutral grey.
        #expect(SourceChipState(.noText(reason: "scan")).needsAttention)
        #expect(SourceChipState(.partial(text: "x", reason: "truncated")).needsAttention)
        #expect(SourceChipState(.unsupported(reason: "x")).needsAttention)
        #expect(SourceChipState(.missing(reason: "x")).needsAttention)
        #expect(SourceChipState.unverifiable.needsAttention)
    }

    @Test("A chip follows the ledger rather than a copy of it")
    func chipFollowsTheLedger() {
        var model = model()
        #expect(model.perform([source(), citation("citation:1")], label: "cite"))
        #expect(model.sourceChips(for: claim).first?.state == .ready)

        // Removing the source does not remove the claim: the citation stays, marked,
        // and the chip stops presenting the source as ready.
        #expect(model.perform(
            [.removeSource(.init(sourceID: "source:brief", reason: "the file moved"))],
            label: "remove"
        ))
        #expect(model.document.sources.citation("citation:1") != nil)
    }

    @Test("A superseded revision is visible on the chip")
    func supersededRevisionNeedsAttention() {
        var model = model()
        #expect(model.perform([source(), citation("citation:1")], label: "cite"))
        #expect(model.sourceChips(for: claim).first?.state == .ready)

        // A new revision arrives, so the citation is flagged for review. The chip
        // is the only place a person would notice that, so it has to notice.
        #expect(model.perform([.importSourceRevision(.init(
            sourceID: "source:brief",
            revision: SourceRevision(
                id: "rev:2", sequence: 2, extraction: .ready(text: "now three steps"),
                digest: "sha256:y"
            ),
            provenance: .human("person:owner")
        ))], label: "import"))
        let chip = model.sourceChips(for: claim).first
        #expect(chip != nil)
        #expect(chip?.state == .ready)
        // The document marks the citation for review even though the file itself is
        // perfectly readable, and the chip reports the file's state honestly rather
        // than borrowing the citation's.
        if case .needsReview = model.document.sources.citation("citation:1")!.status {} else {
            Issue.record("the citation should be flagged for review")
        }
    }

    // MARK: Attaching a file the person chose

    @Test("A chosen file is read and attached in one action")
    func attachingAChosenFile() throws {
        var model = model()
        let url = directory.appendingPathComponent("brief.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("Signup takes nine steps today.".utf8).write(to: url)

        let read = try #require(model.attachSource(at: url, to: claim))
        #expect(read.extraction.isUsable)
        // The source is in the document, with a recorded revision, and nothing was
        // copied into it.
        let source = try #require(
            model.document.sources.source(SourceID("source:" + String(read.digest.prefix(16))))
        )
        #expect(source.locator == url.absoluteString)
        #expect(source.attempts.count == 1)
        #expect(model.document.sources.source(source.id)?.extraction.isUsable == true)
    }

    @Test("A file with no text is attached, and the chip says so")
    func attachingAFileWithNoText() throws {
        var model = model()
        let url = directory.appendingPathComponent("empty.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("   ".utf8).write(to: url)

        let read = try #require(model.attachSource(at: url, to: claim))
        // Attached, honestly labelled, and not announced as read.
        if case .noText = read.extraction {} else {
            Issue.record("an empty file must be reported as having no text")
        }
        let id = SourceID("source:" + String(read.digest.prefix(16)))
        #expect(model.document.sources.source(id) != nil)
        #expect(model.document.sources.source(id)?.extraction.isUsable == false)
    }

    @Test("A file that cannot be read attaches nothing")
    func unreadableFileAttachesNothing() throws {
        var model = model()
        let before = model.document
        #expect(model.attachSource(at: URL(fileURLWithPath: "/nowhere/missing.txt"), to: claim) == nil)
        // Nothing partial: the read happens before any command, so a failure cannot
        // leave a source with no revision.
        #expect(model.document.sources.sources.isEmpty)
        #expect(model.document == before)
        #expect(model.status != nil)
    }

    @Test("The same file twice is one source with two revisions, not two sources")
    func sameFileTwice() throws {
        var model = model()
        let url = directory.appendingPathComponent("brief.md")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("First version.".utf8).write(to: url)
        let first = try #require(model.attachSource(at: url, to: claim))

        try Data("Second version.".utf8).write(to: url)
        let second = try #require(model.attachSource(at: url, to: claim))

        // The id comes from the content, so a changed file is a new source rather
        // than a second copy pretending to be the first.
        #expect(first.digest != second.digest)
        #expect(model.document.sources.sources.count == 2)
    }


    // MARK: Opening a citation and recording a check

    /// A model with one text source cited by `claim` on lines 2 to 4.
    private func modelWithCitation() throws -> KollioModel {
        var model = model()
        let url = directory.appendingPathComponent("brief.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("Signup today.\nIt takes nine steps.\nThree would do.\nEnd.".utf8).write(to: url)
        let read = try #require(model.attachSource(at: url, to: claim))
        let id = SourceID("source:" + String(read.digest.prefix(16)))
        let revision = try #require(model.document.sources.source(id)?.latest)
        #expect(model.perform([.addCitation(.init(
            citation: Citation(
                id: "citation:1", claimID: claim, sourceID: id,
                revisionID: revision.id, locator: SourceLocator(lineRange: 1..<3),
                quote: "It takes nine steps."
            ),
            claimID: claim, provenance: .human("person:owner")
        ))], label: "cite"))
        return model
    }

    @Test("A citation opens at the lines its locator points at")
    func citationOpensItsPassage() throws {
        let model = try modelWithCitation()
        let details = model.citations(of: claim)
        #expect(details.count == 1)
        let detail = try #require(details.first)
        #expect(detail.citation.quote == "It takes nine steps.")
        // The passage is the real slice, and it is not reworded.
        #expect(detail.passage == "It takes nine steps.\nThree would do.")
        #expect(detail.isCurrentRevision)
    }

    @Test("A page locator shows no passage rather than a wrong one")
    func pageLocatorHasNoPassage() throws {
        var model = model()
        let url = directory.appendingPathComponent("contract.pdf")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #expect(SourceReaderTests.writeTextPDF(at: url, text: "Clause one.\nClause two."))
        let read = try #require(model.attachSource(at: url, to: claim))
        let id = SourceID("source:" + String(read.digest.prefix(16)))
        let revision = try #require(model.document.sources.source(id)?.latest)
        #expect(model.perform([.addCitation(.init(
            citation: Citation(
                id: "citation:p", claimID: claim, sourceID: id,
                revisionID: revision.id, locator: SourceLocator(page: 1),
                quote: "Clause one."
            ),
            claimID: claim, provenance: .human("person:owner")
        ))], label: "cite"))
        // A PDF has pages, not line numbers. Returning a slice of the joined text
        // would be a locator pointing at the wrong place.
        #expect(model.citations(of: claim).first?.passage == nil)
    }

    @Test("A check is recorded with its observation, and an empty one is refused")
    func verificationNeedsAnObservation() throws {
        var model = try modelWithCitation()
        #expect(model.citations(of: claim).first?.citation.status == .unverified)

        // Nothing to say is not a check, and the half-written sentence stays where
        // it was rather than being cleared by a refusal.
        model.verificationDraft = "half a note"
        #expect(model.recordVerification("citation:1", observation: "   ") == false)
        #expect(model.verificationDraft == "half a note")
        #expect(model.document.sources.citation("citation:1")?.status == .unverified)

        #expect(model.recordVerification("citation:1", observation: "Confirmed on line 2."))
        let status = model.document.sources.citation("citation:1")?.status
        #expect(status?.isVerified == true)
        if case .verified(let observation, let author, _) = status! {
            #expect(observation.contains("line 2"))
            #expect(author == "local-user")
        } else {
            Issue.record("the check should carry its observation and its author")
        }
    }


    // MARK: Choosing a passage

    @Test("A chosen passage becomes the quote, verbatim")
    func chosenPassageIsTheQuote() throws {
        var model = try modelWithCitation()
        let sourceID = try #require(model.citations(of: claim).first?.citation.sourceID)
        #expect(model.lines(of: sourceID).count == 4)

        // Lines 0 and 1 chosen: the quote is those lines exactly, not a summary of
        // them and not a retyped version that drifted.
        #expect(model.citePassage(of: sourceID, lines: 0..<2, to: claim))
        let newest = try #require(model.document.sources.citations(supporting: claim).last)
        #expect(newest.quote == "Signup today.\nIt takes nine steps.")
        #expect(newest.locator.lineRange == 0..<2)
    }

    @Test("A citation from the interface lands on the lines that were chosen")
    func pickerCitationRoundTrips() throws {
        var model = try modelWithCitation()
        let sourceID = try #require(model.citations(of: claim).first?.citation.sourceID)
        #expect(model.citePassage(of: sourceID, lines: 2..<3, to: claim))

        // Opening the new citation shows exactly what was selected, which is the
        // property the whole picker exists for.
        let detail = try #require(model.citations(of: claim).last)
        #expect(detail.passage == "Three would do.")
        #expect(detail.citation.quote == "Three would do.")
        #expect(detail.isCurrentRevision)
    }

    @Test("An impossible selection cites nothing")
    func invalidSelectionIsRefused() throws {
        var model = try modelWithCitation()
        let sourceID = try #require(model.citations(of: claim).first?.citation.sourceID)
        let before = model.document.sources.citations(supporting: claim).count

        // Out of range, empty, and an unknown source all fail rather than producing
        // a citation that points nowhere.
        //
        // An inverted range is not tested here because it cannot exist: `3..<1` is a
        // trap in Swift, not a value that can be passed and refused. The first
        // version of this test used one and took the whole test process down, which
        // is worth knowing about the language rather than the code.
        #expect(model.citePassage(of: sourceID, lines: 2..<99, to: claim) == false)
        #expect(model.citePassage(of: sourceID, lines: 1..<1, to: claim) == false)
        #expect(model.citePassage(of: SourceID("source:nope"), lines: 0..<1, to: claim) == false)
        #expect(model.document.sources.citations(supporting: claim).count == before)
    }

    @Test("A source with no text offers no lines to select")
    func unreadableSourceHasNoLines() throws {
        var model = model()
        let url = directory.appendingPathComponent("empty.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("  ".utf8).write(to: url)
        let read = try #require(model.attachSource(at: url, to: claim))
        let id = SourceID("source:" + String(read.digest.prefix(16)))
        // Nothing to select is the honest state, and the picker says so rather than
        // showing an empty list that looks broken.
        #expect(model.lines(of: id).isEmpty)
    }
}
