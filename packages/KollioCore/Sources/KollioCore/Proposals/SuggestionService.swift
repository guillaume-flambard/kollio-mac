import Foundation

/// What an intelligence source can do, reported to the client so the UI never
/// offers an intent the current source cannot honour.
public struct SuggestionCapabilities: Codable, Hashable, Sendable {
    public var intents: [ProposalRequest.Intent]
    public var deterministic: Bool
    public var requiresNetwork: Bool

    public init(
        intents: [ProposalRequest.Intent],
        deterministic: Bool,
        requiresNetwork: Bool
    ) {
        self.intents = intents
        self.deterministic = deterministic
        self.requiresNetwork = requiresNetwork
    }

    public static let offline = SuggestionCapabilities(
        intents: ProposalRequest.Intent.allCases,
        deterministic: true,
        requiresNetwork: false
    )
}

/// Source of proposals. The app works with no network at all: the offline demo
/// implementation and the remote server implementation are interchangeable.
public protocol SuggestionService: Sendable {
    var capabilities: SuggestionCapabilities { get }
    func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse
}
