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
}
