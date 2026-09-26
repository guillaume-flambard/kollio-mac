import Foundation
import KollioCore

/// The language a case is asked in, and the language the answer is checked
/// against. A model that answers a French request in English is not producing a
/// usable proposal, whatever else it got right.
public enum EvaluationLanguage: String, Codable, Hashable, Sendable, CaseIterable {
    case french = "fr"
    case english = "en"
}

/// What a case demands of the pipeline, stated before anything is generated.
///
/// An expectation is a contract, not a transcript. It contains the synthetic
/// authored text a case starts from and the bounds the answer must respect. It
/// never contains a sentence the model is expected to write: a stochastic
/// sentence is not a contract, and asserting one would make this suite a
/// lottery rather than a measurement.
public struct EvaluationExpectation: Codable, Hashable, Sendable {
    public var scenario: String
    public var language: EvaluationLanguage
    /// The authored context the person starts from. Synthetic in every case.
    public var seedText: String
    /// The instruction sent with the request, when the case has one.
    public var instruction: String?
    public var allowedStatuses: [ProposalStatus]
    /// The bound the case *asks* for, in the instruction the person would give.
    ///
    /// This is a request, not an enforced limit, so it is reported rather than
    /// gated. Whether the adapter can honour a per-request cap is a product
    /// question, and the case that asks for two ideas exists to keep the question
    /// visible.
    public var maxIdeas: Int
    /// The bounds the system actually enforces today: the adapter's own idea cap
    /// and the validator's operation limit. These are what the gate checks,
    /// because a gate must only assert what the code guarantees.
    ///
    /// A test asserts these still mirror `AppleCandidateConverter.maximumIdeas`
    /// and `ProposalValidator.Limits`, so the two cannot drift apart quietly.
    public var enforcedMaxIdeas: Int
    public var enforcedMaxOperations: Int
    public var allowedKinds: [ContentObject.Kind]
    /// Objects the answer must not reach for. A direction that was set aside is
    /// useful to intelligence because of the reason it was set aside for, and
    /// this is where a case states that reaching for it again is a failure.
    public var forbiddenTargetIDs: [String]
    public var expectsCancellation: Bool
    /// Set when the case deliberately starts from a set-aside direction. The
    /// fixture has to create that object and record the rejection, and the
    /// resulting identifier becomes a forbidden target.
    public var setAsideObjectSeed: String?
    public var setAsideObjectText: String?
    public var seedSetAsideRationale: String?
    public var maxOperations: Int

    // The authored text is deliberately not part of the encoded form.
    //
    // `includeTranscripts: false` on Apple's result does not redact anything: the
    // framework serialises the sample's *expected* value into the report, and the
    // first real run proved the report contained the authored text of all 18
    // cases. Encoding the expectation without its text is what makes the claim
    // true rather than intended. The text reaches the runner through a separate
    // index that is not `Codable`, so there is no path from it into a report.
    //
    // Decoding sets both to the empty string, and nothing decodes an expectation
    // in this project: the dataset is built in code.
    public enum CodingKeys: String, CodingKey {
        case scenario, language, allowedStatuses, maxIdeas
        case enforcedMaxIdeas, enforcedMaxOperations
        case allowedKinds, forbiddenTargetIDs, expectsCancellation
        case setAsideObjectSeed
        case maxOperations
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scenario, forKey: .scenario)
        try container.encode(language, forKey: .language)
        try container.encode(allowedStatuses, forKey: .allowedStatuses)
        try container.encode(maxIdeas, forKey: .maxIdeas)
        try container.encode(enforcedMaxIdeas, forKey: .enforcedMaxIdeas)
        try container.encode(enforcedMaxOperations, forKey: .enforcedMaxOperations)
        try container.encode(allowedKinds, forKey: .allowedKinds)
        try container.encode(forbiddenTargetIDs, forKey: .forbiddenTargetIDs)
        try container.encode(expectsCancellation, forKey: .expectsCancellation)
        try container.encodeIfPresent(setAsideObjectSeed, forKey: .setAsideObjectSeed)
        try container.encode(maxOperations, forKey: .maxOperations)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scenario = try container.decode(String.self, forKey: .scenario)
        language = try container.decode(EvaluationLanguage.self, forKey: .language)
        allowedStatuses = try container.decode([ProposalStatus].self, forKey: .allowedStatuses)
        maxIdeas = try container.decode(Int.self, forKey: .maxIdeas)
        enforcedMaxIdeas = try container.decode(Int.self, forKey: .enforcedMaxIdeas)
        enforcedMaxOperations = try container.decode(Int.self, forKey: .enforcedMaxOperations)
        allowedKinds = try container.decode([ContentObject.Kind].self, forKey: .allowedKinds)
        forbiddenTargetIDs = try container.decode([String].self, forKey: .forbiddenTargetIDs)
        expectsCancellation = try container.decode(Bool.self, forKey: .expectsCancellation)
        setAsideObjectSeed = try container.decodeIfPresent(String.self, forKey: .setAsideObjectSeed)
        maxOperations = try container.decode(Int.self, forKey: .maxOperations)
        // No authored text is encoded, so none of it can be recovered. A case
        // that needed it back would have to be given it explicitly.
        seedText = ""
        instruction = nil
        setAsideObjectText = nil
        seedSetAsideRationale = nil
    }

    public init(
        scenario: String,
        language: EvaluationLanguage,
        seedText: String,
        instruction: String? = nil,
        allowedStatuses: [ProposalStatus],
        maxIdeas: Int,
        enforcedMaxIdeas: Int,
        enforcedMaxOperations: Int,
        allowedKinds: [ContentObject.Kind],
        forbiddenTargetIDs: [String] = [],
        expectsCancellation: Bool = false,
        setAsideObjectSeed: String? = nil,
        setAsideObjectText: String? = nil,
        seedSetAsideRationale: String? = nil,
        maxOperations: Int = 8
    ) {
        self.scenario = scenario
        self.language = language
        self.seedText = seedText
        self.instruction = instruction
        self.allowedStatuses = allowedStatuses
        self.maxIdeas = maxIdeas
        self.enforcedMaxIdeas = enforcedMaxIdeas
        self.enforcedMaxOperations = enforcedMaxOperations
        self.allowedKinds = allowedKinds
        self.forbiddenTargetIDs = forbiddenTargetIDs
        self.expectsCancellation = expectsCancellation
        self.setAsideObjectSeed = setAsideObjectSeed
        self.setAsideObjectText = setAsideObjectText
        self.seedSetAsideRationale = seedSetAsideRationale
        self.maxOperations = maxOperations
    }
}

/// What the pipeline actually did, as counts and verdicts.
///
/// There is deliberately no field for generated prose. The observation records
/// the shape of the answer and the numbers that can be checked, never the text,
/// so a report can be committed without carrying a single word of model output
/// or source content into version control.
public struct PipelineObservation: Codable, Hashable, Sendable {
    public var status: ProposalStatus?
    /// The name of the error type when inference failed. Never the message: an
    /// error message can quote the prompt.
    public var failureKind: String?
    public var validatorAccepted: Bool?
    /// The name of the refusal reason, never the message.
    public var validatorFailureKind: String?
    public var ideaCount: Int
    public var operationCount: Int
    /// The names of the operations the answer asked for, used to prove no
    /// forbidden command was minted.
    public var operationNames: [String]
    public var createdKinds: [ContentObject.Kind]
    public var referencedObjectIDs: [String]
    public var unknownReferencedObjectIDs: [String]
    public var rationaleLength: Int
    public var questionCount: Int
    public var detectedLanguage: EvaluationLanguage?
    public var durationSeconds: Double
    public var firstProgressSeconds: Double?
    public var progressUpdateCount: Int
    public var wasCancelled: Bool
    /// True when generation was stopped before a proposal existed. A cancelled
    /// run that still produced a proposal has broken the rule that a partial
    /// result is never a proposal.
    public var proposalWasPrevented: Bool
    /// The document's semantic revision after the run. Intelligence must not
    /// move it; if it does, the answer was not a proposal but an edit.
    public var documentRevisionAfter: Int
    public var documentRevisionBefore: Int

    public init(
        status: ProposalStatus? = nil,
        failureKind: String? = nil,
        validatorAccepted: Bool? = nil,
        validatorFailureKind: String? = nil,
        ideaCount: Int = 0,
        operationCount: Int = 0,
        operationNames: [String] = [],
        createdKinds: [ContentObject.Kind] = [],
        referencedObjectIDs: [String] = [],
        unknownReferencedObjectIDs: [String] = [],
        rationaleLength: Int = 0,
        questionCount: Int = 0,
        detectedLanguage: EvaluationLanguage? = nil,
        durationSeconds: Double = 0,
        firstProgressSeconds: Double? = nil,
        progressUpdateCount: Int = 0,
        wasCancelled: Bool = false,
        proposalWasPrevented: Bool = false,
        documentRevisionAfter: Int = 0,
        documentRevisionBefore: Int = 0
    ) {
        self.status = status
        self.failureKind = failureKind
        self.validatorAccepted = validatorAccepted
        self.validatorFailureKind = validatorFailureKind
        self.ideaCount = ideaCount
        self.operationCount = operationCount
        self.operationNames = operationNames
        self.createdKinds = createdKinds
        self.referencedObjectIDs = referencedObjectIDs
        self.unknownReferencedObjectIDs = unknownReferencedObjectIDs
        self.rationaleLength = rationaleLength
        self.questionCount = questionCount
        self.detectedLanguage = detectedLanguage
        self.durationSeconds = durationSeconds
        self.firstProgressSeconds = firstProgressSeconds
        self.progressUpdateCount = progressUpdateCount
        self.wasCancelled = wasCancelled
        self.proposalWasPrevented = proposalWasPrevented
        self.documentRevisionAfter = documentRevisionAfter
        self.documentRevisionBefore = documentRevisionBefore
    }
}

/// The shared value type between a case and what inference produced.
///
/// Apple's harness requires the sample's expected value and the subject's value
/// to be the same type, so one record carries both: the contract, and the
/// observation once the model has answered. In the dataset the observation is
/// absent; in a result it is present.
public struct EvaluationOutcome: Codable, Hashable, Sendable {
    public var caseID: String
    public var expectation: EvaluationExpectation
    public var observation: PipelineObservation?

    public init(caseID: String, expectation: EvaluationExpectation, observation: PipelineObservation? = nil) {
        self.caseID = caseID
        self.expectation = expectation
        self.observation = observation
    }
}

/// What appears in a report in place of the case.
///
/// The framework prints the sample's description into the result table, so this
/// type is the privacy boundary of the whole suite: it reports that a case
/// exists, how long its authored text was, and nothing about what it said.
public struct RedactedCaseDescription: Codable, Hashable, Sendable, CustomStringConvertible {
    public var caseID: String
    public var scenario: String
    public var language: EvaluationLanguage
    public var authoredCharacters: Int
    public var hasInstruction: Bool

    public init(caseID: String, scenario: String, language: EvaluationLanguage, authoredCharacters: Int, hasInstruction: Bool) {
        self.caseID = caseID
        self.scenario = scenario
        self.language = language
        self.authoredCharacters = authoredCharacters
        self.hasInstruction = hasInstruction
    }

    public init(expectation: EvaluationExpectation, caseID: String) {
        self.init(
            caseID: caseID,
            scenario: expectation.scenario,
            language: expectation.language,
            authoredCharacters: expectation.seedText.count + (expectation.instruction?.count ?? 0),
            hasInstruction: expectation.instruction != nil
        )
    }

    public var description: String {
        "\(caseID) [\(scenario)/\(language.rawValue)] authored=\(authoredCharacters)ch withheld"
    }
}
