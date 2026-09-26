import Foundation
import AppKit
import Testing
import KollioCore
@testable import KollioApp

/// CAN-05, "Create, duplicate, remove".
///
/// The chapter turns on one distinction the product keeps making everywhere else:
/// an *occurrence* is something drawn, an *object* is something said. Duplicate and
/// delete each exist twice, once for each, and the two are never the same gesture.
/// The tests below hold that line from both sides.
@Suite("CAN-05: create, duplicate, remove")
@MainActor
struct CreatingAndRemovingTests {
    private func makeModel() -> (KollioModel, URL) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-can05-\(UUID().uuidString)")
        return (
            KollioModel(document: SarahFixture.document(),
                        service: KollioModel.makeDemoService(languageCode: "fr"),
                        fileStore: DocumentFileStore(directory: directory)),
            directory
        )
    }

    private let csv = KollioID.object("sarah-csv")
    private let crm = KollioID.object("sarah-crm")

    // MARK: Creating without a category

    @Test("An idea is written down before its kind is known")
    func anIdeaNeedsNoCategory() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        let id = try! #require(model.createIdea("Une idée dont je ne sais pas encore la nature", near: csv))
        let created = try! #require(model.object(id))

        // The point of the kind: it is a real, nameable state, not nil and not a
        // guess dressed up as a category.
        #expect(created.kind == .unclear)
        #expect(created.text.text == "Une idée dont je ne sais pas encore la nature")
        // It is drawn near what it was written next to, not at the origin.
        #expect(model.document.presentation.instance(for: id)?.position
                != model.document.presentation.instance(for: csv)?.position)
    }

    @Test("Creating an idea never asks a model")
    func creatingIsLocal() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        // A service that would fail loudly if it were consulted. Creating an idea
        // must not depend on Apple Intelligence being available, and must not turn
        // an unavailable model into a network call (invariant 7).
        let exploding = ExplodingSuggestionService()
        let local = KollioModel(document: SarahFixture.document(), service: exploding,
                                fileStore: DocumentFileStore(directory: directory))
        #expect(local.createIdea("Une idée locale", near: csv) != nil)
        #expect(exploding.callCount == 0)
    }

    @Test("An empty idea is not created")
    func anEmptyIdeaIsNotCreated() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let before = model.document.content.count
        #expect(model.createIdea("   \n ", near: csv) == nil)
        #expect(model.document.content.count == before)
    }

    // MARK: Occurrence and variant are different things

    @Test("Duplicating an occurrence draws it twice and says it once")
    func duplicatingAnOccurrenceKeepsTheObject() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let objectsBefore = model.document.content.count
        let relationshipsBefore = model.document.relationships.count
        let revisionBefore = model.document.semanticRevision

        let original = try! #require(model.document.presentation.instance(for: csv))
        let copy = try! #require(model.duplicateOccurrence(of: original.id))

        // Two drawings...
        #expect(model.document.presentation.instances(of: csv).count == 2)
        // ...of one object, which is the whole claim.
        #expect(model.document.content.count == objectsBefore)
        #expect(model.document.relationships.count == relationshipsBefore)
        // Nothing semantic moved, so this is not a claim about the world.
        #expect(model.document.semanticRevision == revisionBefore)
        #expect(model.document.presentation.instance(id: copy)?.objectID == csv)
        // And the copy is visible rather than hidden under the original.
        #expect(model.document.presentation.instance(id: copy)?.position != original.position)
    }

    @Test("A variant is a new object that says where it came from")
    func aVariantIsANewObject() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        let variant = try! #require(model.duplicateAsVariant(of: crm))
        #expect(variant != crm)
        #expect(model.object(variant)?.text.text == model.object(crm)?.text.text)

        // The link is the reason a variant is not a copy: the document can still
        // answer why this exists.
        let link = try! #require(
            model.document.relationships.values.first { $0.kind == .derivedFrom }
        )
        #expect(link.from == variant)
        #expect(link.to == crm)
        // A variant is a claim, so unlike an occurrence it moves semanticRevision.
        #expect(model.document.semanticRevision > 0)
    }

    @Test("Changing a variant leaves the idea it came from alone")
    func aVariantIsIndependent() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        let variant = try! #require(model.duplicateAsVariant(of: crm))
        let originalText = try! #require(model.object(crm)).text.text
        #expect(model.applyEdit(to: variant, text: "Une autre piste"))

        #expect(model.object(crm)?.text.text == originalText)
    }

    @Test("A variant starts at version zero, not at the version it was copied from")
    func aVariantStartsFresh() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(model.applyEdit(to: crm, text: "Une version modifiée"))
        #expect(model.object(crm)?.objectVersion == 1)

        let variant = try! #require(model.duplicateAsVariant(of: crm))
        // Inheriting the version would make the copy look stale against text it was
        // never written against.
        #expect(model.object(variant)?.objectVersion == 0)
    }

    // MARK: AC01, and the reason the two duplicates are not the same command

    /// A document with somebody else's contribution in the ledger and a product
    /// that shares revenue with them.
    ///
    /// Seeded rather than built through commands, because there is no command that
    /// registers a contribution: `addContributionToProduct` only adds a share to a
    /// contribution that is already there. That gap is owed and recorded; it does not
    /// affect AC01, which is about what duplication does to a ledger that exists.
    private func modelWithRoyalties(
        _ directory: URL
    ) -> (KollioModel, ActorID, ObjectID) {
        let owner = ActorID("actor:diane")
        let product = ObjectID("object:product")
        let contributed = ObjectID("object:contributed")

        var document = SarahFixture.document()
        document.contributions[owner] = ContributionRecord(
            id: owner, name: "Diane", kind: .method, owner: owner
        )
        document.products[product] = ProductComposition(
            id: product,
            name: LocalizedText("Le produit"),
            memberContributionIDs: [owner],
            shares: [owner.rawValue: 0.4]
        )
        let model = KollioModel(
            document: document,
            service: KollioModel.makeDemoService(languageCode: "fr"),
            fileStore: DocumentFileStore(directory: directory)
        )
        _ = model.perform([
            .createObject(CreateObject(
                id: contributed, kind: .method, text: LocalizedText("Une méthode réutilisable"),
                contributionID: owner, position: Position(x: 0, y: 600),
                provenance: Provenance(actor: owner, kind: .human)
            ))
        ], label: "contribution")
        return (model, owner, product)
    }

    @Test("AC01: duplicating does not double royalties")
    func duplicatingDoesNotDoubleRoyalties() {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-can05-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let (model, owner, product) = modelWithRoyalties(directory)

        let sharesBefore = try! #require(model.document.products[product]?.shares)
        let membersBefore = try! #require(model.document.products[product]?.memberContributionIDs)
        #expect(sharesBefore[owner.rawValue] == 0.4)
        #expect(model.document.contributions.count == 1)

        let contributed = ObjectID("object:contributed")
        let instance = try! #require(model.document.presentation.instance(for: contributed))

        // Drawing it a second time, and saying it again as a variant.
        _ = model.duplicateOccurrence(of: instance.id)
        _ = model.duplicateAsVariant(of: contributed)

        // One owner, one record, one membership, one share. Putting the same thing
        // in two places, and saying it twice, does not entitle its author to twice
        // the revenue: the ledger counts contributions, not appearances.
        #expect(model.document.contributions.count == 1)
        #expect(model.document.products[product]?.shares == sharesBefore)
        #expect(model.document.products[product]?.memberContributionIDs == membersBefore)
        #expect(model.document.products[product]?.share(for: owner) == 0.4)
        #expect(model.document.contributions[owner]?.owner == owner)
    }

    @Test("A copy points at the same contribution instead of minting an author")
    func aCopyIsAReferenceNotASecondAuthor() {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-can05-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let (model, owner, _) = modelWithRoyalties(directory)

        let contributed = ObjectID("object:contributed")
        let instance = try! #require(model.document.presentation.instance(for: contributed))
        _ = model.duplicateOccurrence(of: instance.id)
        _ = model.duplicateAsVariant(of: contributed)

        // Two objects now refer to Diane's contribution, and the ledger still has
        // exactly one record of her.
        let referring = model.document.content.values.filter { $0.contributionID == owner }
        #expect(referring.count == 2)
        #expect(model.document.contributions.count == 1)
    }

    // MARK: AC02, undo restoring links and positions

    @Test("AC02: undo restores the links a variant added")
    func undoRestoresLinks() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let relationshipsBefore = model.document.relationships.count
        let objectsBefore = model.document.content.count

        _ = model.duplicateAsVariant(of: crm)
        #expect(model.document.relationships.count == relationshipsBefore + 1)

        model.undo()
        // Both halves go: the new object *and* the link that explained it. A link
        // left pointing at a removed object would be a document that lies.
        #expect(model.document.relationships.count == relationshipsBefore)
        #expect(model.document.content.count == objectsBefore)
        #expect(model.document.relationships.values.allSatisfy { $0.from != crm || $0.to != crm }
                || model.document.relationships.count == relationshipsBefore)
    }

    @Test("AC02: undo restores the positions a duplicate moved nothing of")
    func undoRestoresPositions() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let positionsBefore = Dictionary(
            uniqueKeysWithValues: model.document.presentation.instances.map { ($0.id, $0.position) }
        )

        let original = try! #require(model.document.presentation.instance(for: csv))
        _ = model.duplicateOccurrence(of: original.id)
        #expect(model.document.presentation.instances.count == positionsBefore.count + 1)

        model.undo()
        // The original is exactly where it was, and the copy is gone. Not "roughly
        // where it was": the same position, so a restored world looks untouched.
        #expect(Dictionary(
            uniqueKeysWithValues: model.document.presentation.instances.map { ($0.id, $0.position) }
        ) == positionsBefore)
    }

    @Test("AC02: undo of a removal puts the idea and its drawing back")
    func undoRestoresARemovedOccurrence() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        // Two occurrences, so one of them can go: removing the last one is a
        // different decision and is refused, which the next test covers.
        let first = try! #require(model.document.presentation.instance(for: csv))
        let second = try! #require(model.duplicateOccurrence(of: first.id))
        let countBefore = model.document.presentation.instances(of: csv).count

        let secondPosition = try! #require(model.document.presentation.instance(id: second)).position
        #expect(model.removeOccurrence(second))
        #expect(model.document.presentation.instances(of: csv).count == countBefore - 1)
        #expect(model.object(csv) != nil)

        model.undo()
        // The drawing comes back where it was, not merely somewhere.
        #expect(model.document.presentation.instances(of: csv).count == countBefore)
        let restored = try! #require(model.document.presentation.instance(id: second))
        #expect(restored.position == secondPosition)
        #expect(restored.objectID == csv)
    }

    // MARK: Removing an occurrence and removing the idea

    @Test("Removing an occurrence keeps the idea")
    func removingAnOccurrenceKeepsTheIdea() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try! #require(model.document.presentation.instance(for: csv))
        let second = try! #require(model.duplicateOccurrence(of: first.id))

        let secondPosition = try! #require(model.document.presentation.instance(id: second)).position
        #expect(model.removeOccurrence(second))
        #expect(model.object(crm) != nil)
        #expect(model.object(first.objectID) != nil)
        #expect(model.document.presentation.instances(of: csv).count == 1)
    }

    @Test("Removing the idea takes its links and its drawings with it")
    func removingTheIdeaTakesItsLinks() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let linksBefore = model.document.relationships.values.filter { $0.from == crm || $0.to == crm }

        #expect(model.removeFromDocument(crm))
        #expect(model.object(crm) == nil)
        #expect(model.document.presentation.instance(for: crm) == nil)
        // The links are gone rather than left pointing at nothing.
        #expect(linksBefore.isEmpty == false)
        #expect(model.document.relationships.values.allSatisfy { $0.from != crm && $0.to != crm })
    }

    @Test("The last drawing of an idea is refused rather than hiding the idea")
    func theLastOccurrenceIsRefused() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let only = try! #require(model.document.presentation.instance(for: csv))

        // Removing it would leave a node nothing draws, and the next save would
        // write a document nobody can see. That is a decision to remove the idea, so
        // it has to be taken as one.
        #expect(model.removeOccurrence(only.id) == false)
        #expect(model.object(csv) != nil)
        #expect(model.document.presentation.instance(id: only.id) != nil)
    }

    @Test("An idea a decision points at is not removed out from under the decision")
    func anObjectWithADecisionIsProtected() async {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        // Set aside is a durable decision, not a deletion, and it keeps its memory.
        model.setAside(csv, reason: "Pas maintenant")
        #expect(model.document.decisions.values.contains { $0.targetObjectID == csv })

        // Removing the object would orphan a record that says something happened
        // here. The decision is revoked first, by a person.
        #expect(model.removeFromDocument(csv) == false)
        #expect(model.object(csv) != nil)
    }

    // MARK: The two removals ask, and the question says which is which

    @Test("The two removals are separate entries whose labels say what they lose")
    func theTwoRemovalsAreWrittenOut() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        let set = model.contextualActions(for: csv)

        // Two entries, never one "Delete".
        #expect(set.contains(.removeOccurrence))
        #expect(set.contains(.removeObject))
        #expect(set.secondary.contains(.removeObject))

        // Each label says what happens to the idea, which is the difference the
        // specification asks to be written in the menu.
        #expect(L10n.actionRemoveOccurrence != L10n.actionRemoveObject)
        #expect(L10n.actionKeepOccurrence != L10n.actionLoseIdea)
        #expect(L10n.actionDuplicateOccurrence != L10n.actionDuplicateVariant)

        // Presentation-only actions are labelled as such, so the menu can group them
        // and a confirmation can tell them apart.
        #expect(set.reach(of: .removeOccurrence) == .presentation)
        #expect(set.reach(of: .removeObject) == .meaning)
        #expect(set.reach(of: .duplicateOccurrence) == .presentation)
        #expect(set.reach(of: .duplicateVariant) == .meaning)
    }

    @Test("The question is asked before either removal, and cancelling changes nothing")
    func theQuestionComesFirst() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        model.requestRemoveFromDocument(crm)
        #expect(model.pendingRemoval == crm)
        // Asking is not doing.
        #expect(model.object(crm) != nil)

        model.resolvePendingRemoval(keepingIdea: true)
        #expect(model.pendingRemoval == nil)
        #expect(model.object(crm) != nil)

        model.requestRemoveFromDocument(crm)
        model.resolvePendingRemoval(keepingIdea: false)
        #expect(model.object(crm) == nil)
    }

    @Test("Intelligence is refused both removals")
    func intelligenceCannotRemove() {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        // A proposal that deletes is not a bounded addition, it is a decision, and
        // the only actor allowed to take it is the person whose thinking it removes.
        for command in [
            Command.removeObject(RemoveObject(id: csv)),
            .removeNodeInstance(RemoveNodeInstance(
                instanceID: model.document.presentation.instance(for: csv)!.id
            ))
        ] {
            let proposal = makeProposal(in: model.document, operations: [command])
            #expect(throws: DocumentError.self) {
                try ProposalValidator().validate(
                    proposal, against: model.document, scope: ProposalRequest.Scope()
                )
            }
        }
    }

    @Test("Intelligence may make a variant, charged against its budget")
    func intelligenceMayMakeAVariant() throws {
        let (model, directory) = makeModel()
        defer { try? FileManager.default.removeItem(at: directory) }

        let variant = ObjectID("object:variant-by-model")
        let proposal = makeProposal(in: model.document, operations: [
            .duplicateObject(DuplicateObject(
                sourceID: crm, id: variant,
                instanceID: InstanceID("instance:variant-by-model"),
                relationshipID: RelationshipID("relationship:variant-by-model"),
                provenance: Provenance(actor: ActorID("local-engine"), kind: .localEngine,
                                        requestId: UUID().uuidString)
            ))
        ])
        try ProposalValidator().validate(
            proposal, against: model.document, scope: ProposalRequest.Scope()
        )
    }
}

/// A proposal against a real document, built the way the adapters build one, so
/// the validator sees a well-formed patch rather than a convenient stub.
private func makeProposal(in document: KollioDocument, operations: [Command]) -> Proposal {
    Proposal(
        proposalId: UUID().uuidString,
        requestId: UUID().uuidString,
        documentId: document.documentId,
        baseSemanticRevision: document.semanticRevision,
        summary: LocalizedText("Une proposition"),
        operations: operations,
        generator: Proposal.Generator(name: "test", deterministic: true)
    )
}

/// A service that fails the test if it is ever asked. Used to prove that creating
/// an idea is local: the point is not that a model is available, it is that
/// writing down your own idea never depends on one.
private final class ExplodingSuggestionService: SuggestionService, @unchecked Sendable {
    private(set) var callCount = 0
    let capabilities = SuggestionCapabilities.offline

    func respond(
        to request: ProposalRequest,
        document: KollioDocument
    ) async throws -> ProposalResponse {
        callCount += 1
        throw DocumentError.forbiddenOperation("this service exists only to fail")
    }
}
