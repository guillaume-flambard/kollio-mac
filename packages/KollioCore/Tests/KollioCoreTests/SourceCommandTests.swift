import Foundation
import Testing
@testable import KollioCore

/// Sources and citations as commands, not as side effects.
///
/// A source is part of the document, so attaching one is undoable, transactional
/// and versioned with everything else. The last test here is the important one:
/// intelligence is refused these operations outright.
@Suite("Source commands")
struct SourceCommandTests {
    private func store() -> DocumentStore {
        DocumentStore(document: Fixture.sarah())
    }

    private func source(_ id: String = "source:brief") -> SourceReference {
        SourceReference(id: SourceID(id), kind: .text, title: "Brief", locator: "file:///tmp/brief.md")
    }

    private func revision(
        _ id: String = "rev:1",
        _ sequence: Int = 1
    ) -> SourceRevision {
        SourceRevision(
            id: SourceRevisionID(id),
            sequence: sequence,
            extraction: .ready(text: "Signup takes nine steps."),
            digest: "sha256:abc"
        )
    }

    @Test("Attaching a source is a semantic change, and it lands in the document")
    func attachingIsSemantic() throws {
        var store = store()
        let semanticBefore = store.semanticRevision
        try store.apply([.attachSource(.init(
            source: source(), attachedTo: KollioID.object("sarah-csv"),
            provenance: .human("person:owner")
        ))])
        #expect(store.document.sources.source("source:brief") != nil)
        #expect(store.semanticRevision == semanticBefore + 1)
    }

    @Test("A duplicate source is refused")
    func duplicateSourceIsRefused() throws {
        var store = store()
        let attach = Command.attachSource(.init(source: source(), provenance: .human("me")))
        try store.apply([attach])
        #expect(throws: DocumentError.duplicateSource("source:brief")) {
            try store.apply([attach])
        }
    }

    @Test("A source attached to an object that is not there is refused")
    func attachmentToNothingIsRefused() throws {
        var store = store()
        #expect(throws: DocumentError.unknownObject(KollioID.object("ghost"))) {
            try store.apply([.attachSource(.init(
                source: source(), attachedTo: KollioID.object("ghost"), provenance: .human("me")
            ))])
        }
        #expect(store.document.sources.source("source:brief") == nil)
    }

    @Test("A transaction that fails halfway attaches nothing")
    func attachmentIsAtomic() throws {
        var store = store()
        let before = store.document
        let commands: [Command] = [
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(
                sourceID: "source:absent", revision: revision(), provenance: .human("me")
            ))
        ]
        #expect(throws: DocumentError.unknownSource("source:absent")) {
            try store.apply(commands)
        }
        // The first command succeeded on a copy and was never published, because
        // the transaction as a whole failed.
        #expect(store.document == before)
        #expect(store.document.sources.source("source:brief") == nil)
    }

    @Test("A failed extraction is recorded, and the good version stays current")
    func failedExtractionIsRecordedAndKeepsTheGoodVersion() throws {
        var store = store()
        try store.apply([
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(sourceID: "source:brief", revision: revision(), provenance: .human("me")))
        ])

        // The attempt is applied, not refused: the chip has to be able to say "we
        // read it and there is no text", which needs the fact to exist.
        let scanned = SourceRevision(
            id: "rev:2", sequence: 2,
            extraction: .noText(reason: "no text layer"), digest: "sha256:def"
        )
        #expect(throws: Never.self) {
            try store.apply([.importSourceRevision(.init(
                sourceID: "source:brief", revision: scanned, provenance: .human("me")
            ))])
        }

        // Both attempts are on record, and the usable one is still the one a new
        // citation reads against, so a broken import replaced nothing.
        let stored = try #require(store.document.sources.source("source:brief"))
        #expect(stored.attempts.count == 2)
        #expect(stored.latest?.id == "rev:1")
        #expect(stored.extraction.isUsable)
    }

    @Test("A citation needs a claim to attach to")
    func citationNeedsAClaim() throws {
        var store = store()
        try store.apply([
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(sourceID: "source:brief", revision: revision(), provenance: .human("me")))
        ])
        let citation = Citation(
            id: "citation:1", claimID: KollioID.object("sarah-csv"),
            sourceID: "source:brief", revisionID: "rev:1",
            locator: SourceLocator(page: 1), quote: "nine steps"
        )
        #expect(throws: DocumentError.unknownObject(KollioID.object("ghost"))) {
            try store.apply([.addCitation(.init(
                citation: citation, claimID: KollioID.object("ghost"), provenance: .human("me")
            ))])
        }
        #expect(store.document.sources.citation("citation:1") == nil)
    }

    @Test("A verification needs an observation")
    func verificationNeedsAnObservation() throws {
        var store = store()
        try store.apply([
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(sourceID: "source:brief", revision: revision(), provenance: .human("me"))),
            .addCitation(.init(
                citation: Citation(
                    id: "citation:1", claimID: KollioID.object("sarah-csv"),
                    sourceID: "source:brief", revisionID: "rev:1",
                    locator: SourceLocator(page: 1), quote: "nine steps"
                ),
                claimID: KollioID.object("sarah-csv"), provenance: .human("me")
            ))
        ])
        #expect(throws: DocumentError.forbiddenOperation("a verification needs an observation")) {
            try store.apply([.recordVerification(.init(
                citationID: "citation:1", observation: "   ", author: "person:owner"
            ))])
        }
        #expect(store.document.sources.citation("citation:1")?.status == .unverified)

        try store.apply([.recordVerification(.init(
            citationID: "citation:1", observation: "Confirmed on page 1.", author: "person:owner"
        ))])
        #expect(store.document.sources.citation("citation:1")?.status.isVerified == true)
    }

    @Test("Removing a source keeps the citation and the document")
    func removingASourceKeepsTheClaim() throws {
        var store = store()
        try store.apply([
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(sourceID: "source:brief", revision: revision(), provenance: .human("me"))),
            .addCitation(.init(
                citation: Citation(
                    id: "citation:1", claimID: KollioID.object("sarah-csv"),
                    sourceID: "source:brief", revisionID: "rev:1",
                    locator: SourceLocator(page: 1), quote: "nine steps"
                ),
                claimID: KollioID.object("sarah-csv"), provenance: .human("me")
            ))
        ])
        try store.apply([.removeSource(.init(sourceID: "source:brief", reason: "the file moved"))])

        // The claim the person attached to the document is still there, and the
        // citation is still readable. Only the ability to check it quietly is gone.
        #expect(store.document.content[KollioID.object("sarah-csv")] != nil)
        let citation = store.document.sources.citation("citation:1")
        #expect(citation?.quote == "nine steps")
        if case .sourceMissing = citation!.status {} else {
            Issue.record("a citation whose source was removed must say so")
        }
    }

    @Test("Intelligence may not attach evidence or award itself a verified badge")
    func intelligenceMayNotTouchEvidence() throws {
        let document = Fixture.sarah()
        let claim = KollioID.object("sarah-csv")
        let attempts: [(String, Command)] = [
            ("attachSource", .attachSource(.init(source: source(), provenance: .human("apple:on-device")))),
            ("importSourceRevision", .importSourceRevision(.init(
                sourceID: "source:brief", revision: revision(),
                provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))),
            ("addCitation", .addCitation(.init(
                citation: Citation(
                    id: "citation:1", claimID: KollioID.object("sarah-csv"),
                    sourceID: "source:brief", revisionID: "rev:1",
                    locator: SourceLocator(page: 1), quote: "invented"
                ),
                claimID: claim, provenance: .init(actor: "apple:on-device", kind: .localEngine)
            ))),
            ("recordVerification", .recordVerification(.init(
                citationID: "citation:1", observation: "I checked it.", author: "apple:on-device"
            ))),
            ("removeSource", .removeSource(.init(sourceID: "source:brief", reason: "no longer relevant"))),
        ]

        for (name, command) in attempts {
            let proposal = Proposal(
                proposalId: "proposal:\(name)",
                requestId: "request:\(name)",
                documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision,
                summary: LocalizedText("Trying \(name)"),
                operations: [command],
                generator: .init(name: "apple-on-device", deterministic: false)
            )
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(proposal, against: document, scope: ProposalRequest.Scope(maxOperations: 8, allowNewObjects: true))
            }
        }
    }

    @Test("Sources and citations survive a save and reload")
    func sourcesRoundTrip() throws {
        var store = store()
        try store.apply([
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(sourceID: "source:brief", revision: revision(), provenance: .human("me"))),
            .addCitation(.init(
                citation: Citation(
                    id: "citation:1", claimID: KollioID.object("sarah-csv"),
                    sourceID: "source:brief", revisionID: "rev:1",
                    locator: SourceLocator(lineRange: 2..<5), quote: "nine steps"
                ),
                claimID: KollioID.object("sarah-csv"), provenance: .human("me")
            ))
        ])

        let data = try DocumentCodec.encode(store.document)
        let reloaded = try DocumentCodec.decode(data)
        // The claim and what it was based on travel together in one file.
        #expect(reloaded.sources.source("source:brief")?.title == "Brief")
        #expect(reloaded.sources.citation("citation:1")?.locator.lineRange == 2..<5)
        #expect(reloaded.sources.citation("citation:1")?.status == .unverified)
    }

    // MARK: The published contract

    @Test("Every top-level key the codec writes is declared in the schema")
    func codecAndSchemaAgree() throws {
        // This is not a full JSON Schema validation, and it is not pretending to
        // be one. It checks the one thing that actually drifted: the codec gained a
        // top-level key that `additionalProperties: false` would have rejected, and
        // nothing noticed because nothing compared the two.
        let root = try #require(packageRoot())
        let schemaPath = root.appendingPathComponent("contracts/schemas/kollio-document.schema.json")
        let schemaData = try Data(contentsOf: schemaPath)
        let schema = try JSONSerialization.jsonObject(with: schemaData) as? [String: Any]
        let declared = try #require((schema?["properties"] as? [String: Any])?.keys)
        let required = try #require(schema?["required"] as? [String])

        // A document that actually carries sources, so the new key is exercised
        // rather than being absent by luck.
        var store = store()
        try store.apply([
            .attachSource(.init(source: source(), provenance: .human("me"))),
            .importSourceRevision(.init(sourceID: "source:brief", revision: revision(), provenance: .human("me"))),
            .addCitation(.init(
                citation: Citation(
                    id: "citation:1", claimID: KollioID.object("sarah-csv"),
                    sourceID: "source:brief", revisionID: "rev:1",
                    locator: SourceLocator(page: 1), quote: "nine steps"
                ),
                claimID: KollioID.object("sarah-csv"), provenance: .human("me")
            ))
        ])

        let encoded = try JSONSerialization.jsonObject(
            with: try DocumentCodec.encode(store.document)
        ) as? [String: Any]
        let keys = try #require(encoded?.keys)

        for key in keys {
            #expect(declared.contains(key), "the codec writes '\(key)' but the schema does not declare it")
        }
        for key in required {
            #expect(keys.contains(key), "the schema requires '\(key)' but the codec does not write it: it writes \(keys.sorted())")
        }
        // And the version the codec claims is one the schema accepts.
        let version = try #require(schema?["properties"] as? [String: Any])
        let bounds = try #require((version["schemaVersion"] as? [String: Any])?["maximum"] as? Int)
        #expect(KollioDocument.currentSchemaVersion <= bounds)
    }

    /// The package root, found by walking up to the directory holding `contracts`.
    private func packageRoot() -> URL? {
        var directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        for _ in 0..<6 {
            directory.deleteLastPathComponent()
            if FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("contracts/schemas").path
            ) {
                return directory
            }
        }
        return nil
    }
}
