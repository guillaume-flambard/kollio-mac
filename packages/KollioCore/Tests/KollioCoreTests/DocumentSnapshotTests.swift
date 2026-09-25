import Foundation
import Testing
import KollioCore

/// The transport contract between a client that owns its document and a server
/// that does not. Everything here is about what may cross the wire, and what is
/// refused when it should be.
@Suite("Document snapshot")
struct DocumentSnapshotTests {
    private func document() -> KollioDocument {
        var builder = DocumentBuilder()
        let context = builder.object("ctx", kind: .context, "Recover the list", en: "Recover the list", at: .zero)!
        let direct = builder.object("direct", kind: .hypothesis, "Direct call", en: "Direct call", at: Position(x: -240, y: 200))!
        let export = builder.object("export", kind: .hypothesis, "Export", en: "Export", at: Position(x: 240, y: 200))!
        let far = builder.object("far", kind: .note, "Unrelated elsewhere", en: "Unrelated elsewhere", at: Position(x: 900, y: 900))!
        _ = builder.link("l1", from: context, to: direct, .alternativeTo)
        _ = builder.link("l2", from: context, to: export, .alternativeTo)
        _ = builder.link("l3", from: direct, to: far, .uses)
        return builder.document
    }

    @Test("A snapshot carries the target and its neighbourhood, and nothing else")
    func scopeIsBounded() throws {
        let document = self.document()
        let snapshot = try document.snapshot(targeting: ["object:ctx"])
        #expect(snapshot.objects.keys.contains("object:ctx"))
        #expect(snapshot.objects.keys.contains("object:direct"))
        #expect(snapshot.objects.keys.contains("object:export"))
        // One hop, so the far object is not dragged along.
        #expect(snapshot.objects.keys.contains("object:far") == false)
        #expect(snapshot.documentId == document.documentId)
        #expect(snapshot.semanticRevision == document.semanticRevision)
        try snapshot.validate(targets: ["object:ctx"])
    }

    @Test("A snapshot carries no visual layout")
    func noLayoutIsCarried() throws {
        let document = self.document()
        let snapshot = try document.snapshot(targeting: ["object:ctx"])
        // The server must never place anything, so no coordinates travel.
        let encoded = try JSONEncoder().encode(snapshot)
        let json = String(decoding: encoded, as: UTF8.self)
        #expect(json.contains("\"position\"") == false)
        #expect(json.contains("\"instances\"") == false)
    }

    @Test("The snapshot rebuilds a real document the server can validate against")
    func rebuildsARealDocument() throws {
        let document = self.document()
        let snapshot = try document.snapshot(targeting: ["object:ctx"])
        let rebuilt = snapshot.makeDocument()
        #expect(rebuilt.documentId == document.documentId)
        #expect(rebuilt.semanticRevision == document.semanticRevision)
        #expect(rebuilt.object("object:ctx")?.text.text == "Recover the list")
        // The relationships of the slice survive with their kinds.
        #expect(rebuilt.relationships.count == 2)
        #expect(rebuilt.relationship("relationship:l1")?.kind == .alternativeTo)
    }

    @Test("A relationship naming an object the snapshot lacks is refused")
    func danglingReferenceIsRefused() throws {
        let document = self.document()
        var snapshot = try document.snapshot(targeting: ["object:ctx"])
        snapshot.relationships["relationship:ghost"] = .init(
            id: "relationship:ghost",
            from: "object:ctx",
            to: "object:not-here",
            kind: .uses,
            provenance: .human("test")
        )
        #expect(throws: DocumentSnapshot.SnapshotError.self) {
            try snapshot.validate()
        }
    }

    @Test("A target outside the snapshot is refused, not guessed")
    func targetOutsideIsRefused() throws {
        let document = self.document()
        let snapshot = try document.snapshot(targeting: ["object:ctx"])
        #expect(throws: DocumentSnapshot.SnapshotError.self) {
            try snapshot.validate(targets: ["object:far"])
        }
    }

    @Test("An object set aside by an unsent decision is refused")
    func unknownDecisionIsRefused() throws {
        let document = self.document()
        var snapshot = try document.snapshot(targeting: ["object:ctx"])
        var object = try #require(snapshot.objects["object:export"])
        object.setAsideByDecision = "decision:absent"
        snapshot.objects["object:export"] = object
        #expect(throws: DocumentSnapshot.SnapshotError.self) {
            try snapshot.validate()
        }
    }

    @Test("An unsupported snapshot version is refused")
    func versionIsChecked() throws {
        let document = self.document()
        var snapshot = try document.snapshot(targeting: ["object:ctx"])
        snapshot.snapshotVersion = 99
        #expect(throws: DocumentSnapshot.SnapshotError.self) {
            try snapshot.validate()
        }
    }

    @Test("An oversized snapshot is refused rather than truncated")
    func oversizedIsRefused() throws {
        var builder = DocumentBuilder()
        let root = builder.object("root", kind: .context, "Root", en: "Root", at: .zero)!
        // A star graph: every node touches the root, so the slice is everything.
        for index in 0..<(DocumentSnapshot.maximumObjects + 10) {
            let child = builder.object("n\(index)", kind: .note, "n\(index)", en: "n\(index)", at: .zero)!
            _ = builder.link("r\(index)", from: root, to: child, .uses)
        }
        let document = builder.document
        #expect(throws: DocumentSnapshot.SnapshotError.self) {
            try document.snapshot(targeting: ["object:root"])
        }
    }

    @Test("Asking for an object that does not exist is a client error")
    func missingTargetIsAClientError() {
        let document = self.document()
        #expect(throws: DocumentSnapshot.SnapshotError.self) {
            try document.snapshot(targeting: ["object:does-not-exist"])
        }
    }

    @Test("A decision about something in the slice travels with it")
    func decisionsTravel() throws {
        var builder = DocumentBuilder()
        let context = builder.object("ctx", kind: .context, "Ctx", en: "Ctx", at: .zero)!
        let branch = builder.object("branch", kind: .hypothesis, "Branch", en: "Branch", at: Position(x: 0, y: 200))!
        _ = builder.link("l1", from: context, to: branch, .alternativeTo)
        var session = KollioSession(document: builder.document)
        let applied = session.apply([
            .recordDecision(.init(
                id: "decision:d1",
                kind: .setAside,
                targetObjectID: branch,
                rationale: LocalizedText("Not now"),
                provenance: .human("test")
            ))
        ], label: "set aside")
        #expect(applied)
        let document = session.document

        let snapshot = try document.snapshot(targeting: ["object:branch"])
        // The provider can see the direction was already rejected.
        #expect(snapshot.decisions["decision:d1"] != nil)
        try snapshot.validate()
        let rebuilt = snapshot.makeDocument()
        #expect(rebuilt.object("object:branch")?.isSetAside == true)
    }
}
