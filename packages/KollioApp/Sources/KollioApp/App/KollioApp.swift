import SwiftUI
import KollioCore
import AppKit

@main
struct KollioApp: App {
    /// Built from the environment at launch, so the app starts with the source it
    /// was actually configured for rather than always the offline engine.
    @State private var model = KollioModel.makeAppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("Kollio", id: "main") {
            RootView(model: model)
                .kollioThemed()
                .task {
                    try? await Task.sleep(for: .seconds(3))
                    await model.prepareVisualStateForReview()
                }
                // The delegate saves on quit. It has to be handed the same model
                // the window is showing, or every save on quit is a silent no-op.
                .onAppear { delegate.model = model }
                .frame(minWidth: 720, minHeight: 480)
        }
        .defaultSize(width: 1280, height: 860)
        .windowToolbarStyle(.unifiedCompact)
        .commands { KollioCommands(model: model) }
    }
}

struct RootView: View {
    let model: KollioModel

    var body: some View {
        ZStack {
            if model.isEmpty {
                FirstExperienceView(model: model)
            } else {
                CanvasView(model: model)
            }
        }
        .background(Color.clear)
    }
}

/// System commands live in native macOS menus. The canvas itself stays empty.
struct KollioCommands: Commands {
    let model: KollioModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(L10n.newDocument) { model.newDocument() }
                .keyboardShortcut("n", modifiers: .command)
            Button(L10n.openDemo) { model.loadDemo() }
                .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        CommandGroup(replacing: .saveItem) {
            Button(L10n.save) { model.save() }
                .keyboardShortcut("s", modifiers: .command)
        }
        CommandGroup(replacing: .undoRedo) {
            Button(L10n.undo) { model.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!model.canUndo)
            Button(L10n.redo) { model.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!model.canRedo)
        }
        CommandGroup(after: .toolbar) {
            Button(L10n.fit) { model.fitContent() }
                .keyboardShortcut("0", modifiers: .command)
            Button(L10n.actualSize) {
                model.camera = Camera()
            }
            .keyboardShortcut("1", modifiers: .command)
        }
        // Find is a system command, so it lives in the Edit menu where macOS puts
        // Cmd+F and not in a bar on the canvas. It asks no model: it is a search
        // over what is already in the document.
        CommandGroup(after: .textEditing) {
            Button(L10n.search) { model.openSearch() }
                .keyboardShortcut("f", modifiers: .command)
        }
        // The tour is reachable and leavable without a pointer, which is AC01 rather
        // than a convenience: the arrow keys move between points and Escape leaves,
        // so a person who never touches the canvas can still read the document
        // through it.
        CommandGroup(after: .pasteboard) {
            Button(model.isPresenting ? L10n.presentationExit : L10n.presentationStart) {
                if model.isPresenting { model.exitPresentation() } else { model.beginPresentation() }
            }
            .keyboardShortcut(.return, modifiers: .command)
            Button(L10n.presentationPrevious) { model.rewindPresentation() }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(model.presentation?.index ?? 0 == 0)
            Button(L10n.presentationNext) { model.advancePresentation() }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(model.presentation == nil)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var model: KollioModel?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// The macOS client owns the local document: it is saved on quit, and
    /// restored on the next launch.
    ///
    /// Both hooks are deliberate. `applicationShouldTerminate` is the one that
    /// runs for a normal quit, and it can still refuse; the `WillTerminate`
    /// notification is the last chance for the other paths. Neither one reports
    /// success unless `save()` actually returned true.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        MainActor.assumeIsolated { saveOnQuit() }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { saveOnQuit() }
    }

    @MainActor
    private func saveOnQuit() {
        guard let model else {
            // Nothing to save is worse than a visible failure: say so rather
            // than quitting as if the work were safe on disk.
            NSLog("Kollio: quitting with no model attached, the document was not saved")
            return
        }
        if model.save() == false {
            NSLog("Kollio: the document could not be saved on quit: \(model.status ?? "")")
        }
    }
}
