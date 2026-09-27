import Foundation
import Testing
@testable import KollioCore

/// AI-12: the record of what an answer was allowed to see.
///
/// Three facts are in play and the type has to keep all three apart: a limit does
/// not lose text, a known constraint does not disappear silently, and the output
/// states its scope. The tests below are about the record, because the record is
/// the only thing a person can check later.
@Suite("Proposal context scope")
struct ProposalContextScopeTests {
    private func costs(
        required: [String],
        optional: [String],
        size: Int
    ) -> [ContextProjector.ItemCost] {
        var all: [ContextProjector.ItemCost] = []
        for id in required {
            all.append(.init(item: .object(ObjectID(id)), characters: size, isRequired: true))
        }
        for id in optional {
            all.append(.init(item: .object(ObjectID(id)), characters: size, isRequired: false))
        }
        return all
    }

    @Test("The record is built from what was sent, not from what was available")
    func recordFollowsTheProjection() {
        let projection = ContextProjector().project(
            rootContext: ["object:root"],
            targets: ["object:target"],
            costs: costs(required: ["object:target"], optional: ["object:a", "object:b"], size: 100),
            budgetCharacters: 250,
            locality: .localOnly
        )
        let scope = ProposalContextScope(projection)
        // Required first, then optional while there is room. The order is the
        // payload's order, so the list reads the way the prompt was built.
        #expect(scope.readObjectIDs == ["object:target", "object:a"])
        #expect(scope.omittedObjectIDs == ["object:b"])
        #expect(scope.measuredCharacters == 200)
        #expect(scope.budgetCharacters == 250)
        #expect(scope.isNarrowed)
        #expect(scope.isComplete == false)
    }

    @Test("A complete projection records a scope that says it is complete")
    func completeScope() {
        let projection = ContextProjector().project(
            rootContext: ["object:root"],
            targets: ["object:target"],
            costs: costs(required: ["object:target"], optional: [], size: 100),
            budgetCharacters: 1_000,
            locality: .localOnly
        )
        let scope = ProposalContextScope(projection)
        #expect(scope.isComplete)
        #expect(scope.isNarrowed == false)
        #expect(scope.omittedObjectIDs.isEmpty)
    }

    @Test("A required item is never recorded as omitted")
    func requiredIsNeverAnOmission() {
        // The failure this rules out: a constraint that did not fit being written
        // down as optional material that was dropped. It is refused before
        // generation, so the record must have no way of saying otherwise.
        let projection = ContextProjector().project(
            rootContext: ["object:root"],
            targets: ["object:target"],
            costs: costs(required: ["object:target"], optional: ["object:a"], size: 1_000),
            budgetCharacters: 10,
            locality: .localOnly
        )
        #expect(projection.missingRequired == [.object("object:target")])
        let scope = ProposalContextScope(projection)
        // The optional one is a legitimate budget drop. The required one is not an
        // omission at all: it is refused before generation, so the record must have
        // no way of presenting a dropped constraint as ordinary material.
        #expect(scope.omittedObjectIDs == ["object:a"])
        #expect(scope.omittedObjectIDs.contains("object:target") == false)
        #expect(scope.readObjectIDs.isEmpty)
    }

    @Test("The count is declared as characters, not as tokens")
    func theUnitIsDeclared() {
        // The app cannot know the model's tokenizer, so a number that looked
        // precise while being a guess would be worse than an honest unit.
        let scope = ProposalContextScope(readObjectIDs: ["object:a"], measuredCharacters: 120, budgetCharacters: 200)
        #expect(scope.countsTokens == false)
    }

    @Test("A scope survives a round trip, and an older record without one still reads")
    func coding() throws {
        let scope = ProposalContextScope(
            readObjectIDs: ["object:a", "object:b"],
            omittedObjectIDs: ["object:c"],
            measuredCharacters: 120,
            budgetCharacters: 200
        )
        let data = try JSONEncoder().encode(scope)
        #expect(try JSONDecoder().decode(ProposalContextScope.self, from: data) == scope)

        // Optional on the wire, so a proposal written before this existed decodes
        // rather than failing to load a document.
        let proposal = Proposal(
            proposalId: "p1", requestId: "r1", documentId: "d", baseSemanticRevision: 0,
            summary: LocalizedText("One direction"),
            generator: .init(name: "demo", deterministic: true)
        )
        #expect(proposal.contextScope == nil)
        let encoded = try JSONEncoder().encode(proposal)
        #expect(try JSONDecoder().decode(Proposal.self, from: encoded).contextScope == nil)
    }

    @Test("An omitted item keeps its identity, not just its count")
    func omissionsAreIdentified() {
        // A count says something was left out. An identity says which, which is the
        // difference between a person deciding to retry and a person guessing.
        let scope = ProposalContextScope(
            readObjectIDs: ["object:a"],
            omittedObjectIDs: ["object:b", "object:c"],
            measuredCharacters: 10,
            budgetCharacters: 10
        )
        #expect(scope.omittedObjectIDs == ["object:b", "object:c"])
        #expect(scope.readObjectIDs.contains("object:b") == false)
    }
}
