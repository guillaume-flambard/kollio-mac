import Foundation

/// Offline, deterministic intelligence.
///
/// This is a *demo engine*, not a language model: it reacts to the real current
/// state of the document (what a direction is already attached to, whether it was
/// set aside, how far the branch goes), so rejecting, reopening or editing an
/// object genuinely changes the next answer. It is not a recorded screenshot
/// sequence. The prototype is fully usable with no network at all.
public struct LocalDemoSuggestionService: SuggestionService {
    public struct Context: Sendable {
        /// Authored content for the demo scenarios. Kept here, outside the domain
        /// engine, so KollioCore never learns about Sarah.
        public var authored: [String: Expansion]
        public var language: String

        public init(language: String = "fr", authored: [String: Expansion] = [:]) {
            self.language = language
            self.authored = authored
        }
    }

    /// Content template used to grow a branch from a given object.
    public struct Expansion: Codable, Hashable, Sendable {
        public var summary: LocalizedText
        public var rationale: LocalizedText
        public var steps: [Step]

        public struct Step: Codable, Hashable, Sendable {
            public var kind: ContentObject.Kind
            public var text: LocalizedText
            public var relation: Relationship.Kind
            public var offsetX: Double
            public var offsetY: Double

            public init(kind: ContentObject.Kind, text: LocalizedText, relation: Relationship.Kind, offsetX: Double = 0, offsetY: Double = 170) {
                self.kind = kind
                self.text = text
                self.relation = relation
                self.offsetX = offsetX
                self.offsetY = offsetY
            }
        }

        public init(summary: LocalizedText, rationale: LocalizedText, steps: [Step]) {
            self.summary = summary
            self.rationale = rationale
            self.steps = steps
        }
    }

    private let context: Context

    public init(context: Context = Context()) {
        self.context = context
    }

    public var capabilities: SuggestionCapabilities {
        SuggestionCapabilities(intents: [.explore, .add, .setAside, .reopen, .clarify], deterministic: true, requiresNetwork: false)
    }

    public func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        let validator = ProposalValidator()
        let contentLanguage = request.contentLocale

        switch request.intent {
        case .reopen:
            return reopenResponse(request: request, document: document)
        case .add, .clarify:
            guard let instruction = request.instruction?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !instruction.isEmpty else {
                return .needsInput([LocalizedText("Que faut-il ajouter à cette direction ?", variants: [
                    "en": "What should be added to this direction?"
                ])])
            }
            return annotationResponse(request: request, document: document, instruction: instruction)
        case .explore:
            break
        case .setAside:
            return .noChange()
        }

        guard let targetID = request.targetIds.first else {
            return .needsInput([LocalizedText("Sélectionnez une direction à explorer.", variants: [
                "en": "Select a direction to explore."
            ])])
        }
        guard let target = document.object(targetID) else {
            throw DocumentError.unknownObject(targetID)
        }
        if target.isSetAside {
            // "A rejected branch is not reopened by the model." The person decided;
            // proposing it again would be the engine arguing with a decision rather
            // than working with the document.
            return .noChange()
        }

        let expansion = expansion(for: target, document: document, language: contentLanguage)

        // What has already been said, in any of the three senses that matter.
        let existingTexts = Set(document.content.values.map(\.text.text))

        // AI-03 AC02: the directions already rejected, and the reason each was
        // rejected for. Without this the engine repeats a dead end and the rejection
        // looks like it never happened. The reason is read as well as the text,
        // because "no budget" and "tried in March" close different doors and only one
        // of them is a door.
        let rejected = RejectedDirections(document: document, readSet: request.context)

        let freshSteps = expansion.steps.filter { step in
            guard !existingTexts.contains(step.text.text) else { return false }
            return !rejected.blocks(step.text.text)
        }
        guard !freshSteps.isEmpty else {
            // "A repetitive loop yields noChange or a question, never infinite
            // duplication." Everything this expansion could offer is either already
            // in the document or something the person turned down, so the honest
            // answer is that there is nothing new.
            return .noChange()
        }

        let actor = ActorID("local-demo")
        let provenance = Provenance(actor: actor, kind: .localEngine, requestId: request.requestId)

        var operations: [Command] = []
        var hints: [Proposal.PlacementHint] = []
        var rootID: ObjectID?

        for (index, step) in freshSteps.enumerated() {
            let objectID = ObjectID("\(request.requestId):\(index)")
            rootID = rootID ?? objectID
            operations.append(.createObject(CreateObject(
                id: objectID,
                kind: step.kind,
                text: step.text,
                provenance: provenance
            )))
            hints.append(.init(objectID: objectID, relativeTo: targetID, offsetX: step.offsetX, offsetY: step.offsetY))
            operations.append(.addRelationship(AddRelationship(
                id: RelationshipID("\(request.requestId):rel:\(index)"),
                from: targetID,
                to: objectID,
                kind: step.relation,
                provenance: provenance
            )))
        }

        let proposal = Proposal(
            proposalId: "proposal:\(request.requestId)",
            requestId: request.requestId,
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: expansion.summary,
            rationale: expansion.rationale,
            operations: operations,
            placementHints: hints,
            generator: .init(name: "LocalDemoSuggestionService", deterministic: true)
        )
        try validator.validate(proposal, against: document, scope: request.scope)
        return ProposalResponse(status: .proposed, proposal: proposal)
    }

    // MARK: - What has already been turned down

    /// The directions the person has already rejected, as this request was told
    /// about them.
    ///
    /// AI-03 AC02. It is built from the request's own read set rather than from the
    /// whole document on purpose: an engine may only honour the rejections it was
    /// actually given. Reading the whole document instead would make it look like it
    /// was consulting the reasoning when it was only pattern-matching the whole
    /// state, and a client that forgot to transmit a rejection would be quietly
    /// forgiven.
    private struct RejectedDirections {
        /// Text of every rejected direction this request was told about, folded to
        /// lowercase because a difference in case is not a difference in direction.
        private let texts: Set<String>
        /// The reasons, kept so the summary can say *why* rather than only *what*.
        private let reasons: [String]

        init(document: KollioDocument, readSet: [ProposalRequest.ContextItem]) {
            var texts: Set<String> = []
            var reasons: [String] = []
            for item in readSet {
                guard item.lifecycle == .setAside else { continue }
                // A reopened direction is not a rejection any more, and treating it
                // as one would make the engine refuse a door the person opened.
                guard let object = document.object(item.objectID), object.isSetAside else { continue }
                texts.insert(Self.fold(item.text))
                if let reason = item.reason, reason.isEmpty == false {
                    reasons.append(reason)
                }
            }
            self.texts = texts
            self.reasons = reasons
        }

        /// Whether this candidate is a direction the person already refused.
        func blocks(_ text: String) -> Bool {
            texts.contains(Self.fold(text))
        }

        var isEmpty: Bool { texts.isEmpty }

        private static func fold(_ text: String) -> String {
            text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    // MARK: - Strategies

    private func expansion(for target: ContentObject, document: KollioDocument, language: String) -> Expansion {
        if let authored = context.authored[DemoContent.textSignature(for: target)] {
            return authored
        }
        switch target.kind {
        case .context, .need:
            return genericBifurcation(for: target, language: language)
        default:
            return genericContinuation(for: target, language: language)
        }
    }

    private func genericBifurcation(for target: ContentObject, language: String) -> Expansion {
        let short = DemoContent.shortLabel(target.text.resolve(languageCode: language))
        return Expansion(
            summary: LocalizedText("Deux directions possibles", variants: ["en": "Two possible directions"]),
            rationale: LocalizedText(
                "« \(short) » peut être attaqué de deux façons. Les deux restent visibles jusqu’à ce qu’on en choisisse une.",
                variants: ["en": "“\(short)” can be approached two ways. Both stay visible until one is chosen."]
            ),
            steps: [
                .init(kind: .hypothesis, text: LocalizedText("Direction A : \(short)", variants: [
                    "en": "Direction A: \(short)"
                ]), relation: .alternativeTo, offsetX: -200, offsetY: 190),
                .init(kind: .hypothesis, text: LocalizedText("Direction B : autre angle", variants: [
                    "en": "Direction B: another angle"
                ]), relation: .alternativeTo, offsetX: 200, offsetY: 190)
            ]
        )
    }

    private func genericContinuation(for target: ContentObject, language: String) -> Expansion {
        let short = DemoContent.shortLabel(target.text.resolve(languageCode: language))
        return Expansion(
            summary: LocalizedText("Ce qu’il faut savoir avant de choisir", variants: [
                "en": "What to know before choosing"
            ]),
            rationale: LocalizedText(
                "Avancer sur « \(short) » demande d’abord un critère et une vérification.",
                variants: ["en": "Moving on “\(short)” needs a criterion and a verification first."]
            ),
            steps: [
                .init(kind: .constraint, text: LocalizedText("Quel critère tranche ce choix ?", variants: [
                    "en": "Which criterion decides this?"
                ]), relation: .constrains, offsetX: 0, offsetY: 170),
                .init(kind: .evidence, text: LocalizedText("Source à vérifier", variants: [
                    "en": "Source to verify"
                ]), relation: .supports, offsetX: 0, offsetY: 320)
            ]
        )
    }

    private func annotationResponse(request: ProposalRequest, document: KollioDocument, instruction: String) -> ProposalResponse {
        guard let targetID = request.targetIds.first, document.object(targetID) != nil else {
            return .needsInput([LocalizedText("Sélectionnez un élément.", variants: ["en": "Select an item."])])
        }
        let provenance = Provenance(actor: ActorID("local-demo"), kind: .localEngine, requestId: request.requestId)
        let questionID = ObjectID("\(request.requestId):q")
        let proposal = Proposal(
            proposalId: "proposal:\(request.requestId)",
            requestId: request.requestId,
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("Une question à trancher", variants: ["en": "A question to settle"]),
            rationale: LocalizedText(instruction, variants: [:]),
            operations: [
                .createObject(CreateObject(
                    id: questionID,
                    kind: .question,
                    text: LocalizedText(instruction, variants: [:]),
                    provenance: provenance
                )),
                .addRelationship(AddRelationship(
                    id: RelationshipID("\(request.requestId):rel"),
                    from: targetID,
                    to: questionID,
                    kind: .addresses,
                    provenance: provenance
                ))
            ],
            placementHints: [.init(objectID: questionID, relativeTo: targetID)],
            generator: .init(name: "LocalDemoSuggestionService", deterministic: true)
        )
        return ProposalResponse(status: .proposed, proposal: proposal)
    }

    private func reopenResponse(request: ProposalRequest, document: KollioDocument) -> ProposalResponse {
        guard let targetID = request.targetIds.first, let target = document.object(targetID) else {
            return .noChange()
        }
        guard target.isSetAside else { return .noChange() }
        let provenance = Provenance(actor: ActorID("local-demo"), kind: .localEngine, requestId: request.requestId)
        let decisionID = DecisionID("decision:reopen:\(request.requestId)")
        let proposal = Proposal(
            proposalId: "proposal:\(request.requestId)",
            requestId: request.requestId,
            documentId: document.documentId,
            baseSemanticRevision: document.semanticRevision,
            summary: LocalizedText("Rouvrir cette direction", variants: ["en": "Reopen this direction"]),
            rationale: LocalizedText(
                "Cette direction avait été écartée. La rouvrir restaure ses objets et ses positions.",
                variants: ["en": "This direction was set aside. Reopening restores its objects and positions."]
            ),
            operations: [
                .recordDecision(RecordDecision(
                    id: decisionID,
                    kind: .reopened,
                    targetObjectID: targetID,
                    rationale: target.text,
                    provenance: provenance
                ))
            ],
            generator: .init(name: "LocalDemoSuggestionService", deterministic: true)
        )
        return ProposalResponse(status: .proposed, proposal: proposal)
    }
}

/// Helpers shared by the demo engine.
public enum DemoContent {
    /// A stable signature for what an object *says*, independent of its id, its
    /// kind and its topology. Authored demo content is matched on this.
    public static func textSignature(for object: ContentObject) -> String {
        let normalized = object.text.text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "en"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let variant = object.text.variants["en"]?
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "en"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(normalized)|\(variant ?? "")"
    }

    /// A stable signature for an object, independent of its id: authored demo
    /// content is matched on what the object *says* and on what it already
    /// carries.
    public static func signature(for object: ContentObject, document: KollioDocument) -> String {
        let normalized = object.text.text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "en"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let variant = object.text.variants["en"]?
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "en"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let relationships = document.relationships(from: object.id)
            .map(\.kind.rawValue)
            .sorted()
            .joined(separator: ",")
        return "\(normalized)|\(variant ?? "")|\(object.kind.rawValue)|\(relationships)"
    }

    public static func shortLabel(_ value: String, limit: Int = 34) -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count > limit else { return value }
        return String(value.prefix(limit - 1)) + "…"
    }
}
