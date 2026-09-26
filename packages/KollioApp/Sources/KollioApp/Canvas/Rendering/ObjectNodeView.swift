import SwiftUI
import KollioCore

/// One object of the document, rendered in one of three visual families.
///
/// The domain kind decides the form, but the type names are never printed: the
/// graph has to be understandable before any metadata is read.
struct ObjectNodeView: View {
    let object: ContentObject
    let text: String
    let detail: String?
    let isSelected: Bool
    let isHovered: Bool
    let isDragging: Bool
    let width: Double
    /// Sources cited by this object. Empty for most objects, and never invented:
    /// the chip is drawn from the ledger or not at all.
    let sourceChips: [SourceChip]
    /// Set when this object's evidence moved, or when a mark applied by a previous
    /// assessment has not been looked at. A mark nobody can see on the canvas is a
    /// record in a file and nothing else, so it is drawn here rather than only
    /// being readable in the review card.
    let needsReview: Bool
    let isCitationsOpen: Bool
    let onToggleCitations: () -> Void
    let onSelect: (Bool) -> Void
    let onHover: (Bool) -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onDoubleClick: () -> Void

    @Environment(\.kollioTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch object.form {
            case .thought:
                thought
            case .reference:
                reference
            case .richResult:
                richResult
            }
        }
        .overlay(alignment: .topTrailing) {
            if needsReview {
                // Small, quiet, and not a control: it says the ground under this
                // moved, and the control that reads it is the action beside the
                // object, not the badge.
                Text(L10n.impactNeedsReview)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.attention)
                    .padding(.horizontal, Space.xs)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.attention.opacity(0.12)))
                    .offset(x: 4, y: -6)
                    .allowsHitTesting(false)
                    .accessibilityLabel(L10n.impactNeedsReview)
            }
        }
        .frame(width: width, alignment: .leading)
        .padding(.vertical, Space.s)
        .padding(.horizontal, Space.m)
        .background(selectionBackground)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(false) }
        .onHover { onHover($0) }
        .gesture(dragGesture)
        .simultaneousGesture(TapGesture(count: 2).onEnded { onDoubleClick() })
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel(text)
        .accessibilityHint(L10n.explore)
        .help(text)
    }

    // MARK: Forms

    private var thought: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(text)
                .font(object.kind == .context ? TypeScale.mainContext : TypeScale.primaryThought)
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(TypeScale.body)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var reference: some View {
        HStack(alignment: .top, spacing: Space.s) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.accent)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(text)
                    .font(TypeScale.body.weight(.medium))
                    .foregroundStyle(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(TypeScale.metadata)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if sourceChips.isEmpty == false {
                    // On the object rather than in a panel: a chip about evidence
                    // belongs next to the claim it supports, and nowhere else.
                    SourceChipRow(
                        chips: sourceChips,
                        isOpen: isCitationsOpen,
                        onOpen: onToggleCitations
                    )
                }
            }
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.reference, style: .continuous)
                .fill(theme.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.reference, style: .continuous)
                .strokeBorder(theme.decorativeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(theme.isDark ? 0.35 : 0.10), radius: 5, y: 2)
    }

    private var richResult: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(text)
                .font(TypeScale.primaryThought)
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let detail, !detail.isEmpty {
                Divider().overlay(theme.decorativeBorder)
                Text(detail)
                    .font(TypeScale.body)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Space.l)
        .background(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .fill(theme.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .strokeBorder(theme.decorativeBorder, lineWidth: 1)
        )
    }

    /// A thought has no visible container at rest. Selection and hover are
    /// signalled by ink, not by a permanent box.
    @ViewBuilder
    private var selectionBackground: some View {
        switch object.form {
        case .thought:
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.surfaceSubtle.opacity(isSelected ? 0.9 : (isHovered ? 0.5 : 0)))
        case .reference, .richResult:
            if isSelected {
                RoundedRectangle(cornerRadius: object.form == .reference ? Radius.reference : Radius.richBlock, style: .continuous)
                    .strokeBorder(theme.accent, lineWidth: 2)
            }
        }
    }

    private var icon: String {
        switch object.kind {
        case .evidence: return "checkmark.seal"
        case .contribution: return "shippingbox"
        default: return "doc.text"
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { onDragChanged($0.translation) }
            .onEnded { _ in onDragEnded() }
    }
}

/// A direction that was set aside: compact, still inspectable, still there.
struct CollapsedDirectionView: View {
    let text: String
    let reason: String?
    let width: Double
    let onReopen: () -> Void

    @Environment(\.kollioTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(text)
                .font(TypeScale.body)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let reason, !reason.isEmpty {
                Text(reason)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: width, alignment: .leading)
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.s)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.surfaceSubtle)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(theme.decorativeBorder)
                .frame(width: 2)
                .padding(.vertical, Space.s)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onReopen() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text). \(L10n.setAside)")
        // The hint used to be the reason, which is empty when no reason was
        // given: a screen reader user then had no way to know reopening existed.
        // The reason stays, and the action is now a real accessibility action
        // rather than a double-click nobody can perform.
        .accessibilityHint(reason.map { "\($0). \(L10n.reopen)" } ?? L10n.reopen)
        .accessibilityAction(named: L10n.reopen) { onReopen() }
    }
}


/// The state of the sources behind a claim, on the claim itself.
///
/// Small and quiet. The chip itself is not a control: it says what state the
/// sources are in, and clicking it opens the citations beside the claim, where
/// reading a passage and recording a check actually happen. It is a label that
/// happens to be a door, not a row of buttons pretending to be evidence.
struct SourceChipRow: View {
    let chips: [SourceChip]
    let isOpen: Bool
    let onOpen: () -> Void
    @Environment(\.kollioTheme) private var theme

    var body: some View {
        HStack(spacing: Space.xs) {
            ForEach(chips) { chip in
                HStack(spacing: 2) {
                    Image(systemName: symbol(for: chip.state))
                        .font(.system(size: 9, weight: .semibold))
                    Text(label(for: chip))
                        .font(TypeScale.metadata)
                }
                .foregroundStyle(chip.state.needsAttention ? theme.attention : theme.textSecondary)
                .padding(.horizontal, Space.xs)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(isOpen ? theme.accentSurface : theme.surfaceSubtle)
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .help(L10n.citationsTitle)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOpen ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel(
            chips.map { L10n.sourceChipAccessibility($0.title, $0.state.accessibilityDescription) }
                .joined(separator: ". ")
        )
        .accessibilityHint(L10n.citationsTitle)
    }

    private func symbol(for state: SourceChipState) -> String {
        switch state {
        case .ready: return "checkmark.circle"
        case .importing: return "arrow.triangle.2.circlepath"
        case .notRead: return "circle.dashed"
        case .partial: return "exclamationmark.circle"
        case .noText: return "doc.text.magnifyingglass"
        case .unsupported: return "questionmark.circle"
        case .missing, .unverifiable: return "exclamationmark.triangle"
        }
    }

    private func label(for chip: SourceChip) -> String {
        let count = chip.citations
        return count > 1
            ? L10n.sourceChipCount(chip.title, count)
            : L10n.sourceChip(chip.title)
    }
}
