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
    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { model?.save() }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        MainActor.assumeIsolated { model?.save() }
        return .terminateNow
    }
}
