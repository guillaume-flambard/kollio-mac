import Foundation
import Testing
@testable import KollioCore

/// CAN-10: the path, and what is left of it once the document has moved on.
///
/// The criteria are AC01 a complete keyboard path, AC02 exit returns to the
/// previous context, and AC03 no model call to present. Two of those three are
/// about the view and are proved in `PresentationInterfaceTests`. What is here is
/// the part the view cannot be trusted with: the order, the resolution, and above
/// all the promise that a point which is gone is skipped and never quietly
/// replaced by something else.
@Suite("Reading path")
struct ReadingPathTests {
    private let csv = KollioID.object("sarah-csv")
    private let crm = KollioID.object("sarah-crm")
    private let viable = KollioID.object("sarah-viable")
    private let blocked = KollioID.object("sarah-blocked")
    private let context = KollioID.object("sarah-context")

    private func store() throws -> DocumentStore {
        var store = DocumentStore(document: Fixture.sarah())
        try store.apply([.recordDecision(.init(
            id: "decision:crm",
            kind: .setAside,
            targetObjectID: crm,
            rationale: LocalizedText(
                "Pas de budget pour l'API avant mars",
                variants: ["en": "No budget for the API before March"]
            ),
            provenance: .human("me")
        ))])
        try store.apply([.attachSource(.init(
            source: SourceReference(
                id: SourceID("source:brief"), kind: .text,
                title: "Brief signup", locator: "file:///tmp/brief.md"
            ),
            attachedTo: csv,
            provenance: .human("me")
        ))])
        return store
    }

    @Test("The path is the order, and a title is a label rather than the content")
    func thePathIsTheOrder() throws {
        let document = try store().document
        let resolved = ReadingPath(objects: [csv, crm]).resolved(in: document, languageCode: "fr")
        #expect(resolved.entries.map(\.point) == [.object(csv), .object(crm)])
        #expect(resolved.entries[0].label == "Export CSV depuis l’outil source")
        // A label, never the whole object: a tour that quoted a document back at the
        // person is a second copy of it in a place nobody asked for one.
        for entry in resolved.entries {
            #expect(entry.label.count <= 62)
            #expect(entry.anchorObjectID != nil)
        }
    }

    @Test("The same document gives the same tour twice")
    func theTourIsDeterministic() throws {
        let document = try store().document
        let first = ReadingPath.automatic(in: document).points
        for _ in 0..<5 {
            #expect(ReadingPath.automatic(in: document).points == first)
        }
        // And it starts where a person starts: at the context.
        #expect(first.first == .object(context))
        // Evidence and reasoning are points too. A tour that could not open either
        // is not a presentation of the document.
        #expect(first.contains(.source(SourceID("source:brief"))))
        #expect(first.contains(.decision(DecisionID("decision:crm"))))
    }

    @Test("A tour reaches a branch and the constraint that blocks it")
    func theTourFollowsTheRelationships() throws {
        let document = try store().document
        let objects = ReadingPath.automatic(in: document).points.compactMap { point -> ObjectID? in
            if case .object(let id) = point { return id }
            return nil
        }
        // Both of the CRM's neighbours are in there: a tour of the relationships,
        // not a sort of the identifiers.
        #expect(objects.contains(blocked))
        #expect(objects.contains(viable))
        #expect(Set(objects).count == objects.count, "an object was visited twice")
    }

    @Test("A point that is gone is skipped, and never replaced by another object")
    func aDeletedPointIsSkipped() throws {
        var store = try store()
        let path = ReadingPath(objects: [csv, viable, blocked])
        // The middle point stops existing after the path was chosen. The CRM
        // direction cannot be used here: the domain refuses to remove the target of
        // a decision, and a reading tour has no business undoing that rule to make
        // a test easier.
        try store.apply([.removeObject(.init(id: viable))])
        let resolved = path.resolved(in: store.document, languageCode: "fr")

        // The two that are still there keep their places, in order.
        #expect(resolved.entries.map(\.point) == [.object(csv), .object(blocked)])
        // And the gap is a gap, named by its identifier. A tour that quietly showed
        // the next object in the gap's place would be showing something the reader
        // never asked to read.
        #expect(resolved.skipped.map(\.point) == [.object(viable)])
        #expect(resolved.isPartial)
        #expect(resolved.requested == 3)
        #expect(resolved.count == 2)
        // The entry that follows the gap is the one that was always third, carrying
        // its own label and not a substitute for the second.
        #expect(resolved.entries.map(\.label) == [
            "Export CSV depuis l’outil source",
            "Identifiants API indisponibles",
        ])
    }

    @Test("A source nothing cites is still a point, with nothing to stand on")
    func aSourceNothingCitesHasNoAnchor() throws {
        var store = try store()
        try store.apply([.removeObject(.init(id: csv))])
        let entry = try #require(
            ReadingPath(points: [.source(SourceID("source:brief"))])
                .resolved(in: store.document, languageCode: "fr")
                .entries.first
        )
        // The source is still readable; there is simply nothing on the canvas to
        // centre it on, and the card says so rather than the view moving nowhere.
        #expect(entry.label == "Brief signup")
        #expect(entry.anchorObjectID == nil)
    }

    @Test("A decision is shown at the direction it decided")
    func aDecisionIsAnchoredOnItsTarget() throws {
        let entry = try #require(
            ReadingPath(points: [.decision(DecisionID("decision:crm"))])
                .resolved(in: try store().document, languageCode: "en")
                .entries.first
        )
        // The reasoning is shown next to the thing it is reasoning about, and in
        // the language being read.
        #expect(entry.anchorObjectID == crm)
        #expect(entry.label == "No budget for the API before March")
    }

    @Test("A decision in French is read in French")
    func aDecisionIsReadInTheLanguageBeingRead() throws {
        let entry = try #require(
            ReadingPath(points: [.decision(DecisionID("decision:crm"))])
                .resolved(in: try store().document, languageCode: "fr")
                .entries.first
        )
        #expect(entry.label == "Pas de budget pour l'API avant mars")
    }

    @Test("A point of each kind is gone when its thing is gone")
    func everyKindCanGoMissing() throws {
        let resolved = ReadingPath(points: [
            .object(csv), .source(SourceID("source:nothing")), .decision(DecisionID("decision:nothing")),
        ]).resolved(in: Fixture.sarah(), languageCode: "fr")
        #expect(resolved.entries.map(\.point) == [.object(csv)])
        #expect(resolved.skipped.count == 2)
        #expect(resolved.isPartial)
    }

    @Test("An empty path resolves to nothing, and asked for nothing")
    func anEmptyPathIsEmpty() throws {
        let resolved = ReadingPath(points: []).resolved(in: try store().document)
        #expect(resolved.isEmpty)
        #expect(resolved.isPartial == false)
        #expect(resolved.requested == 0)
    }

    @Test("A chosen path is a path, and a point can be asked about on its own")
    func chosenPathsArePaths() {
        let a = KollioID.object("a")
        let path = ReadingPath(points: [.object(a), .source("b")])
        #expect(path.contains(.object(a)))
        #expect(path.contains(.source("b")))
        #expect(path.contains(.object(KollioID.object("c"))) == false)
        #expect(path.isEmpty == false)
        #expect(ReadingPath(points: []).isEmpty)
        // The identifier of a point carries its kind, so a gap can be named without
        // knowing which of the three it was.
        #expect(ReadingPath.Point.source("x").id == "source:x")
        #expect(ReadingPath.Point.decision("x").kind == .decision)
        #expect(ReadingPath.Point.object(a).id == "object:a")
    }

    @Test("A bare string literal is not the identifier the document uses")
    func aBareLiteralIsNotAnIdentifier() {
        // Recorded because it cost a debugging round in this very file, and it will
        // cost one again: `ObjectID` is `ExpressibleByStringLiteral`, so a literal
        // is taken verbatim, and `"sarah-csv"` is not `object:sarah-csv`. A path
        // built from bare literals therefore resolves to nothing, silently.
        #expect(ObjectID("sarah-csv") != KollioID.object("sarah-csv"))
        #expect(KollioID.object("sarah-csv").rawValue == "object:sarah-csv")
        let resolved = ReadingPath(objects: [ObjectID("sarah-csv")])
            .resolved(in: Fixture.sarah(), languageCode: "fr")
        #expect(resolved.entries.isEmpty)
    }
}
