import Foundation
import Testing
import Evaluations
import FoundationModels
import KollioCore
@testable import KollioApp
import KollioEvaluationKit

/// Measures what the real on-device model actually does to Kollio's pipeline.
///
/// Not part of the deterministic suite. It is opt-in evidence about a real Mac,
/// it is never run by `verify.sh`, and it refuses to report success when the
/// model is unavailable. The structural gate itself lives in
/// `KollioEvaluationKit`, which is tested without a model; this suite is the
/// half that cannot be.
@Suite(
    "Apple model evaluation",
    .enabled(if: ProcessInfo.processInfo.environment["KOLLIO_EVALUATE"] == "1")
)
struct AppleModelEvaluationTests {
    /// The availability annotation is on the test, not on the suite: the suite
    /// macro cannot expand inside an availability-gated type. The suite is
    /// already opt-in through KOLLIO_EVALUATE, so the annotation is a second
    /// gate rather than the first.
    @available(macOS 27.0, *)
    @Test("The dataset holds every safety property, measured on the real model")
    func evaluate() async throws {
        let probe = SystemModelProbe()
        let availability = probe.availability()
        try #require(
            availability.isUsable,
            """
            The on-device model is not usable here: \(availability).
            Nothing was measured. This suite does not skip into a pass; the \
            script treats this as a distinct exit code.
            """
        )

        let dataset = EvaluationDataset.cases()
        let samples = dataset.map { outcome in
            KollioSample(
                input: RedactedCaseDescription(expectation: outcome.expectation, caseID: outcome.caseID),
                expected: outcome
            )
        }
        let recorder = VerdictRecorder()
        let runner = PipelineRunner(
            recorder: recorder,
            texts: EvaluationDataset.textIndex(for: dataset)
        )
        let evaluation = KollioAppleEvaluation(
            dataset: ArrayLoader(samples: samples),
            runner: runner
        )

        let started = Date()
        let result = try await evaluation.run(info: [
            "datasetVersion": String(EvaluationDataset.version),
            "profile": EvaluationDataset.profileVersion,
            "contextSize": String(probe.contextSize() ?? -1),
        ])
        let elapsed = Date().timeIntervalSince(started)

        let outputDirectory = URL(fileURLWithPath:
            ProcessInfo.processInfo.environment["KOLLIO_EVAL_OUTPUT"] ?? "build/evaluations"
        )
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        // Transcripts are not written. A committed report must not carry a word
        // of model output.
        let appleReport = try result.saveJSON(
            to: outputDirectory,
            includeReportMetadata: true,
            includeTranscripts: false
        )

        let failures = await recorder.gateFailures
        let warnings = await recorder.warnings
        let measured = await recorder.measured

        let summary = EvaluationSummary(
            datasetVersion: EvaluationDataset.version,
            profile: EvaluationDataset.profileVersion,
            model: "system, on-device",
            caseCount: samples.count,
            structuralFailures: failures,
            behaviouralWarnings: warnings,
            measuredFindings: measured,
            wallClockSeconds: elapsed,
            unmeasuredDimensions: ["relevance", "usefulnessOfNextStep", "languageQuality"],
            cases: await recorder.observedOutcomes.map(EvaluationSummary.CaseRecord.init(outcome:))
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let summaryURL = outputDirectory.appendingPathComponent("kollio-evaluation-summary.json")
        try encoder.encode(summary).write(to: summaryURL)

        print("""
        EVALUATION dataset=v\(EvaluationDataset.version) profile=\(EvaluationDataset.profileVersion)
        EVALUATION cases=\(samples.count) findings=\(measured) wall=\(String(format: "%.1fs", elapsed)) serial=true
        EVALUATION structural=\(failures.isEmpty ? "pass" : "fail") warnings=\(warnings.count)
        EVALUATION unmeasured=relevance,usefulnessOfNextStep,languageQuality
        EVALUATION report=\(appleReport.lastPathComponent)
        EVALUATION summary=\(summaryURL.path)
        """)
        for failure in failures {
            print("EVALUATION FAIL \(failure)")
        }
        for warning in warnings {
            print("EVALUATION WARN \(warning)")
        }

        #expect(
            failures.isEmpty,
            """
            Structural gate failed on \(failures.count) finding(s). This is a safety \
            property of the pipeline, not a matter of taste.
            \(failures.joined(separator: "\n"))
            """
        )
    }
}

/// The small, stable, diffable half of a run.
///
/// Per case it records the shape of the answer and the numbers, never the words.
/// Two runs of the same dataset version are then comparable by eye and by `diff`,
/// which is the entire reason a machine-readable report exists.
struct EvaluationSummary: Codable {
    var datasetVersion: Int
    var profile: String
    var model: String
    var caseCount: Int
    var structuralFailures: [String]
    var behaviouralWarnings: [String]
    var measuredFindings: Int
    var wallClockSeconds: Double
    /// Named explicitly, because a dimension that is absent reads like a
    /// dimension that passed.
    var unmeasuredDimensions: [String]
    var cases: [CaseRecord]

    struct CaseRecord: Codable {
        var id: String
        var scenario: String
        var language: String
        var status: String?
        var failureKind: String?
        var ideaCount: Int
        var operationCount: Int
        var validatorAccepted: Bool?
        var durationSeconds: Double
        var firstProgressSeconds: Double?
        var progressUpdateCount: Int
    }
}

extension EvaluationSummary.CaseRecord {
    /// Built from the outcome, keeping only what can be compared and nothing that
    /// was written.
    init(outcome: EvaluationOutcome) {
        let observation = outcome.observation
        self.init(
            id: outcome.caseID,
            scenario: outcome.expectation.scenario,
            language: outcome.expectation.language.rawValue,
            status: observation?.status?.rawValue,
            failureKind: observation?.failureKind,
            ideaCount: observation?.ideaCount ?? 0,
            operationCount: observation?.operationCount ?? 0,
            validatorAccepted: observation?.validatorAccepted,
            durationSeconds: observation?.durationSeconds ?? 0,
            firstProgressSeconds: observation?.firstProgressSeconds,
            progressUpdateCount: observation?.progressUpdateCount ?? 0
        )
    }
}

/// Collects findings while Apple's harness runs.
///
/// Apple's `EvaluationResult` exposes its numbers through a `DataFrame`, the
/// right shape for a report and the wrong shape for a gate. Reading pass and
/// fail back out of a table would tie the gate to a display format, so the gate
/// is computed from this recorder and Apple's own JSON is written beside it as
/// the richer artefact.
actor VerdictRecorder {
    private(set) var gateFailures: [String] = []
    private(set) var warnings: [String] = []
    private(set) var measured = 0
    private(set) var outcomes: [EvaluationOutcome] = []

    func recordOutcome(_ outcome: EvaluationOutcome) {
        outcomes.append(outcome)
    }

    var observedOutcomes: [EvaluationOutcome] { outcomes }

    func record(_ verdicts: [StructuralVerdict]) {
        for verdict in verdicts {
            measured += 1
            if verdict.isGate && !verdict.passed {
                gateFailures.append(verdict.detail)
            } else if !verdict.isGate && !verdict.passed {
                warnings.append(verdict.detail)
            }
        }
    }
}

/// The sample Apple's harness iterates over.
///
/// `Input` is the redacted description rather than the case, because the harness
/// writes the input's `description` into the result table. That one choice is
/// what keeps authored and generated text out of a committed report.
/// Every type below is annotated for macOS 27 because Apple's `Evaluations`
/// types are. The suite that uses them is opt-in through `KOLLIO_EVALUATE`, so
/// the annotation is the second gate rather than the first.
@available(macOS 27.0, *)
struct KollioSample: SampleProtocol {
    typealias Input = RedactedCaseDescription
    typealias ExpectedValue = EvaluationOutcome

    var input: RedactedCaseDescription
    /// Optional because the protocol requires it: a case may exist with no
    /// expectation yet. Every case this suite builds has one, and the runner
    /// refuses to proceed without it rather than defaulting.
    var expected: EvaluationOutcome?

    func requireExpectation() throws -> EvaluationOutcome {
        guard let expected else {
            throw PipelineError.fixtureRejected("the sample carried no expectation")
        }
        return expected
    }
}

/// Builds a document from a case, runs the real model over it, and reduces the
/// answer to the counts the gate is computed from.
@available(macOS 27.0, *)
struct PipelineRunner {
    let recorder: VerdictRecorder
    /// The authored text, deliberately outside the sample. The expectation does
    /// not encode it, so a report cannot contain it.
    let texts: [String: EvaluationDataset.CaseText]

    func makeDocument(
        caseID: String,
        for expectation: EvaluationExpectation
    ) throws -> (document: KollioDocument, targets: [ObjectID], setAsideID: String?) {
        var builder = DocumentBuilder()
        let isEnglish = expectation.language == .english
        guard let text = texts[caseID] else {
            throw PipelineError.fixtureRejected("no authored text for this case")
        }
        guard let context = builder.object(
            "ctx",
            kind: .context,
            text.seedText,
            en: isEnglish ? text.seedText : nil,
            at: .zero
        ) else {
            throw PipelineError.fixtureRejected("the context object was refused")
        }
        var targets = [context]
        var setAsideID: String?

        if let seed = expectation.setAsideObjectSeed,
           let text = texts[caseID]?.setAsideObjectText,
           let rationale = texts[caseID]?.setAsideRationale,
           let rejected = builder.object(
               seed,
               kind: .method,
               text,
               en: isEnglish ? text : nil,
               at: Position(x: 320, y: 0)
           ) {
            guard builder.setAside(
                "reject-\(seed)",
                target: rejected,
                rationale: rationale,
                rationaleEN: isEnglish ? rationale : nil
            ) else {
                throw PipelineError.fixtureRejected("the rejection could not be recorded")
            }
            _ = builder.link(
                "link-\(seed)",
                from: context,
                to: rejected,
                .contradicts,
                label: isEnglish ? "abandoned" : "abandonnée"
            )
            targets.append(rejected)
            setAsideID = rejected.rawValue
        }

        return (builder.document, targets, setAsideID)
    }

    func run(sample: KollioSample) async -> EvaluationOutcome {
        let started = Date()
        do {
            let declared = try sample.requireExpectation()
            let built = try makeDocument(caseID: declared.caseID, for: declared.expectation)
            let revisionBefore = built.document.semanticRevision
            let request = try makeRequest(
                expectation: declared.expectation,
                document: built.document,
                targets: built.targets,
                requestCaseID: declared.caseID
            )
            let service = AppleLocalSuggestionService(probe: SystemModelProbe())

            var expectation = declared.expectation
            if let setAsideID = built.setAsideID {
                expectation.forbiddenTargetIDs = [setAsideID]
            }

            let observation = expectation.expectsCancellation
                ? await runCancelled(
                    service: service, request: request, document: built.document,
                    revisionBefore: revisionBefore, started: started)
                : await runToCompletion(
                    service: service, request: request, document: built.document,
                    revisionBefore: revisionBefore, started: started)

            await recorder.record(StructuralAssessor.assess(
                caseID: declared.caseID, expectation: expectation, observation: observation))
            await recorder.record(StructuralAssessor.performance(
                caseID: declared.caseID, observation: observation))
            let recorded = EvaluationOutcome(
                caseID: declared.caseID,
                expectation: expectation,
                observation: observation
            )
            await recorder.recordOutcome(recorded)
            return recorded
        } catch {
            // A fixture that will not build is a harness bug, and it must be
            // visible as a failure rather than as a model that did badly.
            let fallback = EvaluationExpectation(
                scenario: "unknown", language: .english, seedText: "",
                allowedStatuses: [], maxIdeas: 0, enforcedMaxIdeas: 0,
                enforcedMaxOperations: 0, allowedKinds: [])
            let declared = EvaluationOutcome(
                caseID: sample.input.caseID,
                expectation: (try? sample.requireExpectation())?.expectation ?? fallback
            )
            let observation = PipelineObservation(failureKind: String(describing: type(of: error)))
            await recorder.record(StructuralAssessor.assess(
                caseID: declared.caseID, expectation: declared.expectation, observation: observation))
            let recorded = EvaluationOutcome(
                caseID: declared.caseID, expectation: declared.expectation, observation: observation)
            await recorder.recordOutcome(recorded)
            return recorded
        }
    }

    private func makeRequest(
        expectation: EvaluationExpectation,
        document: KollioDocument,
        targets: [ObjectID],
        requestCaseID: String
    ) throws -> ProposalRequest {
        let scoped = try document.snapshot(targeting: targets)
        var request = ProposalRequest(
            requestId: "eval-\(expectation.scenario)-\(expectation.language.rawValue)",
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            intent: .explore,
            targetIds: targets,
            instruction: texts[requestCaseID]?.instruction,
            contentLocale: expectation.language.rawValue,
            snapshot: scoped
        )
        request.context = ContextBuilder().context(for: request, document: document)
        return request
    }

    private func runToCompletion(
        service: AppleLocalSuggestionService,
        request: ProposalRequest,
        document: KollioDocument,
        revisionBefore: Int,
        started: Date
    ) async -> PipelineObservation {
        let tracker = ProgressTracker()
        do {
            let response = try await service.stream(
                to: request, document: document, onProgress: { _ in tracker.record() })
            return observe(
                response: response, document: document, request: request,
                revisionBefore: revisionBefore, started: started, tracker: tracker)
        } catch {
            return PipelineObservation(
                failureKind: failureToken(for: error),
                durationSeconds: Date().timeIntervalSince(started),
                firstProgressSeconds: tracker.first,
                progressUpdateCount: tracker.count,
                documentRevisionAfter: document.semanticRevision,
                documentRevisionBefore: revisionBefore
            )
        }
    }

    private func runCancelled(
        service: AppleLocalSuggestionService,
        request: ProposalRequest,
        document: KollioDocument,
        revisionBefore: Int,
        started: Date
    ) async -> PipelineObservation {
        let tracker = ProgressTracker()
        let task = Task {
            try await service.stream(
                to: request, document: document, onProgress: { _ in tracker.record() })
        }
        // Cancel once generation is actually under way, so the case measures the
        // cancellation of a live stream rather than of an instant refusal. A
        // fixed sleep instead would make the case a reading of the machine's mood.
        try? await Task.sleep(for: .milliseconds(400))
        task.cancel()
        var response: ProposalResponse?
        var failure: String?
        do {
            response = try await task.value
        } catch {
            failure = failureToken(for: error)
        }
        let leaked = response?.proposal
        return PipelineObservation(
            status: response?.status,
            failureKind: failure,
            ideaCount: 0,
            operationCount: leaked?.operations.count ?? 0,
            durationSeconds: Date().timeIntervalSince(started),
            firstProgressSeconds: tracker.first,
            progressUpdateCount: tracker.count,
            wasCancelled: true,
            proposalWasPrevented: leaked == nil,
            documentRevisionAfter: document.semanticRevision,
            documentRevisionBefore: revisionBefore
        )
    }

    private func observe(
        response: ProposalResponse,
        document: KollioDocument,
        request: ProposalRequest,
        revisionBefore: Int,
        started: Date,
        tracker: ProgressTracker
    ) -> PipelineObservation {
        var accepted: Bool?
        var failure: String?
        var operationNames: [String] = []
        var createdKinds: [ContentObject.Kind] = []
        var referenced: [String] = []
        var rationaleLength = 0

        if let proposal = response.proposal {
            operationNames = proposal.operations.map { Self.operationName(of: $0) }
            for operation in proposal.operations {
                if case .createObject(let create) = operation {
                    createdKinds.append(create.kind)
                }
            }
            referenced = Self.referencedIdentifiers(in: proposal.operations)
            rationaleLength = proposal.rationale?.text.count ?? 0
            do {
                try ProposalValidator().validate(proposal, against: document, scope: request.scope)
                accepted = true
            } catch {
                accepted = false
                failure = failureToken(for: error)
            }
        }

        // A proposal may create an object and then relate it. Those ids exist in
        // the proposal, not yet in the document, and counting them as
        // fabrications was a bug in this harness, not a finding about the model.
        var known = Set(document.content.keys.map(\.rawValue))
        if let proposal = response.proposal {
            for operation in proposal.operations {
                if case .createObject(let create) = operation {
                    known.insert(create.id.rawValue)
                }
            }
        }
        return PipelineObservation(
            status: response.status,
            validatorAccepted: accepted,
            validatorFailureKind: failure,
            ideaCount: createdKinds.count,
            operationCount: response.proposal?.operations.count ?? 0,
            operationNames: operationNames,
            createdKinds: createdKinds,
            referencedObjectIDs: referenced,
            unknownReferencedObjectIDs: referenced.filter { !known.contains($0) },
            rationaleLength: rationaleLength,
            questionCount: response.questions.count,
            detectedLanguage: Self.detectLanguage(in: response),
            durationSeconds: Date().timeIntervalSince(started),
            firstProgressSeconds: tracker.first,
            progressUpdateCount: tracker.count,
            wasCancelled: false,
            proposalWasPrevented: false,
            documentRevisionAfter: document.semanticRevision,
            documentRevisionBefore: revisionBefore
        )
    }

    static func operationName(of command: Command) -> String {
        String(describing: command).split(separator: "(").first.map(String.init) ?? ""
    }

    static func referencedIdentifiers(in operations: [Command]) -> [String] {
        var found: Set<String> = []
        for operation in operations {
            if case .addRelationship(let add) = operation {
                found.insert(add.from.rawValue)
                found.insert(add.to.rawValue)
            }
        }
        return Array(found)
    }

    /// Detects the answer's language from its own words, with no model and no
    /// network. A French answer to an English request is a real failure and has
    /// to be caught by something deterministic.
    static func detectLanguage(in response: ProposalResponse) -> EvaluationLanguage? {
        var parts = [response.proposal?.rationale?.text ?? ""]
        parts.append(contentsOf: response.questions.map(\.text))
        if case .createObject(let create) = response.proposal?.operations.first {
            parts.append(create.text.text)
        }
        let joined = parts.joined(separator: " ")
        guard joined.count > 8 else { return nil }
        let french = [" le ", " la ", " les ", " des ", " une ", " pour ", " dans ", " avec ", " que ", " est "]
        let english = [" the ", " and ", " with ", " for ", " that ", " this ", " should ", " from "]
        let haystack = " " + joined.lowercased() + " "
        let frenchHits = french.filter { haystack.contains($0) }.count
        let englishHits = english.filter { haystack.contains($0) }.count
        if frenchHits == englishHits { return nil }
        return frenchHits > englishHits ? .french : .english
    }
}

enum PipelineError: Error {
    case fixtureRejected(String)
}

/// A stable token for a failure, with no message and no prompt in it.
///
/// The type name alone was not enough: `AppleModelError` covers an unavailable
/// model, a context too large, and a generation failure, and those three mean
/// very different things in a report. The associated message is never recorded,
/// because a generation failure can quote the prompt back.
func failureToken(for error: Error) -> String {
    switch error {
    case let error as AppleModelError:
        switch error {
        case .unavailable: return "AppleModelError.unavailable"
        case .contextTooLarge: return "AppleModelError.contextTooLarge"
        case .generationFailed: return "AppleModelError.generationFailed"
        }
    case is CancellationError:
        return "CancellationError"
    default:
        return String(describing: type(of: error))
    }
}

/// Counts progress updates without a lock on the hot path.
final class ProgressTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var updates = 0
    private var firstAt: Double?
    private let origin = Date()

    func record() {
        lock.withLock {
            updates += 1
            if firstAt == nil { firstAt = Date().timeIntervalSince(origin) }
        }
    }

    var count: Int { lock.withLock { updates } }
    var first: Double? { lock.withLock { firstAt } }
}

/// The evaluation itself.
@available(macOS 27.0, *)
struct KollioAppleEvaluation: Evaluation {
    typealias Sample = KollioSample
    typealias Subject = ModelSubject<EvaluationOutcome>
    typealias SampleLoader = ArrayLoader<KollioSample>

    let dataset: ArrayLoader<KollioSample>
    let runner: PipelineRunner

    func subject(from sample: KollioSample) async throws -> ModelSubject<EvaluationOutcome> {
        ModelSubject(value: await runner.run(sample: sample))
    }

    @EvaluatorsBuilder<KollioSample, ModelSubject<EvaluationOutcome>>
    var evaluators: [any EvaluatorProtocol<KollioSample, ModelSubject<EvaluationOutcome>>] {
        StructuralGate()
        UnmeasuredDimensions()
    }

    /// Required by the protocol, and deliberately empty.
    ///
    /// Aggregation is not where this run's numbers come from: the gate is the
    /// recorder, and the comparable figures are in the summary this suite
    /// writes. Filling this in would compute means the report does not use,
    /// which is a second set of numbers to keep in step with the first. Recorded
    /// as a known limitation rather than dressed up as a feature.
    func aggregateMetrics(using aggregator: inout MetricsAggregator) {}
}

/// The pure assessment, expressed in Apple's metrics.
@available(macOS 27.0, *)
struct StructuralGate: EvaluatorProtocol {
    func metrics(subject: ModelSubject<EvaluationOutcome>, input: KollioSample) async throws -> [Metric] {
        StructuralAssessor.assess(
            caseID: subject.value.caseID,
            expectation: subject.value.expectation,
            observation: subject.value.observation
        )
        .map { verdict in
            let metric = Metric(verdict.name)
            return verdict.passed
                ? metric.passing(rationale: verdict.isGate ? "structural" : "observed")
                : metric.failing(rationale: verdict.isGate ? "structural gate" : "behavioural observation")
        }
    }
}

/// Records explicitly that three dimensions are not being measured.
@available(macOS 27.0, *)
struct UnmeasuredDimensions: EvaluatorProtocol {
    func metrics(subject: ModelSubject<EvaluationOutcome>, input: KollioSample) async throws -> [Metric] {
        StructuralAssessor.assess(
            caseID: subject.value.caseID,
            expectation: subject.value.expectation,
            observation: subject.value.observation
        )
        .filter { $0.name.hasPrefix("judged.") }
        .map { Metric($0.name).ignore(rationale: "needs a model judge, not implemented") }
    }
}
