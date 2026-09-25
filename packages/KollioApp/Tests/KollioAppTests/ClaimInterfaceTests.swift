import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// Stating a claim from the interface, and saying how it stands.
///
/// The behaviours worth protecting are the ones a person can get wrong: an
/// accidental sweeping scope, a verdict recorded without an observation, and a
/// constraint offered a stance that belongs to a hypothesis.
@Suite("Claim interface")
@MainActor
struct ClaimInterfaceTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    private let crm = ObjectID("object:sarah-crm")
    private let csv = ObjectID("object:sarah-csv")

    @Test("A claim takes the current selection as its scope")
    func scopeComesFromTheSelection() {
        var model = model()
        // Two objects selected: the claim is about both, which is the scoped case
        // and should not be the fiddly one.
        model.selection = [crm, csv]
        model.startClaim(role: .constraint, anchor: crm)
        #expect(model.claimDraft?.scopeObjects == [crm, csv])
    }

    @Test("With nothing selected, the claim is about the object being worked on")
    func singleObjectScope() {
        var model = model()
        model.selection = []
        model.startClaim(role: .hypothesis, anchor: csv)
        #expect(model.claimDraft?.scopeObjects == [csv])
    }

    @Test("A stated claim lands in the document with its scope and stays open")
    func statingAClaim() throws {
        var model = model()
        model.selection = [crm]
        model.startClaim(role: .constraint, anchor: crm)
        model.claimDraft?.criterion = "Until the credentials exist"
        #expect(model.submitClaim())

        let claim = try #require(model.claimSummary(for: crm))
        #expect(claim.role == .constraint)
        #expect(claim.scopeCount == 1)
        #expect(claim.criterion == "Until the credentials exist")
        // Stating a claim says nothing about whether it holds.
        #expect(claim.isAsserted == false)
        #expect(model.claimDraft == nil)
    }

    @Test("An empty scope states nothing and says why")
    func emptyScopeStatesNothing() {
        var model = model()
        model.startClaim(role: .hypothesis, anchor: crm)
        model.claimDraft?.scopeObjects = []
        #expect(model.submitClaim() == false)
        #expect(model.status != nil)
        #expect(model.document.claims.allClaims().isEmpty)
        // The draft survives, so the scope can be fixed rather than retyped.
        #expect(model.claimDraft != nil)
    }

    @Test("A stance needs an observation")
    func stanceNeedsAnObservation() throws {
        var model = model()
        model.selection = [crm]
        model.startClaim(role: .constraint, anchor: crm)
        #expect(model.submitClaim())

        // The draft is set the way the interface sets it, so the sentence being
        // preserved is the sentence a person actually typed.
        model.stanceDraft = .init(anchor: crm, stance: .satisfied)
        model.stanceDraft?.observation = "   "
        #expect(model.recordStance(try #require(model.stanceDraft)) == false)
        // Still open, and the draft is untouched so the sentence can be finished.
        #expect(model.claimSummary(for: crm)?.isAsserted == false)
        #expect(model.stanceDraft?.stance == .satisfied)

        model.stanceDraft?.observation = "The credentials arrived on Tuesday."
        #expect(model.recordStance(try #require(model.stanceDraft)))
        #expect(model.claimSummary(for: crm)?.isAsserted == true)
        // Cleared only once the command was accepted.
        #expect(model.stanceDraft == nil)
    }

    @Test("A hypothesis and a constraint are offered different stances")
    func stancesDependOnTheRole() {
        // The two vocabularies are kept apart in the domain, and the interface only
        // offers what applies: a constraint cannot be refuted, a hypothesis cannot
        // be satisfied.
        #expect(KollioModel.Stance.applicable(to: .hypothesis) == [.open, .supported, .contradicted, .refuted])
        #expect(KollioModel.Stance.applicable(to: .constraint) == [.open, .satisfied, .notApplicable])
    }

    @Test("A verdict that does not belong to the role is not recorded as itself")
    func crossRoleVerdictIsNotRecorded() {
        var model = model()
        model.selection = [crm]
        model.startClaim(role: .constraint, anchor: crm)
        #expect(model.submitClaim())

        // "Refuted" is a hypothesis's word. On a constraint it resolves to open
        // rather than inventing a state the type does not have.
        var draft = KollioModel.StanceDraft(anchor: crm, stance: .refuted)
        draft.observation = "Not a hypothesis verdict."
        #expect(model.recordStance(draft))
        #expect(model.claimSummary(for: crm)?.constraint == .open)
    }

    @Test("The claim is read back off the document, not a cache")
    func claimComesFromTheDocument() {
        var model = model()
        model.selection = [crm]
        model.startClaim(role: .hypothesis, anchor: crm)
        #expect(model.submitClaim())
        #expect(model.claim(on: crm) != nil)
        #expect(model.claim(on: csv) == nil)
    }
}
