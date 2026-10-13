import AppKit
import SwiftUI
import Testing
import KollioCore
@testable import KollioApp

/// Opt-in, isolated native validation. Captures only our NSHostingView, never
/// the user's screen or another application's windows. No user files touched.
@Suite("Spatial C2.8 — real macOS surface acceptance")
struct SpatialNativeAcceptanceTests {
    @Test("A two-occurrence .kollio scene renders with selected-card controls")
    @MainActor
    func renderTwoOccurrences() throws {
        guard let pngPath = ProcessInfo.processInfo.environment["KOLLIO_SPATIAL_C28_CAPTURE"]
        else { return }

        var document = SarahFixture.document()
        let objectID = try #require(document.content.keys.sorted {
            $0.rawValue < $1.rawValue
        }.first)
        document.presentation.instances = [
            NodeInstance(id: "c28-first", objectID: objectID,
                         position: Position(x: 260, y: 220)),
            NodeInstance(id: "c28-second", objectID: objectID,
                         position: Position(x: 680, y: 400))
        ]
        let original = document
        let fileStore = DocumentFileStore(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("kollio-c28-native-\(UUID().uuidString)"))
        let languageCode = ProcessInfo.processInfo.environment["KOLLIO_SPATIAL_C29_LANGUAGE"] == "en" ? "en" : "fr"
        let model = KollioModel(document: document,
                                service: KollioModel.makeDemoService(languageCode: languageCode),
                                fileStore: fileStore, languageCode: languageCode, mode: .demo)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let compact = ProcessInfo.processInfo.environment["KOLLIO_SPATIAL_C28_COMPACT"] == "1"
        let frame = NSRect(x: 0, y: 0, width: compact ? 900 : 1280,
                           height: compact ? 700 : 1100)
        let hosting = NSHostingView(rootView: SpatialV3WindowView(
            initialSelectedID: objectID.rawValue, model: model
        ))
        hosting.frame = frame
        let window = NSWindow(
            contentRect: frame, styleMask: [.titled], backing: .buffered, defer: false
        )
        window.title = "Kollio C2.8 — isolated native document"
        window.contentView = hosting
        window.orderFront(nil)
        defer { window.orderOut(nil) }

        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        hosting.layoutSubtreeIfNeeded()
        let bitmap = try #require(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: pngPath), options: .atomic)

        let projected = SpatialDocumentScene(projection: SpatialDocumentProjection(
            document: model.document, languageCode: model.languageCode
        ))
        #expect(projected.occurrenceCount(for: objectID.rawValue) == 2)
        #expect(projected.instanceIDByVisualID[objectID.rawValue] == "c28-first")
        #expect(model.document == original)
        print("NATIVE-C28 capture \(pngPath) (\(data.count) bytes)")
    }
}
