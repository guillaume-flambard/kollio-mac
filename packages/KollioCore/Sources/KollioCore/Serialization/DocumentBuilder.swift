import Foundation

/// Fluent construction of a document. Used by the first experience, by fixtures,
/// and by tests. Everything still goes through validated commands, so a document
/// built here is indistinguishable from one built by user interaction.
public struct DocumentBuilder {
    public private(set) var store: DocumentStore

    public init(document: KollioDocument = KollioDocument()) {
        self.store = DocumentStore(document: document)
    }

    public var document: KollioDocument { store.document }

    public static let human = Provenance.human(ActorID("local-user"))

    public mutating func addContribution(_ contribution: ContributionRecord) {
        var document = store.document
        document.contributions[contribution.id] = contribution
        store.replace(with: document)
    }

    @discardableResult
    public mutating func object(
        _ seed: String,
        kind: ContentObject.Kind,
        _ text: String,
        en: String? = nil,
        detail: String? = nil,
        detailEN: String? = nil,
        at position: Position = .zero,
        contribution: ActorID? = nil,
        provenance: Provenance = DocumentBuilder.human
    ) -> ObjectID? {
        let id = KollioID.object(seed)
        var variants: [String: String] = [:]
        if let en { variants["en"] = en }
        var detailVariants: [String: String] = [:]
        if let detailEN { detailVariants["en"] = detailEN }
        let command = Command.createObject(CreateObject(
            id: id,
            kind: kind,
            text: LocalizedText(text, variants: variants),
            detail: detail.map { LocalizedText($0, variants: detailVariants) },
            contributionID: contribution,
            position: position,
            provenance: provenance
        ))
        return apply(command) ? id : nil
    }

    @discardableResult
    public mutating func link(
        _ seed: String,
        from: ObjectID,
        to: ObjectID,
        _ kind: Relationship.Kind,
        label: String? = nil,
        labelEN: String? = nil,
        provenance: Provenance = DocumentBuilder.human
    ) -> Bool {
        var variants: [String: String] = [:]
        if let labelEN { variants["en"] = labelEN }
        return apply(.addRelationship(AddRelationship(
            id: KollioID.relationship(seed),
            from: from,
            to: to,
            kind: kind,
            label: label.map { LocalizedText($0, variants: variants) },
            provenance: provenance
        )))
    }

    @discardableResult
    public mutating func apply(_ command: Command) -> Bool {
        do {
            try store.apply([command])
            return true
        } catch {
            assertionFailure("DocumentBuilder command failed: \(error)")
            return false
        }
    }

    @discardableResult
    public mutating func move(_ instanceID: InstanceID, to position: Position) -> Bool {
        apply(.moveNodeInstances(MoveNodeInstances(moves: [.init(instanceID: instanceID, position: position)])))
    }

    @discardableResult
    public mutating func setAside(
        _ seed: String,
        target: ObjectID,
        rationale: String,
        rationaleEN: String? = nil,
        at date: Date = Date()
    ) -> Bool {
        var variants: [String: String] = [:]
        if let rationaleEN { variants["en"] = rationaleEN }
        let id = KollioID.decision(seed)
        let command = Command.recordDecision(RecordDecision(
            id: id,
            kind: .setAside,
            targetObjectID: target,
            rationale: LocalizedText(rationale, variants: variants),
            provenance: Self.human
        ))
        do {
            try store.apply([command], at: date)
            return true
        } catch {
            assertionFailure("DocumentBuilder decision failed: \(error)")
            return false
        }
    }

    /// Marks a created object as set aside with a durable reason, and reopens it.
    @discardableResult
    public mutating func reopen(_ seed: String, target: ObjectID, at date: Date = Date()) -> Bool {
        do {
            try store.apply([.recordDecision(RecordDecision(
                id: KollioID.decision(seed),
                kind: .reopened,
                targetObjectID: target,
                provenance: Self.human
            ))], at: date)
            return true
        } catch {
            assertionFailure("DocumentBuilder reopen failed: \(error)")
            return false
        }
    }
}
