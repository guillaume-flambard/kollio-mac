import Foundation
import Testing
@testable import KollioApp
import KollioCore

/// AI-06, the part where a synthesis stops being stored and starts being received.
///
/// Every test here drives the model the way a person would, and asserts on what
/// the card can show. A deliverable nobody can see is not a deliverable, which is
/// why these exist even though the domain already passes its own suite.
@Suite("Summary interface")
@MainActor
struct SummaryInterfaceTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
                .isolatedDirectory()
        )
    }

    @Test("Composing a synthesis opens a card and writes a draft")
    func composes() {
        let model = model()
        let id = model.startSummary()
        #expect(id != nil)
        #expect(model.openSummaryID == id)
        let summary = model.summary(id!)
        #expect(summary?.isDraft == true)
        #expect(summary?.title.isEmpty == false)
        #expect(summary?.objective.text.text.isEmpty == false)
    }

    @Test("The card says the revision it read")
    func cardNamesTheRevision() {
        let model = model()
        guard let id = model.startSummary() else {
            Issue.record("no synthesis was composed")
            return
        }
        let block = model.openSummaryBlock
        // The revision it *read*, which is one behind the revision that exists now
        // because writing the synthesis moved the document. A card that showed the
        // current revision would be claiming to describe a document that includes
        // the synthesis itself.
        #expect(block?.usedRevision == model.document.semanticRevision - 1)
        #expect(block?.isDraft == true)
    }

    @Test("An empty document offers nothing to compose, and says so")
    func emptyDocumentHasNoAction() {
        let model = KollioModel(
            document: KollioDocument(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
        // With nothing in the document, composing would produce four empty
        // sections, so the action is absent rather than present and refusing.
        let set = model.contextualActions(for: ObjectID("object:none"))
        #expect(set.secondary.contains(.composeSynthesis) == false)
    }

    @Test("A document with something in it offers the action")
    func actionIsOffered() {
        let model = model()
        #expect(model.contextualActions(for: KollioID.object("sarah-csv"))
            .secondary.contains(.composeSynthesis))
    }

    @Test("Composing writes to the document, so it is meaning and not presentation")
    func composesMeaning() {
        // Composing writes a record into the document, so it is meaning. A test
        // that let it be filed as layout would let a deliverable be versioned like
        // a drawing, and layout is not versioned.
        let set = model().contextualActions(for: KollioID.object("sarah-csv"))
        #expect(set.reach(of: .composeSynthesis) == .meaning)
    }

    @Test("Confirming is refused while a section says nothing, and names it")
    func confirmRefusesAndExplains() {
        let model = model()
        guard let id = model.startSummary() else {
            Issue.record("no synthesis was composed")
            return
        }
        // The composer leaves uncertainties absent on purpose, so this press is
        // refused and the person is told which section to deal with rather than
        // being met with a failure they cannot act on.
        let confirmed = model.confirmSummary(id)
        #expect(confirmed == false)
        #expect(model.status?.isEmpty == false)
        #expect(model.summary(id)?.isDraft == true)
    }

    @Test("A synthesis survives a save and a reload")
    func survivesAReload() throws {
        let model = model()
        guard let id = model.startSummary() else {
            Issue.record("no synthesis was composed")
            return
        }
        let reloaded = try DocumentCodec.decode(DocumentCodec.encode(model.document))
        #expect(reloaded.summaries.summary(id) != nil)
        #expect(reloaded.summaries.all().count == 1)
    }

    @Test("Exporting writes a file that names the revision")
    func exportWritesTheRevision() throws {
        let model = model()
        guard let id = model.startSummary() else {
            Issue.record("no synthesis was composed")
            return
        }
        let url = try #require(model.exportSummary(id))
        let read = model.summary(id)!.baseSemanticRevision
        #expect(url.lastPathComponent.contains("-r\(read)-"))
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("Document revision read"))
    }

    @Test("An outdated synthesis says so in the card and in the export")
    func outdatedIsVisible() throws {
        let model = model()
        guard let id = model.startSummary(over: [KollioID.object("sarah-crm")]) else {
            Issue.record("no synthesis was composed")
            return
        }
        #expect(model.openSummaryBlock?.isOutdated == false)

        // A decision on something the synthesis read. The card has to say so, and
        // the export has to say so in its header rather than in a footnote.
        // Confirmed first, because a draft is a question and a question cannot go
        // out of date. A person hands the synthesis over, and only then is it a
        // claim about the document that a later decision can contradict.
        for section in SummaryArtifact.Section.allCases {
            if model.summary(id)!.sections(section).isEmpty {
                _ = model.perform([.setSummarySection(.init(
                    summaryID: id, kind: section,
                    section: SummaryArtifact.SummarySection(section, lines: [], isNothingRecorded: true),
                    provenance: .human("local-user")
                ))], label: "declare")
            }
        }
        #expect(model.confirmSummary(id))
        #expect(model.openSummaryBlock?.isOutdated == false)
        model.setAside(KollioID.object("sarah-crm"), reason: "Identifiants API indisponibles")
        #expect(model.summary(id)?.isOutdated(against: model.document) == true)
        #expect(model.openSummaryBlock?.isOutdated == true)

        let url = try #require(model.exportSummary(id))
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("**Outdated.**"))
        // Compared against the two catalog strings rather than against a French
        // substring: these tests run in the system language, and a test that only
        // passed in one language is a test about the test runner.
        #expect(model.status == L10n.summaryExportedOutdated)
    }

    @Test("The card distinguishes nothing uncertain from not written yet")
    func absenceIsDistinguishable() {
        let model = model()
        guard let id = model.startSummary() else {
            Issue.record("no synthesis was composed")
            return
        }
        let block = try? #require(model.summary(id))
        #expect(block != nil)
        // Sarah's document has no unreasoned rejection and no unexamined
        // hypothesis, so the composer declares those sections empty rather than
        // leaving them unwritten, and the card can tell the two apart.
        let summary = model.summary(id)!
        #expect(summary.reasons.first?.isNothingRecorded == true)
        #expect(summary.uncertainties.isEmpty)
        #expect(summary.uncertainties != summary.reasons)
    }

    @Test("Closing the card forgets where the person was looking, and nothing else")
    func closingTheCard() {
        let model = model()
        guard let id = model.startSummary() else {
            Issue.record("no synthesis was composed")
            return
        }
        model.openSummaryID = nil
        #expect(model.openSummaryID == nil)
        // Closing a card is not a removal. The synthesis is a record, not a
        // viewport, and a person who closed it did not delete their work.
        #expect(model.summary(id) != nil)
    }
}

private extension DocumentFileStore {
    /// A store in its own directory, so an export written by one test is not read
    /// by another.
    func isolatedDirectory() -> DocumentFileStore {
        DocumentFileStore(directory: directory.appendingPathComponent("summary-\(UUID().uuidString)", isDirectory: true))
    }
}
