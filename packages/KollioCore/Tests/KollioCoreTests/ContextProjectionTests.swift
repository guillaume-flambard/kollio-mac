import Foundation
import Testing
@testable import KollioCore

/// What intelligence is shown, and what it is not shown.
///
/// The rule that matters: a person can see the omissions, a required item is never
/// dropped to fit a budget, and a truncated context is never presented as a
/// complete understanding.
@Suite("Context projection")
struct ContextProjectionTests {
    private func cost(
        _ id: String,
        _ characters: Int,
        required: Bool = false
    ) -> ContextProjector.ItemCost {
        ContextProjector.ItemCost(
            item: .object(ObjectID(id)),
            characters: characters,
            isRequired: required
        )
    }

    @Test("The list is the payload: what is included is what was measured")
    func theListIsThePayload() {
        let projection = ContextProjector().project(
            rootContext: ["ctx"],
            targets: ["ctx"],
            costs: [cost("ctx", 100, required: true), cost("note", 50)],
            budgetCharacters: 1_000,
            locality: .localOnly
        )
        #expect(projection.included.count == 2)
        #expect(projection.measuredCharacters == 150)
        #expect(projection.isComplete)
        #expect(projection.mayLeaveTheMachine == false)
    }

    @Test("Optional material is dropped to fit, and the drop is visible")
    func optionalMaterialIsDroppedVisibly() {
        let projection = ContextProjector().project(
            rootContext: ["ctx"],
            targets: ["ctx"],
            costs: [cost("ctx", 100, required: true), cost("big", 900)],
            budgetCharacters: 200,
            locality: .localOnly
        )
        #expect(projection.included.map(\.id) == ["object:ctx"])
        #expect(projection.omissions == [.droppedForBudget(.object("big"))])
        // Incomplete, so the interface has to say the model was not shown
        // everything rather than implying it understood the whole thing.
        #expect(projection.isComplete == false)
        // Nothing required is missing, so the answer is still about the request.
        #expect(projection.missingRequired.isEmpty)
    }

    @Test("A required item is never dropped to fit, and its absence is reported")
    func requiredItemsAreNeverDropped() {
        let projection = ContextProjector().project(
            rootContext: ["ctx"],
            targets: ["ctx"],
            costs: [cost("ctx", 100, required: true), cost("constraint", 5_000, required: true)],
            budgetCharacters: 200,
            locality: .localOnly
        )
        // The optional-looking large item did not get in, and the constraint is
        // reported missing rather than quietly left out.
        #expect(projection.missingRequired == [.object("constraint")])
        #expect(projection.included.map(\.id) == ["object:ctx"])
        #expect(projection.isComplete == false)
    }

    @Test("A required item is considered before optional material")
    func requiredIsConsideredFirst() {
        // A budget that fits the constraint but not the note. Considering optional
        // items first would spend the budget on the note and starve the constraint.
        let projection = ContextProjector().project(
            rootContext: [],
            targets: ["constraint"],
            costs: [
                cost("note", 150),
                cost("constraint", 100, required: true)
            ],
            budgetCharacters: 120,
            locality: .localOnly
        )
        #expect(projection.included.map(\.id) == ["object:constraint"])
        #expect(projection.missingRequired.isEmpty)
    }

    @Test("Local-only context cannot be sent, and says so")
    func localOnlyForbidsSending() {
        let local = ContextProjector().project(
            rootContext: ["ctx"], targets: ["ctx"],
            costs: [cost("ctx", 10, required: true)],
            budgetCharacters: 100, locality: .localOnly
        )
        #expect(local.mayLeaveTheMachine == false)

        let shareable = ContextProjector().project(
            rootContext: ["ctx"], targets: ["ctx"],
            costs: [cost("ctx", 10, required: true)],
            budgetCharacters: 100, locality: .shareable
        )
        #expect(shareable.mayLeaveTheMachine == true)
    }

    @Test("Excluding something for this request does not touch the projection's items")
    func exclusionIsPerRequest() {
        // Exclusion is expressed by the caller not offering the item, so the
        // document is untouched. What the projection reports is only what it was
        // given and what it could not fit.
        let projection = ContextProjector().project(
            rootContext: ["ctx"], targets: ["ctx"],
            costs: [cost("ctx", 10, required: true)],
            budgetCharacters: 100, locality: .localOnly
        )
        #expect(projection.omissions.isEmpty)
        #expect(projection.included.map(\.id) == ["object:ctx"])
    }

    @Test("The result is stable between runs")
    func projectionIsDeterministic() {
        let costs = [cost("a", 30), cost("b", 30), cost("c", 30)]
        let first = ContextProjector().project(
            rootContext: [], targets: [],
            costs: costs, budgetCharacters: 70, locality: .localOnly
        )
        let second = ContextProjector().project(
            rootContext: [], targets: [],
            costs: costs, budgetCharacters: 70, locality: .localOnly
        )
        #expect(first.included == second.included)
        #expect(first.omissions == second.omissions)
    }
}
