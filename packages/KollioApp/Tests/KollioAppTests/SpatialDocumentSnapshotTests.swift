import AppKit
import SwiftUI
import Testing
import KollioCore
@testable import KollioApp

@Suite("Spatial Ink — real native document view")
struct SpatialDocumentSnapshotTests {
    /// Set KOLLIO_SPATIAL_DOCUMENT_CAPTURE to a local PNG destination.
    /// No screenshot files or user documents are committed from this test.
    @Test("Sarah renders in the actual NSHostingView without touching its document")
    @MainActor
    func captureIfRequested() throws {
        guard let path = ProcessInfo.processInfo.environment["KOLLIO_SPATIAL_DOCUMENT_CAPTURE"] else { return }
        let document = SarahFixture.document()
        let before = document
        let model = KollioModel.deterministicModel(document: document)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let frame = NSRect(x: 0, y: 0, width: 1270, height: 1040)
        let selected = ProcessInfo.processInfo.environment["KOLLIO_SPATIAL_C23_SELECTED"] == "1"
            ? SpatialDocumentProjection(document: document).nodes.first?.id : nil
        let hosting = NSHostingView(rootView: SpatialV3WindowView(
            initialSelectedID: selected, model: model
        ))
        hosting.frame = frame
        let window = NSWindow(contentRect: frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "Kollio — document Sarah, édition locale"
        window.contentView = hosting
        window.orderFront(nil)
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        hosting.layoutSubtreeIfNeeded()
        let bitmap = try #require(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        #expect(model.document == before)
        #expect(SpatialDocumentProjection(document: model.document).nodes.count == document.content.count)
        window.orderOut(nil)
        print("Native real-document snapshot saved to \(path)")
    }
}
