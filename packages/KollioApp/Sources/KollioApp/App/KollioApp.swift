import SwiftUI
import KollioCore
import AppKit

@main
struct KollioApp: App {
    @State private var model = KollioModel()
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
