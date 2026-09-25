import Foundation
import KollioCore

/// Which intelligence source the app talks to, and how honestly it can say so.
///
/// This is a development configuration, chosen by environment variable, not a
/// control panel on the canvas. There is deliberately no UI for it: the mode is
/// reported once, in the status line, and never silently changed.
///
/// Four modes, in the order of increasing consequence:
///
/// - `apple`  the on-device system model. No network, no key, no server. This is
///            the primary path when the model is actually available on this Mac.
/// - `demo`   the local deterministic engine. No network, no key, explicit.
/// - `server` the local Vapor backend. Which provider the server uses is the
///            server's business: `DemoProvider` or `GroqProvider` depending on
///            whether it was started with a key.
/// - the `KOLLIO_API_TOKEN` for the backend is the app's own token and lives in
///   the Keychain. It is never the provider key: a Groq key stays on the server
///   and never reaches the app or the repository.
public enum ServiceConfiguration: Equatable, Sendable {
    case apple
    case demo
    case server(baseURL: URL)

    public static let environmentKey = "KOLLIO_SERVICE"
    public static let serverURLKey = "KOLLIO_SERVER_URL"
    public static let defaultServerURL = URL(string: "http://127.0.0.1:8080")!

    /// A short, honest name for the status line. Never a promise of quality.
    public var label: String {
        switch self {
        case .apple: return "On this Mac"
        case .demo: return "demo (offline)"
        case .server: return "local server"
        }
    }

    public var requiresNetwork: Bool {
        switch self {
        case .apple, .demo: return false
        case .server: return true
        }
    }

    public var isDeterministic: Bool {
        switch self {
        case .apple: return false
        case .demo: return true
        // The server may be running either provider, so determinism is unknown
        // from here. Saying "unknown" is better than claiming either way.
        case .server: return false
        }
    }

    /// Resolves the mode from the environment, defaulting to the on-device model
    /// when it is genuinely usable, and to the offline engine otherwise.
    ///
    /// The fallback is stated, never silent: the app reports the real condition
    /// through `AppleLocalSuggestionService.availability` rather than pretending
    /// the demo engine is a model. A server mode without a token also falls back,
    /// and says so, because a silent fallback would look like the backend
    /// answered when it never was contacted.
    public static func fromEnvironment(
        _ values: [String: String] = ProcessInfo.processInfo.environment,
        token: String? = TokenStore.load(),
        appleIsUsable: Bool = SystemModelProbe().availability().isUsable
    ) -> (configuration: ServiceConfiguration, token: String?) {
        let raw = values[environmentKey]?.lowercased().trimmingCharacters(in: .whitespaces)
        switch raw {
        case "demo":
            return (.demo, nil)
        case "server":
            let urlString = values[serverURLKey]
            let url = urlString.flatMap(URL.init(string:)) ?? defaultServerURL
            guard let token, token.isEmpty == false else { return (.demo, nil) }
            return (.server(baseURL: url), token)
        case "apple":
            // Asked for explicitly. If the model is not usable, the app still
            // starts: it reports the reason and keeps the manual editor.
            return (.apple, nil)
        default:
            // No preference: prefer the real model, then the engine.
            return (appleIsUsable ? .apple : .demo, nil)
        }
    }
}
