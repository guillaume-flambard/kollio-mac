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
/// Each row offers preview (read-only view of the document at that revision),
/// restore (a new transaction that brings the document to that state, DEC-06
/// AC03), and the card as a whole offers purge (removes old entries by a
/// retention horizon). Opening the card writes nothing; closing it writes
/// nothing; the present is exactly where the person left it.
struct HistoryTimelineView: View {
    let model: KollioModel
    let anchor: ObjectID

    @Environment(\.kollioTheme) private var theme
    @State private var previewDocument: KollioDocument?
    @State private var showPreview = false

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
                        HStack(spacing: Space.xs) {
                            Button(L10n.historyPreview) { preview(at: item.entryID) }
                                .font(TypeScale.caption)
                                .foregroundStyle(theme.accent)
                            Button(L10n.historyRestore) { restore(to: item.entryID) }
                                .font(TypeScale.caption)
                                .foregroundStyle(theme.attention)
                        }
                    }
                }
            }

            HStack {
                Button(L10n.historyPurge) { purge() }
                    .font(TypeScale.caption)
                    .foregroundStyle(theme.textSecondary)
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
        .sheet(isPresented: $showPreview) {
            if let doc = previewDocument {
                HistoryPreviewView(document: doc, onClose: { showPreview = false })
            }
        }
    }

    private func preview(at entryID: HistoryEntryID) {
        previewDocument = try? model.previewHistory(at: entryID)
        showPreview = true
    }

    private func restore(to entryID: HistoryEntryID) {
        _ = model.restoreHistory(to: entryID, label: L10n.historyRestoreLabel)
    }

    private func purge() {
        // Keep the last 50 entries; the spec allows explicit retention.
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        _ = model.purgeHistory(olderThan: cutoff)
    }
}

/// A read-only preview of the document at a past revision.
struct HistoryPreviewView: View {
    let document: KollioDocument
    let onClose: () -> Void

    @Environment(\.kollioTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            Text(L10n.historyPreviewTitle)
                .font(TypeScale.metadata.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            Text("\(document.objects.count) objects, \(document.relationships.count) relations, revision \(document.revision)")
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)

            ScrollView {
                VStack(alignment: .leading, spacing: Space.xs) {
                    ForEach(document.objects.sorted { $0.id.rawValue < $1.id.rawValue }) { object in
                        Text(object.text.resolve(languageCode: "fr"))
                            .font(TypeScale.caption)
                            .foregroundStyle(theme.textPrimary)
                    }
                }
            }

            HStack {
                Spacer(minLength: 0)
                ActionButton(title: L10n.historyClose, isDefault: true, action: onClose)
            }
        }
        .padding(Space.l)
        .frame(width: 420, height: 320)
        .background(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .fill(theme.surfacePrimary)
        )
    }
}
