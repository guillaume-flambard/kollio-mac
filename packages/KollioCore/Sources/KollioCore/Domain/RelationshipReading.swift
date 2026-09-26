import Foundation

/// What a relationship says, in a sentence, with both ends named.
///
/// CAN-06 asks for a link to be understandable rather than merely visible: a
/// person should be able to read what it means and which way it points without
/// interpreting an arrow. The sentence is therefore derived from the relationship
/// and the two objects, never stored beside it, so it cannot drift from what the
/// link actually is.
public struct RelationshipSentence: Hashable, Sendable {
    public var subject: String
    public var verb: String
    public var object: String
    public var qualifier: String?

    /// "The CRM constrains the CSV export", in the interface's language.
    public var text: String {
        let base = "\(subject) \(verb) \(object)"
        return qualifier.map { "\(base) (\($0))" } ?? base
    }

    /// What a person needs in order to act on it: which end is the source.
    public var direction: Direction { subject == object ? .unclear : .fromSubjectToObject }

    public enum Direction: String, Hashable, Sendable {
        case fromSubjectToObject
        case unclear
    }
}

/// How a relationship may be edited, and what that costs.
///
/// CAN-06: "Editing changes the meaning explicitly, not just the arrow." A swap of
/// the two ends is the most dangerous edit in the document, because the two objects
/// look identical before and after and the sentence inverts. It is therefore a
/// named operation with a precondition rather than a drag.
public enum RelationshipEdit: Codable, Hashable, Sendable {
    case retitle(LocalizedText)
    case reverse
    case changeKind(Relationship.Kind)

    /// The precondition, if any. A reverse whose ends are not the same pair is
    /// refused rather than applied to whatever happens to be there.
    public func precondition(for relationship: Relationship) -> RelationshipEditPrecondition? {
        switch self {
        case .retitle, .changeKind:
            return nil
        case .reverse:
            return RelationshipEditPrecondition.sameEnds(relationship.from, relationship.to)
        }
    }
}

public enum RelationshipEditPrecondition: Codable, Hashable, Sendable {
    /// The reverse may only apply to the pair it was requested for.
    case sameEnds(ObjectID, ObjectID)
    case objectMissing(ObjectID)
    case selfRelation
    case duplicate(RelationshipID)

    /// The ends an edit is allowed to produce, when it has any.
    public var ends: (ObjectID, ObjectID)? {
        if case .sameEnds(let first, let second) = self { return (first, second) }
        return nil
    }

    /// Whether the link in hand is the one this precondition was written for.
    public func isSatisfied(_ relationship: Relationship) -> Bool {
        switch self {
        case .sameEnds(let first, let second):
            // Either the link already has these ends, or it has the other order
            // and the edit is the swap that produces them.
            return (relationship.from, relationship.to) == (first, second)
                || (relationship.from, relationship.to) == (second, first)
        case .objectMissing:
            return true
        case .selfRelation:
            return relationship.from != relationship.to
        case .duplicate(let other):
            return relationship.id != other
        }
    }
}

public extension Relationship {
    /// The sentence this link says, given the two objects it joins.
    ///
    /// Returns nil rather than a partial sentence when an endpoint is not in the
    /// document. A sentence with a missing end reads as a fact about something that
    /// is not there, which is worse than saying nothing.
    func sentence(
        in document: KollioDocument,
        languageCode: String,
        includeQualifier: Bool = true
    ) -> RelationshipSentence? {
        guard let from = document.object(from), let to = document.object(to) else { return nil }
        let subject = from.text.resolve(languageCode: languageCode)
        let object = to.text.resolve(languageCode: languageCode)
        return RelationshipSentence(
            subject: subject,
            verb: kind.verb(languageCode: languageCode),
            object: object,
            qualifier: includeQualifier ? label?.resolve(languageCode: languageCode) : nil
        )
    }

    /// How wide a pointer has to be for this link to be catchable.
    ///
    /// CAN-06: "The hit area exceeds the stroke." A 1-point line is not a target,
    /// especially at low zoom, and the area has to grow as the view shrinks so a
    /// link stays as easy to catch as a node.
    func hitArea(zoom: Double) -> Double {
        let stroke: Double = 1.5
        let minimum: Double = 18
        // At high zoom the stroke is already wide enough on screen; at low zoom the
        // minimum is what keeps it catchable.
        return max(stroke * 2, minimum / max(zoom, 0.2))
    }
}

public extension Relationship.Kind {
    /// The verb, in the interface's language.
    ///
    /// English and French are not translations of each other here: the verb is what
    /// makes the direction readable, so it is chosen per language rather than
    /// derived from a name.
    func verb(languageCode: String) -> String {
        let french = languageCode == "fr"
        switch self {
        case .addresses: return french ? "traite" : "addresses"
        case .uses: return french ? "utilise" : "uses"
        case .dependsOn: return french ? "dépend de" : "depends on"
        case .constrains: return french ? "contraint" : "constrains"
        case .supports: return french ? "appuie" : "supports"
        case .contradicts: return french ? "contredit" : "contradicts"
        case .alternativeTo: return french ? "est une alternative à" : "is an alternative to"
        case .derivedFrom: return french ? "découle de" : "comes from"
        case .associatedWith: return french ? "est lié à" : "is linked to"
        }
    }

    /// Every kind a person can choose, in the order the interface offers them.
    static func choosable(languageCode: String) -> [Relationship.Kind] {
        allCases
    }
}


public extension KollioDocument {
    /// The link already saying this exact thing, if there is one.
    ///
    /// CAN-06: "A duplicate of the same kind and endpoints reveals the existing
    /// one." Not refused with an error, because a refusal tells a person nothing
    /// about what they just collided with; the caller is handed the link to go and
    /// look at.
    func existingRelationship(
        kind: Relationship.Kind,
        from: ObjectID,
        to: ObjectID
    ) -> Relationship? {
        relationships.values
            .filter { $0.kind == kind && $0.from == from && $0.to == to }
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .first
    }
}
