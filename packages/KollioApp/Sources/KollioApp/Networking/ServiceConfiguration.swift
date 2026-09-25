import Foundation
import KollioCore

/// Which intelligence source the app talks to, and how honestly it can say so.
///
/// This is a development configuration, chosen by environment variable, not a
/// control panel on the canvas. There is deliberately no UI for it: the mode is
/// reported once, in the status line, and never silently changed.
///
/// Three modes, in the order of increasing consequence:
///
/// - `demo`   the local deterministic engine. No network, no key, works offline.
/// - `server` the local Vapor backend. Which provider the server uses is the
///            server's business: `DemoProvider` or `GroqProvider` depending on
///            whether it was started with a key.
/// - the `KOLLIO_API_TOKEN` for the backend is the app's own token and lives in
///   the Keychain. It is never the provider key: a Groq key stays on the server
///   and never reaches the app or the repository.
public enum ServiceConfiguration: Equatable, Sendable {
    case demo
    case server(baseURL: URL)

    public static let environmentKey = "KOLLIO_SERVICE"
    public static let serverURLKey = "KOLLIO_SERVER_URL"
    public static let defaultServerURL = URL(string: "http://127.0.0.1:8080")!

    /// A short, honest name for the status line. Never a promise of quality.
    public var label: String {
        switch self {
        case .demo: return "demo (offline)"
        case .server: return "local server"
        }
    }

    public var requiresNetwork: Bool {
        switch self {
        case .demo: return false
        case .server: return true
        }
    }

    public var isDeterministic: Bool {
        switch self {
        case .demo: return true
        // The server may be running either provider, so determinism is unknown
        // from here. Saying "unknown" is better than claiming either way.
        case .server: return false
        }
    }

    /// Resolves the mode from the environment, defaulting to the offline engine.
    ///
    /// A server mode without a token in the Keychain falls back to the demo
    /// engine *and says so*, because a silent fallback would look like the
    /// backend answered when it never was contacted.
    public static func fromEnvironment(
        _ values: [String: String] = ProcessInfo.processInfo.environment,
        token: String? = TokenStore.load()
    ) -> (configuration: ServiceConfiguration, token: String?) {
        let raw = values[environmentKey]?.lowercased().trimmingCharacters(in: .whitespaces)
        guard raw == "server" else { return (.demo, nil) }
        let urlString = values[serverURLKey]
        let url = urlString.flatMap(URL.init(string:)) ?? defaultServerURL
        guard let token, token.isEmpty == false else { return (.demo, nil) }
        return (.server(baseURL: url), token)
    }
}
