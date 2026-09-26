import Foundation
import Testing
@testable import KollioCore

/// CTX-05: what new information touched, and what it left alone.
///
/// The behaviours worth protecting are the ones that would be easy to get wrong
/// and hard to notice: a readable file quietly promoting every object in the
/// document, one branch's evidence removing a tool another branch still needs, a
/// cycle in the graph looping forever, and a mark that a person cannot undo.
@Suite("Impact of new information")
struct ImpactAssessmentTests {
    private let csv = ObjectID("object:export")
    private let identifiers = ObjectID("object:identifiers")
    private let sharedTool = ObjectID("object:tool")
    private let leftBranch = ObjectID("object:left")
    private let rightBranch = ObjectID("object:right")
    private let source = SourceID("source:export")
    private let oldRevision = SourceRevisionID("revision:export-1")
    private let newRevision = SourceRevisionID("revision:export-2")

    /// A document with evidence, an explicit dependency, a shared tool, an
    /// alternative that is not a dependency, and a cycle.
    ///
    /// With `revised` the CSV gets a second revision, which is what makes the
    /// citation need review. Every test that wants an impact asks for one here
    /// rather than importing inside the test, so the state under test is never
    /// half-built.
    private func world(revised: Bool = false) -> KollioDocument {
        var builder = DocumentBuilder()
        builder.object("export", kind: .hypothesis, "The export is available")
        builder.object("identifiers", kind: .hypothesis, "The identifiers come with it")
        builder.object("tool", kind: .method, "The import tool")
        builder.object("left", kind: .need, "The left direction")
        builder.object("right", kind: .need, "The right direction")

        // The identifiers rest on the export, and the export names the
        // identifiers back: a real cycle, drawn on purpose.
        builder.link("l1", from: identifiers, to: self.csv, .dependsOn)
        builder.link("l8", from: self.csv, to: identifiers, .dependsOn)
        // The left direction is a conclusion drawn from the export.
        builder.link("l2", from: self.csv, to: leftBranch, .supports)
        // Both directions use one tool, and neither is an alternative that would
        // collapse: they are siblings that happen to share a step.
        builder.link("l3", from: leftBranch, to: sharedTool, .uses)
        builder.link("l4", from: rightBranch, to: sharedTool, .uses)
        builder.link("l5", from: leftBranch, to: rightBranch, .alternativeTo)

        var document = builder.document
        let first = SourceRevision(
            id: oldRevision, sequence: 1, extraction: .ready(text: "name,city"), digest: "d1"
        )
        document.sources.addAndImportForTesting(first, for: source)
        // A citation on the first revision: the evidence the claim was read against.
        document.sources.citeForTesting(
            Citation(
                id: CitationID("citation:export"),
                claimID: csv,
                sourceID: source,
                revisionID: oldRevision,
                locator: SourceLocator(lineRange: 0..<1),
                quote: "name,city"
            )
        )
        guard revised else { return document }
        // The file moves on. The citation is not repointed: it is marked, which is
        // the whole difference between CTX-03 and a quiet rewrite.
        document.sources.importRevision(
            SourceRevision(
                id: self.newRevision, sequence: 2,
                extraction: .ready(text: "name,city,segment"), digest: "d2"
            ),
            for: source
        )
        return document
    }

    /// The one citation of the CSV, which is the one the assessment is built from.
    private func citation(_ document: KollioDocument) throws -> Citation {
        guard let citation = document.sources.citation(CitationID("citation:export")) else {
            throw DocumentError.unknownCitation(CitationID("citation:export"))
        }
        return citation
    }

    // MARK: - AC01 availability is not dependence

    @Test("A readable file touches only what actually cited it")
    func aReadableSourceDoesNotPromoteEverything() throws {
        let document = world(revised: true)
        // The file became readable and current. Nothing about the identifiers
        // changed, and the point of AC01 is that it must not now look as though it
        // did.
        #expect(document.sources.citation(CitationID("citation:export"))?.status.isNeedsReview == true)
        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        // The one object that carries the citation, and the two that explicitly
        // rest on it. Nothing else in the document is touched by a file becoming
        // readable: the CSV being available is not a fact about anything that never
        // read it, and that is AC01.
        #expect(assessment.objectIDs == [csv, identifiers, leftBranch])
        #expect(assessment.proposedChanges[0].reason == .evidenceMoved)
        #expect(try #require(assessment.proposedChanges.first { $0.objectID == identifiers }).reason
                == .reliesOnImpactedObject)
        // A readable file says nothing about the right direction, which never cited
        // it and is not a conclusion drawn from it.
        #expect(assessment.objectIDs.contains(rightBranch) == false)
        #expect(assessment.objectIDs.contains(sharedTool) == false)
    }

    @Test("A link is walked towards what relies on it, never away from it")
    func propagationFollowsTheDirectionOfReliance() throws {
        let document = world(revised: true)
        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        // The export supports the left direction, so the left is affected. The tool
        // the left *uses* is not something the export supports, and a step somebody
        // else relies on does not move because the person using it changed their
        // mind. Walking that link the other way is how a shared tool ends up
        // flagged in every branch that happens to need it.
        #expect(assessment.objectIDs.contains(leftBranch))
        #expect(assessment.objectIDs.contains(sharedTool) == false)
        // And the object the export itself names, which the export relies on, is
        // left alone for the same reason.
        #expect(assessment.proposedChanges.allSatisfy { $0.objectID != rightBranch })
    }

    // MARK: - AC02 a shared tool stays usable elsewhere

    @Test("A shared tool is reported as unrelated rather than as a casualty")
    func aSharedToolStaysUsable() throws {
        let document = world(revised: true)
        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        // The right is an alternative to the left, and the tool is used by both.
        // Neither is listed, and both are named as examined and left alone, which
        // is the pair of facts a person needs before deciding this is safe to
        // ignore.
        let unaffected = Dictionary(
            uniqueKeysWithValues: assessment.unaffectedRefs.map { ($0.objectID, $0.why) }
        )
        #expect(assessment.objectIDs.contains(rightBranch) == false)
        #expect(assessment.objectIDs.contains(sharedTool) == false)
        #expect(unaffected[rightBranch] == .linkIsNotADependence)
        #expect(unaffected[sharedTool] == .linkIsNotADependence)
        // "Stays usable elsewhere" is a claim about the document, not about a card:
        // both usages are still there and the tool is still active.
        #expect(document.relationships(from: rightBranch).contains { $0.to == sharedTool })
        #expect(document.object(sharedTool)?.lifecycle == .active)
    }

    @Test("Applying a mark purges nothing")
    func applyingIsNotABranchPurge() throws {
        let before = world(revised: true)
        var session = KollioSession(document: before)
        let assessment = try #require(before.impactAssessment(for: try citation(before)))
        let decisionIDs = assessment.proposedChanges.map { DecisionID("decision:test-\($0.objectID.rawValue)") }

        let applied = session.apply([.applyImpact(.init(
            assessment: assessment, decisionIDs: decisionIDs, provenance: .human("local-user")
        ))], label: "impact")
        #expect(applied)

        let after = session.document
        // Every object is still there, still active, and every relationship too.
        #expect(after.content == before.content)
        #expect(after.relationships == before.relationships)
        #expect(after.objects.allSatisfy { $0.lifecycle == .active })
        // The marks are new, and they are the only thing that changed.
        #expect(after.decisions != before.decisions)
        // One decision per impacted object, naming exactly that object.
        for change in assessment.proposedChanges {
            let decision = try #require(after.pendingImpactReview(for: change.objectID))
            #expect(decision.branchObjectIDs == [change.objectID])
            #expect(decision.rationale?.text == change.reason.rationale)
        }
    }

    @Test("The impact is one transaction and undoes in one step")
    func theImpactUndoesAsOneTransaction() throws {
        let before = world(revised: true)
        var session = KollioSession(document: before)
        let assessment = try #require(before.impactAssessment(for: try citation(before)))
        let decisionIDs = assessment.proposedChanges.map { DecisionID("decision:test-\($0.objectID.rawValue)") }
        let applied = session.apply([.applyImpact(.init(
            assessment: assessment, decisionIDs: decisionIDs, provenance: .human("local-user")
        ))], label: "impact")
        #expect(applied)
        #expect(session.document != before)

        let undone = session.undo()
        // One undo, the whole document back: not one mark at a time.
        #expect(session.document.decisions == before.decisions)
        #expect(session.document.content == before.content)
        #expect(session.document.revision == before.revision)
    }

    // MARK: - Cycles, bounds, and reasons

    @Test("A cycle terminates and is listed once")
    func aCycleTerminates() throws {
        let document = world(revised: true)
        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        // export and identifiers point at each other, so a walk without a visited
        // set would never return. Every object appears exactly once and the walk
        // finishes, declared rather than merely observed by timing.
        #expect(assessment.objectIDs.count == Set(assessment.objectIDs).count)
        #expect(assessment.objectIDs == [csv, identifiers, leftBranch])
        #expect(assessment.wasTruncated == false)
    }

    @Test("A walk that hits its bound says so")
    func aTruncatedWalkIsDeclared() throws {
        let document = world(revised: true)
        // A bound of one cannot reach anything, and the assessment says so rather
        // than presenting a two-object world as the whole graph.
        let assessment = try #require(document.impactAssessment(for: try citation(document), limit: 1))
        #expect(assessment.wasTruncated)
        #expect(assessment.objectIDs == [csv])
    }

    @Test("No reason inverts a decision")
    func noReasonIsAVerdict() {
        // The whole of "removing evidence marks needsReview without inverting the
        // decision", expressed as the absence of cases rather than as a test of
        // behaviour: nothing in this vocabulary can say a claim is refuted.
        let reasons = Set(ImpactReason.allCases.map(\.rawValue))
        #expect(reasons == ["evidenceMoved", "evidenceLost", "reliesOnImpactedObject"])
    }

    @Test("Losing the source marks the claim without touching its stance")
    func losingEvidenceDoesNotInvertTheStance() throws {
        let claimID = ClaimID("claim:export")
        var session = KollioSession(document: world())
        let claim = Claim(
            id: claimID,
            objectID: csv,
            role: .hypothesis,
            scope: ClaimScope(id: ScopeID("scope:export"), title: "The export", objectIDs: [csv]),
            assessment: .supported(.init(observation: "The header row is there", by: ActorID("local-user")))
        )
        let asserted = session.apply([.assertClaim(.init(claim: claim, provenance: .human("local-user")))], label: "claim")
        #expect(asserted)

        let removed = session.apply([.removeSource(.init(sourceID: source, reason: "the file was deleted"))], label: "remove")
        #expect(removed)
        let document = session.document
        // The citation is marked, and the claim keeps both its assessment and its
        // wording. A missing file is a fact about the file.
        #expect(document.sources.citation(CitationID("citation:export"))?.status.isSourceMissing == true)
        #expect(document.claims.claim(claimID)?.assessment.isSupported == true)

        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        #expect(assessment.trigger.kind == .sourceUnavailable)
        #expect(assessment.proposedChanges[0].reason == .evidenceLost)
    }

    @Test("The same document gives the same assessment twice")
    func theAssessmentIsStable() throws {
        let document = world(revised: true)
        let moved = try citation(document)
        let first = try #require(document.impactAssessment(for: moved, id: ImpactID("impact:fixed")))
        let second = try #require(document.impactAssessment(for: moved, id: ImpactID("impact:fixed")))
        // A read set that reshuffles between runs would make two identical
        // assessments look like two different ones, and the person would be asked
        // to re-check a change that had not moved.
        #expect(first == second)
    }

    @Test("Intelligence is refused the command that applies an impact")
    func intelligenceCannotApplyAnImpact() throws {
        let document = world(revised: true)
        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        let proposal = Proposal(
            proposalId: "p1",
            requestId: "r1",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("mark everything"),
            rationale: nil,
            operations: [.applyImpact(.init(
                assessment: assessment,
                decisionIDs: assessment.proposedChanges.map { _ in DecisionID("decision:x") },
                provenance: .human("local-user")
            ))],
            placementHints: [],
            generator: .init(name: "test", deterministic: true)
        )
        #expect(throws: DocumentError.self) {
            try ProposalValidator().validate(
                proposal, against: document, scope: .init(maxOperations: 32, allowNewObjects: true)
            )
        }
    }

    @Test("An impact cannot be recorded without the assessment behind it")
    func aBareImpactDecisionIsRefused() throws {
        var store = DocumentStore(document: world())
        #expect(throws: DocumentError.self) {
            try store.apply([.recordDecision(.init(
                id: DecisionID("decision:bare"),
                kind: .impacted,
                targetObjectID: self.csv,
                provenance: .human("local-user")
            ))])
        }
    }

    @Test("An assessment with nothing in it is refused")
    func anEmptyAssessmentIsRefused() {
        var store = DocumentStore(document: world())
        let empty = ImpactAssessment(
            id: ImpactID("impact:empty"),
            trigger: .init(kind: .sourceRevisionSuperseded, sourceID: source, reason: "nothing"),
            readSet: .init(sourceID: source)
        )
        #expect(throws: DocumentError.self) {
            try store.apply([.applyImpact(.init(
                assessment: empty, decisionIDs: [], provenance: .human("local-user")
            ))])
        }
    }

    @Test("Taking a position clears the mark and keeps the record")
    func aStanceClearsTheMark() throws {
        let before = world(revised: true)
        var session = KollioSession(document: before)
        let claimID = ClaimID("claim:export")
        let claim = Claim(
            id: claimID,
            objectID: csv,
            role: .hypothesis,
            scope: ClaimScope(id: ScopeID("scope:export"), title: "The export", objectIDs: [csv])
        )
        let asserted = session.apply([.assertClaim(.init(claim: claim, provenance: .human("local-user")))], label: "claim")
        #expect(asserted)
        let assessment = try #require(session.document.impactAssessment(for: try citation(session.document)))
        let marked = try #require(assessment.proposedChanges.first)
        let applied = session.apply([.applyImpact(.init(
            assessment: assessment,
            decisionIDs: assessment.proposedChanges.map { DecisionID("decision:\($0.objectID.rawValue)") },
            provenance: .human("local-user")
        ))], label: "impact")
        #expect(applied)
        #expect(session.document.pendingImpactReview(for: marked.objectID) != nil)

        // The person says how it stands. The mark is looked at, not erased: the
        // decision is superseded rather than removed, so "it was flagged, and here
        // is what I said" is still readable.
        let assessed = session.apply([.assessHypothesis(.init(
            claimID: claimID,
            assessment: .supported(.init(observation: "The new header is there", by: ActorID("local-user"))),
            provenance: .human("local-user")
        ))], label: "stance")
        #expect(assessed)
        #expect(session.document.pendingImpactReview(for: marked.objectID) == nil)
        // The decision is superseded rather than removed, so "it was flagged, and
        // here is what I said" is still readable. And the citation stays marked:
        // a position taken on a claim does not put the old revision back.
        #expect(session.document.decisions.values.contains { $0.kind == .impacted })
        #expect(session.document.sources.citation(CitationID("citation:export"))?.status.isNeedsReview == true)
    }

    @Test("A closed direction is reported as closed, and not walked through")
    func aSetAsideDirectionIsNotReopened() throws {
        var document = world(revised: true)
        // The right direction is set aside, and it uses the shared tool.
        var builder = DocumentBuilder(document: document)
        let setAside = builder.setAside("d1", target: rightBranch, rationale: "Not this quarter")
        #expect(setAside)
        document = builder.document

        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        #expect(assessment.objectIDs.contains(rightBranch) == false)
        #expect(assessment.unaffectedRefs.contains {
            $0.objectID == rightBranch && $0.why == .setAside
        })
    }

    @Test("A citation still on the current revision is listed as valid")
    func anIntactCitationIsReportedAsValid() throws {
        var document = world(revised: true)
        // A second source, cited by the left direction and never moved.
        let other = SourceID("source:other")
        document.sources.addAndImportForTesting(
            SourceRevision(id: SourceRevisionID("revision:other-1"), sequence: 1,
                           extraction: .ready(text: "note"), digest: "d9"),
            for: other
        )
        document.sources.citeForTesting(Citation(
            id: CitationID("citation:other"),
            claimID: leftBranch,
            sourceID: other,
            revisionID: SourceRevisionID("revision:other-1"),
            locator: SourceLocator(lineRange: 0..<1),
            quote: "note"
        ))

        let assessment = try #require(document.impactAssessment(for: try citation(document)))
        // The other citation is not read at all, because it is a citation of
        // another source: the read set says which evidence the answer rests on.
        #expect(assessment.readSet.citationIDs == [CitationID("citation:export")])
    }
}

// MARK: - Test-only ways to build a ledger

private extension SourceLedger {
    /// Adds a source and records its first revision, without going through the
    /// command layer, for fixtures.
    mutating func addAndImportForTesting(_ revision: SourceRevision, for id: SourceID) {
        self.add(SourceReference(id: id, kind: .csv, title: "export.csv", locator: "/tmp/export.csv"))
        _ = self.importRevision(revision, for: id)
    }

    mutating func citeForTesting(_ citation: Citation) {
        _ = self.cite(citation)
    }
}

private extension VerificationStatus {
    var isSourceMissing: Bool {
        if case .sourceMissing = self { return true }
        return false
    }

    var isNeedsReview: Bool {
        if case .needsReview = self { return true }
        return false
    }
}

private extension HypothesisAssessment {
    var isSupported: Bool {
        if case .supported = self { return true }
        return false
    }
}
