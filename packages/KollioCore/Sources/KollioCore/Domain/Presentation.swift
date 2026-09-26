import Foundation

/// One visual instance of a semantic object.
///
/// A single object can have several instances (the same contribution shown in two
/// products). Moving an instance is presentation-only: it never bumps the
/// semantic revision and never creates a contribution.
public struct NodeInstance: Codable, Hashable, Sendable, Identifiable {
    public var id: InstanceID
    public var objectID: ObjectID
    public var position: Position
    /// Optional explicit size. When nil, the renderer measures the content.
    public var size: Size?
    /// Set when the instance is hidden because an ancestor of its object was set
    /// aside, or because a proposal is only being previewed.
    public var hidden: Bool

    public init(id: InstanceID, objectID: ObjectID, position: Position, size: Size? = nil, hidden: Bool = false) {
        self.id = id
        self.objectID = objectID
        self.position = position
        self.size = size
        self.hidden = hidden
    }
}

/// Layout only. Hover, focus, drag and selection are editor-session state and
/// must never be written to a `.kollio` file.
public struct Presentation: Codable, Hashable, Sendable {
    public var instances: [NodeInstance]

    public init(instances: [NodeInstance] = []) {
        self.instances = instances
    }

    public func instance(for objectID: ObjectID) -> NodeInstance? {
        instances.first { $0.objectID == objectID }
    }

    public func instance(id: InstanceID) -> NodeInstance? {
        instances.first { $0.id == id }
    }

    /// Every instance of one object.
    ///
    /// `instance(for:)` answers with the *first* instance, which is what a canvas
    /// wants when it needs "where is this object drawn". It is the wrong answer for
    /// a move: CAN-03 says "moving an occurrence does not move its other
    /// occurrences", so anything that addresses a place on the canvas has to be
    /// able to say which occurrence it means.
    public func instances(of objectID: ObjectID) -> [NodeInstance] {
        instances.filter { $0.objectID == objectID }
    }
}

/// A product assembling reusable contributions. Provenance for later revenue
/// sharing is preserved in the domain, but the prototype never surfaces it.
public struct ProductComposition: Codable, Hashable, Sendable, Identifiable {
    public var id: ObjectID
    public var name: LocalizedText
    public var memberContributionIDs: [ActorID]
    /// Fraction of the eventual revenue attributed to each contribution.
    /// Always 0 in the prototype; preserved so nothing is lost in the format.
    public var shares: [String: Double]

    public init(id: ObjectID, name: LocalizedText, memberContributionIDs: [ActorID] = [], shares: [String: Double] = [:]) {
        self.id = id
        self.name = name
        self.memberContributionIDs = memberContributionIDs
        self.shares = shares
    }

    public func share(for contribution: ActorID) -> Double {
        shares[contribution.rawValue] ?? 0
    }
}
