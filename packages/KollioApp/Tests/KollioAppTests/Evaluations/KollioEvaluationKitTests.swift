import Foundation
import Testing
import KollioCore
@testable import KollioEvaluationKit
@testable import KollioApp

/// The structural gate, exercised without a model, a network or the Evaluations
/// framework.
///
/// This suite is the reason the gate can be trusted. If the gate were computed
/// inside Apple's harness, a change in the model could quietly change what
/// counts as safe. Here the model is replaced by numbers, and the numbers are
/// chosen to fail.
@Suite("Structural gate")
struct StructuralAssessorTests {
    /// `maxIdeas` is the bound the case asks for; `enforcedMaxIdeas` is the bound
    /// the code guarantees. The two are separate on purpose, and a case where the
    /// first is smaller than the second is the interesting one.
    private func expectation(
        allowed: [ProposalStatus] = [.proposed, .noChange],
        maxIdeas: Int = 6,
        enforcedMaxIdeas: Int = 3,
        enforcedMaxOperations: Int = 8,
        forbiddenTargets: [String] = []
    ) -> EvaluationExpectation {
        EvaluationExpectation(
            scenario: "T",
            language: .french,
            seedText: "texte",
            allowedStatuses: allowed,
            maxIdeas: maxIdeas,
            enforcedMaxIdeas: enforcedMaxIdeas,
            enforcedMaxOperations: enforcedMaxOperations,
            allowedKinds: [.method, .question, .contribution],
            forbiddenTargetIDs: forbiddenTargets
        )
    }

    private func cleanObservation(
        status: ProposalStatus = .proposed,
        expectation: EvaluationExpectation
    ) -> PipelineObservation {
        PipelineObservation(
            status: status,
            validatorAccepted: true,
            ideaCount: 2,
            operationCount: 2,
            operationNames: ["createObject", "createObject"],
            createdKinds: [.method],
            rationaleLength: 90,
            questionCount: status == .needsInput ? 1 : 0,
            detectedLanguage: expectation.language,
            durationSeconds: 2.4,
            firstProgressSeconds: 0.6,
            progressUpdateCount: 3,
            documentRevisionAfter: 7,
            documentRevisionBefore: 7
        )
    }

    @Test("A clean answer passes every gate")
    func cleanPasses() {
        let expectation = expectation()
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: cleanObservation(expectation: expectation)
        )
        let gates = verdicts.filter(\.isGate)
        #expect(!gates.isEmpty)
        #expect(gates.allSatisfy { $0.passed }, "failed: \(gates.filter { !$0.passed }.map(\.name))")
    }

    @Test("A missing observation fails rather than scoring zero")
    func missingObservationFails() {
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation(), observation: nil
        )
        #expect(verdicts.count == 1)
        #expect(verdicts[0].isGate)
        #expect(!verdicts[0].passed)
    }

    @Test("An inference failure is structural, not a low score")
    func inferenceFailureIsGate() {
        var observation = cleanObservation(expectation: expectation())
        observation.failureKind = "AppleModelError"
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation(), observation: observation
        )
        #expect(gate(verdicts, "inferenceCompleted")?.passed == false)
    }

    @Test("A refused proposal fails the gate even when it looked complete")
    func refusedProposalFails() {
        var observation = cleanObservation(expectation: expectation())
        observation.validatorAccepted = false
        observation.validatorFailureKind = "DocumentError"
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation(), observation: observation
        )
        #expect(gate(verdicts, "validatorAccepts")?.passed == false)
    }

    @Test("A status outside the case's permission is reported, never gated")
    func statusOutsidePermissionIsNotAGate() {
        // A real run of this suite is what decided this: the adversarial case
        // answered `noChange` once and `proposed` the next time, fabricating
        // nothing either time. A gate that flips with the weather is a gate
        // somebody will eventually switch off.
        let expectation = expectation(allowed: [.noChange, .needsInput])
        let observation = cleanObservation(status: .proposed, expectation: expectation)
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        let status = verdicts.first { $0.name == "statusWithinExpectation" }
        #expect(status?.passed == false)
        #expect(status?.isGate == false)
        // The safety property the case cares about is untouched and still holds.
        #expect(gate(verdicts, "noFabricatedReference")?.passed == true)
    }

    @Test("Too many ideas fails the enforced bound")
    func tooManyIdeasFails() {
        let expectation = expectation(maxIdeas: 6)
        var observation = cleanObservation(expectation: expectation)
        observation.ideaCount = 5
        observation.operationCount = 5
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        #expect(gate(verdicts, "ideaCountWithinEnforcedLimit")?.passed == false)
    }

    @Test("A bound the case asked for is reported, not gated")
    func declaredConstraintIsNotAGate() {
        // A case may ask for fewer ideas than the system enforces. Nothing
        // enforces that today, so gating on it would be a permanently red gate.
        let expectation = expectation(maxIdeas: 2)
        var observation = cleanObservation(expectation: expectation)
        observation.ideaCount = 3
        observation.operationCount = 3
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        let declared = verdicts.first { $0.name == "declaredConstraintRespected" }
        #expect(declared?.isGate == false)
        #expect(declared?.passed == false)
        // The enforced bound still held, so the gate is clean.
        #expect(verdicts.filter { $0.isGate }.allSatisfy { $0.passed })
    }

    @Test("The language heuristic can never fail the gate")
    func languageHeuristicIsNotAGate() {
        let expectation = expectation()
        var observation = cleanObservation(expectation: expectation)
        observation.detectedLanguage = .english
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        let locale = verdicts.first { $0.name == "localeHeuristicAgrees" }
        #expect(locale?.isGate == false)
        #expect(locale?.passed == false)
        #expect(verdicts.filter { $0.isGate }.allSatisfy { $0.passed })
    }

    @Test("The enforced bounds still mirror the adapter and the validator")
    func enforcedBoundsMirrorTheCode() {
        #expect(EvaluationDataset.enforcedMaxIdeas == AppleCandidateConverter.maximumIdeas)
        let limits = ProposalValidator.Limits()
        #expect(EvaluationDataset.enforcedMaxOperations == limits.maxOperations)
        #expect(EvaluationDataset.enforcedMaxIdeas <= limits.maxNewObjects)
    }

    @Test("An unrenderable kind fails")
    func unrenderableKindFails() {
        let expectation = expectation()
        var observation = cleanObservation(expectation: expectation)
        observation.createdKinds = [.method, .evidence]
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        #expect(gate(verdicts, "kindsRenderable")?.passed == false)
    }

    @Test("A reference to an object that does not exist fails")
    func fabricatedReferenceFails() {
        let expectation = expectation()
        var observation = cleanObservation(expectation: expectation)
        observation.referencedObjectIDs = ["obj_ghost"]
        observation.unknownReferencedObjectIDs = ["obj_ghost"]
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        #expect(gate(verdicts, "noFabricatedReference")?.passed == false)
    }

    @Test("Reaching back to a set-aside direction fails")
    func repeatedRejectedDirectionFails() {
        let expectation = expectation(forbiddenTargets: ["obj_rejected"])
        var observation = cleanObservation(expectation: expectation)
        observation.referencedObjectIDs = ["obj_rejected"]
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        #expect(gate(verdicts, "doesNotRepeatRejectedDirection")?.passed == false)
    }

    @Test("A proposal that tries to accept or delete is refused")
    func forbiddenCommandFails() {
        let expectation = expectation()
        for command in ["applyProposal", "rejectProposal", "removeObject", "removeNodeInstance"] {
            var observation = cleanObservation(expectation: expectation)
            observation.operationNames = ["createObject", command]
            let verdicts = StructuralAssessor.assess(
                caseID: "t", expectation: expectation, observation: observation
            )
            #expect(gate(verdicts, "noForbiddenCommand")?.passed == false, "\(command) was allowed")
        }
    }

    @Test("Intelligence that moved the document fails")
    func mutatedDocumentFails() {
        let expectation = expectation()
        var observation = cleanObservation(expectation: expectation)
        observation.documentRevisionAfter = 8
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        #expect(gate(verdicts, "documentUnchanged")?.passed == false)
    }

    @Test("A cancelled run is judged only on cancellation")
    func cancellationCase() {
        var expectation = expectation()
        expectation.expectsCancellation = true
        let stopped = PipelineObservation(
            wasCancelled: true,
            proposalWasPrevented: true,
            documentRevisionAfter: 3,
            documentRevisionBefore: 3
        )
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: stopped
        )
        #expect(verdicts.allSatisfy { $0.passed })
        #expect(gate(verdicts, "cancellationRespected") != nil)

        // A cancelled run that still produced a proposal has broken the rule that
        // a partial result is never a proposal.
        let leaked = PipelineObservation(
            status: .proposed,
            wasCancelled: true,
            proposalWasPrevented: false,
            documentRevisionAfter: 3,
            documentRevisionBefore: 3
        )
        let badVerdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: leaked
        )
        #expect(gate(badVerdicts, "cancelledRunIsNotAProposal")?.passed == false)
    }

    @Test("A missing rationale is a warning, not a gate")
    func rationaleIsNotAGate() {
        let expectation = expectation()
        var observation = cleanObservation(expectation: expectation)
        observation.rationaleLength = 0
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        let rationale = verdicts.first { $0.name == "rationalePresent" }
        #expect(rationale?.isGate == false)
        #expect(rationale?.passed == false)
        #expect(verdicts.filter { $0.isGate }.allSatisfy { $0.passed })
    }

    @Test("The three judged dimensions are recorded as unmeasured")
    func judgedDimensionsAreExplicit() {
        let expectation = expectation()
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: cleanObservation(expectation: expectation)
        )
        let judged = verdicts.filter { $0.name.hasPrefix("judged.") }.map(\.name).sorted()
        #expect(judged == ["judged.languageQuality", "judged.relevance", "judged.usefulnessOfNextStep"])
        #expect(verdicts.filter { $0.name.hasPrefix("judged.") }.allSatisfy { !$0.isGate })
    }

    @Test("Performance findings are never a gate")
    func performanceIsNotAGate() {
        let verdicts = StructuralAssessor.performance(
            caseID: "t",
            observation: PipelineObservation(durationSeconds: 30, firstProgressSeconds: 20, progressUpdateCount: 0)
        )
        #expect(!verdicts.isEmpty)
        #expect(verdicts.allSatisfy { !$0.isGate })
    }

    @Test("The dataset is versioned, synthetic and covers both languages")
    func datasetShape() {
        let cases = EvaluationDataset.cases()
        #expect(!cases.isEmpty)
        #expect(EvaluationDataset.version >= 1)
        #expect(Set(cases.map(\.expectation.language)) == [.french, .english])
        #expect(Set(cases.map(\.caseID)).count == cases.count, "case identifiers must be unique")
        // Every case must state a bound, or the gate has nothing to check.
        #expect(cases.allSatisfy { $0.expectation.maxIdeas > 0 })
        #expect(cases.allSatisfy { !$0.expectation.allowedStatuses.isEmpty })
        // At least one case must exist where nothing should change, or a model
        // that always proposes would score perfectly.
        #expect(cases.contains { $0.expectation.allowedStatuses == [.noChange, .needsInput] })
        // At least one case must bound the number of ideas.
        #expect(cases.contains { $0.expectation.maxIdeas <= 2 })
        // At least one case must forbid reaching back to a rejected direction.
        #expect(cases.contains { $0.expectation.setAsideObjectSeed != nil })
        // At least one case must test cancellation.
        #expect(cases.contains { $0.expectation.expectsCancellation })
    }

    @Test("A request for more than the enforced bound gates on the enforced one")
    func enforcedBoundWins() {
        let expectation = expectation(maxIdeas: 6, enforcedMaxIdeas: 3)
        var observation = cleanObservation(expectation: expectation)
        observation.ideaCount = 4
        let verdicts = StructuralAssessor.assess(
            caseID: "t", expectation: expectation, observation: observation
        )
        #expect(gate(verdicts, "ideaCountWithinEnforcedLimit")?.passed == false)
    }

    @Test("An encoded outcome carries no authored text")
    func encodedOutcomeOmitsText() throws {
        // This is a guard, not a nicety. The first real run wrote the authored
        // text of all 18 cases into Apple's report, because the framework
        // serialises the sample's expected value and `includeTranscripts: false`
        // does not redact it. The dataset is synthetic, so nothing private
        // leaked, but a suite that claims redaction must actually redact.
        for outcome in EvaluationDataset.cases() {
            let data = try JSONEncoder().encode(outcome)
            let json = String(decoding: data, as: UTF8.self)
            #expect(!json.contains(outcome.expectation.seedText), "\(outcome.caseID) leaked its context")
            for authored in [
                outcome.expectation.instruction,
                outcome.expectation.setAsideObjectText,
                outcome.expectation.seedSetAsideRationale,
            ].compactMap({ $0 }) {
                #expect(!json.contains(authored), "\(outcome.caseID) leaked authored text")
            }
        }
    }

    @Test("The authored text reaches the runner through a separate index")
    func textIndexCarriesTheText() {
        let cases = EvaluationDataset.cases()
        let index = EvaluationDataset.textIndex(for: cases)
        #expect(index.count == cases.count)
        for outcome in cases {
            #expect(index[outcome.caseID]?.seedText == outcome.expectation.seedText)
            #expect(index[outcome.caseID]?.instruction == outcome.expectation.instruction)
            #expect(index[outcome.caseID]?.setAsideObjectText == outcome.expectation.setAsideObjectText)
            #expect(index[outcome.caseID]?.setAsideRationale == outcome.expectation.seedSetAsideRationale)
        }
    }

    @Test("A case description never carries the text it withheld")
    func redactionHolds() {
        for outcome in EvaluationDataset.cases() {
            let description = RedactedCaseDescription(
                expectation: outcome.expectation,
                caseID: outcome.caseID
            )
            #expect(!description.description.contains(outcome.expectation.seedText))
            if let instruction = outcome.expectation.instruction {
                #expect(!description.description.contains(instruction))
            }
        }
    }

    private func gate(_ verdicts: [StructuralVerdict], _ name: String) -> StructuralVerdict? {
        verdicts.first { $0.name == name }
    }
}

/// The script and the suite have to agree on one string, and they are two files
/// in two languages that never see each other at build time.
///
/// This guard exists because the disagreement happened twice while writing the
/// measurement: the script promised an exit code it did not produce, and then
/// grepped for a sentence the suite never emitted, in the wrong case. Both
/// failures are silent — the script still runs, and it still reports something
/// plausible. A test that reads both files is cheaper than discovering it in a
/// pipeline.
@Suite("Evaluation script agreement")
struct EvaluationScriptTests {
    private static func repositoryRoot() -> URL? {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Evaluations
            .deletingLastPathComponent()   // KollioAppTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // KollioApp
            .deletingLastPathComponent()   // packages
            .deletingLastPathComponent()   // the repository root
    }

    @Test("The script's availability marker is a string the suite emits")
    func availabilityMarkerMatches() throws {
        let root = try #require(Self.repositoryRoot(), "could not locate the repository root")
        let script = try String(contentsOf: root.appendingPathComponent("scripts/evaluate-apple-model.sh"), encoding: .utf8)
        let suite = try String(
            contentsOf: root.appendingPathComponent(
                "packages/KollioApp/Tests/KollioAppTests/Evaluations/AppleModelEvaluation.swift"
            ),
            encoding: .utf8
        )

        // Read the marker out of the line that uses it rather than out of a
        // pattern over the whole file. A pattern here was itself wrong on the
        // first attempt, which is the argument for the simpler version.
        let searchLine = try #require(
            script.split(separator: "\n").first { $0.contains("grep -qF") },
            "the script no longer searches the log for a fixed string"
        )
        let quoted = searchLine.components(separatedBy: "\"")
        // `if grep -qF "…" "$log"; then` splits into
        // [`if grep -qF `, `…`, ` `, `$log`, …]: the marker is the second piece.
        let marker = try #require(
            quoted.count > 1 ? quoted[1] : nil,
            "the script's fixed-string search has no quoted marker in it"
        )
        #expect(
            suite.contains(marker),
            "the script looks for \(marker) and the suite does not emit it; the 'model unavailable' exit code would never fire"
        )
    }

    @Test("The script refuses a run that matched no tests")
    func noTestsIsAFailure() throws {
        let root = try #require(Self.repositoryRoot())
        let script = try String(contentsOf: root.appendingPathComponent("scripts/evaluate-apple-model.sh"), encoding: .utf8)
        // A Swift Testing filter that matches nothing exits zero. Without this
        // check the script would report a successful measurement of nothing.
        #expect(script.contains("No matching test cases were run"))
        #expect(script.contains("exit 2"))
        #expect(script.contains("exit 3"))
    }
}
