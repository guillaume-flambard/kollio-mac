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
            LocalAction(title: L10n.clarify, hint: L10n.clarify) {
                model.startComposer(anchor: target, intent: .add)
            },
            LocalAction(title: L10n.edit, hint: L10n.edit) {
                model.startEditing(anchor: target)
            },
            LocalAction(title: L10n.setAside, hint: L10n.setAside) {
                model.requestSetAsideReason(for: target)
            },
            LocalAction(title: L10n.addSource, hint: L10n.addSourceHint) {
                chooseSource()
            }
        ]
    }

    /// Asks for a file, reads it, and attaches what came out.
    ///
    /// The panel is a system one and cancellable, because "not now" is a real
    /// answer. Nothing is read until a file is actually chosen, and a file that
    /// cannot be read leaves the document untouched and says so.
    private func chooseSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = L10n.addSourceHint
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let read = model.attachSource(at: url, to: target) else { return }
        // The chip reports the state; the line only says the file was attached, so
        // a scan is never announced as a successful read.
        switch read.extraction {
        case .ready:
            model.status = L10n.sourceAttached(read.title)
        case .noText(let reason), .unsupported(let reason), .partial(_, let reason):
            model.status = L10n.sourceAttachedWithoutText(read.title, reason)
        case .notAttempted, .pending, .missing:
            model.status = L10n.sourceAttached(read.title)
        }
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
        switch model.composer?.intent {
        case .setAside: return L10n.composerSetAsidePlaceholder
        case .edit: return L10n.composerEditPlaceholder
        default: return L10n.composerAddPlaceholder
        }
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

/// The first experience: one invitation, one multiline field, one action.
///
/// This is the product's entry point, so it is the same canvas-first screen
/// with nothing added around it. `Enter` inserts a newline because a context is
/// a paragraph, not a query; `Cmd+Enter` submits, and the button does the same.
struct FirstExperienceView: View {
    let model: KollioModel

    @Environment(\.kollioTheme) private var theme
    @FocusState private var focused: Bool
    @State private var text: String = ""
    @State private var isSubmitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Text(L10n.initialTitle)
                .font(TypeScale.invitation)
                .foregroundStyle(theme.textPrimary)

            Text(L10n.initialSubtitle)
                .font(TypeScale.body)
                .foregroundStyle(theme.textSecondary)

            // A stored document that could not be read is reported here rather
            // than hidden behind a fresh canvas, and its file is left untouched.
            if model.hasUnreadableDocument {
                Text(L10n.errorLoadFailed)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.error)
                    .frame(width: 520, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextEditor(text: $text)
                .font(TypeScale.primaryThought)
                .foregroundStyle(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(Space.s)
                .frame(width: 520, height: 132)
                .background(
                    RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                        .fill(theme.surfacePrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                        .strokeBorder(focused ? theme.accent.opacity(0.6) : theme.decorativeBorder, lineWidth: 1)
                )
                .focused($focused)
                .overlay(alignment: .bottomTrailing) {
                    Text(L10n.submitHint)
                        .font(TypeScale.metadata)
                        .foregroundStyle(theme.textSecondary)
                        .padding(Space.s)
                        .allowsHitTesting(false)
                }

            HStack(spacing: Space.s) {
                Text("⌘↩")
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
                ActionButton(title: L10n.explore, isDefault: true) { submit() }
                    .disabled(isSubmitting)
            }
            // Cmd+Enter submits from anywhere in the field. `Enter` is left alone
            // on purpose: a context is a paragraph, and a newline belongs in it.
            .background(
                Button("") { submit() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .hidden()
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear { focused = true }
        .onExitCommand { focused = true }
        .accessibilityElement(children: .contain)
    }

    private func submit() {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, isSubmitting == false else { return }
        isSubmitting = true
        // The sentence is handed to the model, which persists it before it asks
        // anything of the intelligence source. A failure there cannot cost the
        // user their words, so nothing is restored here.
        guard let context = model.start(with: value) else {
            isSubmitting = false
            return
        }
        text = ""
        Task {
            await model.exploreInitialContext(context)
            isSubmitting = false
        }
    }
}
