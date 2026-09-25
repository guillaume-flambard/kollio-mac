import Foundation
import Vapor
import KollioCore

/// Everything the server needs from its environment.
///
/// No secret is ever hardcoded: the API token is either provided or generated
/// for this process. The provider key is optional, and its absence simply keeps
/// the remote provider disabled.
public struct ServerConfiguration: Sendable {
    public var bindAddress: String
    public var port: Int
    /// Opaque bearer token shared with the macOS client.
    public var apiToken: String
    public var tokenWasGenerated: Bool
    public var maxRequestBodyBytes: Int
    /// One live intelligence request per principal at a time.
    public var maxConcurrentRequests: Int
    public var providerTimeout: Duration
    public var groqAPIKey: String?
    public var groqModel: String

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        generateToken: () -> String = { String(UUID().uuidString) }
    ) {
        bindAddress = environment["KOLLIO_BIND"] ?? "127.0.0.1"
        port = Int(environment["KOLLIO_PORT"] ?? "8080") ?? 8080
        if let provided = environment["KOLLIO_API_TOKEN"], !provided.isEmpty {
            apiToken = provided
            tokenWasGenerated = false
        } else {
            apiToken = generateToken()
            tokenWasGenerated = true
        }
        maxRequestBodyBytes = 256 * 1024
        maxConcurrentRequests = 1
        providerTimeout = .seconds(20)
        groqAPIKey = environment["KOLLIO_GROQ_API_KEY"].flatMap { $0.isEmpty ? nil : $0 }
        // Verified against the provider's model list before the provider was
        // written; change it here, never in a view.
        groqModel = environment["KOLLIO_GROQ_MODEL"] ?? "openai/gpt-oss-120b"
    }

    public var groqIsEnabled: Bool { groqAPIKey != nil }
}

/// One live request at a time per principal, and no unbounded queue.
public actor RequestGate {
    private var inFlight: Int = 0
    private let limit: Int

    public init(limit: Int) {
        self.limit = limit
    }

    public func acquire() -> Bool {
        guard inFlight < limit else { return false }
        inFlight += 1
        return true
    }

    public func release() {
        inFlight = Swift.max(0, inFlight - 1)
    }
}

/// Track of the requests that were cancelled, so a late result cannot be
/// mistaken for a live one.
public actor RequestRegistry {
    private var cancelled: Set<String> = []
    private var live: Set<String> = []

    public init() {}

    public func open(_ id: String) {
        live.insert(id)
    }

    public func cancel(_ id: String) {
        live.remove(id)
        cancelled.insert(id)
    }

    public func finish(_ id: String) {
        live.remove(id)
    }

    public func isCancelled(_ id: String) -> Bool {
        cancelled.contains(id)
    }

    public func liveCount() -> Int { live.count }
}
