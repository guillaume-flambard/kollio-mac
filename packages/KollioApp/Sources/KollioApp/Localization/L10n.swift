import Foundation

/// Every user-facing string in the interface, in French and English.
///
/// Strings live in a native String Catalog (`Resources/Localizable.xcstrings`).
/// Keys are semantic, never shown. User-authored document content is *not*
/// translated when the interface language changes: only the interface is.
/// Anchor used to find the app bundle when the code is not built by SwiftPM.
private final class BundleToken {}

public enum L10n {
    /// The catalog lives in a resource bundle under SwiftPM, and in the app
    /// bundle under Xcode. One accessor serves both build systems.
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }

    static func callAsFunction(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), table: "Localizable", bundle: bundle)
    }

    // Canvas actions
    public static var explore: String { callAsFunction("canvas.explore") }
    public static var add: String { callAsFunction("canvas.add") }
    public static var setAside: String { callAsFunction("canvas.setAside") }
    public static var keep: String { callAsFunction("canvas.keep") }
    public static var reopen: String { callAsFunction("canvas.reopen") }
    public static var clarify: String { callAsFunction("canvas.clarify") }
    public static var proposal: String { callAsFunction("canvas.proposal") }
    public static var setAsideReason: String { callAsFunction("canvas.setAsideReason") }
    public static var cancel: String { callAsFunction("canvas.cancel") }

    // First experience
    public static var initialTitle: String { callAsFunction("document.initialPrompt") }
    public static var initialSubtitle: String { callAsFunction("document.initialSubtitle") }
    public static var initialPlaceholder: String { callAsFunction("document.initialPlaceholder") }
    public static var seedDirectionA: String { callAsFunction("seed.directionA") }
    public static var seedDirectionB: String { callAsFunction("seed.directionB") }
    public static var seedDirectionAEN: String { callAsFunction("seed.directionA.en") }
    public static var seedDirectionBEN: String { callAsFunction("seed.directionB.en") }

    // Composer
    public static var composerPlaceholder: String { callAsFunction("composer.placeholder") }
    public static var composerAddPlaceholder: String { callAsFunction("composer.addPlaceholder") }
    public static var composerHint: String { callAsFunction("composer.hint") }
    public static var composerSetAsidePlaceholder: String { callAsFunction("composer.setAsidePlaceholder") }
    public static var composerSetAsideHint: String { callAsFunction("composer.setAsideHint") }

    // Status
    public static var statusNoChange: String { callAsFunction("status.noChange") }
    public static var statusKept: String { callAsFunction("status.kept") }
    public static var statusDiscarded: String { callAsFunction("status.discarded") }
    public static var statusSaved: String { callAsFunction("status.saved") }
    public static var statusThinking: String { callAsFunction("status.thinking") }
    public static var errorGeneric: String { callAsFunction("error.generic") }
    public static var errorSaveFailed: String { callAsFunction("error.saveFailed") }

    // Undo labels
    public static var undoMove: String { callAsFunction("undo.move") }
    public static var undoKeepProposal: String { callAsFunction("undo.keepProposal") }
    public static var undoSetAside: String { callAsFunction("undo.setAside") }
    public static var undoReopen: String { callAsFunction("undo.reopen") }

    // Menu
    public static var newDocument: String { callAsFunction("menu.newDocument") }
    public static var openDemo: String { callAsFunction("menu.openDemo") }
    public static var save: String { callAsFunction("menu.save") }
    public static var fit: String { callAsFunction("menu.fit") }
    public static var actualSize: String { callAsFunction("menu.actualSize") }
    public static var undo: String { callAsFunction("menu.undo") }
    public static var redo: String { callAsFunction("menu.redo") }
}
