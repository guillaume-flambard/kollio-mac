import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// Reading what new information touched, from the interface.
///
/// The card is the only place a person sees an impact, so what is worth testing is
/// the shape of what it says: the action is offered when the document has
/// something to say, it names both the objects to look at and the ones that stay,
/// marking is a record rather than a rewrite, and one undo puts the whole thing
/// back.
@Suite("Impact review from the interface")
@MainActor
struct ImpactReviewInterfaceTests {
    private func model() -> KollioModel {
        KollioModel(
            document: SarahFixture.document(),
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
        )
    }

    private let csv = ObjectID("object:sarah-csv")
    /// The conclusion the export supports.
    private let viable = ObjectID("object:sarah-viable")
    /// The question the export addresses: a topic, not a reliance.
    private let question = ObjectID("object:sarah-question")
    /// The credentials the specification's own AC01 is about.
    private let blocked = ObjectID("object:sarah-blocked")

    private let source = SourceID("source:export")
    private let oldRevision = SourceRevisionID("rev:1")
    private let newRevision = SourceRevisionID("rev:2")

    /// A model whose CSV cites a text source, whose source then gets a newer
    /// revision. That is the situation CTX-05 is about, built the way the
    /// interface builds it.
    private func modelWithMovedSource() throws -> KollioModel {
        var model = model()
        let attached = model.perform([.attachSource(.init(
            source: SourceReference(
                id: source, kind: .csv, title: "export.csv",
                locator: "file:///tmp/export.csv",
                revisions: [SourceRevision(
                    id: oldRevision, sequence: 1,
                    extraction: .ready(text: "name,city"), digest: "sha256:a"
                )]
            ),
            provenance: .human("local-user")
        ))], label: "attach")
        #expect(attached)
        let cited = model.perform([.addCitation(.init(
            citation: Citation(
                id: "citation:1", claimID: csv, sourceID: source, revisionID: oldRevision,
                locator: SourceLocator(lineRange: 0..<1), quote: "name,city"
            ),
            claimID: csv, provenance: .human("local-user")
        ))], label: "cite")
        #expect(cited)
        let imported = model.perform([.importSourceRevision(.init(
            sourceID: source,
            revision: SourceRevision(
                id: newRevision, sequence: 2,
                extraction: .ready(text: "name,city,segment"), digest: "sha256:b"
            ),
            provenance: .human("local-user")
        ))], label: "import")
        #expect(imported)
        return model
    }

    // MARK: Offering the review

    @Test("The review is offered only when the document has something to say")
    func theActionFollowsTheDocument() {
        var model = model()
        // Nothing has moved, so there is no review to open. A control that opens an
        // empty answer every time teaches people to stop opening it.
        #expect(model.needsImpactReview(csv) == false)
        #expect(model.contextualActions(for: csv).contains(.reviewImpact) == false)

        #expect(model.perform([.attachSource(.init(
            source: SourceReference(
                id: source, kind: .csv, title: "export.csv", locator: "file:///tmp/export.csv",
                revisions: [SourceRevision(
                    id: oldRevision, sequence: 1, extraction: .ready(text: "name,city"), digest: "a"
                )]
            ),
            provenance: .human("local-user")
        ))], label: "attach"))
        #expect(model.perform([.addCitation(.init(
            citation: Citation(
                id: "citation:1", claimID: csv, sourceID: source, revisionID: oldRevision,
                locator: SourceLocator(page: 1), quote: "name,city"
            ),
            claimID: csv, provenance: .human("local-user")
        ))], label: "cite"))
        // A citation on the version being read is not an impact.
        #expect(model.needsImpactReview(csv) == false)
        #expect(model.reviewImpact(of: csv) == false)
        #expect(model.status != nil)
    }

    @Test("A moved source offers the review, behind the secondary control")
    func theActionIsOfferedBehindTheMenu() throws {
        let model = try modelWithMovedSource()
        let actions = model.contextualActions(for: csv)
        #expect(actions.contains(.reviewImpact))
        // The specification fixes three primary actions for an ordinary idea, so the
        // review joins the rest behind the one named control rather than pushing
        // something else off the bar.
        #expect(actions.primary.count <= ContextualActionSet.maximumPrimary)
        #expect(actions.primary.contains(.reviewImpact) == false)
        #expect(actions.secondary.contains(.reviewImpact))
    }

    // MARK: What the card says

    @Test("The card names what needs review and what stays valid")
    func theCardAnswersBothQuestions() throws {
        var model = try modelWithMovedSource()
        #expect(model.reviewImpact(of: csv))
        let assessment = try #require(model.impactAssessment)
        #expect(model.impactReviewAnchor == csv)

        // What needs review: the cited object, and the conclusion that rests on it.
        #expect(assessment.objectIDs == [csv, viable])
        #expect(assessment.proposedChanges[0].reason == .evidenceMoved)
        #expect(assessment.proposedChanges[1].reason == .reliesOnImpactedObject)

        // What stays valid, and why: the question the export addresses is a topic,
        // not a reliance, and the credentials were never derived from this file.
        // The second one is AC01 in the specification's own words: a readable export
        // does not make the CRM identifiers available.
        let unaffected = Dictionary(
            uniqueKeysWithValues: assessment.unaffectedRefs.map { ($0.objectID, $0.why) }
        )
        #expect(unaffected[question] == .linkIsNotADependence)
        #expect(assessment.objectIDs.contains(blocked) == false)

        // And it says what it read, so the answer can be checked rather than trusted.
        #expect(assessment.readSet.citationIDs == ["citation:1"])
        #expect(assessment.readSet.visitedObjectIDs == [csv, viable])
        #expect(assessment.wasTruncated == false)
    }

    @Test("Opening the review puts the citations card away")
    func oneCardUnderOneObject() throws {
        var model = try modelWithMovedSource()
        // Both cards open under the same object, so leaving the citations open would
        // stack two of them at the same point and neither would be readable.
        model.openCitationClaim = csv
        #expect(model.reviewImpact(of: csv))
        #expect(model.openCitationClaim == nil)
        #expect(model.readingSourceID == nil)
        #expect(model.impactAssessment != nil)
    }

    @Test("The mark is a fact about the object, not about the card")
    func theMarkSurvivesTheCard() throws {
        var model = try modelWithMovedSource()
        // Before anything is applied, the evidence itself is what needs a look, and
        // the object says so. That is what the badge on the node is drawn from.
        #expect(model.needsImpactReview(csv))
        #expect(model.needsImpactReview(viable) == false)
        #expect(model.needsImpactReview(question) == false)

        #expect(model.reviewImpact(of: csv))
        #expect(model.applyImpactReview())
        // The card is gone, the mark is not, and the object still says so.
        #expect(model.impactAssessment == nil)
        #expect(model.needsImpactReview(csv))
        #expect(model.needsImpactReview(viable))
    }

    @Test("Reviewing asks for no model")
    func reviewingIsLocal() throws {
        // This service throws on every call, which is the harshest version of "a
        // later intelligence failure".
        let failing = FailingSuggestionService()
        var model = try modelWithMovedSource()
        model.service = failing
        #expect(model.reviewImpact(of: csv))
        #expect(model.impactAssessment != nil)
        #expect(failing.callCount == 0)
    }

    // MARK: Applying

    @Test("Marking records a precise decision and changes nothing else")
    func markingIsPrecise() throws {
        var model = try modelWithMovedSource()
        #expect(model.reviewImpact(of: csv))
        let before = model.document
        let assessment = try #require(model.impactAssessment)

        #expect(model.applyImpactReview())
        let after = model.document

        // One decision per impacted object, each naming exactly that object.
        for change in assessment.proposedChanges {
            let decision = try #require(after.pendingImpactReview(for: change.objectID))
            #expect(decision.branchObjectIDs == [change.objectID])
            #expect(decision.rationale?.text == change.reason.rationale)
        }
        // Everything the person wrote is byte-identical: the mark is a record, not a
        // rewrite, and no branch was set aside.
        #expect(after.content == before.content)
        #expect(after.relationships == before.relationships)
        #expect(after.objects.allSatisfy { $0.lifecycle == .active })
        // The card closes, because what it read is now in the document.
        #expect(model.impactAssessment == nil)
        #expect(model.impactReviewAnchor == nil)
    }

    @Test("The marks survive a save and a reload")
    func marksArePersisted() throws {
        var model = try modelWithMovedSource()
        #expect(model.reviewImpact(of: csv))
        #expect(model.applyImpactReview())

        let url = model.fileStore.url(named: "impact")
        try model.fileStore.save(model.document, to: url)
        let reloaded = try model.fileStore.load(url)
        // A mark nobody has looked at has to survive quitting, or the review becomes
        // advice that evaporates.
        #expect(reloaded.pendingImpactReview(for: csv) != nil)
        #expect(reloaded.pendingImpactReview(for: viable) != nil)
        // Only the two marks this assessment made, and nothing else changed.
        #expect(reloaded.decisions.values.filter { $0.kind == .impacted }.count == 2)
        #expect(reloaded.object(csv)?.lifecycle == .active)
    }

    @Test("One undo puts the whole assessment back")
    func theImpactUndoesInOneStep() throws {
        var model = try modelWithMovedSource()
        #expect(model.reviewImpact(of: csv))
        let before = model.document
        #expect(model.applyImpactReview())
        #expect(model.document != before)

        model.undo()
        #expect(model.document.decisions == before.decisions)
        #expect(model.document.revision == before.revision)
    }

    @Test("Not now closes the card and writes nothing")
    func notNowWritesNothing() throws {
        var model = try modelWithMovedSource()
        let before = model.document
        #expect(model.reviewImpact(of: csv))
        model.dismissImpactReview()
        #expect(model.impactAssessment == nil)
        #expect(model.document == before)
        // And the citation that prompted it is still marked, so the offer is still
        // there next time. Closing a card is not a decision.
        #expect(model.needsImpactReview(csv))
    }

    @Test("Applying nothing is refused and says so")
    func applyingNothingIsRefused() {
        var model = model()
        #expect(model.applyImpactReview() == false)
        #expect(model.status != nil)
    }

    @Test("Escape closes the review before the selection")
    func escapeClosesTheReviewFirst() throws {
        var model = try modelWithMovedSource()
        model.selection = [csv]
        #expect(model.reviewImpact(of: csv))
        // The card is deeper than the selection, so one Escape reads the card away
        // and keeps the selection the person built.
        #expect(model.dismissOneLevel() == .impactReview)
        #expect(model.selection == [csv])
        #expect(model.impactAssessment == nil)
    }

    @Test("Taking a position looks at the mark, and keeps the record")
    func aStanceLooksAtTheMark() throws {
        var model = try modelWithMovedSource()
        model.selection = [csv]
        model.startClaim(role: .hypothesis, anchor: csv)
        #expect(model.submitClaim())
        #expect(model.reviewImpact(of: csv))
        #expect(model.applyImpactReview())
        #expect(model.document.pendingImpactReview(for: csv) != nil)

        var draft = KollioModel.StanceDraft(anchor: csv, stance: .supported)
        draft.observation = "The new column is there."
        #expect(model.recordStance(draft))
        // Looked at, not erased: the decision is superseded and still readable, and
        // the citation stays marked because a position on the claim does not put the
        // old revision back.
        #expect(model.document.pendingImpactReview(for: csv) == nil)
        #expect(model.document.decisions.values.contains { $0.kind == .impacted })
        if case .needsReview = model.document.sources.citation("citation:1")?.status {} else {
            Issue.record("the citation should still be marked for review")
        }
    }
}

/// Throws on every call, the way a quota or a transport fault does. Used to prove
/// that reading an impact never reaches for a model.
private final class FailingSuggestionService: SuggestionService, @unchecked Sendable {
    private(set) var callCount = 0
    let capabilities = SuggestionCapabilities.offline

    func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        callCount += 1
        throw DocumentError.forbiddenOperation("no intelligence available")
    }
}
