import Foundation
import Testing
@testable import KollioCore

/// Hypotheses and constraints: what is asserted, where, and how it stands.
///
/// The three acceptance criteria for CTX-04 are the reason this file exists, and
/// each has a test named after it:
///
/// - AC01 a constraint only blocks within its scope
/// - AC02 not applicable is not satisfied
/// - AC03 supported is not absolute truth
@Suite("Claims")
struct ClaimLedgerTests {
    private func store() -> DocumentStore {
        DocumentStore(document: Fixture.sarah())
    }

    private func scope(_ id: String, _ objects: [ObjectID]) -> ClaimScope {
        ClaimScope(id: ScopeID(id), title: "Scope \(id)", objectIDs: Set(objects))
    }

    private func constraint(
        _ id: String = "claim:1",
        scopeID: String = "scope:1",
        objects: [ObjectID] = ["object:sarah-crm"]
    ) -> Claim {
        Claim(
            id: ClaimID(id),
            objectID: "object:sarah-blocked",
            role: .constraint,
            scope: scope(scopeID, objects)
        )
    }

    private func hypothesis(
        _ id: String = "claim:h",
        objects: [ObjectID] = ["object:sarah-csv"]
    ) -> Claim {
        Claim(
            id: ClaimID(id),
            objectID: "object:sarah-csv",
            role: .hypothesis,
            scope: scope("scope:h", objects)
        )
    }

    // MARK: AC01

    @Test("AC01: a constraint only blocks inside its own scope")
    func constraintBlocksOnlyWithinScope() throws {
        var store = store()
        let claim = constraint(objects: ["object:sarah-crm"])
        try store.apply([.assertClaim(.init(claim: claim, provenance: .human("me")))])

        let ledger = store.document.claims
        let stored = try #require(ledger.claim("claim:1"))
        // Inside the scope it blocks.
        #expect(ledger.blocks(stored, object: "object:sarah-crm"))
        // Outside it, it is a remark about the CRM, not a law of the document.
        #expect(ledger.blocks(stored, object: "object:sarah-csv") == false)
        #expect(ledger.blockedObjects(for: stored) == ["object:sarah-crm"])
    }

    @Test("A claim with an empty scope is refused")
    func emptyScopeIsRefused() throws {
        var store = store()
        let before = store.document
        #expect(throws: DocumentError.emptyScope("claim:1")) {
            try store.apply([.assertClaim(.init(
                claim: constraint(objects: []), provenance: .human("me")
            ))])
        }
        // Read as "everything" it would forbid every branch in the document.
        #expect(store.document == before)
    }

    @Test("A scope naming an object that is not there is refused")
    func scopeMustExist() throws {
        var store = store()
        #expect(throws: DocumentError.unknownObject("object:ghost")) {
            try store.apply([.assertClaim(.init(
                claim: constraint(objects: ["object:ghost"]), provenance: .human("me")
            ))])
        }
    }

    @Test("A hypothesis never blocks anything")
    func hypothesisDoesNotBlock() throws {
        var store = store()
        try store.apply([.assertClaim(.init(claim: hypothesis(), provenance: .human("me")))])
        let stored = try #require(store.document.claims.claim("claim:h"))
        // Only a constraint blocks. Treating a hypothesis as a blocker would turn
        // an idea into a rule.
        #expect(store.document.claims.blocks(stored, object: "object:sarah-csv") == false)
        #expect(store.document.claims.blockedObjects(for: stored).isEmpty)
    }

    // MARK: AC02

    @Test("AC02: not applicable is not satisfied")
    func notApplicableIsNotSatisfied() throws {
        var store = store()
        try store.apply([
            .assertClaim(.init(claim: constraint(), provenance: .human("me"))),
            .resolveConstraint(.init(
                claimID: "claim:1",
                resolution: .notApplicable(.init(observation: "The CRM is not used here.", by: "me")),
                provenance: .human("me")
            ))
        ])
        let stored = try #require(store.document.claims.claim("claim:1"))
        #expect(stored.resolution.isSatisfied == false)
        if case .notApplicable = stored.resolution {} else {
            Issue.record("the resolution should still be notApplicable")
        }
        // And it does not block: the constraint does not speak about this object at
        // all, which is a different thing from being met.
        #expect(store.document.claims.blocks(stored, object: "object:sarah-crm") == false)
    }

    @Test("A satisfied constraint blocks nothing either")
    func satisfiedConstraintBlocksNothing() throws {
        var store = store()
        try store.apply([
            .assertClaim(.init(claim: constraint(), provenance: .human("me"))),
            .resolveConstraint(.init(
                claimID: "claim:1",
                resolution: .satisfied(.init(observation: "Credentials obtained.", by: "me")),
                provenance: .human("me")
            ))
        ])
        let stored = try #require(store.document.claims.claim("claim:1"))
        #expect(stored.resolution.isSatisfied)
        #expect(store.document.claims.blockedObjects(for: stored).isEmpty)
        #expect(store.document.claims.blocks(stored, object: "object:sarah-crm") == false)
    }

    @Test("A resolution needs an observation")
    func resolutionNeedsAnObservation() throws {
        var store = store()
        try store.apply([.assertClaim(.init(claim: constraint(), provenance: .human("me")))])
        #expect(throws: DocumentError.forbiddenOperation("a resolution needs an observation")) {
            try store.apply([.resolveConstraint(.init(
                claimID: "claim:1",
                resolution: .satisfied(.init(observation: "  ", by: "me")),
                provenance: .human("me")
            ))])
        }
        let stored = try #require(store.document.claims.claim("claim:1"))
        #expect(stored.resolution == .open)
    }

    // MARK: AC03

    @Test("AC03: supported is not absolute truth")
    func supportedIsNotTruth() throws {
        var store = store()
        try store.apply([
            .assertClaim(.init(claim: hypothesis(), provenance: .human("me"))),
            .assessHypothesis(.init(
                claimID: "claim:h",
                assessment: .supported(.init(observation: "The export exists.", by: "me")),
                provenance: .human("me")
            ))
        ])
        let stored = try #require(store.document.claims.claim("claim:h"))
        #expect(stored.assessment.evidence != nil)
        // There is no way to say a hypothesis is correct, only that something backs
        // it: every non-open case carries evidence, so a bare "supported" cannot
        // be built. The first version of this test asserted on
        // String(describing:) of the type, which proved nothing about the cases.
        if case .supported(let evidence) = stored.assessment {
            #expect(evidence.observation == "The export exists.")
            #expect(evidence.by == "me")
        } else {
            Issue.record("the hypothesis should be supported with its evidence")
        }
        #expect(stored.isAsserted)
        // And a supported hypothesis resolves nothing, because the two questions
        // are not the same question.
        #expect(stored.resolution == .open)
    }

    @Test("An assessment needs an observation, and the roles do not cross")
    func rolesDoNotCross() throws {
        var store = store()
        try store.apply([
            .assertClaim(.init(claim: hypothesis(), provenance: .human("me"))),
            .assertClaim(.init(
                claim: Claim(
                    id: "claim:c", objectID: "object:sarah-blocked", role: .constraint,
                    scope: scope("scope:c", ["object:sarah-crm"])
                ),
                provenance: .human("me")
            ))
        ])
        // A hypothesis is not a constraint.
        #expect(throws: DocumentError.wrongClaimRole("claim:h", expected: "constraint")) {
            try store.apply([.resolveConstraint(.init(
                claimID: "claim:h", resolution: .satisfied(.init(observation: "x", by: "me")),
                provenance: .human("me")
            ))])
        }
        // A constraint is not a hypothesis.
        #expect(throws: DocumentError.wrongClaimRole("claim:c", expected: "hypothesis")) {
            try store.apply([.assessHypothesis(.init(
                claimID: "claim:c",
                assessment: .supported(.init(observation: "x", by: "me")),
                provenance: .human("me")
            ))])
        }
        #expect(throws: DocumentError.forbiddenOperation("an assessment needs an observation")) {
            try store.apply([.assessHypothesis(.init(
                claimID: "claim:h",
                assessment: .supported(.init(observation: "", by: "me")),
                provenance: .human("me")
            ))])
        }
    }

    @Test("A claim built as a constraint cannot arrive pre-resolved")
    func roleForcesTheOtherSideOpen() {
        // The initialiser is where a mistake would be cheapest to make, so it is
        // checked here rather than trusted.
        let asConstraint = Claim(
            id: "claim:x", objectID: "object:sarah-csv", role: .constraint,
            scope: scope("s", ["object:sarah-csv"]),
            assessment: .supported(.init(observation: "sneaky", by: "me"))
        )
        #expect(asConstraint.assessment == .open)
        let asHypothesis = Claim(
            id: "claim:y", objectID: "object:sarah-csv", role: .hypothesis,
            scope: scope("s", ["object:sarah-csv"]),
            resolution: .satisfied(.init(observation: "sneaky", by: "me"))
        )
        #expect(asHypothesis.resolution == .open)
    }

    // MARK: Contradictory scopes

    @Test("Two claims over the same ground ask for precision")
    func overlappingScopesAreSurfaced() throws {
        var store = store()
        try store.apply([
            .assertClaim(.init(
                claim: constraint("claim:1", scopeID: "scope:a", objects: ["object:sarah-crm"]),
                provenance: .human("me")
            )),
            .assertClaim(.init(
                claim: constraint("claim:2", scopeID: "scope:b", objects: ["object:sarah-csv"]),
                provenance: .human("me")
            ))
        ])
        // Disjoint scopes are not a conflict.
        #expect(store.document.claims.overlappingScopes().isEmpty)
        // Two claims over the same ground are not a conflict yet either: nobody has
        // taken a position, so there is nothing to reconcile.
        try store.apply([.assertClaim(.init(
            claim: constraint("claim:9", scopeID: "scope:z", objects: ["object:sarah-crm"]),
            provenance: .human("me")
        ))])
        #expect(store.document.claims.overlappingScopes().isEmpty)

        try store.apply([.assertClaim(.init(
            claim: constraint("claim:3", scopeID: "scope:c", objects: ["object:sarah-crm", "object:sarah-csv"]),
            provenance: .human("me")
        ))])
        // Still nothing to reconcile: every claim is still open.
        #expect(store.document.claims.overlappingScopes().isEmpty)

        // Once somebody takes a position, the overlap is surfaced for a person to
        // resolve rather than settled by picking a winner.
        try store.apply([.resolveConstraint(.init(
            claimID: "claim:1",
            resolution: .satisfied(.init(observation: "Credentials obtained.", by: "me")),
            provenance: .human("me")
        ))])
        let overlaps = store.document.claims.overlappingScopes()
        #expect(overlaps.isEmpty == false)
        #expect(overlaps.contains { $0.sharedObjects.contains("object:sarah-crm") })
    }

    @Test("Claims survive a save and reload")
    func claimsRoundTrip() throws {
        var store = store()
        try store.apply([
            .assertClaim(.init(claim: constraint(), provenance: .human("me"))),
            .resolveConstraint(.init(
                claimID: "claim:1",
                resolution: .notApplicable(.init(observation: "Not used here.", by: "me")),
                provenance: .human("me")
            ))
        ])
        let reloaded = try DocumentCodec.decode(try DocumentCodec.encode(store.document))
        let stored = try #require(reloaded.claims.claim("claim:1"))
        #expect(stored.scope.objectIDs == ["object:sarah-crm"])
        if case .notApplicable = stored.resolution {} else {
            Issue.record("the resolution should survive a round trip")
        }
    }

    @Test("Intelligence may suggest a claim but may not record how it stands")
    func intelligenceCannotGradeItsOwnWork() throws {
        let document = Fixture.sarah()
        let scope = scope("s", ["object:sarah-crm"])

        // Allowed: an open claim, which is how a model says "this looks like a
        // constraint" and lets the person correct it.
        let suggestion = Proposal(
            proposalId: "proposal:suggest",
            requestId: "request:suggest",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("A constraint worth stating"),
            operations: [.assertClaim(.init(
                claim: Claim(
                    id: "claim:s", objectID: "object:sarah-blocked", role: .constraint, scope: scope
                ),
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))],
            generator: .init(name: "apple-on-device", deterministic: false)
        )
        try ProposalValidator().validate(
            suggestion, against: document, scope: ProposalRequest.Scope()
        )

        // Refused: the same claim arriving already resolved, and any attempt to
        // record an assessment at all.
        let preResolved = Proposal(
            proposalId: "proposal:resolved",
            requestId: "request:resolved",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("A constraint, already satisfied"),
            operations: [.assertClaim(.init(
                claim: Claim(
                    id: "claim:r", objectID: "object:sarah-blocked", role: .constraint,
                    scope: scope, resolution: .satisfied(.init(observation: "trust me", by: "me"))
                ),
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))],
            generator: .init(name: "apple-on-device", deterministic: false)
        )
        #expect(throws: DocumentError.self) {
            try ProposalValidator().validate(
                preResolved, against: document, scope: ProposalRequest.Scope()
            )
        }

        for command: Command in [
            .assessHypothesis(.init(
                claimID: "claim:s",
                assessment: .supported(.init(observation: "I agree with myself", by: "me")),
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            )),
            .resolveConstraint(.init(
                claimID: "claim:s",
                resolution: .satisfied(.init(observation: "out of the way", by: "me")),
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))
        ] {
            let proposal = Proposal(
                proposalId: "proposal:grade",
                requestId: "request:grade",
                documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision,
                summary: LocalizedText("Grading my own work"),
                operations: [command],
                generator: .init(name: "apple-on-device", deterministic: false)
            )
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(
                    proposal, against: document, scope: ProposalRequest.Scope()
                )
            }
        }
    }
}
