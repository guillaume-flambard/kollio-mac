import Foundation
import Testing
@testable import KollioApp
import KollioCore

/// AI-12 AC03, at the interface: "the output states its scope".
///
/// The adapter's own narrowing is proved in `AppleAdapterTests`. What is proved
/// here is what a person sees afterwards, and it is the part that can be got
/// wrong without anything failing: a source that narrowed its context, a preview
/// that still claims to have read everything, and a panel that says nothing.
@Suite("Answer scope in the interface")
@MainActor
struct ProposalScopeInterfaceTests {
    /// A source that read part of the request, which is what a real budget forces
    /// it to do. It names what it left out rather than answering as though it had
    /// seen the whole thing.
    private final class NarrowingService: SuggestionService, @unchecked Sendable {
        let omitted: ObjectID
        init(omitting omitted: ObjectID) { self.omitted = omitted }

        var capabilities: SuggestionCapabilities {
            SuggestionCapabilities(intents: [.explore, .add, .clarify], deterministic: false, requiresNetwork: false)
        }

        func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
            let read = request.context.map(\.objectID).filter { $0 != omitted }
            let id = ObjectID("object:narrowed-branch")
            return ProposalResponse(
                status: .proposed,
                proposal: Proposal(
                    proposalId: "proposal:\(request.requestId)",
                    requestId: request.requestId,
                    documentId: request.documentId,
                    baseSemanticRevision: request.baseSemanticRevision,
                    summary: LocalizedText("One direction"),
                    operations: [.createObject(CreateObject(
                        id: id, kind: .hypothesis, text: LocalizedText("Une direction"),
                        provenance: .init(actor: ActorID("test"), kind: .localEngine, requestId: request.requestId)
                    ))],
                    placementHints: [.init(objectID: id)],
                    generator: .init(name: "test-narrowing", deterministic: false),
                    contextScope: ProposalContextScope(
                        readObjectIDs: read,
                        omittedObjectIDs: [omitted],
                        measuredCharacters: 400,
                        budgetCharacters: 400
                    )
                )
            )
        }
    }

    private func model(omitting omitted: ObjectID, languageCode: String = "fr") -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: NarrowingService(omitting: omitted),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory())),
            languageCode: languageCode
        )
    }

    @Test("What was read no longer claims the material that was left out")
    func readListFollowsTheScope() async throws {
        let omitted = ObjectID("object:sarah-crm")
        let model = model(omitting: omitted)
        await model.explore(KollioID.object("sarah-csv"))
        let preview = try #require(model.preview)
        // The list is built from the request, so before this it named everything the
        // document could have offered. A person reading "what this was based on"
        // would have been told about a source the answer never saw.
        #expect(preview.readRefs.contains { $0.id == omitted.rawValue } == false)
        // And the target is still there: a panel that listed what was read and left
        // out the thing that was clicked would be misleading in the other direction.
        #expect(preview.readRefs.contains { $0.id == ObjectID("object:sarah-csv").rawValue })
    }

    @Test("A narrowed answer says so on the status line, not only in a panel")
    func theStatusLineCarriesTheScope() async throws {
        let model = model(omitting: ObjectID("object:sarah-crm"))
        await model.explore(KollioID.object("sarah-csv"))
        // The attribution panel is closed by default, and a scope nobody opens is a
        // scope nobody reads. The status line is the part that is always there.
        let status = try #require(model.status)
        #expect(status.contains("1"))
        #expect(status.contains("status.contextNarrowed") == false, "a key is never shown")
    }

    @Test("A refusal is not overwritten by the scope notice")
    func aRefusalWins() async throws {
        // The narrowed answer never arrives, because the required context did not
        // fit. The person is told the real reason, and the notice about a partial
        // answer does not appear on top of it.
        let model = KollioModel(
            document: SarahFixture.document(),
            service: AppleLocalSuggestionService(
                probe: StubAppleModelProbe(availability: .available, contextSize: 8)
            ),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
        await model.explore(KollioID.object("sarah-csv"))
        #expect(model.preview == nil)
        let status = try #require(model.status)
        #expect(status == L10n.appleContextTooLarge)
    }

    @Test("The panel's scope line reads in both languages")
    func scopeStringsAreLocalized() {
        let complete = L10n.proposalScopeComplete(4)
        let narrowed = L10n.proposalScopeNarrowed(4, 2)
        // Each carries the counts, because "some context was left out" is not
        // actionable and "2 of 6" is.
        #expect(complete.contains("4"))
        #expect(narrowed.contains("4"))
        #expect(narrowed.contains("2"))
        for string in [L10n.proposalScopeTitle, complete, narrowed, L10n.statusContextNarrowed(2)] {
            #expect(string.isEmpty == false)
            #expect(string.contains("proposal.scope") == false, "a key is never shown")
            #expect(string.contains("status.context") == false, "a key is never shown")
        }
    }

    @Test("A complete answer leaves the status line alone")
    func aCompleteAnswerIsQuiet() async throws {
        // The notice is only worth reading if it appears when there is something to
        // say. A line that is always lit is a line nobody reads.
        let model = KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
        await model.explore(KollioID.object("sarah-csv"))
        let preview = try #require(model.preview)
        #expect(preview.proposal.contextScope == nil)
        // Nothing about a narrowing is announced, because there was no narrowing.
        // The demo engine does set a status of its own, so the check is that it is
        // not this notice.
        #expect(model.status != L10n.statusContextNarrowed(1))
    }
}
