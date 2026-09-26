import Foundation
import KollioCore

/// The actions a selected object offers, split into what is shown and what is
/// behind the single named secondary control.
///
/// `SPECIFICATIONS.md` §Surfaces U02 fixes the primary set for an ordinary idea —
/// Explore, Add, Set aside — and names a secondary menu for the rest. The
/// requirement "contextual actions are few, named and reachable" adds the shape:
/// at most three primary, everything else behind one named entry.
///
/// The set lives here, in the model, rather than in the view, for one reason: a
/// limit that only exists as a layout is a limit nobody can test. This is the
/// only place that decides which actions an object has, and `maximumPrimary` is
/// checked here rather than hoped for in a `HStack`.
public struct ContextualActionSet: Hashable, Sendable {
    /// How many primary actions may be shown at once. Three is the specification's
    /// number, not a preference.
    public static let maximumPrimary = 3

    public enum Role: Hashable, Sendable {
        /// Shown as a button next to the object.
        case primary
        /// Reached through the one named secondary control.
        case secondary
    }

    public enum Kind: Hashable, Sendable, CaseIterable {
        case explore
        case add
        case setAside
        case reopen
        case edit
        case addSource
        case assertClaim
        case link
        case comment
        case duplicate

        /// The French and English label lives in `L10n`, not here, so the String
        /// Catalog stays the only place an interface string is written.
        public var localizationKey: String {
            switch self {
            case .explore: return "explore"
            case .add: return "clarify"
            case .setAside: return "setAside"
            case .reopen: return "reopen"
            case .edit: return "edit"
            case .addSource: return "addSource"
            case .assertClaim: return "claimComposerPrompt"
            case .link: return "link"
            case .comment: return "comment"
            case .duplicate: return "duplicate"
            }
        }
    }

    public let primary: [Kind]
    public let secondary: [Kind]
    /// The one action a person is most likely to want, and the only one drawn
    /// with the accent fill.
    public let isDefault: Kind?

    public init(primary: [Kind], secondary: [Kind], isDefault: Kind? = nil) {
        // The limit is enforced here rather than by a caller remembering it. A
        // fourth primary action is a programming error, not a layout problem, so
        // it is refused instead of silently demoted.
        precondition(
            primary.count <= Self.maximumPrimary,
            "\(primary.count) primary actions for one object; the specification allows \(Self.maximumPrimary)."
        )
        self.primary = primary
        self.secondary = secondary
        self.isDefault = isDefault
    }

    public func contains(_ kind: Kind) -> Bool {
        primary.contains(kind) || secondary.contains(kind)
    }

    /// The set for an object the model can act on.
    ///
    /// A set-aside direction offers exactly one thing, because there is only one
    /// thing to do with it. Everything else is the ordinary case.
    public static func forObject(
        id: ObjectID,
        kind: ContentObject.Kind,
        canReopen: Bool,
        canAttachSource: Bool,
        canAssertClaim: Bool
    ) -> ContextualActionSet {
        if canReopen {
            return ContextualActionSet(primary: [.reopen], secondary: [], isDefault: .reopen)
        }

        // Primary: the three the specification names for an ordinary idea.
        var secondary: [Kind] = [.edit]
        if canAttachSource { secondary.append(.addSource) }
        if canAssertClaim { secondary.append(.assertClaim) }
        // Not implemented yet, so not offered. A disabled button is worse than an
        // absent one, and the specification forbids a decorative action.
        //
        // if linked { secondary.append(.link) }
        // if discussable { secondary.append(.comment) }
        // if duplicable { secondary.append(.duplicate) }

        return ContextualActionSet(
            primary: [.explore, .add, .setAside],
            secondary: secondary,
            isDefault: .explore
        )
    }
}
