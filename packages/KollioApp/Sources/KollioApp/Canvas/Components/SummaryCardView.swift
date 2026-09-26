import SwiftUI
import KollioCore

/// A synthesis, as a person reads it before deciding whether to hand it over.
///
/// ## The shape comes from three refusals
///
/// - **The compact form omits rather than shortens.** One line of the state, the
///   count of uncertainties, the revision it read. Three lines of the state would
///   read as a summary of the section, and a person would take it as one.
/// - **An empty section is visible.** A section that recorded nothing says so, and
///   a section nobody has written yet says something different. Collapsing the two
///   would make "nobody wrote down what is not known" look like a rendering fault.
/// - **Outdated is stated, not styled away.** When a decision it read has moved the
///   card says so in words. A badge nobody can interpret is decoration.
struct SummaryCardView: View {
    let model: KollioModel
    let id: SummaryID

    @Environment(\.kollioTheme) private var theme
    @State private var isExpanded = false

    private var summary: SummaryArtifact? { model.summary(id) }
    private var block: SummaryExport.CompactBlock? { model.openSummaryBlock }

    var body: some View {
        if let summary, let block {
            VStack(alignment: .leading, spacing: Space.s) {
                header(summary, block)
                if block.isOutdated {
                    outdatedBanner
                }
                stateBlock(summary, block)
                uncertaintyBlock(summary, block)
                revisionLine(summary, block)
                if isExpanded {
                    expandedSections(summary)
                }
                actions(summary, block)
            }
            .padding(Space.l)
            .frame(width: 420, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                    .fill(theme.surfacePrimary)
                    .shadow(color: .black.opacity(theme.isDark ? 0.4 : 0.14), radius: 18, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
        }
    }

    // MARK: Blocks

    private func header(_ summary: SummaryArtifact, _ block: SummaryExport.CompactBlock) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(block.title)
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
            Text(summary.objective.text.resolve(languageCode: model.languageCode))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            if block.isDraft {
                Label(L10n.summaryDraft, systemImage: "pencil.line")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var outdatedBanner: some View {
        Label(L10n.summaryOutdated, systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(theme.attention)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func stateBlock(_ summary: SummaryArtifact, _ block: SummaryExport.CompactBlock) -> some View {
        Group {
            if block.stateHeadline.isEmpty {
                Text(L10n.summaryNotWritten)
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                Text(block.stateHeadline)
                    .font(.callout)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(isExpanded ? nil : 3)
            }
        }
    }

    /// Uncertainties, and the one absence this feature exists to keep visible.
    private func uncertaintyBlock(_ summary: SummaryArtifact, _ block: SummaryExport.CompactBlock) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(L10n.summaryUncertainties)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
            if block.statesNothingIsUncertain {
                // Different from "not written yet", and the difference is AC02 in
                // two words.
                Text(L10n.summaryNothingUncertain)
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else if block.uncertaintyCount == 0 {
                Text(L10n.summaryNotWritten)
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                Text(L10n.summaryUncertaintyCount(block.uncertaintyCount))
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    /// The revision, because a deliverable that does not say which version it
    /// describes cannot answer "is this still true?".
    private func revisionLine(_ summary: SummaryArtifact, _ block: SummaryExport.CompactBlock) -> some View {
        HStack(spacing: Space.xs) {
            Text(L10n.summaryRevision(block.usedRevision))
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            if block.sourceCount > 0 {
                Text("·")
                    .foregroundStyle(theme.textSecondary)
                Text(L10n.summarySourceCount(block.sourceCount))
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private func expandedSections(_ summary: SummaryArtifact) -> some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Divider().overlay(theme.textSecondary.opacity(0.2))
            ForEach(SummaryArtifact.Section.allCases, id: \.self) { section in
                sectionBlock(summary, section)
            }
        }
    }

    private func sectionBlock(_ summary: SummaryArtifact, _ section: SummaryArtifact.Section) -> some View {
        let values = summary.sections(section)
        return VStack(alignment: .leading, spacing: Space.xs) {
            Text(section.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
            if values.isEmpty {
                Text(L10n.summaryNotWritten)
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else if values.allSatisfy({ $0.lines.isEmpty && $0.isNothingRecorded }) {
                Text(L10n.summaryNothingRecorded)
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            } else {
                ForEach(values.flatMap(\.lines)) { line in
                    HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                        Text(line.text.resolve(languageCode: model.languageCode))
                            .font(.footnote)
                            .foregroundStyle(theme.textPrimary)
                        if line.wasEdited {
                            // A correction is marked where it is read, and the
                            // original travels in the export. A line a person
                            // changed must never read as the model's own words.
                            Text(L10n.summaryCorrected)
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func actions(_ summary: SummaryArtifact, _ block: SummaryExport.CompactBlock) -> some View {
        HStack(spacing: Space.s) {
            ActionButton(
                title: isExpanded ? L10n.summaryCollapse : L10n.summaryExpand,
                isDefault: false
            ) {
                isExpanded.toggle()
            }
            if block.isDraft {
                ActionButton(title: L10n.summaryConfirm, isDefault: true) {
                    model.confirmSummary(id)
                }
            }
            ActionButton(title: L10n.summaryExport, isDefault: false) {
                model.exportSummary(id)
            }
            Spacer(minLength: 0)
            ActionButton(title: L10n.comparisonClose, isDefault: false) {
                model.openSummaryID = nil
            }
        }
    }
}
