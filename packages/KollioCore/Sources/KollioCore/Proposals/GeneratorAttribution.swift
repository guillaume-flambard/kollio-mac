import Foundation

/// Where a proposal came from, in words a person can act on.
///
/// This exists because the failure it prevents is not theoretical. A local model
/// failing silently into a remote one, or a demonstration answering as though it
/// were the product, are both worse than a refusal, because a person acts on the
/// answer. The destination is therefore named, always, and the four names are not
/// interchangeable:
///
/// - **On this Mac.** The answer never left the machine.
/// - **Apple Private Cloud.** Authorised, and off the machine. Not reachable today,
///   and saying it exists in the interface before it works would be the exact lie
///   this type is here to prevent.
/// - **Remote service.** Somebody else's machine, and a different privacy contract.
/// - **Demonstration.** Not an answer at all, and the label has to survive into the
///   proposal rather than staying in a menu.
///
/// The label is metadata. A client that declares `onDeviceApple` proves nothing
/// cryptographically, and a type whose comment implied otherwise would be worse
/// than no attribution at all.
public enum ProposalDestination: String, Codable, Hashable, Sendable, CaseIterable {
    case onDeviceApple
    case privateCloud
    case remoteService
    case demonstration

    /// Whether the content of the proposal crossed a machine boundary.
    ///
    /// The one question a person actually needs answered before repeating anything
    /// from a proposal to someone else.
    public var leftThisMachine: Bool {
        switch self {
        case .onDeviceApple, .demonstration: return false
        case .privateCloud, .remoteService: return true
        }
    }

    /// True when the destination is implemented and usable in this build.
    ///
    /// Private Cloud is a real Apple API and is not wired up, so it is reported as
    /// unavailable rather than offered. An interface that lists a destination the
    /// product cannot reach is a lie with a menu on it.
    public var isAvailableInThisBuild: Bool {
        switch self {
        case .onDeviceApple, .demonstration: return true
        case .privateCloud, .remoteService: return false
        }
    }

    public var isPrivate: Bool {
        switch self {
        case .onDeviceApple, .privateCloud: return true
        case .remoteService, .demonstration: return false
        }
    }
}

/// Everything a person is entitled to know about how a proposal was produced.
///
/// Four things, and the absence of a fifth is the design. A prompt, a chain of
/// reasoning and an API key are all things a person can be shown and should not
/// be: the first two are noise, and the third is a secret. So this type has no
/// field that could carry any of them, and a test asserts that a rendered
/// attribution never contains one.
public struct GeneratorAttribution: Codable, Hashable, Sendable {
    public var name: String
    public var model: String?
    /// Which of the app's prompt revisions asked the question.
    ///
    /// A proposal whose prompt version is unknown is still shown, with the gap
    /// stated. Dropping it would lose the reason the answer looks the way it does,
    /// and inventing one would be worse.
    public var promptVersion: String?
    public var destination: ProposalDestination
    /// True for the offline demo and for anything else that answers the same way
    /// every time.
    public var isDeterministic: Bool

    public init(
        name: String,
        model: String? = nil,
        promptVersion: String? = nil,
        destination: ProposalDestination,
        isDeterministic: Bool
    ) {
        self.name = name
        self.model = model
        self.promptVersion = promptVersion
        self.destination = destination
        self.isDeterministic = isDeterministic
    }

    /// A client-declared label. Metadata, never a proof: this cannot be used to
    /// assert that a proposal was produced on this machine, only that the client
    /// said so.
    public var isSelfDeclared: Bool { true }

    /// Carried over from the older three-field generator so a stored proposal from
    /// before this type existed still reads. The destination is inferred from the
    /// generator's own determinism, which is the only signal the old record has, and
    /// the interface says the prompt version is unknown rather than hiding it.
    public init(from generator: Proposal.Generator) {
        self.init(
            name: generator.name,
            model: generator.model,
            promptVersion: nil,
            destination: generator.deterministic ? .demonstration : .onDeviceApple,
            isDeterministic: generator.deterministic
        )
    }
}

/// One thing the generator was shown, and whether it is still there.
///
/// A reference to something the document no longer holds is kept and marked
/// unavailable. Dropping it would quietly change the meaning of a proposal: it
/// would look as though the generator had read less than it did, and the person
/// reading the attribution would draw a false conclusion about what informed the
/// answer.
public struct ProposalInputRef: Codable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case object
        case source
        case sourceRevision
        case decision
        case citation
    }

    public var id: String
    public var kind: Kind
    /// A short, safe description of what was read. A label, never the content: a
    /// proposal that pasted the text of a source into its own record would be a
    /// copy of somebody's document living somewhere it was not asked to be.
    public var label: String
    /// False when the thing is no longer in the document.
    public var isAvailable: Bool

    public init(id: String, kind: Kind, label: String, isAvailable: Bool = true) {
        self.id = id
        self.kind = kind
        self.label = label
        self.isAvailable = isAvailable
    }
}

extension ProposalInputRef {
    /// Checks a reference against the document and records whether it is still there.
    ///
    /// Kept rather than dropped, and marked, because a proposal that quietly lost
    /// a reference would read as though the generator had been shown less than it
    /// was — and a person deciding whether to trust an answer is deciding exactly
    /// that. An unavailable reference is a fact about the document, not a defect in
    /// the proposal.
    public static func resolve(
        _ id: String,
        kind: Kind,
        label: String,
        in document: KollioDocument
    ) -> ProposalInputRef {
        let isAvailable: Bool
        switch kind {
        case .object:
            isAvailable = document.content[ObjectID(id)] != nil
        case .source:
            isAvailable = document.sources.source(SourceID(id)) != nil
        case .sourceRevision:
            isAvailable = document.sources.sources.values.contains { $0.revision(SourceRevisionID(id)) != nil }
        case .decision:
            isAvailable = document.decisions[DecisionID(id)] != nil
        case .citation:
            isAvailable = document.sources.citation(CitationID(id)) != nil
        }
        return ProposalInputRef(id: id, kind: kind, label: label, isAvailable: isAvailable)
    }

    /// Resolves a whole list, in the order given, because the order the generator
    /// read things in is part of what it read.
    public static func resolveAll(
        _ refs: [(id: String, kind: Kind, label: String)],
        in document: KollioDocument
    ) -> [ProposalInputRef] {
        refs.map { resolve($0.id, kind: $0.kind, label: $0.label, in: document) }
    }
}
