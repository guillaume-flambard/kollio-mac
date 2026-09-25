import Foundation

/// Exactly what intelligence is about to be shown, and what it will not be shown.
///
/// CTX-06 asks for one thing above all: a person can see the root context, the
/// targets, the chosen sources, the decisions and the omissions before the answer
/// arrives, and the list matches the payload that was actually built. That is why
/// this is a value that is built once, measured, and then sent, rather than a
/// selection made in the interface and hoped to match later.
///
/// Three rules are structural rather than documentary:
///
/// - **Truncation is never silent.** Anything dropped is counted and named, and a
///   drop makes the projection incomplete.
/// - **A mandatory item is never dropped to fit.** If the required context does not
///   fit, the projection says so and asks for a narrower task. Quietly shrinking a
///   required constraint would let the model answer about something other than what
///   was asked.
/// - **Local-only is a fact, not a preference.** A projection marked `localOnly`
///   cannot be sent anywhere, and the type carries that as a value rather than
///   leaving it to whoever remembers to check.
public struct ContextProjection: Hashable, Sendable {
    public enum Item: Hashable, Sendable, Identifiable {
        case object(ObjectID)
        case decision(DecisionID)
        case source(SourceID)
        case citation(CitationID)

        public var id: String {
            switch self {
            case .object(let id): return "object:\(id.rawValue)"
            case .decision(let id): return "decision:\(id.rawValue)"
            case .source(let id): return "source:\(id.rawValue)"
            case .citation(let id): return "citation:\(id.rawValue)"
            }
        }
    }

    /// Why an item is not in the payload. A bare count would not be enough: the
    /// person deciding whether to retry needs to know whether the thing left out
    /// was optional.
    public enum Omission: Hashable, Sendable, Identifiable {
        case droppedForBudget(Item)
        case excludedByRequest(Item)
        case unavailable(Item)

        public var id: String { item.id }
        public var item: Item {
            switch self {
            case .droppedForBudget(let item),
                 .excludedByRequest(let item),
                 .unavailable(let item):
                return item
            }
        }
    }

    public var rootContext: [ObjectID]
    public var targets: [ObjectID]
    public var included: [Item]
    public var omissions: [Omission]
    /// Required references the payload does not contain. A non-empty list means the
    /// answer would be about something other than what was asked.
    public var missingRequired: [Item]
    /// Measured, never estimated: this is the size of what was actually built.
    public var measuredCharacters: Int
    public var budgetCharacters: Int
    /// Whether this context may leave the machine at all.
    public var locality: Locality

    public enum Locality: String, Hashable, Sendable {
        case localOnly
        case shareable
    }

    public init(
        rootContext: [ObjectID] = [],
        targets: [ObjectID] = [],
        included: [Item] = [],
        omissions: [Omission] = [],
        missingRequired: [Item] = [],
        measuredCharacters: Int = 0,
        budgetCharacters: Int = 0,
        locality: Locality = .localOnly
    ) {
        self.rootContext = rootContext
        self.targets = targets
        self.included = included
        self.omissions = omissions
        self.missingRequired = missingRequired
        self.measuredCharacters = measuredCharacters
        self.budgetCharacters = budgetCharacters
        self.locality = locality
    }

    /// Whether the answer will be about the whole request.
    ///
    /// Incomplete is not a failure state to be tolerated quietly. It is the signal
    /// to ask for a narrower task, and the interface is expected to say so rather
    /// than presenting a truncated understanding as a complete one.
    public var isComplete: Bool { missingRequired.isEmpty && omissions.isEmpty }

    /// Whether this payload may be handed to a remote provider.
    public var mayLeaveTheMachine: Bool { locality == .shareable }
}

/// Builds a `ContextProjection` and measures it, so the list a person sees is the
/// payload that was sent.
///
/// The budget is counted in characters on purpose. It is not tokens, because the
/// app cannot know the model's tokenizer, and a number that looks precise while
/// being a guess is worse than an honest unit. What matters is that the count is
/// real and that dropping something is always visible.
public struct ContextProjector: Sendable {
    public struct ItemCost: Sendable {
        public var item: ContextProjection.Item
        public var characters: Int
        /// A constraint, a target or the root context is not optional. Optional
        /// items are dropped to fit; required ones never are.
        public var isRequired: Bool

        public init(item: ContextProjection.Item, characters: Int, isRequired: Bool) {
            self.item = item
            self.characters = characters
            self.isRequired = isRequired
        }
    }

    public init() {}

    /// Projects the items that fit, and reports everything that did not.
    ///
    /// Order is the caller's: required items are considered first, so a budget
    /// spent on optional material never starves a constraint. Ties are broken by the
    /// order given, which keeps the result predictable between runs.
    public func project(
        rootContext: [ObjectID],
        targets: [ObjectID],
        costs: [ItemCost],
        budgetCharacters: Int,
        locality: ContextProjection.Locality
    ) -> ContextProjection {
        var requiredSeen: Set<ContextProjection.Item> = []
        var optionalItems: [ItemCost] = []
        var included: [ContextProjection.Item] = []
        var omissions: [ContextProjection.Omission] = []
        var missingRequired: [ContextProjection.Item] = []
        var used = 0

        for target in targets { requiredSeen.insert(.object(target)) }
        for id in rootContext { requiredSeen.insert(.object(id)) }

        // Required first, in the order given. Anything that does not fit is not
        // silently lost: the projection is incomplete and says what is missing.
        for cost in costs where cost.isRequired {
            if used + cost.characters <= budgetCharacters {
                used += cost.characters
                included.append(cost.item)
            } else {
                missingRequired.append(cost.item)
            }
        }

        // Then whatever optional material still fits. Omitting an optional item
        // makes the projection incomplete too, but in a weaker way: it is recorded
        // as a budget drop rather than as a missing requirement.
        for cost in costs where cost.isRequired == false {
            if used + cost.characters <= budgetCharacters {
                used += cost.characters
                included.append(cost.item)
            } else {
                omissions.append(.droppedForBudget(cost.item))
            }
        }

        return ContextProjection(
            rootContext: rootContext,
            targets: targets,
            included: included,
            omissions: omissions.sorted { $0.id < $1.id },
            missingRequired: missingRequired,
            measuredCharacters: used,
            budgetCharacters: budgetCharacters,
            locality: locality
        )
    }
}
