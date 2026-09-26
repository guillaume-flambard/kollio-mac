import SwiftUI
import KollioCore

/// The frames drawn on the canvas, behind the nodes.
///
/// A frame is furniture, not content: it is drawn under everything, it never
/// intercepts a click meant for a node, and it carries only the two things a person
/// needs to keep using one — its name, and a control to fold it.
///
/// Folding is deliberately a *view* state. Nothing here sets an object aside, and
/// the folded chip says how much is inside rather than pretending the branch is
/// closed, because a frame fold is a way of looking at the canvas and a decision is
/// a way of thinking about the document.
struct FrameLayer: View {
    let model: KollioModel

    @Environment(\.kollioTheme) private var theme

    var body: some View {
        ForEach(model.canvasFrames) { frame in
            frameView(frame)
        }
    }

    @ViewBuilder
    private func frameView(_ frame: Frame) -> some View {
        let offset = model.frameDragOffset(for: frame.id)
        if frame.isFolded {
            foldedChip(frame)
                .offset(x: offset.x, y: offset.y)
        } else if let bounds = model.bounds(of: frame) {
            outline(frame, bounds: bounds)
                .offset(x: offset.x, y: offset.y)
        }
    }

    /// The drawn container: a border, the name, and the controls. The header sits
    /// above the members, in the padding the frame reserves for it, so the name
    /// never overlaps a node.
    private func outline(_ frame: Frame, bounds: Rect) -> some View {
        let name = frame.name.resolve(languageCode: model.languageCode)
        return VStack(alignment: .leading, spacing: 0) {
            header(frame, name: name)
            Spacer(minLength: 0)
        }
        .frame(
            width: bounds.size.width,
            height: bounds.size.height - FrameLayout.headerHeight
        )
        // The border and the fill never take a click: a tap that lands on a frame
        // but not on a node is a tap on the canvas, and swallowing it would make the
        // canvas feel broken in the one place a person is tidying up. The header is
        // the exception, and it is applied to the two decoration modifiers rather
        // than to the container, because `allowsHitTesting(false)` on a parent
        // disables the whole subtree and would take the frame's own controls with
        // it. That is exactly the bug this comment is here to prevent.
        .background(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .fill(theme.accentSurface)
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .strokeBorder(theme.decorativeBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                .allowsHitTesting(false)
        )
        .offset(x: bounds.minX, y: bounds.minY)
        .gesture(frameDragGesture(frame))
    }

    private func header(_ frame: Frame, name: String) -> some View {
        HStack(spacing: Space.xs) {
            Text(name)
                .font(TypeScale.metadata.weight(.medium))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
            Text(L10n.frameCount(frame.memberInstanceIDs.count))
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
            Spacer(minLength: 0)
            FrameIconButton(
                systemImage: "chevron.up",
                label: L10n.frameFold,
                hint: L10n.frameFoldHint
            ) {
                model.setFolded(frame.id, true)
            }
            FrameIconButton(
                systemImage: "pencil",
                label: L10n.frameRename,
                hint: L10n.frameRenameHint
            ) {
                model.startRenaming(frame.id)
            }
            FrameIconButton(
                systemImage: "trash",
                label: L10n.frameRemove,
                hint: L10n.frameRemoveHint
            ) {
                model.removeFrame(frame.id)
            }
        }
        // The header is the one part of a frame that takes clicks, and it is small
        // on purpose: a person rearranges a frame by dragging it, not by aiming at
        // three icons.
        .padding(.horizontal, Space.s)
        .padding(.vertical, Space.xs)
        .frame(height: FrameLayout.headerHeight)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.accentSurface)
        )
        .contentShape(Rectangle())
        .gesture(frameDragGesture(frame))
    }

    /// A folded frame is a chip: the name, how much is inside, and one control to
    /// open it again. It is not a summary of a branch and it does not claim to be
    /// one, because nothing has been set aside.
    private func foldedChip(_ frame: Frame) -> some View {
        let name = frame.name.resolve(languageCode: model.languageCode)
        return HStack(spacing: Space.xs) {
            Image(systemName: "square.stack.3d.down.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Text(name)
                .font(TypeScale.metadata.weight(.medium))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
            Text(L10n.frameCount(frame.memberInstanceIDs.count))
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
            Spacer(minLength: 0)
            FrameIconButton(
                systemImage: "chevron.down",
                label: L10n.frameUnfold,
                hint: L10n.frameFoldHint
            ) {
                model.setFolded(frame.id, false)
            }
        }
        .padding(.horizontal, Space.s)
        // Sized by its own name rather than by a constant: a fixed width clipped
        // "Set aside for now" mid-word, which is the one thing a label must never
        // do to a phrase a person wrote.
        .frame(minWidth: FrameLayout.collapsedWidth, idealWidth: FrameLayout.collapsedWidth,
               maxWidth: FrameLayout.collapsedWidth * 2, minHeight: FrameLayout.collapsedHeight,
               maxHeight: FrameLayout.collapsedHeight)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.accentSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .strokeBorder(theme.decorativeBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
        .offset(x: frame.position.x, y: frame.position.y)
        .contentShape(Rectangle())
        .gesture(frameDragGesture(frame))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.frameFoldedAccessibility(name, L10n.frameCount(frame.memberInstanceIDs.count)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: L10n.frameUnfold) { model.setFolded(frame.id, false) }
    }

    private func frameDragGesture(_ frame: Frame) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { model.beginFrameDrag(frame.id, screenTranslation: $0.translation) }
            .onEnded { _ in model.endFrameDrag() }
    }

    // MARK: Tokens only
    //
    // A frame is drawn with the same colours as everything else, so it reads as part
    // of the same document rather than as an overlay drawn by something else. No raw
    // colour appears in this file, in either appearance.
}

/// One small control in a frame's header or in a comparison's criterion row.
///
/// Shared by the two, deliberately: both are places where a person needs a named
/// control that is not a row of buttons pretending to be evidence, and two icons
/// that mean the same thing in two files would drift apart within a week.
///
/// A plain button with a label, so it is reachable by keyboard and named by VoiceOver
/// rather than being an icon with a tooltip and nothing else.
struct FrameIconButton: View {
    let systemImage: String
    let label: String
    /// Optional: a frame's own controls have something to say beyond their name, and
    /// a small icon in a criterion row does not.
    var hint: String = ""
    let action: () -> Void

    @Environment(\.kollioTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(hint)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
    }
}

/// Naming a frame, beside the frame rather than in a panel.
///
/// The field is the whole action, and it is refused when empty, because a frame
/// whose name is blank is a label nobody can read back. Submitting keeps the
/// members, the positions and every citation exactly as they were: renaming a
/// branch does not rename its sources.
struct FrameNameView: View {
    let model: KollioModel
    let id: FrameID

    @Environment(\.kollioTheme) private var theme
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(L10n.frameNamePrompt)
                .font(TypeScale.metadata.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            TextField(
                L10n.frameNamePlaceholder,
                text: Binding(
                    get: { model.renamingFrameDraft },
                    set: { model.renamingFrameDraft = $0 }
                )
            )
            .textFieldStyle(.plain)
            .font(TypeScale.body)
            .foregroundStyle(theme.textPrimary)
            .focused($focused)
            .onSubmit { _ = model.submitFrameName() }

            Text(L10n.frameRenameHint)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer(minLength: 0)
                ActionButton(title: L10n.cancel, isDefault: false) {
                    model.dismissOneLevel()
                }
                ActionButton(title: L10n.frameRename, isDefault: true) {
                    _ = model.submitFrameName()
                }
            }
        }
        .padding(Space.m)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .fill(theme.surfacePrimary)
                .shadow(color: .black.opacity(theme.isDark ? 0.4 : 0.14), radius: 18, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
        )
        .onAppear { focused = true }
        .onExitCommand { model.dismissOneLevel() }
        .accessibilityElement(children: .contain)
    }
}
