import Foundation
import SwiftUI
// QuickLookUI predates Swift 6 concurrency and its delegate types are not
// annotated `Sendable`. The import is marked preconcurrency rather than silencing
// the diagnostic: the panel is only ever touched from the main actor, which is
// written explicitly below instead of being assumed by the compiler.
@preconcurrency import Quartz

/// Opens a chosen file in the system's own reader, beside the canvas.
///
/// This is QuickLook rather than a viewer written here. A long PDF is a document
/// with pagination, selection, search and accessibility that Apple already builds
/// and tests, and reimplementing a worse version of it inside Kollio would be the
/// wrong kind of ambition. The file is passed by URL, so QuickLook reads the
/// person's own file and Kollio never copies it.
///
/// The panel is a sheet over the window rather than a separate application, so the
/// claim being checked stays visible behind the thing being checked against.
@MainActor
public final class SourcePreviewPanel: NSObject, ObservableObject, QLPreviewPanelDataSource {
    /// The file to show, and whether anything is showing.
    @Published public private(set) var url: URL?
    @Published public private(set) var isShowing = false

    private weak var window: NSWindow?

    public func attach(to window: NSWindow?) {
        self.window = window
    }

    /// Opens the file, or closes the panel when the URL is nil.
    public func present(_ url: URL?) {
        guard let url else {
            close()
            return
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            // The file was there when it was attached and is not there now. Saying
            // so beats showing an empty reader.
            self.url = nil
            self.isShowing = false
            return
        }
        self.url = url
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        if let window {
            panel.makeKeyAndOrderFront(window)
        } else {
            panel.orderFront(nil)
        }
        isShowing = true
    }

    public func close() {
        QLPreviewPanel.shared()?.orderOut(nil)
        url = nil
        isShowing = false
    }

    // MARK: QLPreviewPanelDataSource

    public nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        // Read through the main actor: the URL is published state, and QuickLook
        // calls this on its own schedule.
        MainActor.assumeIsolated { url == nil ? 0 : 1 }
    }

    public nonisolated func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> any QLPreviewItem {
        MainActor.assumeIsolated { (url ?? URL(fileURLWithPath: "/")) as any QLPreviewItem }
    }
}
