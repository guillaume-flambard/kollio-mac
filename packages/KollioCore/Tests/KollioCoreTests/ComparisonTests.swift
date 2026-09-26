import Foundation
import Testing
@testable import KollioCore

/// AI-05: comparing directions without inventing scores.
///
/// Every test here is about a way the comparison could have lied: a number with
/// nothing behind it, an average over a subset of the criteria, a cell whose object
/// has been edited since, a total that survived a draft, and a "keep" that quietly
/// removed the alternatives.
@Suite("Comparison")
struct ComparisonTests {
    private func world() -> KollioDocument {
        var builder = DocumentBuilder()
        builder.object("crm", kind: .hypothesis, "Direct CRM connection")
        builder.object("csv", kind: .hypothesis, "CSV export")
        builder.link("l1", from: ObjectID("object:crm"), to: ObjectID("object:csv"), .alternativeTo)
        return builder.document
    }

    private var crm: ObjectID { ObjectID("object:crm") }
    private var csv: ObjectID { ObjectID("object:csv") }

    private func measured(_ id: String = "criterion:cost", higherIsBetter: Bool = false) -> Criterion {
        Criterion(
            id: CriterionID(id),
            title: "Cost",
            measure: Measure(unit: "days", higherIsBetter: higherIsBetter),
            weight: 1
        )
    }

    private func unmeasured(_ id: String = "criterion:feel") -> Criterion {
        Criterion(id: CriterionID(id), title: "How it feels")
    }

    private func start(
        criteria: [Criterion],
        draft: Bool = false,
        in store: inout DocumentStore
    ) throws -> ComparisonID {
        let comparison = Comparison(
            id: ComparisonID("comparison:one"),
            title: "Two directions",
            directionIDs: [crm, csv],
            criteria: criteria,
            isDraft: draft
        )
        try store.apply([.startComparison(.init(comparison: comparison, provenance: .human("local-user")))])
        return comparison.id
    }

    private func cell(
        _ criterion: CriterionID,
        _ direction: ObjectID,
        _ value: Cell.Value,
        references: [ComparisonReference] = []
    ) -> Command {
        .recordComparisonCell(.init(
            comparisonID: ComparisonID("comparison:one"),
            cell: Cell(
                criterionID: criterion,
                directionID: direction,
                value: value,
                references: references,
                recordedBy: ActorID("local-user")
            ),
            provenance: .human("local-user")
        ))
    }

    // MARK: AC01 no numeric rating without a measure

    @Test("A number needs a measure")
    func aNumberNeedsAMeasure() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [unmeasured()], in: &store)

        // AC01, refused where refusing is worth something: a rating without a
        // measure is an opinion wearing a decimal point.
        #expect(throws: DocumentError.criterionHasNoMeasure("criterion:feel")) {
            try store.apply([cell("criterion:feel", crm, .number(3))])
        }
        #expect(store.document.comparisons.comparison(id)?.cells.isEmpty == true)

        // Words are allowed on the same criterion, because words are not pretending
        // to be more precise than they are.
        _ = try store.apply([cell("criterion:feel", crm, .text("feels brittle"))])
        #expect(store.document.comparisons.comparison(id)?.cells.first?.value.text == "feels brittle")
    }

    @Test("A measure with no weight still gives no total")
    func anUnweightedCriterionGivesNoTotal() throws {
        var store = DocumentStore(document: world())
        let criterion = Criterion(
            id: "criterion:cost", title: "Cost",
            measure: Measure(unit: "days", higherIsBetter: false)
        )
        let id = try start(criteria: [criterion], in: &store)
        _ = try store.apply([cell("criterion:cost", crm, .number(3))])

        // A weight nobody typed is not a weight of one. It is an absent one, and the
        // arithmetic refuses to invent it.
        #expect(store.document.comparisons.comparison(id)?.total(for: crm) == nil)
        #expect(store.document.comparisons.comparison(id)?.hasDefinedTotals == false)
    }

    @Test("A total is defined only when the terms are all defined")
    func aTotalNeedsEveryTerm() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured(), measured("criterion:time", higherIsBetter: true)], in: &store)
        _ = try store.apply([cell("criterion:cost", crm, .number(3)), cell("criterion:time", crm, .number(2))])
        _ = try store.apply([cell("criterion:cost", csv, .number(1)), cell("criterion:time", csv, .number(5))])

        let comparison = try #require(store.document.comparisons.comparison(id))
        // "lower is better" for cost and "higher is better" for time, so the CRM at
        // 3 days and 2 units scores -3 + 2, and the CSV at 1 day and 5 units scores
        // -1 + 5. The arithmetic is the sign the measure itself states, and nothing
        // else: no averaging, no normalisation, no hidden weight.
        #expect(comparison.total(for: crm) == -1)
        #expect(comparison.total(for: csv) == 4)
        #expect(comparison.hasDefinedTotals)

        // One cell missing and the total is not "partial": it is not defined, because
        // a total over a subset of the criteria is a different claim.
        _ = try store.apply([.recordComparisonCell(.init(
            comparisonID: id,
            cell: Cell(
                criterionID: "criterion:time", directionID: crm, value: .notRecorded,
                recordedBy: ActorID("local-user")
            ),
            provenance: .human("local-user")
        ))])
        #expect(store.document.comparisons.comparison(id)?.total(for: crm) == nil)
        #expect(store.document.comparisons.comparison(id)?.hasDefinedTotals == false)
    }

    @Test("A draft holds nothing at all")
    func aDraftHoldsNothing() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], draft: true, in: &store)
        // A criterion nobody agreed to cannot hold a value, and no total can be read
        // out of a question.
        #expect(throws: DocumentError.comparisonIsDraft(id)) {
            try store.apply([cell("criterion:cost", crm, .number(3))])
        }
        #expect(store.document.comparisons.comparison(id)?.total(for: crm) == nil)

        // Setting criteria and confirming them are two presses. The first version
        // merged them, and adding one criterion to a draft confirmed the whole
        // comparison behind the person's back.
        _ = try store.apply([.setComparisonCriteria(.init(
            comparisonID: id, criteria: [measured()], provenance: .human("local-user")
        ))])
        #expect(store.document.comparisons.comparison(id)?.isDraft == true)
        #expect(throws: DocumentError.comparisonIsDraft(id)) {
            try store.apply([cell("criterion:cost", crm, .number(3))])
        }
        _ = try store.apply([.confirmComparisonCriteria(.init(
            comparisonID: id, provenance: .human("local-user")
        ))])
        _ = try store.apply([cell("criterion:cost", crm, .number(3))])
        #expect(store.document.comparisons.comparison(id)?.total(for: crm) == -3)
    }

    @Test("Setting the criteria drops the cells of criteria that are gone")
    func settingCriteriaDropsOrphanCells() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured(), unmeasured()], draft: true, in: &store)
        _ = try store.apply([.confirmComparisonCriteria(.init(
            comparisonID: id, provenance: .human("local-user")
        ))])
        _ = try store.apply([cell("criterion:feel", crm, .text("brittle"))])

        // The person decides the second criterion was the wrong question. Confirming
        // without it must not leave a value recorded against a question that is no
        // longer being asked.
        _ = try store.apply([.setComparisonCriteria(.init(
            comparisonID: id, criteria: [measured()], provenance: .human("local-user")
        ))])
        let comparison = try #require(store.document.comparisons.comparison(id))
        #expect(comparison.criteria.map { $0.id } == ["criterion:cost"])
        #expect(comparison.cells.isEmpty)
    }

    // MARK: AC02 each comparison keeps its references

    @Test("A cell keeps what it rests on")
    func cellsKeepTheirReferences() throws {
        var store = DocumentStore(document: world())
        let source = SourceID("source:brief")
        var document = store.document
        document.sources.add(SourceReference(
            id: source, kind: .text, title: "Brief", locator: "file:///tmp/brief",
            revisions: [SourceRevision(
                id: "rev:1", sequence: 1, extraction: .ready(text: "three days"), digest: "d1"
            )]
        ))
        _ = document.sources.cite(Citation(
            id: "citation:1", claimID: crm, sourceID: source, revisionID: "rev:1",
            locator: SourceLocator(lineRange: 0..<1), quote: "three days"
        ))
        store.replace(with: document)

        let id = try start(criteria: [measured()], in: &store)
        _ = try store.apply([cell("criterion:cost", crm, .number(3), references: [
            .init(kind: .citation, id: "citation:1"),
            .init(kind: .source, id: source.rawValue),
            .init(kind: .object, id: crm.rawValue),
        ])])
        let recorded = try #require(store.document.comparisons.comparison(id)?
            .cell(criterion: "criterion:cost", direction: crm))
        // AC02: the comparison cannot be read without also being able to check it.
        #expect(recorded.references.map { $0.id } == ["citation:1", source.rawValue, crm.rawValue])
    }

    @Test("A reference towards something that is not there is refused")
    func unknownReferenceIsRefused() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], in: &store)
        #expect(throws: DocumentError.self) {
            try store.apply([cell("criterion:cost", crm, .number(3), references: [
                .init(kind: .object, id: "object:nope"),
            ])])
        }
        #expect(store.document.comparisons.comparison(id)?.cells.isEmpty == true)
    }

    @Test("A cell whose object was edited afterwards needs a review")
    func anEditedObjectNeedsAReview() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], in: &store)
        // The fingerprint is taken when the cell is recorded, from the text as it was.
        var recorded = Cell(
            criterionID: "criterion:cost", directionID: crm, value: .number(3),
            references: [.init(kind: .object, id: crm.rawValue)],
            recordedBy: ActorID("local-user")
        )
        recorded.referenceFingerprints[crm.rawValue] =
            store.document.semanticFingerprint(for: [crm])
        _ = try store.apply([.recordComparisonCell(.init(
            comparisonID: id, cell: recorded, provenance: .human("local-user")
        ))])
        #expect(store.document.comparisons.comparison(id)?.needsReview(in: store.document) == nil)

        // The person rewrites the direction. The number was recorded against a
        // different sentence, and the comparison says so instead of carrying on.
        _ = try store.apply([.updateObjectText(.init(
            id: crm, text: LocalizedText("A pooled CRM connection"), provenance: .human("local-user")
        ))])
        let reason = try #require(store.document.comparisons.comparison(id)?
            .needsReview(in: store.document))
        #expect(reason == .referencedObjectChanged)
    }

    @Test("A cell whose source moved on needs a review")
    func aMovedSourceNeedsAReview() throws {
        var store = DocumentStore(document: world())
        let source = SourceID("source:brief")
        var document = store.document
        document.sources.add(SourceReference(
            id: source, kind: .text, title: "Brief", locator: "file:///tmp/brief",
            revisions: [SourceRevision(
                id: "rev:1", sequence: 1, extraction: .ready(text: "three days"), digest: "d1"
            )]
        ))
        store.replace(with: document)
        let id = try start(criteria: [measured()], in: &store)

        var recorded = Cell(
            criterionID: "criterion:cost", directionID: crm, value: .number(3),
            references: [.init(kind: .source, id: source.rawValue)],
            recordedBy: ActorID("local-user")
        )
        recorded.referenceRevisions[source.rawValue] = "rev:1"
        _ = try store.apply([.recordComparisonCell(.init(
            comparisonID: id, cell: recorded, provenance: .human("local-user")
        ))])
        #expect(store.document.comparisons.comparison(id)?.needsReview(in: store.document) == nil)

        // The file changes. The cell was recorded against the old version of it.
        _ = try store.apply([.importSourceRevision(.init(
            sourceID: source,
            revision: SourceRevision(
                id: "rev:2", sequence: 2, extraction: .ready(text: "one day"), digest: "d2"
            ),
            provenance: .human("local-user")
        ))])
        #expect(store.document.comparisons.comparison(id)?.needsReview(in: store.document) == .evidenceMoved)
    }

    // MARK: AC03 keeping does not delete the other directions

    @Test("Keeping one direction removes nothing")
    func keepingRemovesNothing() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured(), unmeasured()], in: &store)
        _ = try store.apply([
            cell("criterion:cost", crm, .number(3)),
            cell("criterion:cost", csv, .number(1)),
            cell("criterion:feel", csv, .text("plain")),
        ])
        let before = try #require(store.document.comparisons.comparison(id))

        _ = try store.apply([.keepDirection(.init(
            comparisonID: id, directionID: csv, provenance: .human("local-user")
        ))])
        let after = try #require(store.document.comparisons.comparison(id))

        #expect(after.keptDirectionIDs == [csv])
        #expect(after.isKept(csv))
        #expect(after.isKept(crm) == false)
        // Every cell, of both directions, is still there. Keeping is not choosing
        // over the others; it is saying which one to work on next.
        #expect(after.cells.count == before.cells.count)
        #expect(after.cell(criterion: "criterion:feel", direction: csv)?.value.text == "plain")
        #expect(after.cell(criterion: "criterion:cost", direction: crm)?.value.number == 3)
        // And the objects are untouched: a comparison records, it does not decide.
        #expect(store.document.content == world().content)
    }

    @Test("Keeping is explicit, repeatable and additive")
    func keepingIsAdditive() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], in: &store)
        for _ in 0..<2 {
            _ = try store.apply([.keepDirection(.init(
                comparisonID: id, directionID: crm, provenance: .human("local-user")
            ))])
        }
        #expect(store.document.comparisons.comparison(id)?.keptDirectionIDs == [crm])
    }

    @Test("Keeping something that is not a direction is refused")
    func keepingAnOutsiderIsRefused() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], in: &store)
        #expect(throws: DocumentError.notAComparisonDirection(id, ObjectID("object:context"))) {
            try store.apply([.keepDirection(.init(
                comparisonID: id, directionID: ObjectID("object:context"),
                provenance: .human("local-user")
            ))])
        }
    }

    // MARK: Correcting, and the refusals around it

    @Test("Correcting a cell replaces it and says who wrote it")
    func correctingACell() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], in: &store)
        _ = try store.apply([cell("criterion:cost", crm, .number(3))])
        _ = try store.apply([.recordComparisonCell(.init(
            comparisonID: id,
            cell: Cell(
                criterionID: "criterion:cost", directionID: crm, value: .number(1),
                note: "measured again on Tuesday",
                recordedBy: ActorID("local-user")
            ),
            provenance: .human("local-user")
        ))])
        let comparison = try #require(store.document.comparisons.comparison(id))
        // One cell, not two, and the correction carries who wrote it and why.
        #expect(comparison.cells.count == 1)
        #expect(comparison.cell(criterion: "criterion:cost", direction: crm)?.value.number == 1)
        #expect(comparison.cell(criterion: "criterion:cost", direction: crm)?.note == "measured again on Tuesday")
    }

    @Test("A comparison of one direction is refused")
    func aComparisonNeedsTwoDirections() throws {
        var store = DocumentStore(document: world())
        let comparison = Comparison(
            id: ComparisonID("comparison:lone"), title: "One", directionIDs: [crm]
        )
        #expect(throws: DocumentError.self) {
            try store.apply([.startComparison(.init(
                comparison: comparison, provenance: .human("local-user")
            ))])
        }
        #expect(store.document.comparisons.all().isEmpty)
    }

    @Test("A weight that is not a weight is refused")
    func anInvalidWeightIsRefused() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured()], in: &store)
        #expect(throws: DocumentError.self) {
            try store.apply([.setCriterionWeight(.init(
                comparisonID: id, criterionID: "criterion:cost", weight: -1,
                provenance: .human("local-user")
            ))])
        }
        #expect(store.document.comparisons.comparison(id)?.criterion("criterion:cost")?.weight == 1)
    }

    @Test("Intelligence is refused every comparison command")
    func intelligenceCannotRecordAComparison() throws {
        let document = world()
        for operation in [
            Command.startComparison(.init(
                comparison: Comparison(
                    id: ComparisonID("comparison:ai"), title: "Mine",
                    directionIDs: [crm, csv], criteria: [measured()]
                ),
                provenance: .human("local-user")
            )),
            .recordComparisonCell(.init(
                comparisonID: ComparisonID("comparison:ai"),
                cell: Cell(
                    criterionID: "criterion:cost", directionID: crm, value: .number(9),
                    recordedBy: ActorID("local-user")
                ),
                provenance: .human("local-user")
            )),
            .keepDirection(.init(
                comparisonID: ComparisonID("comparison:ai"), directionID: crm,
                provenance: .human("local-user")
            )),
            .setComparisonCriteria(.init(
                comparisonID: ComparisonID("comparison:ai"), criteria: [measured()],
                provenance: .human("local-user")
            )),
            .confirmComparisonCriteria(.init(
                comparisonID: ComparisonID("comparison:ai"),
                provenance: .human("local-user")
            )),
            .setCriterionWeight(.init(
                comparisonID: ComparisonID("comparison:ai"), criterionID: "criterion:cost",
                weight: 1, provenance: .human("local-user")
            )),
        ] {
            let proposal = Proposal(
                proposalId: "p1",
                requestId: "r1",
                documentId: document.documentId,
                baseSemanticRevision: document.semanticRevision,
                summary: LocalizedText("mine is better"),
                operations: [operation],
                generator: .init(name: "test", deterministic: true)
            )
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(
                    proposal, against: document, scope: .init(maxOperations: 32, allowNewObjects: true)
                )
            }
        }
    }

    // MARK: The format

    @Test("A document written before comparisons existed still opens")
    func legacyPayloadDecodes() throws {
        let legacy = """
        {
          "schemaVersion": 4,
          "documentId": "legacy",
          "revision": 0,
          "semanticRevision": 0,
          "createdAt": "2026-01-01T00:00:00.000Z",
          "updatedAt": "2026-01-01T00:00:00.000Z",
          "content": {},
          "relationships": {},
          "decisions": {},
          "contributions": {},
          "products": {},
          "presentation": { "instances": [] }
        }
        """
        let document = try DocumentCodec.decode(Data(legacy.utf8))
        // Absent is a document with no comparisons, not a broken one.
        #expect(document.comparisons.all().isEmpty)
    }

    @Test("A cell's value is written so a person can read it")
    func theValueIsGreppable() throws {
        var store = DocumentStore(document: world())
        _ = try start(criteria: [measured(), unmeasured()], in: &store)
        _ = try store.apply([
            cell("criterion:cost", crm, .number(3)),
            cell("criterion:feel", crm, .text("brittle")),
        ])
        let text = String(decoding: try DocumentCodec.encode(store.document), as: UTF8.self)
        // Not `{"number":{"_0":3}}`, which is what an enum with associated values
        // encodes to by synthesised conformance. The format is meant to be read.
        #expect(text.contains("\"kind\" : \"number\""))
        #expect(text.contains("\"kind\" : \"text\""))
        #expect(text.contains("\"_0\"") == false)
    }

    @Test("Comparisons survive a round trip, numbers and references included")
    func comparisonsRoundTrip() throws {
        var store = DocumentStore(document: world())
        let id = try start(criteria: [measured(), unmeasured()], in: &store)
        _ = try store.apply([
            cell("criterion:cost", crm, .number(3), references: [.init(kind: .object, id: crm.rawValue)]),
            cell("criterion:feel", csv, .text("plain")),
        ])
        _ = try store.apply([.keepDirection(.init(
            comparisonID: id, directionID: csv, provenance: .human("local-user")
        ))])

        let reloaded = try DocumentCodec.decode(try DocumentCodec.encode(store.document))
        #expect(reloaded.comparisons.comparison(id) == store.document.comparisons.comparison(id))
        #expect(reloaded.comparisons.comparison(id)?
            .cell(criterion: "criterion:cost", direction: crm)?.value.number == 3)
        // And the total is still not defined after a round trip, because one of the
        // two criteria is still unmeasured. Serialisation did not quietly invent it.
        #expect(reloaded.comparisons.comparison(id)?.total(for: crm) == nil)
    }
}
