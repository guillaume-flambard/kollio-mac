import Foundation

/// Fills a synthesis from the document, without a model.
///
/// ## Why the first composer is deterministic
///
/// Because a composer that needed a model would be the least trustworthy part of
/// the product, and there is a version that needs none. Everything it writes is a
/// fact it can point at: an object that is active, a rejection that carries a
/// reason, a hypothesis that nobody has cited. It never concludes anything, and it
/// never writes a line it cannot attach a reference to, which is also why every
/// line it produces would pass `validateLine` rather than being caught by it.
///
/// A model-backed composer belongs here later, and it inherits the same
/// constraint: `SummaryLine.isUnsupportedAssertion` refuses an engine line that
/// rests on nothing, so a composer that wanted to assert freely could not be
/// written without changing that rule first. The rule is the budget.
///
/// ## What it refuses to do
///
/// - **Never fill a section it has nothing for.** A section with no evidence is
///   left absent, which the confirming command then refuses, and that refusal is
///   the correct outcome rather than a bug to route around.
/// - **Never turn a rejection into a direction.** A set-aside object is reported
///   as set aside. Offering it again is the failure this whole document is built
///   to prevent.
/// - **Never claim something is verified.** `nextVerifications` names what has not
///   been checked, and says so as a fact about the document rather than a
///   prediction about the world.
public enum SummaryComposer {
    /// The default read set: everything active, plus everything that was decided.
    ///
    /// Bounded on purpose. A synthesis over a document with ten thousand objects is
    /// a different act, and one this composer refuses rather than attempts badly.
    public static let objectLimit = 40

    public struct Outcome: Sendable {
        public var summary: SummaryArtifact
        /// Set when the selection was too wide to read honestly.
        public var proposedNarrowerScope: SummaryArtifact.NarrowerScope?
    }

    public static func compose(
        id: SummaryID,
        title: String,
        objective: SummaryArtifact.SummaryLine,
        in document: KollioDocument,
        languageCode: String,
        now: Date = Date(timeIntervalSince1970: 0)
    ) -> Outcome {
        let active = document.content.values
            .filter { $0.lifecycle == .active }
            .sorted { $0.id.rawValue < $1.id.rawValue }
        let setAside = document.content.values
            .filter { $0.lifecycle == .setAside }
            .sorted { $0.id.rawValue < $1.id.rawValue }
        let decisions = document.decisions.values.sorted { $0.id.rawValue < $1.id.rawValue }

        // The read set covers both, because a rejection is part of what was read.
        // The current state does not: listing a set-aside object as current is the
        // single most misleading thing this composer could do, and the first
        // version did exactly that because it reused the read set for both.
        let everything = active + setAside
        var narrower: SummaryArtifact.NarrowerScope?
        var readObjects = everything
        if everything.count > objectLimit {
            // Refuse the width and say what it would have preferred, rather than
            // summarising forty objects into a sentence that fits.
            readObjects = Array(everything.prefix(objectLimit))
            narrower = SummaryArtifact.NarrowerScope(
                objectIDs: readObjects.map(\.id),
                reason: "The selection covered \(everything.count) objects. A synthesis that wide would assert things about branches nobody read."
            )
        }

        // Citations are indexed per source, not per object, and this composer
        // reads objects. So it records no citation: the honest entry is an empty
        // list rather than a lookup against a source that was never named. The
        // first version did that lookup, got nothing, and looked as though it had
        // checked.
        let readSet = SummaryArtifact.SummaryReadSet(
            objectIDs: readObjects.map(\.id).sorted { $0.rawValue < $1.rawValue },
            sourceRevisionIDs: [],
            citationIDs: [],
            decisionIDs: decisions.map(\.id).sorted { $0.rawValue < $1.rawValue }
        )

        var currentState: [SummaryArtifact.SummarySection] = []
        if !active.isEmpty {
            currentState = [SummaryArtifact.SummarySection(.currentState, lines: active
                .filter { readObjects.contains($0) }
                .map { objectLine($0, in: document, languageCode: languageCode) })]
        }

        // A rejection is a reason somebody wrote down, so it belongs in the
        // reasons. A rejection with no reason is an uncertainty, because the
        // document records that something stopped and not why.
        var reasons: [SummaryArtifact.SummarySection] = []
        var uncertainties: [SummaryArtifact.SummarySection] = []
        var reasonLines: [SummaryArtifact.SummaryLine] = []
        var uncertaintyLines: [SummaryArtifact.SummaryLine] = []

        for decision in decisions {
            guard let target = document.content[decision.targetObjectID] else { continue }
            let reference = SummaryReference(kind: .decision, id: decision.id.rawValue)
            switch decision.kind {
            case .setAside:
                if let rationale = decision.rationale?.text.trimmingCharacters(in: .whitespacesAndNewlines),
                   rationale.isEmpty == false {
                    reasonLines.append(SummaryArtifact.SummaryLine(
                        id: SummaryLineID("reason-\(decision.id.rawValue)"),
                        text: LocalizedText(
                            "\(excerpt(target.text.text, languageCode: languageCode)) was set aside: \(rationale)",
                            variants: [:]
                        ),
                        provenance: Provenance(actor: ActorID("actor:composer"), kind: .localEngine),
                        references: [reference, SummaryReference(kind: .object, id: target.id.rawValue)]
                    ))
                } else {
                    uncertaintyLines.append(SummaryArtifact.SummaryLine(
                        id: SummaryLineID("uncertain-\(decision.id.rawValue)"),
                        text: LocalizedText(
                            "\(excerpt(target.text.text, languageCode: languageCode)) was set aside with no reason recorded.",
                            variants: [:]
                        ),
                        provenance: Provenance(actor: ActorID("actor:composer"), kind: .localEngine),
                        references: [reference, SummaryReference(kind: .object, id: target.id.rawValue)]
                    ))
                }
            default:
                break
            }
        }
        if !reasonLines.isEmpty {
            reasons = [SummaryArtifact.SummarySection(.reasons, lines: reasonLines)]
        }
        if !uncertaintyLines.isEmpty {
            uncertainties = [SummaryArtifact.SummarySection(.uncertainties, lines: uncertaintyLines)]
        }

        // Citations hang off claims, not off objects, so "nothing is cited for
        // this" is not a question this document can answer and the composer does
        // not pretend otherwise. What it can answer is whether any claim rests on
        // an object, and a hypothesis no claim touches is unexamined, which is a
        // fact about the document rather than a prediction about the world.
        var verifications: [SummaryArtifact.SummarySection] = []
        let unexamined = active
            .filter { $0.kind == .hypothesis }
            .filter { object in claimsAbout(object, in: document) == false }
        if !unexamined.isEmpty {
            verifications = [SummaryArtifact.SummarySection(.nextVerifications, lines: unexamined.map {
                SummaryArtifact.SummaryLine(
                    id: SummaryLineID("verify-\($0.id.rawValue)"),
                    text: LocalizedText(
                        "\(excerpt($0.text.text, languageCode: languageCode)) is a hypothesis and no claim rests on it yet.",
                        variants: [:]
                    ),
                    provenance: Provenance(actor: ActorID("actor:composer"), kind: .localEngine),
                    references: [SummaryReference(kind: .object, id: $0.id.rawValue)]
                )
            })]
        }

        var summary = SummaryArtifact(
            id: id,
            title: title,
            objective: objective,
            currentState: currentState,
            reasons: reasons,
            uncertainties: uncertainties,
            nextVerifications: verifications,
            readSet: readSet,
            baseSemanticRevision: document.semanticRevision,
            isDraft: true,
            proposedNarrowerScope: narrower,
            createdAt: now
        )
        // A section with nothing is declared, not left missing: the difference
        // between "nobody has written here" and "there was nothing to write" is
        // exactly what the composer can tell and a person cannot guess.
        summary = declaringEmptySections(summary)
        return Outcome(summary: summary, proposedNarrowerScope: narrower)
    }

    /// Marks every section that has nothing as a deliberate absence.
    ///
    /// It does *not* do this for sections it has no evidence about, which is the
    /// distinction the whole feature rests on. A composer that declared its own
    /// uncertainty would be claiming to know that nothing is uncertain, and this
    /// is a deterministic reader: it knows what the document says, and it has no
    /// way of knowing what the document failed to say.
    private static func declaringEmptySections(_ summary: SummaryArtifact) -> SummaryArtifact {
        var result = summary
        for section in SummaryArtifact.Section.allCases where summary.sections(section).isEmpty {
            // Uncertainties are left absent on purpose: the composer cannot know
            // that nothing is uncertain, only that it found none.
            guard section != .uncertainties else { continue }
            result = result.settingSections(
                [SummaryArtifact.SummarySection(section, lines: [], isNothingRecorded: true)],
                for: section
            )
        }
        return result
    }

    /// Whether any claim rests on an object.
    ///
    /// Written out rather than borrowed from a claim's scope, because
    /// `ClaimScope.contains` answers a different question and using it here would
    /// have read as though the ledger had been searched.
    private static func claimsAbout(_ object: ContentObject, in document: KollioDocument) -> Bool {
        document.claims.allClaims().contains { $0.objectID == object.id }
    }

    private static func objectLine(
        _ object: ContentObject,
        in document: KollioDocument,
        languageCode: String
    ) -> SummaryArtifact.SummaryLine {
        SummaryArtifact.SummaryLine(
            id: SummaryLineID("object-\(object.id.rawValue)"),
            text: LocalizedText(excerpt(object.text.text, languageCode: languageCode), variants: [:]),
            provenance: Provenance(actor: ActorID("actor:composer"), kind: .localEngine),
            references: [SummaryReference(kind: .object, id: object.id.rawValue)]
        )
    }

    /// A line a person can read in a compact block, without inventing an ellipsis
    /// that was never in the text.
    private static func excerpt(_ text: String, languageCode: String, limit: Int = 120) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
