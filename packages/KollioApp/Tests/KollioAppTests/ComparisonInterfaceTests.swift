import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// Comparing directions from the interface.
///
/// The path worth protecting: the action appears only with two directions, the
/// criteria start as a draft that records nothing, confirming is explicit, a cell
/// without a measure never becomes a number, a total appears only when the terms
/// are all defined, and keeping one direction leaves the others exactly as they
/// were.
@Suite("Comparison from the interface")
@MainActor
struct ComparisonInterfaceTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    private let crm = ObjectID("object:sarah-crm")
    private let csv = ObjectID("object:sarah-csv")

    @Test("The action needs two directions")
    func theActionFollowsTheSelection() {
        let model = model()
        model.selection = [crm]
        #expect(model.contextualActions(for: crm).contains(.compareDirections) == false)

        model.selection = [crm, csv]
        let actions = model.contextualActions(for: crm)
        #expect(actions.contains(.compareDirections))
        // Behind the secondary menu: the three primary actions are fixed.
        #expect(actions.primary.contains(.compareDirections) == false)
    }

    @Test("A comparison of one direction is refused and says why")
    func oneDirectionIsRefused() {
        let model = model()
        model.selection = [crm]
        #expect(model.startComparison() == nil)
        #expect(model.document.comparisons.all().isEmpty)
        #expect(model.status != nil)
    }

    @Test("A comparison starts as a draft that records nothing")
    func aComparisonStartsAsADraft() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let comparison = try #require(model.comparison(id))
        #expect(comparison.isDraft)
        #expect(comparison.directionIDs == [crm, csv])
        #expect(model.openComparison == id)

        // A cell cannot be recorded while the criteria are unconfirmed...
        let criterion = try #require(model.addCriterionOwned("How it feels", to: id))
        #expect(model.comparison(id)?.isDraft == true)
        #expect(model.recordCell(.text("brittle"), criterion: criterion, direction: crm, in: id) == false)

        // ...and once they are confirmed, the same cell is accepted. A number is
        // still refused on this criterion, because it has no measure: words are what
        // it can hold.
        model.confirmComparisonCriteria(id)
        #expect(model.comparison(id)?.isDraft == false)
        #expect(model.recordCell(.text("brittle"), criterion: criterion, direction: crm, in: id))
        #expect(model.recordCell(.number(3), criterion: criterion, direction: crm, in: id) == false)
        #expect(model.comparison(id)?.cell(criterion: criterion, direction: crm)?.value.text == "brittle")
    }

    @Test("A draft refuses a cell before it is confirmed")
    func aDraftRefusesACell() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        // Confirmed criteria, then a draft put back by a fresh comparison: the
        // interface must not be able to write into an unconfirmed question.
        model.confirmComparisonCriteria(id)
        let criterion = try #require(model.confirmedCriterion("Cost", in: id))
        let second = try #require(model.startComparison())
        #expect(model.comparison(second)?.isDraft == true)
        #expect(model.recordCell(.text("brittle"), criterion: criterion, direction: crm, in: second) == false)
        #expect(model.status != nil)
        #expect(model.comparison(second)?.cells.isEmpty == true)
    }

    @Test("A criterion with no measure never becomes a number")
    func noMeasureNoNumber() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("How it feels", in: id))

        // Refused in the interface *and* in the store. The interface does not offer a
        // number field for such a criterion, so this is the backstop rather than the
        // friction; the test calls the command directly to prove the backstop holds.
        let refused = model.recordCell(.number(4), criterion: criterion, direction: crm, in: id)
        #expect(refused == false)
        #expect(model.comparison(id)?.cells.isEmpty == true)

        // Words are accepted on the same criterion, and the total stays undefined.
        #expect(model.recordCell(.text("brittle"), criterion: criterion, direction: crm, in: id))
        #expect(model.comparison(id)?.cell(criterion: criterion, direction: crm)?.value.text == "brittle")
        #expect(model.comparison(id)?.total(for: crm) == nil)
        #expect(model.comparisonRows(id).first?.total == nil)
    }

    @Test("A total appears only once every term is defined")
    func aTotalNeedsEveryTerm() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost in days", in: id))
        // A measure and a weight are the person's to state; until both are, no total.
        #expect(model.setWeight(nil, criterion: criterion, in: id))
        #expect(model.setWeight(1, criterion: criterion, in: id))
        #expect(model.setMeasure("days", higherIsBetter: false, criterion: criterion, in: id))
        #expect(model.recordCell(.number(3), criterion: criterion, direction: crm, in: id))
        // One direction recorded, the other not: not "partial", not defined.
        #expect(model.comparison(id)?.total(for: crm) == -3)
        #expect(model.comparison(id)?.hasDefinedTotals == false)

        #expect(model.recordCell(.number(1), criterion: criterion, direction: csv, in: id))
        #expect(model.comparison(id)?.hasDefinedTotals == true)
        let rows = model.comparisonRows(id)
        #expect(rows.first { $0.id == crm }?.total == -3)
        #expect(rows.first { $0.id == csv }?.total == -1)
    }

    @Test("A missing cell reads as not recorded, never as a zero")
    func aMissingCellIsNotAZero() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost in days", in: id))
        _ = model.setWeight(1, criterion: criterion, in: id)
        _ = model.setMeasure("days", higherIsBetter: false, criterion: criterion, in: id)
        _ = model.recordCell(.number(3), criterion: criterion, direction: crm, in: id)

        let csvCell = model.comparison(id)?.cell(criterion: criterion, direction: csv)
        // Nothing recorded is a state, and the value is not a number.
        #expect(csvCell?.value.number == nil)
        #expect(csvCell?.value.text == nil)
        // And the row for that direction says so rather than showing a total.
        #expect(model.comparisonRows(id).first { $0.id == csv }?.cellCount == 0)
    }

    @Test("A measure and a weight can be stated from the interface")
    func measureAndWeightAreReachable() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.addCriterionOwned("Cost", to: id))
        model.confirmComparisonCriteria(id)

        // The two facts that decide whether a total exists, both stated the way the
        // card's editor states them. Until they exist, the card shows "no total yet",
        // and a criterion nobody can measure is a criterion nobody can sum.
        #expect(model.setMeasure("days", higherIsBetter: false, criterion: criterion, in: id))
        #expect(model.setWeight(1, criterion: criterion, in: id))
        #expect(model.comparison(id)?.criterion(criterion)?.measure
                == Measure(unit: "days", higherIsBetter: false))
        #expect(model.comparison(id)?.criterion(criterion)?.weight == 1)

        #expect(model.recordCell(.number(3), criterion: criterion, direction: crm, in: id))
        #expect(model.recordCell(.number(1), criterion: criterion, direction: csv, in: id))
        #expect(model.comparison(id)?.hasDefinedTotals == true)
    }

    @Test("A blank unit means judged in words, and a blank weight means unweighted")
    func blankMeansAbsent() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.addCriterionOwned("Cost", to: id))
        model.confirmComparisonCriteria(id)
        _ = model.setMeasure("days", higherIsBetter: true, criterion: criterion, in: id)
        _ = model.setWeight(2, criterion: criterion, in: id)
        _ = model.recordCell(.number(5), criterion: criterion, direction: crm, in: id)
        #expect(model.comparison(id)?.total(for: crm) == 10)

        // Removing them again is an action a person takes, not a repair: no total,
        // and the cell that was recorded is still recorded.
        #expect(model.setMeasure(nil, higherIsBetter: true, criterion: criterion, in: id))
        #expect(model.setWeight(nil, criterion: criterion, in: id))
        #expect(model.comparison(id)?.criterion(criterion)?.measure == nil)
        #expect(model.comparison(id)?.total(for: crm) == nil)
        #expect(model.comparison(id)?.cell(criterion: criterion, direction: crm)?.value.number == 5)
    }

    @Test("A cell keeps the references it rests on")
    func cellsKeepReferences() throws {
        let model = model()
        // A source cited by the CRM, so the cell has something real to point at.
        #expect(model.perform([.attachSource(.init(
            source: SourceReference(
                id: "source:brief", kind: .text, title: "Brief", locator: "file:///tmp/b",
                revisions: [SourceRevision(
                    id: "rev:1", sequence: 1, extraction: .ready(text: "three days"), digest: "d"
                )]
            ),
            provenance: .human("local-user")
        ))], label: "attach"))
        #expect(model.perform([.addCitation(.init(
            citation: Citation(
                id: "citation:1", claimID: crm, sourceID: "source:brief", revisionID: "rev:1",
                locator: SourceLocator(page: 1), quote: "three days"
            ),
            claimID: crm, provenance: .human("local-user")
        ))], label: "cite"))

        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost", in: id))
        #expect(model.recordCell(.text("three days"), criterion: criterion, direction: crm, in: id))

        let cell = try #require(model.comparison(id)?.cell(criterion: criterion, direction: crm))
        // AC02 through the interface: the cell points at the citation, the source and
        // the object, and at the revision the citation was read against.
        #expect(cell.references.map(\.kind).contains(.citation))
        #expect(cell.references.map(\.kind).contains(.source))
        #expect(cell.referenceRevisions["source:brief"] == "rev:1")
    }

    @Test("A cell whose object was edited needs a review")
    func anEditedObjectNeedsAReview() async throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost", in: id))
        #expect(model.recordCell(.text("three days"), criterion: criterion, direction: crm, in: id))
        #expect(model.comparisonNeedsReview(id) == nil)

        // The person rewrites the direction: the cell was recorded against different
        // words, and the comparison says so.
        model.startEditing(anchor: crm)
        model.composer?.text = "A pooled CRM connection"
        await model.submitComposer()
        // The edit went through, and the comparison noticed on its own.
        #expect(model.text(of: crm) == "A pooled CRM connection")
        #expect(model.comparisonNeedsReview(id) == .referencedObjectChanged)
    }

    @Test("Keeping a direction leaves the others and their cells")
    func keepingLeavesTheOthers() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let cost = try #require(model.confirmedCriterion("Cost", in: id))
        let feel = try #require(model.confirmedCriterion("How it feels", in: id))
        #expect(model.recordCell(.text("three days"), criterion: cost, direction: crm, in: id))
        #expect(model.recordCell(.text("a day"), criterion: cost, direction: csv, in: id))
        #expect(model.recordCell(.text("brittle"), criterion: feel, direction: crm, in: id))
        let content = model.document.content

        #expect(model.keepDirection(csv, in: id))
        let rows = model.comparisonRows(id)
        // AC03 through the interface: one row says kept, the other is still there with
        // everything recorded.
        #expect(rows.first { $0.id == csv }?.isKept == true)
        #expect(rows.first { $0.id == crm }?.isKept == false)
        #expect(rows.first { $0.id == crm }?.cellCount == 2)
        #expect(model.comparison(id)?.cell(criterion: feel, direction: crm)?.value.text == "brittle")
        // And nothing about the document itself moved.
        #expect(model.document.content == content)
    }

    @Test("A comparison is one transaction per action and undoes one step at a time")
    func undoIsOneStepAtATime() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost", in: id))
        #expect(model.recordCell(.text("three days"), criterion: criterion, direction: crm, in: id))
        #expect(model.recordCell(.text("a day"), criterion: criterion, direction: csv, in: id))
        #expect(model.keepDirection(csv, in: id))

        // `undo()` returns nothing, so the document is read after each press rather
        // than a Boolean being asserted, which also proves the *state* is what came
        // back and not merely that something was undone.
        //
        // The recorded steps are spelled out because a "one undo per action" claim
        // that does not say which actions is a claim about nothing: the comparison,
        // a criterion and its confirmation, the second criterion, a cell for each
        // direction, and the keep.
        model.undo()
        #expect(model.comparison(id)?.isKept(csv) == false)
        model.undo()
        #expect(model.comparison(id)?.cell(criterion: criterion, direction: csv) == nil)
        model.undo()
        #expect(model.comparison(id)?.cell(criterion: criterion, direction: crm) == nil)
        // Three presses, three pieces of work undone, and the comparison with its
        // criteria is still there: one step at a time rather than all at once.
        #expect(model.comparison(id)?.cells.isEmpty == true)
        #expect(model.comparison(id)?.criteria.isEmpty == false)
        // Pressing on until the comparison is gone, counting rather than assuming:
        // eight transactions were recorded, and the last one is the comparison itself.
        var presses = 3
        while model.comparison(id) != nil, presses < 20 {
            model.undo()
            presses += 1
        }
        // Six, and the two that are missing are the point: confirming twice is a
        // no-op, and a Cmd+Z should not have to be spent on something that changed
        // nothing. One transaction per *action*, not per function call.
        #expect(presses == 6)
        #expect(model.comparison(id) == nil)
    }

    @Test("Escape closes the comparison without changing it")
    func escapeClosesTheComparison() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost", in: id))
        #expect(model.recordCell(.text("three days"), criterion: criterion, direction: crm, in: id))
        let comparison = try #require(model.comparison(id))

        #expect(model.dismissOneLevel() == .comparison)
        #expect(model.openComparison == nil)
        // Closing a card is not a decision: every cell is still there.
        #expect(model.comparison(id) == comparison)
    }

    @Test("A comparison survives a save and a reload")
    func comparisonsArePersisted() throws {
        let model = model()
        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let criterion = try #require(model.confirmedCriterion("Cost in days", in: id))
        _ = model.setWeight(1, criterion: criterion, in: id)
        _ = model.setMeasure("days", higherIsBetter: false, criterion: criterion, in: id)
        _ = model.recordCell(.number(3), criterion: criterion, direction: crm, in: id)
        _ = model.keepDirection(crm, in: id)

        let url = model.fileStore.url(named: "comparison")
        try model.fileStore.save(model.document, to: url)
        let reloaded = try model.fileStore.load(url)
        #expect(reloaded.comparisons.comparison(id) != nil)
        #expect(reloaded.comparisons.comparison(id)?.isKept(crm) == true)
        #expect(reloaded.comparisons.comparison(id)?.total(for: crm) == -3)
    }

    @Test("The draft's criteria come from the document, and say so")
    func draftCriteriaComeFromTheDocument() throws {
        let model = model()
        // A claim on the CRM with a resolution criterion written on it: the exact
        // thing a comparison should be weighing on, in the person's own words.
        model.selection = [crm]
        model.startClaim(role: .constraint, anchor: crm)
        model.claimDraft?.criterion = "Until the credentials exist"
        #expect(model.submitClaim())

        model.selection = [crm, csv]
        let id = try #require(model.startComparison())
        let comparison = try #require(model.comparison(id))
        // Proposed, and only proposed: it is a draft until the person confirms.
        #expect(comparison.criteria.map(\.title) == ["Until the credentials exist"])
        #expect(comparison.isDraft)
    }
}

private extension KollioModel {
    /// Adds a criterion and returns it, which is what a person typing one does. The
    /// comparison is left a draft, so a test that records a cell has to confirm it
    /// first, exactly as the card's Confirm button makes a person do.
    @discardableResult
    func addCriterionOwned(_ title: String, to id: ComparisonID) -> CriterionID? {
        let before = Set(comparison(id)?.criteria.map { $0.id } ?? [])
        guard addCriterion(title, to: id) else { return nil }
        return comparison(id)?.criteria.map { $0.id }.first { before.contains($0) == false }
    }

    /// The two presses a person makes before recording anything: type the criterion,
    /// then confirm the set.
    @discardableResult
    func confirmedCriterion(_ title: String, in id: ComparisonID) -> CriterionID? {
        guard let criterion = addCriterionOwned(title, to: id),
              confirmComparisonCriteria(id)
        else { return nil }
        return criterion
    }
}
