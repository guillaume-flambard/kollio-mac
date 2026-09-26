import Foundation
import Testing
@testable import KollioCore

/// AI-06, the part where a synthesis becomes real: commands, refusals, and the
/// one thing a synthesis may never do to the document it reads.
@Suite("Summary commands")
struct SummaryCommandTests {
    private var context: ObjectID { ObjectID("object:ctx") }
    private var direction: ObjectID { ObjectID("object:dir") }
    private var elsewhere: ObjectID { ObjectID("object:elsewhere") }

    private func store() -> DocumentStore {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("dir", kind: .method, "Instrument each step")
        builder.object("elsewhere", kind: .context, "Pricing page copy")
        return DocumentStore(document: builder.document)
    }

    private var human: Provenance { .human(ActorID("actor:guillaume")) }
    private var engine: Provenance {
        Provenance(actor: ActorID("actor:model"), kind: .localEngine, requestId: "r1")
    }

    private func objective() -> SummaryArtifact.SummaryLine {
        SummaryArtifact.SummaryLine(
            id: SummaryLineID("objective"),
            text: LocalizedText("Decide what to change before the review"),
            provenance: human
        )
    }

    private func draft(
        readSet: SummaryArtifact.SummaryReadSet? = nil,
        narrower: SummaryArtifact.NarrowerScope? = nil
    ) -> SummaryArtifact {
        SummaryArtifact(
            id: SummaryID("s1"),
            title: "Sign-up funnel, for the release review",
            objective: objective(),
            readSet: readSet ?? SummaryArtifact.SummaryReadSet(objectIDs: [context, direction]),
            baseSemanticRevision: 0,
            proposedNarrowerScope: narrower
        )
    }

    private func line(
        _ seed: String,
        _ text: String = "The funnel loses people at the second step",
        provenance: Provenance? = nil,
        references: [SummaryReference] = [SummaryReference(kind: .object, id: ObjectID("object:ctx").rawValue)]
    ) -> SummaryArtifact.SummaryLine {
        SummaryArtifact.SummaryLine(
            id: SummaryLineID(seed),
            text: LocalizedText(text),
            provenance: provenance ?? engine,
            references: references
        )
    }

    // MARK: - Opening

    @Test("A synthesis opens as a draft whatever it arrived as")
    func alwaysOpensDraft() throws {
        var s = store()
        var arrived = draft()
        arrived.isDraft = false
        try s.apply([Command.startSummary(StartSummary(summary: arrived, provenance: human))])
        // An engine that could hand over a deliverable nobody agreed to would not
        // need a draft at all, so the draft is forced rather than trusted.
        #expect(s.document.summaries.summary(SummaryID("s1"))?.isDraft == true)
    }

    @Test("A synthesis reads only objects that exist")
    func readSetMustResolve() {
        var s = store()
        let bad = draft(readSet: SummaryArtifact.SummaryReadSet(objectIDs: [context, ObjectID("object:ghost")]))
        #expect(throws: DocumentError.self) {
            try s.apply([Command.startSummary(StartSummary(summary: bad, provenance: human))])
        }
    }

    @Test("A synthesis with no title is refused")
    func titleIsRequired() {
        var s = store()
        var untitled = draft()
        untitled.title = "   "
        #expect(throws: DocumentError.self) {
            try s.apply([Command.startSummary(StartSummary(summary: untitled, provenance: human))])
        }
    }

    @Test("The same synthesis cannot be opened twice")
    func noDuplicate() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        #expect(throws: DocumentError.duplicateSummary(SummaryID("s1"))) {
            try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        }
    }

    @Test("A too-wide selection is kept as the scope it would have preferred")
    func narrowerScopeSurvives() throws {
        var s = store()
        let refused = draft(narrower: SummaryArtifact.NarrowerScope(
            objectIDs: [context],
            reason: "The selection covered 40 objects across 6 branches."
        ))
        try s.apply([Command.startSummary(StartSummary(summary: refused, provenance: human))])
        let stored = try #require(s.document.summaries.summary(SummaryID("s1")))
        #expect(stored.proposedNarrowerScope?.objectIDs == [context])
    }

    // MARK: - AC01, the initial text stays intact

    @Test("Editing a line keeps the text the model first produced")
    func editKeepsOriginal() throws {
        var s = store()
        try s.apply([
            Command.startSummary(StartSummary(summary: draft(), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: line("l1"), provenance: human
            )),
        ])
        try s.apply([Command.setSummaryLine(SetSummaryLine(
            summaryID: SummaryID("s1"), section: .currentState,
            line: line("l1", "The funnel loses people at the second step, every time", provenance: human),
            provenance: human
        ))])

        let stored = try #require(s.document.summaries.summary(SummaryID("s1")))
        let edited = try #require(stored.line(SummaryLineID("l1")))
        #expect(edited.text.text == "The funnel loses people at the second step, every time")
        // The point of the whole feature: the first text is still there, and who
        // changed it is recorded.
        #expect(edited.originalText?.text == "The funnel loses people at the second step")
        #expect(edited.editedBy == ActorID("actor:guillaume"))
        #expect(edited.wasEdited)
    }

    @Test("An edit twice keeps the first text, not the previous one")
    func editTwiceKeepsTheFirst() throws {
        var s = store()
        try s.apply([
            Command.startSummary(StartSummary(summary: draft(), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: line("l1"), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState,
                line: line("l1", "second edit", provenance: human), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState,
                line: line("l1", "third edit", provenance: human), provenance: human)),
        ])
        let stored = try #require(s.document.summaries.summary(SummaryID("s1")))
        let edited = try #require(stored.line(SummaryLineID("l1")))
        #expect(edited.text.text == "third edit")
        // Not "second edit": the record is of what was generated, not of the
        // previous keystroke.
        #expect(edited.originalText?.text == "The funnel loses people at the second step")
    }

    @Test("An engine line that rests on nothing is refused")
    func unsupportedAssertionRefused() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        #expect(throws: DocumentError.unsupportedSummaryAssertion(SummaryLineID("l1"))) {
            try s.apply([Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState,
                line: line("l1", "This is clearly the best option", references: []),
                provenance: human
            ))])
        }
    }

    @Test("A person's line needs no reference")
    func personLineAcceptedWithoutReference() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        try s.apply([Command.setSummaryLine(SetSummaryLine(
            summaryID: SummaryID("s1"), section: .uncertainties,
            line: line("u1", "I do not trust the second measurement", provenance: human, references: []),
            provenance: human
        ))])
        let stored = try #require(s.document.summaries.summary(SummaryID("s1")))
        #expect(stored.line(SummaryLineID("u1")) != nil)
    }

    @Test("A line referencing an object that does not exist is refused")
    func danglingReferenceRefused() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        #expect(throws: DocumentError.self) {
            try s.apply([Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .reasons,
                line: line("l1", references: [SummaryReference(kind: .object, id: "object:ghost")]),
                provenance: human
            ))])
        }
    }

    @Test("The objective cannot be rewritten through a section")
    func objectiveIsNotASectionLine() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        #expect(throws: DocumentError.forbiddenOperation("the objective is written when the synthesis opens")) {
            try s.apply([Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: objective(), provenance: human
            ))])
        }
    }

    // MARK: - AC02, uncertainties are visible

    @Test("A section can be declared empty on purpose")
    func declareNothingRecorded() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        try s.apply([Command.setSummarySection(SetSummarySection(
            summaryID: SummaryID("s1"),
            kind: .uncertainties,
            section: SummaryArtifact.SummarySection(.uncertainties, lines: [], isNothingRecorded: true),
            provenance: human
        ))])
        let stored = try #require(s.document.summaries.summary(SummaryID("s1")))
        #expect(stored.uncertainties.count == 1)
        #expect(stored.uncertainties[0].isNothingRecorded)
    }

    @Test("A section cannot be empty on purpose and full at once")
    func contradictorySectionRefused() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        #expect(throws: DocumentError.contradictorySummarySection(SummaryID("s1"))) {
            try s.apply([Command.setSummarySection(SetSummarySection(
                summaryID: SummaryID("s1"),
                kind: .uncertainties,
                section: SummaryArtifact.SummarySection(.uncertainties, lines: [line("u1")], isNothingRecorded: true),
                provenance: human
            ))])
        }
    }

    @Test("Writing a line cancels a declaration of absence")
    func writingCancelsAbsence() throws {
        var s = store()
        try s.apply([
            Command.startSummary(StartSummary(summary: draft(), provenance: human)),
            Command.setSummarySection(SetSummarySection(
                summaryID: SummaryID("s1"),
                kind: .uncertainties,
                section: SummaryArtifact.SummarySection(.uncertainties, lines: [], isNothingRecorded: true),
                provenance: human
            )),
        ])
        try s.apply([Command.setSummaryLine(SetSummaryLine(
            summaryID: SummaryID("s1"), section: .uncertainties,
            line: line("u1", "We do not know whether the form or the network is at fault", provenance: human),
            provenance: human
        ))])
        let stored = try #require(s.document.summaries.summary(SummaryID("s1")))
        // The person has now said something about this section, so the section is
        // no longer allowed to claim there was nothing to say.
        #expect(stored.uncertainties[0].isNothingRecorded == false)
        #expect(stored.uncertainties[0].lines.count == 1)
    }

    // MARK: - Confirming

    @Test("Confirming is refused while a section is silently blank")
    func confirmRefusesSilentSection() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        // Nothing has been written anywhere. This is the template with blanks that
        // "the AI does not fabricate conclusions to fill a template" forbids.
        #expect(throws: DocumentError.self) {
            try s.apply([Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human))])
        }
        #expect(s.document.summaries.summary(SummaryID("s1"))?.isDraft == true)
    }

    @Test("Confirming is refused when a section is present but says nothing")
    func confirmRefusesEmptySection() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        for kind in SummaryArtifact.Section.allCases {
            try s.apply([Command.setSummarySection(SetSummarySection(
                summaryID: SummaryID("s1"),
                kind: kind,
                section: SummaryArtifact.SummarySection(kind, lines: [], isNothingRecorded: false),
                provenance: human
            ))])
        }
        #expect(throws: DocumentError.silentSummarySection(SummaryID("s1"), .currentState)) {
            try s.apply([Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human))])
        }
    }

    @Test("A synthesis that has said something about everything can be confirmed")
    func confirmWhenComplete() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        for kind in SummaryArtifact.Section.allCases {
            try s.apply([Command.setSummarySection(SetSummarySection(
                summaryID: SummaryID("s1"),
                kind: kind,
                section: SummaryArtifact.SummarySection(kind, lines: [], isNothingRecorded: true),
                provenance: human
            ))])
        }
        try s.apply([Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human))])
        #expect(s.document.summaries.summary(SummaryID("s1"))?.isDraft == false)
    }

    @Test("Confirming twice leaves the synthesis alone")
    func confirmTwiceChangesNothing() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        for kind in SummaryArtifact.Section.allCases {
            try s.apply([Command.setSummarySection(SetSummarySection(
                summaryID: SummaryID("s1"),
                kind: kind,
                section: SummaryArtifact.SummarySection(kind, lines: [], isNothingRecorded: true),
                provenance: human
            ))])
        }
        try s.apply([Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human))])
        let confirmed = try #require(s.document.summaries.summary(SummaryID("s1")))
        // The second press is a no-op, exactly as a second confirm on a
        // comparison is. It is recorded as a command, so the revision counter
        // still moves and undoing it undoes nothing. That wart is shared with
        // comparisons and recorded in known-limitations rather than fixed here,
        // because fixing it for syntheses alone would leave the two divergent.
        try s.apply([Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human))])
        let revisionAfterFirst = s.document.revision
        try s.apply([Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human))])
        let after = try #require(s.document.summaries.summary(SummaryID("s1")))
        #expect(after == confirmed)
        // The command is still recorded, so the counter did move; what matters is
        // that the synthesis itself is byte-identical.
        #expect(s.document.revision == revisionAfterFirst + 1)
    }

    // MARK: - Removing

    @Test("Removing a synthesis touches no content, and does move the meaning")
    func removeLeavesContent() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        let contentBefore = s.document.content
        let semanticBefore = s.document.semanticRevision
        try s.apply([Command.removeSummary(RemoveSummary(summaryID: SummaryID("s1"), provenance: human))])
        #expect(s.document.summaries.summary(SummaryID("s1")) == nil)
        // A synthesis holds no content, so removing one cannot lose anything the
        // document does not still hold.
        #expect(s.document.content == contentBefore)
        // The meaning does move, and it should: a document that carried a
        // deliverable no longer carries it, and that is a change in what the
        // document says. The first version of this test asserted the opposite and
        // was wrong.
        #expect(s.document.semanticRevision == semanticBefore + 1)
    }

    @Test("Removing a synthesis that is not there is refused")
    func removeUnknownRefused() {
        var s = store()
        #expect(throws: DocumentError.unknownSummary(SummaryID("nope"))) {
            try s.apply([Command.removeSummary(RemoveSummary(summaryID: SummaryID("nope"), provenance: human))])
        }
    }

    // MARK: - What intelligence may not do

    @Test("Intelligence is refused every synthesis command")
    func intelligenceIsRefused() {
        for command in [
            Command.startSummary(StartSummary(summary: draft(), provenance: engine)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: line("l1"), provenance: engine)),
            Command.setSummarySection(SetSummarySection(
                summaryID: SummaryID("s1"), kind: .reasons,
                section: SummaryArtifact.SummarySection(.reasons), provenance: engine)),
            Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: engine)),
            Command.removeSummary(RemoveSummary(summaryID: SummaryID("s1"), provenance: engine)),
        ] {
            let proposal = Proposal(
                proposalId: "p1",
                requestId: "r1",
                documentId: store().document.documentId,
                baseSemanticRevision: 0,
                summary: LocalizedText("try to take over the deliverable"),
                rationale: LocalizedText("the model would like to"),
                operations: [command],
                generator: Proposal.Generator(name: "test", deterministic: true)
            )
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(
                    proposal, against: store().document, scope: ProposalRequest.Scope()
                )
            }
        }
    }

    // MARK: - Transactions

    @Test("A refused line leaves the synthesis exactly as it was")
    func refusedLineIsAtomic() throws {
        var s = store()
        try s.apply([
            Command.startSummary(StartSummary(summary: draft(), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: line("l1"), provenance: human)),
        ])
        let before = s.document
        #expect(throws: DocumentError.self) {
            try s.apply([Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .reasons,
                line: line("l2", "  ", provenance: human), provenance: human))])
        }
        #expect(s.document == before)
    }

    @Test("A whole batch is one transaction and one undo")
    func oneTransactionOneUndo() throws {
        var session = KollioSession(document: store().document)
        var s = store()
        try s.apply([
            Command.startSummary(StartSummary(summary: draft(), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: line("l1"), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .reasons, line: line("l2"), provenance: human)),
        ])
        let beforeRevision = store().document.revision
        let afterBatch = s.document
        #expect(afterBatch.summaries.all().count == 1)
        // Three commands, one revision. A batch is one transaction, so it moves
        // the document once however many commands it holds, and one press of undo
        // takes all of it back. The first version of this test expected three
        // revisions and was wrong about how batching works.
        #expect(afterBatch.revision == beforeRevision + 1)

        // Called outside the assertion: `apply` and `undo` mutate, and a
        // `#expect` autoclosure receives an immutable value.
        let opened = session.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))], label: "open")
        #expect(opened)
        let undone = session.undo()
        #expect(undone)
        #expect(session.document.summaries.all().isEmpty)
    }

    @Test("A synthesis command moves the meaning, because a deliverable is meaning")
    func synthesisIsSemantic() {
        #expect(Command.startSummary(StartSummary(summary: draft(), provenance: human)).isSemantic)
        #expect(Command.confirmSummary(ConfirmSummary(summaryID: SummaryID("s1"), provenance: human)).isSemantic)
        #expect(Command.setSummaryLine(SetSummaryLine(
            summaryID: SummaryID("s1"), section: .reasons, line: line("l1"), provenance: human
        )).isSemantic)
    }

    @Test("A synthesis survives a save and a reload")
    func survivesAReload() throws {
        var s = store()
        try s.apply([
            Command.startSummary(StartSummary(summary: draft(), provenance: human)),
            Command.setSummaryLine(SetSummaryLine(
                summaryID: SummaryID("s1"), section: .currentState, line: line("l1"), provenance: human)),
        ])
        let decoded = try DocumentCodec.decode(DocumentCodec.encode(s.document))
        let stored = try #require(decoded.summaries.summary(SummaryID("s1")))
        #expect(stored.title == "Sign-up funnel, for the release review")
        #expect(stored.line(SummaryLineID("l1"))?.text.text == "The funnel loses people at the second step")
        #expect(stored.readSet.objectIDs == [context, direction])
        #expect(decoded.schemaVersion == KollioDocument.currentSchemaVersion)
    }

    @Test("A file written before syntheses existed opens")
    func olderFileOpens() throws {
        var s = store()
        try s.apply([Command.startSummary(StartSummary(summary: draft(), provenance: human))])
        var raw = try #require(
            JSONSerialization.jsonObject(with: DocumentCodec.encode(s.document)) as? [String: Any]
        )
        raw.removeValue(forKey: "summaries")
        raw["schemaVersion"] = 5
        let decoded = try DocumentCodec.decode(try JSONSerialization.data(withJSONObject: raw))
        #expect(decoded.summaries.all().isEmpty)
        #expect(decoded.comparisons.all().isEmpty)
        #expect(decoded.content.count == 3)
    }
}
