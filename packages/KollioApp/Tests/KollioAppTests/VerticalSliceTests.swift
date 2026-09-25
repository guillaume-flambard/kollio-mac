import Foundation
import Testing
import KollioCore
@testable import KollioApp

/// The first complete vertical slice, exercised through the real model, the
/// real file, and the real intelligence service. No mocks: this is the flow the
/// brief asks to be proven before anything else is built.
@Suite("Vertical slice: Sarah, explore, keep, undo, set aside, reopen, save")
@MainActor
struct VerticalSliceTests {
    private func makeModel() -> (KollioModel, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-slice-\(UUID().uuidString)")
        let store = DocumentFileStore(directory: directory)
        let model = KollioModel(document: SarahFixture.document(), fileStore: store)
        return (model, directory)
    }

    @Test("Sarah, Explore, Keep, Undo, Explore again, Set aside, Reopen, save, reopen")
    func fullSlice() async throws {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")

        // 1. The document is Sarah, with 6 objects and 5 relationships.
        #expect(model.document.content.count == 6)
        #expect(model.relationshipsToRender().count == 5)

        // 2. Explore a direction: a ghost branch appears, the document is intact.
        await model.explore(csv)
        let preview = try #require(model.preview)
        #expect(preview.objectIDs.count == 3)
        #expect(preview.relationshipIDs.count == 3)
        #expect(model.document.content.count == 6)

        // 3. Keep: the branch becomes real content, in one transaction.
        let revisionBeforeKeep = model.document.semanticRevision
        model.keepPreview()
        #expect(model.document.content.count == 9)
        #expect(model.document.semanticRevision == revisionBeforeKeep + 1)
        #expect(model.preview == nil)

        // 4. Undo restores the exact previous state.
        model.undo()
        #expect(model.document.content.count == 6)
        #expect(model.document.semanticRevision == revisionBeforeKeep)

        // 5. Explore again: the same branch is proposed again, because the
        //    document went back to where it was.
        await model.explore(csv)
        #expect(model.preview?.objectIDs.count == 3)
        model.keepPreview()
        #expect(model.document.content.count == 9)

        // 6. Set aside the CSV direction with a reason, through the composer.
        model.requestSetAsideReason(for: csv)
        #expect(model.composer?.intent == .setAside)
        model.composer?.text = "On garde l’export pour plus tard"
        await model.submitComposer()
        #expect(model.canReopen(csv))
        #expect(model.setAsideReason(of: csv) == "On garde l’export pour plus tard")
        // The branch collapsed, nothing was deleted, the CRM direction is intact.
        // Six objects belonged exclusively to the CSV direction: the direction
        // itself, its two original children and the three objects just kept. Five
        // of them collapse; the direction itself stays, compact and inspectable.
        #expect(model.document.content.count == 9)
        #expect(model.visibleInstances.count == 4)
        #expect(model.setAsideReason(of: KollioID.object("sarah-viable")) == "On garde l’export pour plus tard")
        #expect(model.object(KollioID.object("sarah-crm"))?.isSetAside == false)

        // 7. Reopen restores the objects, the relationships and the positions.
        let positionsBefore = Dictionary(
            uniqueKeysWithValues: model.document.presentation.instances.map { ($0.objectID, $0.position) }
        )
        model.reopen(csv)
        #expect(model.visibleInstances.count == 9)
        for instance in model.document.presentation.instances {
            #expect(instance.position == positionsBefore[instance.objectID])
        }

        // 8. Save, quit, reopen: the accepted state is preserved.
        #expect(model.save())
        let reloaded = KollioModel(document: nil, fileStore: DocumentFileStore(directory: directory))
        #expect(reloaded.document.content.count == 9)
        #expect(reloaded.document.semanticRevision == model.document.semanticRevision)
        #expect(reloaded.relationshipsToRender().count == model.relationshipsToRender().count)
        // The decision history survived the round trip, not just the objects.
        #expect(reloaded.document.decisions.values.contains { $0.kind == .setAside })
    }

    @Test("Exploring the same direction twice proposes nothing new")
    func exploreIsStateReactive() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")

        await model.explore(csv)
        let first = try! #require(model.preview)
        model.keepPreview()

        await model.explore(csv)
        #expect(model.preview == nil)
        #expect(model.status == L10n.statusNoChange)
        #expect(first.objectIDs.isEmpty == false)
    }

    @Test("A proposed branch never lands on top of existing content")
    func ghostsDoNotOverlap() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        await model.explore(KollioID.object("sarah-crm"))
        let preview = try! #require(model.preview)

        let existing = model.visibleInstances.compactMap { model.frame(of: $0.objectID) }
        for id in preview.objectIDs {
            let position = try! #require(preview.placements[id])
            let size = NodeLayout.estimatedSize(
                for: ContentObject(
                    id: id,
                    kind: .question,
                    text: LocalizedText("x"),
                    provenance: .human("ghost")
                )
            )
            let ghost = Rect(origin: Position(x: position.x - size.width / 2, y: position.y), size: size)
            for rect in existing {
                #expect(ghost.insetBy(dx: -6, dy: -6).intersects(rect) == false)
            }
        }
    }

    @Test("Setting a direction aside twice keeps one active decision")
    func repeatedDecisions() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let csv = KollioID.object("sarah-csv")
        model.setAside(csv, reason: "première raison")
        model.reopen(csv)
        model.setAside(csv, reason: "seconde raison")
        let active = model.document.decisions.values.filter { $0.status == .active }
        #expect(active.count == 1)
        #expect(active.first?.rationale?.text == "seconde raison")
        #expect(model.setAsideReason(of: csv) == "seconde raison")
    }
}

@Suite("Fixture file")
struct FixtureFileTests {
    /// The shipped fixture is written from the same builder the app uses, so the
    /// file on disk and the running document cannot drift apart.
    @Test("Writes a readable .kollio file")
    func writesFixture() throws {
        // Built once: a fresh document carries its own creation timestamp.
        let document = SarahFixture.document()
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sarah-\(UUID().uuidString).kollio")
        defer { try? FileManager.default.removeItem(at: url) }
        try DocumentCodec.write(document, to: url)
        let reloaded = try DocumentCodec.read(from: url)
        #expect(reloaded == document)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("\"schemaVersion\""))
        #expect(text.contains("object:sarah-context"))

        // `KOLLIO_WRITE_FIXTURE=<path>` refreshes the shipped reference file, so
        // the contract and the running app can never drift apart.
        if let destination = ProcessInfo.processInfo.environment["KOLLIO_WRITE_FIXTURE"] {
            try FileManager.default.createDirectory(
                at: URL(fileURLWithPath: destination).deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try DocumentCodec.write(document, to: URL(fileURLWithPath: destination))
        }
    }
}
