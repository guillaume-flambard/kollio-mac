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

/// A named frame around part of the canvas.
///
/// CAN-07 calls a frame a **presentation concern**, and this type is the reason
/// that is true rather than aspirational: it lives in `Presentation`, it holds no
/// object of its own, and every command that touches it is presentation-only, so
/// folding or moving one cannot move `semanticRevision` and cannot change what the
/// document says.
///
/// Two decisions are baked in here, both of them from the same paragraph of the
/// specification:
///
/// - **Members are occurrences, not objects.** "Moving the frame moves its
///   occurrences", and CAN-03 already separates an occurrence from an object. A
///   frame holding an object id would move every drawing of that object, including
///   the one somebody deliberately put on another branch. Holding instance ids
///   keeps the other occurrences independent, which is AC03 stated once.
/// - **Folding hides those occurrences in this view and nothing else.** It is not a
///   decision, so `lifecycle` is untouched, the text is untouched, the citations are
///   untouched, and a drawing of the same object outside the frame stays on the
///   canvas.
public struct Frame: Codable, Hashable, Sendable, Identifiable {
    public var id: FrameID
    public var name: LocalizedText
    public var position: Position
    /// The occurrences this frame holds, explicitly. Never inferred from
    /// containment: two frames may overlap and a person may belong to both.
    public var memberInstanceIDs: [InstanceID]
    /// Set when the frame is folded. Folding is a view state, not a decision.
    public var isFolded: Bool
    /// There is deliberately **no cached size** here. The first version had one, and
    /// it was a second copy of a rectangle the canvas already measures from the
    /// members, free to disagree with them after any move. The frame is drawn from
    /// its members every time instead.

    public init(
        id: FrameID,
        name: LocalizedText,
        position: Position,
        memberInstanceIDs: [InstanceID] = [],
        isFolded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.memberInstanceIDs = memberInstanceIDs
        self.isFolded = isFolded
    }

    public func contains(_ instanceID: InstanceID) -> Bool {
        memberInstanceIDs.contains(instanceID)
    }
}

public struct FrameID: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable, ExpressibleByStringLiteral, KollioIdentifier {
    public init(stringLiteral value: String) { self.rawValue = value }
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var idString: String { rawValue }
    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Layout only. Hover, focus, drag and selection are editor-session state and
/// must never be written to a `.kollio` file.
public struct Presentation: Codable, Hashable, Sendable {
    public var instances: [NodeInstance]
    /// The named frames drawn behind the nodes. Absent in a file written before
    /// CAN-07, which is a canvas with no frames on it rather than a broken one, so
    /// it decodes to an empty list instead of failing.
    public var frames: [Frame]

    public init(instances: [NodeInstance] = [], frames: [Frame] = []) {
        self.instances = instances
        self.frames = frames
    }

    private enum CodingKeys: String, CodingKey {
        case instances, frames
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instances = try container.decode([NodeInstance].self, forKey: .instances)
        // A default in an *initializer* would not be a migration; this is the same
        // idiom the rest of the format uses for a key added later.
        frames = try container.decodeIfPresent([Frame].self, forKey: .frames) ?? []
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

    // MARK: Frames

    public func frame(_ id: FrameID) -> Frame? {
        frames.first { $0.id == id }
    }

    /// The frame a drawing belongs to, if any. An occurrence can be in one frame
    /// only: two overlapping frames may both contain the same *object*, but never
    /// the same drawing, or a fold would have to guess which one to hide.
    public func frame(containing instanceID: InstanceID) -> Frame? {
        frames.first { $0.contains(instanceID) }
    }

    /// The frame an object is drawn inside, addressing its first instance, which is
    /// what a person means by "put this in a frame".
    public func frame(of objectID: ObjectID) -> Frame? {
        instance(for: objectID).flatMap { frame(containing: $0.id) }
    }

    public func framesSorted() -> [Frame] {
        frames.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public mutating func setFrame(_ frame: Frame) {
        if let index = frames.firstIndex(where: { $0.id == frame.id }) {
            frames[index] = frame
        } else {
            frames.append(frame)
        }
    }

    public mutating func removeFrame(_ id: FrameID) {
        frames.removeAll { $0.id == id }
    }

    /// The instances a frame hides because it is folded. Only the occurrences it
    /// holds, which is what makes "an object shared elsewhere stays visible" true
    /// without any special case.
    public func hiddenInstanceIDs() -> Set<InstanceID> {
        Set(frames.filter(\.isFolded).flatMap(\.memberInstanceIDs))
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
