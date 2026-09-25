import Foundation
import KollioCore

#if canImport(FoundationModels)
import FoundationModels
#endif

/// How the on-device adapter is doing, stated without guessing.
///
/// The distinction the brief insists on, made concrete: an SDK being present
/// says nothing about a model being usable, and "local" is ambiguous for an API
/// that forwards to the internet. So the mode is named by where the inference
/// actually happens.
public enum AppleModelAvailability: Equatable, Sendable {
    /// Usable right now.
    case available
    /// This Mac is not eligible.
    case deviceNotEligible
    /// The system intelligence setting is off. The app never changes it.
    case intelligenceDisabled
    /// Eligible, but the assets are not on disk yet.
    case assetsNotReady
    /// The framework itself is not present in this build.
    case frameworkUnavailable
    /// The language the document is in is not supported by the loaded model.
    case unsupportedLanguage(String)

    public var isUsable: Bool { self == .available }

    /// An honest, localized-worded description. Never a guess: each case maps to
    /// a reason the framework actually reported.
    public var explanation: String {
        switch self {
        case .available:
            return "On this Mac"
        case .deviceNotEligible:
            return "This Mac is not eligible for on-device intelligence."
        case .intelligenceDisabled:
            return "System intelligence is turned off. Turn it on in System Settings if you want on-device proposals."
        case .assetsNotReady:
            return "The on-device model is still being prepared. Try again shortly."
        case .frameworkUnavailable:
            return "This build has no on-device model support."
        case .unsupportedLanguage(let language):
            return "The on-device model does not support \(language)."
        }
    }
}

/// Reads the real availability of the system model.
///
/// Kept behind a protocol so the deterministic tests can exercise every
/// unavailable state without a Mac that has Apple Intelligence switched off.
public protocol AppleModelProbing: Sendable {
    func availability() -> AppleModelAvailability
    /// How many tokens the loaded model's whole context holds, when known.
    func contextSize() -> Int?
    func supports(languageCode: String) -> Bool
}

#if canImport(FoundationModels)
/// The real probe. Every branch comes from an enum case the SDK actually
/// declares, so no more precise a diagnostic is claimed than the API returns.
public struct SystemModelProbe: AppleModelProbing {
    public init() {}

    @available(macOS 26.0, *)
    private var model: SystemLanguageModel { .default }

    public func availability() -> AppleModelAvailability {
        guard #available(macOS 26.0, *) else { return .frameworkUnavailable }
        switch model.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .deviceNotEligible
            case .appleIntelligenceNotEnabled: return .intelligenceDisabled
            case .modelNotReady: return .assetsNotReady
            // A reason this build does not know about is reported as "not
            // ready" rather than being flattened into a wrong diagnosis.
            @unknown default: return .assetsNotReady
            }
        }
    }

    public func contextSize() -> Int? {
        guard #available(macOS 26.0, *) else { return nil }
        return model.contextSize
    }

    public func supports(languageCode: String) -> Bool {
        guard #available(macOS 26.0, *) else { return false }
        return model.supportsLocale(Locale(identifier: languageCode))
    }
}
#else
/// Built without the framework: every call is honestly "no support", and the
/// app keeps working with manual editing and an explicit demo mode.
public struct SystemModelProbe: AppleModelProbing {
    public init() {}
    public func availability() -> AppleModelAvailability { .frameworkUnavailable }
    public func contextSize() -> Int? { nil }
    public func supports(languageCode: String) -> Bool { false }
}
#endif

/// A probe with a fixed answer, for tests and for the deterministic suite.
public final class StubAppleModelProbe: AppleModelProbing, @unchecked Sendable {
    private let lock = NSLock()
    private let answer: AppleModelAvailability
    private let context: Int?
    private let languages: Set<String>

    public init(availability: AppleModelAvailability, contextSize: Int? = 8192, languages: Set<String> = ["fr", "en"]) {
        self.answer = availability
        self.context = contextSize
        self.languages = languages
    }

    public func availability() -> AppleModelAvailability { lock.withLock { answer } }
    public func contextSize() -> Int? { lock.withLock { context } }
    public func supports(languageCode: String) -> Bool { lock.withLock { languages.contains(languageCode) } }
}
