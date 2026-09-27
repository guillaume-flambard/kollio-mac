import Foundation
import KollioCore
import SwiftUI

/// The temporary contextual timeline of one object (DEC-06).
///
/// It answers one question the document cannot: **how did this get here?** The
/// rows come from the journal, and every row carries the label the person
/// acted under, which is the only record of *why* that exists. A reversal is
/// already folded into the action it cancels, so a person does not have to do
/// the arithmetic between "added a branch" and "undid it".
///
/// What this card deliberately does not do: preview, restore, or purge. The
/// specification's preview-with-differences and restore-as-a-new-action are
/// written and not built, and a timeline that showed a restore button it
/// cannot honour would be an invitation to find out. What it does guarantee
/// is the half the tests can hold: it is a reading. Opening it writes
/// nothing, closing it writes nothing, and the present is exactly where the
/// person left it.
struct HistoryTimelineView: View {
    let model: KollioModel
    let anchor: ObjectID

    @Environment(\.kollioTheme) private var theme

    private var items: [HistoryNarrativeItem] { model.history(of: anchor) }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(L10n.historyTitle)
                .font(TypeScale.metadata.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            ForEach(items.reversed(), id: \.id) { item in
                HStack(alignment: .top, spacing: Space.xs) {
                    Text(item.at, format: .dateTime.day().month().hour().minute())
                        .font(TypeScale.metadata)
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 118, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.label)
                            .font(item.movedMeaning ? TypeScale.body : TypeScale.metadata)
                            .foregroundStyle(item.movedMeaning ? theme.textPrimary : theme.textSecondary)
                        if item.wasLaterReverted {
                            Text(L10n.historyLaterReverted)
                                .font(TypeScale.metadata)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }

            HStack {
                Spacer(minLength: 0)
                ActionButton(title: L10n.historyClose, isDefault: false) {
                    model.openHistoryID = nil
                }
            }
        }
        .padding(Space.l)
        .frame(width: 380, alignment: .leading)
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
