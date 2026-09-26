import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// CAN-02, "Select and reach the actions".
///
/// The three acceptance criteria are decidable without a pointer and without a
/// person, so they are decided here. What is *not* decidable — whether the
/// contextual bar is pleasant to reach with a slow pointer — is owed to a human
/// and is listed in `openspec/changes/l1-entry-and-canvas/tasks.md`.
///
/// Every proposal in this file is a real one, produced by the deterministic
/// service through `explore`. No proposal is hand-built, because a fabricated
/// preview would prove the test's own assumptions rather than the model's.
@Suite("CAN-02: selection and the actions it reaches")
@MainActor
struct SelectionAndActionsTests {
    private func isolatedStore() -> (DocumentFileStore, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-can02-\(UUID().uuidString)")
        return (DocumentFileStore(directory: directory), directory)
    }

    private func makeModel(
        _ service: (any SuggestionService)? = nil
    ) -> (KollioModel, URL) {
        let (store, directory) = isolatedStore()
        let engine = service ?? KollioModel.makeDemoService(languageCode: "fr")
        return (KollioModel(document: SarahFixture.document(), service: engine, fileStore: store), directory)
    }


    @Test("An ordinary idea offers exactly three primary actions and one named control")
    func atMostThreePrimaryActions() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let set = model.contextualActions(for: KollioID.object("sarah-csv"))

        // The specification fixes which three, not just how many: Explore, Add,
        // Set aside. Counting alone would pass for any three.
        #expect(set.primary == [.explore, .add, .setAside])
        #expect(set.primary.count <= ContextualActionSet.maximumPrimary)
        #expect(set.isDefault == .explore)

        // Everything else is behind the single secondary control, and nothing is
        // both: an action shown twice is a control that costs a hit for nothing.
        #expect(set.secondary.contains(.edit))
        #expect(set.secondary.contains(.addSource))
        #expect(set.secondary.contains(.assertClaim))
        #expect(Set(set.primary).isDisjoint(with: set.secondary))
    }

    @Test("A set-aside direction offers only Reopen")
    func aSetAsideDirectionOffersOnlyReopen() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")
        model.setAside(csv, reason: "Pas maintenant")

        let set = model.contextualActions(for: csv)
        #expect(set.primary == [.reopen])
        // There is one thing to do with a set-aside direction, so there is no
        // secondary control to show at all.
        #expect(set.secondary.isEmpty)
    }

    @Test("No action is offered that the model cannot perform")
    func noActionIsOfferedTwiceOrUnimplemented() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        for id in [KollioID.object("sarah-crm"), KollioID.object("sarah-csv")] {
            let set = model.contextualActions(for: id)
            let all = set.primary + set.secondary
            #expect(Set(all).count == all.count)
            // Link and Comment are named in the specification but are not
            // implemented, so they are not offered. An action that exists and does
            // nothing is worse than an absent one.
            #expect(!all.contains(.link))
            #expect(!all.contains(.comment))
            // CAN-05 replaced the single Duplicate with the pair the specification
            // distinguishes, and the two removals with their pair, so none of the
            // four is reachable as one ambiguous action.
            #expect(all.contains(.duplicateOccurrence))
            #expect(all.contains(.duplicateVariant))
            #expect(all.contains(.removeOccurrence))
            #expect(all.contains(.removeObject))
        }
    }

    // MARK: AC02 — a selection never reaches the intelligence seam

    @Test("Selecting, extending and dragging reach no intelligence service")
    func selectionNeverCallsIntelligence() async {
        let service = RefusingSuggestionService()
        let (model, directory) = makeModel(service)
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")

        // Every way a person selects, in the order a person would.
        model.select(crm)
        model.select(csv, extending: true)
        model.select(nil)

        // And the one gesture that legitimately ends in a transaction.
        model.beginDrag(model.draggableInstances(for: csv), screenTranslation: CGSize(width: 40, height: 12))
        model.endDrag()

        // The service counts and throws. The count is the evidence, so a passing
        // test states the fact rather than relying on an exception nobody read.
        #expect(service.callCount == 0)
        #expect(model.selection.isEmpty)
    }

    @Test("A multiple selection hides a proposal without applying or refusing it")
    func multipleSelectionHidesRatherThanRejects() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")

        await model.explore(crm)
        let preview = try! #require(model.preview)
        let contentBefore = model.document.content.count

        // Extending from an empty selection would only have one member, so the
        // first click is a plain select and the second one extends.
        model.select(crm)
        model.select(csv, extending: true)

        #expect(model.selection.count == 2)
        // Hidden. Nothing was applied, so the document is exactly as it was, and
        // nothing was refused, so no decision was recorded.
        #expect(model.preview == nil)
        #expect(model.document.content.count == contentBefore)
        #expect(model.document.decisions.isEmpty)
        #expect(preview.objectIDs.isEmpty == false)
    }

    // MARK: AC03 — Escape closes one level, then the selection

    @Test("Escape leaves the surfaces in order and the selection last")
    func escapeClosesOneLevelAtATime() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let contentBefore = model.document.content.count

        await model.explore(crm)
        model.select(crm)
        model.composer = KollioModel.ComposerState(anchorID: crm, intent: .add)
        model.openCitationClaim = crm

        // The composer is open, so the composer leaves first. Everything else
        // stays: a person who dismisses a field has not dismissed their work.
        #expect(model.dismissOneLevel() == .composer)
        #expect(model.composer == nil)
        #expect(model.selection == [crm])
        #expect(model.preview != nil)
        #expect(model.openCitationClaim == crm)

        #expect(model.dismissOneLevel() == .citation)
        #expect(model.openCitationClaim == nil)
        #expect(model.preview != nil)

        // A proposal is closed, not refused: nothing was applied and nothing is
        // remembered as a decision.
        #expect(model.dismissOneLevel() == .preview)
        #expect(model.preview == nil)
        #expect(model.selection == [crm])
        #expect(model.document.decisions.isEmpty)
        #expect(model.document.content.count == contentBefore)

        // The selection is the last thing Escape takes, and the only thing it takes.
        #expect(model.dismissOneLevel() == .selection)
        #expect(model.selection.isEmpty)

        // And once there is nothing transient, Escape does nothing rather than
        // reaching further into the document.
        #expect(model.dismissOneLevel() == nil)
        #expect(model.document.content.count == contentBefore)
    }

    @Test("Closing a composer keeps the draft and records nothing")
    func escapeKeepsTheComposerDraft() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")

        model.composer = KollioModel.ComposerState(anchorID: crm, text: "Pas maintenant", intent: .setAside)
        model.dismissOneLevel()

        #expect(model.composer == nil)
        // The composer is a surface, not a decision.
        #expect(model.document.decisions.isEmpty)
        #expect(model.setAsideReason(of: crm) == nil)
    }

    @Test("Escape during a drag does not commit the drag")
    func escapeDoesNotCommitADrag() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")
        let before = model.document.presentation.instances.first { $0.objectID == csv }?.position

        model.select(csv)
        model.beginDrag(model.draggableInstances(for: csv), screenTranslation: CGSize(width: 120, height: 0))
        model.dismissOneLevel()

        // Escape took the selection, the deepest thing that was not a gesture. The
        // pointer still owns the drag, so the offset was dropped, not committed.
        #expect(model.selection.isEmpty)
        #expect(model.document.presentation.instances.first { $0.objectID == csv }?.position == before)
    }

    // MARK: AC01 — the actions belong to the selection, not to the pointer

    @Test("The contextual surface follows the selection and not the hover")
    func actionsFollowSelectionNotHover() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")
        let csv = KollioID.object("sarah-csv")

        // Hovering alone offers nothing: no selection, therefore no single target,
        // therefore no contextual surface to draw.
        model.hoveredObjectID = crm
        #expect(model.primarySelection == nil)

        // Selecting offers the actions while the pointer is elsewhere, which is
        // what makes them reachable without hovering.
        model.select(crm)
        #expect(model.primarySelection == crm)
        model.hoveredObjectID = nil
        #expect(model.primarySelection == crm)

        model.select(csv, extending: true)
        #expect(model.selection.count == 2)
    }

    @Test("An object that no longer exists leaves the selection, and nothing replaces it")
    func pruningNeverSelectsSomethingElse() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let crm = KollioID.object("sarah-crm")

        // A kept branch creates real objects, which gives the selection something
        // that can then disappear. The created ids are the difference, not a guess.
        let before = Set(model.document.content.keys)
        await model.explore(crm)
        model.keepPreview()
        let created = try! #require(Set(model.document.content.keys).subtracting(before).first)
        #expect(model.document.object(created) != nil)

        model.select(created)
        model.select(crm, extending: true)
        #expect(model.selection.count == 2)

        // Undo removes what the keep created, and is the one reachable path today
        // by which an object leaves the document. There is no delete command in the
        // domain, so the "removed remotely" case of CAN-02 is not yet reachable;
        // `pruneSelection` is the single place that rule will live when it is.
        model.undo()

        #expect(model.document.object(created) == nil)
        #expect(!model.selection.contains(created))
        // The object that still exists is untouched, and nothing was invented to
        // take the vanished one's place.
        #expect(model.selection == [crm])
    }

}

/// Counts calls and throws on the first one. Used where the point of the test is
/// that a path does not reach the intelligence seam at all: a silent success
/// would prove nothing, so the service refuses rather than answering.
final class RefusingSuggestionService: SuggestionService, @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0

    var capabilities: SuggestionCapabilities { .offline }

    var callCount: Int { lock.withLock { calls } }

    func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        lock.withLock { calls += 1 }
        throw RefusedByTest.unexpectedCall
    }
}

enum RefusedByTest: Error { case unexpectedCall }
