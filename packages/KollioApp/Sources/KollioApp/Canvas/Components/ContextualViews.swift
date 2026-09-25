import SwiftUI
import KollioCore

/// The local action control that appears next to a selected object.
///
/// At most three primary actions. The full action universe is never on screen.
struct ContextualActions: View {
    let model: KollioModel
    let target: ObjectID

    @Environment(\.kollioTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let anchor = anchorPoint() {
            VStack(alignment: .leading, spacing: Space.s) {
                HStack(spacing: Space.xs) {
                    ForEach(actions) { action in
                        ActionButton(title: action.title, isDefault: action.isDefault) {
                            action.perform()
                        }
                        .help(action.hint)
                    }
                }
                if !setAsideReason.isEmpty {
                    Text(setAsideReason)
                        .font(TypeScale.metadata)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: 320, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Space.s)
            .background(
                RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                    .fill(theme.surfacePrimary)
                    .shadow(color: .black.opacity(theme.isDark ? 0.38 : 0.13), radius: 14, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                    .strokeBorder(theme.decorativeBorder, lineWidth: 1)
            )
            .position(anchor)
            .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : -4)))
        }
    }

    // MARK: Actions

    private struct LocalAction: Identifiable {
        let id = UUID()
        let title: String
        let hint: String
        var isDefault: Bool = false
        let perform: () -> Void
    }

    private var actions: [LocalAction] {
        if model.canReopen(target) {
            return [
                LocalAction(title: L10n.reopen, hint: L10n.reopen, isDefault: true) { model.reopen(target) }
            ]
        }
        return [
            LocalAction(title: L10n.explore, hint: L10n.explore, isDefault: true) {
                Task { await model.explore(target) }
            },
            LocalAction(title: L10n.add, hint: L10n.add) {
                model.startComposer(anchor: target)
            },
            LocalAction(title: L10n.setAside, hint: L10n.setAside) {
                model.requestSetAsideReason(for: target)
            }
        ]
    }

    private var setAsideReason: String {
        model.setAsideReason(of: target) ?? ""
    }

    /// Screen position: just under the object, clamped inside the window.
    private func anchorPoint() -> CGPoint? {
        guard let frame = model.frame(of: target) else { return nil }
        let bottomCenter = model.camera.toScreen(Position(x: frame.center.x, y: frame.maxY + 18))
        let width: Double = 300
        let height: Double = setAsideReason.isEmpty ? 52 : 92
        return CGPoint(
            x: min(max(bottomCenter.x, width / 2 + 16), max(model.viewport.width - width / 2 - 16, width / 2)),
            y: min(bottomCenter.y + height / 2, max(model.viewport.height - height / 2 - 16, height / 2))
        )
    }
}

/// The inline composer that opens beside the object being worked on. There is no
/// chat panel: the answer becomes a relation, a question or a proposed branch.
struct ComposerView: View {
    let model: KollioModel
    let anchor: ObjectID

    @Environment(\.kollioTheme) private var theme
    @FocusState private var focused: Bool

    private var placeholder: String {
        model.composer?.intent == .setAside ? L10n.composerSetAsidePlaceholder : L10n.composerAddPlaceholder
    }

    var body: some View {
        if let frame = model.frame(of: anchor) {
            let screen = model.camera.toScreen(Position(x: frame.origin.x, y: frame.maxY + 16))
            VStack(alignment: .leading, spacing: Space.xs) {
                TextField(
                    placeholder,
                    text: Binding(
                        get: { model.composer?.text ?? "" },
                        set: { model.composer?.text = $0 }
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(TypeScale.body)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1...4)
                .focused($focused)
                .onSubmit { Task { await model.submitComposer() } }

                Text(model.composer?.intent == .setAside ? L10n.composerSetAsideHint : L10n.composerHint)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(Space.m)
            .frame(width: 320, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.composer, style: .continuous)
                    .fill(theme.surfacePrimary)
                    .shadow(color: .black.opacity(theme.isDark ? 0.4 : 0.15), radius: 16, y: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.composer, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.5), lineWidth: 1)
            )
            .position(
                x: min(max(screen.x + 170, 180), max(model.viewport.width - 180, 180)),
                y: min(max(screen.y + 70, 90), max(model.viewport.height - 90, 90))
            )
            .onAppear { focused = true }
            .onExitCommand { model.composer = nil }
            .accessibilityLabel(placeholder)
        }
    }
}

/// The first experience: one invitation, one text field, no wizard.
struct FirstExperienceView: View {
    let model: KollioModel

    @Environment(\.kollioTheme) private var theme
    @FocusState private var focused: Bool
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Text(L10n.initialTitle)
                .font(TypeScale.invitation)
                .foregroundStyle(theme.textPrimary)

            Text(L10n.initialSubtitle)
                .font(TypeScale.body)
                .foregroundStyle(theme.textSecondary)

            TextField("", text: $text, prompt: Text(L10n.initialPlaceholder).foregroundStyle(theme.textSecondary))
                .textFieldStyle(.plain)
                .font(TypeScale.primaryThought)
                .foregroundStyle(theme.textPrimary)
                .padding(.vertical, Space.m)
                .padding(.horizontal, Space.l)
                .background(
                    RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                        .fill(theme.surfacePrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                        .strokeBorder(focused ? theme.accent.opacity(0.6) : theme.decorativeBorder, lineWidth: 1)
                )
                .frame(width: 520)
                .focused($focused)
                .onSubmit { submit() }

            HStack(spacing: Space.s) {
                Text("⌘↩")
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
                ActionButton(title: L10n.explore, isDefault: true) { submit() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear { focused = true }
        .onExitCommand { focused = true }
        .accessibilityElement(children: .contain)
    }

    private func submit() {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        text = ""
        model.start(with: value)
    }
}
