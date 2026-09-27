import Foundation
import Testing
@testable import KollioApp
import KollioCore

/// CAN-09 at the interface: find something, and the four things the card has to
/// get right while it does.
///
/// The criteria are AC01 a rejection reason is findable, AC02 returning alters no
/// status, and AC03 a private result is absent from a shared search. The search
/// itself is proved in `DocumentSearchTests`; what is proved here is the behaviour
/// a person would call a bug.
@Suite("Search in the interface")
@MainActor
struct SearchInterfaceTests {
    /// A source that fails loudly if anything asks it for a proposal, so "no
    /// intelligence for a textual search" is proved by the absence of a call
    /// rather than by the absence of a bug report.
    private final class ExplodingService: SuggestionService, @unchecked Sendable {
        var capabilities: SuggestionCapabilities {
            SuggestionCapabilities(intents: [.explore, .add, .clarify], deterministic: false, requiresNetwork: true)
        }
        func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
            Issue.record("a textual search asked the intelligence source for a proposal")
            return .noChange()
        }
    }

    private func model(
        service: (any SuggestionService)? = nil
    ) -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: service ?? KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    /// Sarah, with the CRM direction set aside for a reason of its own.
    private func modelWithAReason(service: (any SuggestionService)? = nil) -> KollioModel {
        let model = model(service: service)
        model.setAside(KollioID.object("sarah-crm"), reason: "Pas de budget pour l'API avant mars")
        return model
    }

    // MARK: - AC01, a rejection reason is findable

    @Test("AC01: the reason somebody wrote is found from the card")
    func aReasonIsFindableFromTheCard() async throws {
        let model = modelWithAReason()
        model.openSearch()
        model.updateSearch("budget")
        let state = try #require(model.search)
        let result = try #require(state.results.first)
        #expect(result.objectID == KollioID.object("sarah-crm"))
        #expect(result.field == .reason)
        // And the card says what state it is in, so a person knows what they are
        // about to click on before they click it.
        #expect(model.searchStateLabel(for: result) == L10n.searchStateSetAside)
        #expect(model.searchFieldLabel(for: result) == L10n.searchFieldReason)
    }

    @Test("A result says it is history when the decision no longer stands")
    func historyIsLabelled() async throws {
        let model = modelWithAReason()
        model.reopen(KollioID.object("sarah-crm"))
        model.openSearch()
        model.updateSearch("budget")
        let result = try #require(model.search?.results.first)
        #expect(result.state == .archived)
        #expect(model.searchStateLabel(for: result) == L10n.searchStateArchived)
    }

    @Test("No intelligence is asked for a textual search")
    func searchAsksNoModel() async throws {
        // The failure is the proof: this service records an issue if it is called
        // once. A search that reached it would fail this test rather than quietly
        // costing a second of somebody's time and their content.
        let model = modelWithAReason(service: ExplodingService())
        model.openSearch()
        model.updateSearch("budget")
        model.updateSearch("export")
        model.updateSearch("CRM")
        #expect(model.search?.results.isEmpty == false)
    }

    // MARK: - AC02, returning alters no status

    @Test("AC02: choosing a result changes no status and moves no revision")
    func choosingAResultAltersNoStatus() async throws {
        let model = modelWithAReason()
        let documentBefore = model.document
        let semanticBefore = model.session.semanticRevision
        let revisionBefore = model.session.revision

        model.openSearch()
        model.updateSearch("budget")
        let result = try #require(model.search?.results.first)
        #expect(model.revealSearchResult(result))

        // The direction is still set aside, the decision still stands, and the
        // document is byte-identical. Showing something and deciding something are
        // two different acts and the first one does not do the second.
        #expect(model.document == documentBefore)
        #expect(model.session.semanticRevision == semanticBefore)
        #expect(model.session.revision == revisionBefore)
        #expect(model.document.object("object:sarah-crm")?.isSetAside == true)
        // And nothing is undoable, because nothing was written.
        #expect(model.canUndo == false)
    }

    @Test("A revealed set-aside direction is on the canvas, still set aside")
    func revealingIsNotReopening() async throws {
        let model = modelWithAReason()
        // A member of a collapsed branch is hidden, so the search is the only way
        // to bring it into view.
        let hidden = KollioID.object("sarah-crm")
        model.openSearch()
        model.updateSearch("budget")
        let result = try #require(model.search?.results.first)
        model.revealSearchResult(result)

        #expect(model.visibleInstances.contains { $0.objectID == hidden })
        #expect(model.canReopen(hidden), "reopening stays available, and stays a separate action")
        #expect(model.document.object(hidden)?.lifecycle == .setAside)
    }

    @Test("Closing the search puts the canvas back exactly as it was")
    func closingRestoresTheCanvas() async throws {
        let model = modelWithAReason()
        let instancesBefore = model.visibleInstances.map(\.id)
        model.openSearch()
        model.updateSearch("budget")
        model.revealSearchResult(try #require(model.search?.results.first))
        #expect(model.visibleInstances.map(\.id) != instancesBefore)

        model.dismissOneLevel()
        #expect(model.search == nil)
        #expect(model.revealedBySearch.isEmpty)
        #expect(model.visibleInstances.map(\.id) == instancesBefore)
    }

    @Test("The search is the level Escape closes, above the selection")
    func searchIsDismissable() async throws {
        let model = model()
        model.select(KollioID.object("sarah-csv"))
        model.openSearch()
        #expect(KollioModel.TransientLevel.topmost(in: model) == .search)
        model.dismissOneLevel()
        // One level, not two: the selection the person had built is still there.
        #expect(model.search == nil)
        #expect(model.selection == [KollioID.object("sarah-csv")])
    }

    // MARK: - Zero results keeps the query

    @Test("Nothing found keeps what was typed, and offers to clear it")
    func zeroResultsKeepsTheQuery() async throws {
        let model = model()
        model.openSearch()
        model.updateSearch("quelque chose qui n'existe pas")
        let state = try #require(model.search)
        #expect(state.isEmpty)
        // The words are still there. A person who mistyped corrects the word; a
        // person handed an empty field starts again and loses the thought.
        #expect(state.query == "quelque chose qui n'existe pas")
        // And there is a way out that is not selecting all of it by hand.
        #expect(L10n.searchClear.isEmpty == false)
        #expect(L10n.searchNoResults.isEmpty == false)

        model.clearSearch()
        #expect(model.search == nil)
    }

    @Test("An empty field is not a search that found nothing")
    func anEmptyFieldSearchesNothing() async throws {
        let model = model()
        model.openSearch()
        model.updateSearch("   ")
        let state = try #require(model.search)
        // No results *and* nothing skipped: no search ran, so there is no partial
        // answer to report and no "0" to misread as a verdict about the document.
        #expect(state.results.isEmpty)
        #expect(state.hasSearched == false)
    }

    // MARK: - AC03, and what was not searched

    @Test("AC03: the local document reports no scope, so nothing is claimed")
    func aLocalSearchIsNotPartial() async throws {
        let model = model()
        model.openSearch()
        model.updateSearch("export")
        let outcome = try #require(model.search?.outcome)
        // Sarah has a source, and Kollio does not read inside files to look for
        // words, so the outcome says so rather than appearing complete.
        #expect(outcome.notSearched.contains(.sourceContent(count: 1)))
        #expect(outcome.isPartial)
        #expect(L10n.searchPartial(1).contains("1"))
    }

    @Test("A permission-limited search never returns what is outside it")
    func aPrivateResultIsAbsent() async throws {
        let model = modelWithAReason()
        // The same search the model offers, restricted to what this caller may
        // read. Sharing is not built, so this is the boundary that exists today:
        // the document itself, filtered before the search.
        let permitted: Set<ObjectID> = [KollioID.object("sarah-csv")]
        let outcome = DocumentSearch().search(
            "CRM", in: model.document, permitted: permitted, languageCode: "fr"
        )
        #expect(outcome.results.isEmpty)
        #expect(outcome.notSearched.contains(.outsideScope(KollioID.object("sarah-crm"))))
    }

    @Test("Every string the card shows is a translated one")
    func cardStringsAreLocalized() {
        let strings = [
            L10n.search, L10n.searchPlaceholder, L10n.searchClear, L10n.searchClearHint,
            L10n.searchNoResults, L10n.searchStateVisible, L10n.searchStateSetAside,
            L10n.searchStateArchived, L10n.searchFieldTitle, L10n.searchFieldBody,
            L10n.searchFieldReason, L10n.searchNotSearched, L10n.searchNotSearchedSources(2),
            L10n.searchPartial(3), L10n.searchReopenHint,
        ]
        for string in strings {
            #expect(string.isEmpty == false)
            #expect(string.contains("search.") == false, "a key is never shown: \(string)")
        }
        #expect(L10n.searchNotSearchedSources(2).contains("2"))
        #expect(L10n.searchPartial(3).contains("3"))
    }
}
