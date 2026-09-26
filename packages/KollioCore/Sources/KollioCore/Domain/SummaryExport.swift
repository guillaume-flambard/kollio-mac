import Foundation

/// The deliverable, as something a person can hand over.
///
/// ## Why an export is a value and not a view
///
/// It is a value, computed from the artifact and the document, with no file, no
/// panel and no model. That is what makes it testable, and it is also what makes
/// it honest: what the recipient sees is exactly what this function returns, and
/// the same synthesis in the same document always exports the same bytes.
///
/// ## What it must never do
///
/// - **Never fill a gap.** A section that says nothing was recorded is exported
///   as exactly that. An export that padded its sections would turn the refusal
///   the commands already make into a lie at the last step.
/// - **Never hide that it has moved.** AC03: the export names the revision used,
///   and when the document has moved since, the export says so in the first lines
///   rather than in a footnote nobody reads.
/// - **Never lose a correction.** A line a person edited is marked as corrected,
///   and the text the model first produced travels in an appendix. A deliverable
///   that silently presented an edited line as a model's own words would
///   misattribute it.
public enum SummaryExport {
    /// The header the reader sees first, and the only place the revision is named.
    public struct Document: Equatable, Sendable {
        public var text: String
        public var filename: String
        /// The revision the synthesis read.
        public var usedRevision: Int
        /// The revision the document is at now. Different from `usedRevision` when
        /// something has moved.
        public var currentRevision: Int
        public var isOutdated: Bool
    }

    /// Markdown, because a deliverable is read by people who are not using this
    /// app, and a format that only this app can read is not a handover.
    ///
    /// - Parameters:
    ///   - languageCode: which variant of each line to write. A synthesis written
    ///     in French and handed to someone who reads English is a deliverable that
    ///     arrives in the wrong language, so the choice is explicit and recorded in
    ///     the header rather than guessed from the system.
    public static func markdown(
        _ summary: SummaryArtifact,
        against document: KollioDocument,
        languageCode: String
    ) -> Document {
        let staleness = summary.staleness(against: document)
        var out: [String] = []
        out.append("# \(summary.title)")
        out.append("")
        out.append(summary.objective.text.resolve(languageCode: languageCode))
        out.append("")

        // The revision, up front. A reader who has to hunt for it will not check it.
        out.append("---")
        out.append("")
        out.append("- Synthesis: `\(summary.id.idString)`")
        out.append("- Document revision read: **\(summary.baseSemanticRevision)**")
        out.append("- Document revision now: \(document.semanticRevision)")
        out.append("- State: \(summary.isDraft ? "draft, not yet handed over" : "confirmed")")
        out.append("- Language: \(languageCode)")

        if staleness.isEmpty {
            out.append("- Current: every decision in the read set still stands.")
        } else {
            // Said here and not at the end, because this is the line that decides
            // whether the recipient trusts the rest.
            out.append("")
            out.append("> **Outdated.** Something this synthesis read has moved since it was written.")
            for reason in staleness { out.append(">")
                out.append("> - \(describe(reason))")
            }
        }
        if let narrower = summary.proposedNarrowerScope {
            out.append("")
            out.append("> This synthesis covers a narrower scope than the one it was asked for.")
            out.append("> \(narrower.reason)")
        }
        out.append("")

        for section in SummaryArtifact.Section.allCases {
            out.append("## \(section.title)")
            out.append("")
            let value = summary.sections(section)
            if value.isEmpty {
                // Reachable only from a draft, because confirming refuses it. An
                // export of a draft says so rather than printing an empty heading.
                out.append("_Not written yet. This synthesis is a draft._")
            } else if value.allSatisfy({ $0.lines.isEmpty && $0.isNothingRecorded }) {
                out.append("_Nothing was recorded here._")
            } else {
                for sectionValue in value {
                    for line in sectionValue.lines {
                        out.append("- \(line.text.resolve(languageCode: languageCode))\(correctionNote(for: line))")
                    }
                }
            }
            out.append("")
        }

        out.append("## Sources")
        out.append("")
        if summary.sourceRefs.isEmpty {
            out.append("_No source was cited._")
        } else {
            for ref in summary.sourceRefs.sorted(by: { $0.id.idString < $1.id.idString }) {
                let title = document.sources.source(ref.sourceID)?.title ?? ref.sourceID.rawValue
                let current = document.sources.source(ref.sourceID)?.latest?.id
                let suffix = current == ref.revisionID ? "" : " (a newer revision exists)"
                out.append("- \(title) — revision `\(ref.revisionID.rawValue)`\(suffix)")
            }
        }
        out.append("")

        out.append("## What was read")
        out.append("")
        let read = summary.readSet
        out.append("- Objects: \(read.objectIDs.count)")
        out.append("- Source revisions: \(read.sourceRevisionIDs.count)")
        out.append("- Citations: \(read.citationIDs.count)")
        out.append("- Decisions: \(read.decisionIDs.count)")
        if read.wasTruncated {
            out.append("- The walk stopped at its bound, so this list is not the whole document.")
        }
        out.append("")

        let appendix = correctionsAppendix(summary, languageCode: languageCode)
        if !appendix.isEmpty {
            out.append("## Corrections")
            out.append("")
            out.append("Lines a person changed after they were written. Both versions travel, so the")
            out.append("recipient can see what the model said and what was kept.")
            out.append("")
            out.append(contentsOf: appendix)
        }

        return Document(
            text: out.joined(separator: "\n"),
            filename: filename(for: summary, languageCode: languageCode),
            usedRevision: summary.baseSemanticRevision,
            currentRevision: document.semanticRevision,
            isOutdated: !staleness.isEmpty
        )
    }

    /// The headings and the parts a person reads first.
    ///
    /// A compact block is what a person sees on the canvas: the objective, the
    /// state, the uncertainties, and whether it has moved. Everything else is one
    /// click away. The compact form is deliberately not an export in miniature —
    /// it omits rather than shortens, because a shortened section reads as a
    /// complete one.
    public struct CompactBlock: Equatable, Sendable {
        public var title: String
        public var objective: String
        public var stateHeadline: String
        public var uncertaintyCount: Int
        public var statesNothingIsUncertain: Bool
        public var isOutdated: Bool
        public var isDraft: Bool
        public var sourceCount: Int
        public var usedRevision: Int
    }

    public static func compact(
        _ summary: SummaryArtifact,
        against document: KollioDocument,
        languageCode: String
    ) -> CompactBlock {
        let uncertaintyLines = summary.uncertainties.flatMap(\.lines)
        return CompactBlock(
            title: summary.title,
            objective: summary.objective.text.resolve(languageCode: languageCode),
            // The first line, or an honest statement that there is none. Never a
            // join of the first three, which would imply a summary of the section.
            stateHeadline: summary.currentState.first?.lines.first?.text
                .resolve(languageCode: languageCode) ?? "",
            uncertaintyCount: uncertaintyLines.count,
            // Distinguishable from an empty section at a glance, which is the whole
            // of AC02 on a canvas.
            statesNothingIsUncertain: summary.uncertainties.contains { $0.isNothingRecorded },
            isOutdated: summary.isOutdated(against: document),
            isDraft: summary.isDraft,
            sourceCount: summary.sourceRefs.count,
            usedRevision: summary.baseSemanticRevision
        )
    }

    private static func correctionNote(for line: SummaryArtifact.SummaryLine) -> String {
        guard line.wasEdited else { return "" }
        return line.editedBy == nil
            ? " _(corrected)_"
            : " _(corrected by \(line.editedBy?.rawValue ?? "a person"))_"
    }

    private static func correctionsAppendix(
        _ summary: SummaryArtifact,
        languageCode: String
    ) -> [String] {
        summary.allLines.compactMap { line in
            guard let original = line.originalText else { return nil }
            let was = original.resolve(languageCode: languageCode)
            let now = line.text.resolve(languageCode: languageCode)
            guard was != now else { return nil }
            return "- **was** \(was)\n  **kept** \(now)"
        }
    }

    private static func describe(_ reason: SummaryStaleness) -> String {
        switch reason {
        case .decisionMoved(let id):
            return "a decision moved since this was written: `\(id.rawValue)`"
        case .revisionMoved(let from, let to):
            return "the document moved from revision \(from) to \(to)"
        case .sourceRevisionSuperseded(let id):
            return "a source has a newer revision: `\(id.rawValue)`"
        }
    }

    /// A filename a person would recognise, without a timestamp nobody reads.
    ///
    /// The revision is in the name because two exports of the same synthesis are
    /// genuinely different documents, and the difference is the whole point of
    /// naming it.
    private static func filename(for summary: SummaryArtifact, languageCode: String) -> String {
        let slug = summary.title
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let safe = slug.isEmpty ? "synthesis" : slug
        return "\(safe)-r\(summary.baseSemanticRevision)-\(languageCode).md"
    }
}
