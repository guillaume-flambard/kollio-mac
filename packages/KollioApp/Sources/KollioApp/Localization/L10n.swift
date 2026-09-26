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
    public static var moreActions: String { callAsFunction("canvas.moreActions") }
    public static var keep: String { callAsFunction("canvas.keep") }
    /// The action that centres the view on a proposal that is off screen. It is
    /// never automatic: a camera that moves by itself takes the view away.
    public static var seeProposal: String { callAsFunction("action.seeProposal") }
    public static var seeProposalHint: String { callAsFunction("action.seeProposalHint") }
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
    public static var composerEditPlaceholder: String { callAsFunction("composer.editPlaceholder") }
    public static var edit: String { callAsFunction("canvas.edit") }
    public static var composerSetAsidePlaceholder: String { callAsFunction("composer.setAsidePlaceholder") }
    public static var composerSetAsideHint: String { callAsFunction("composer.setAsideHint") }

    // Sources
    public static var sourceReadFailed: String { callAsFunction("source.readFailed") }
    public static var addSource: String { callAsFunction("source.add") }
    public static var addSourceHint: String { callAsFunction("source.addHint") }
    public static var undoAttachSource: String { callAsFunction("undo.attachSource") }
    public static var undoRecordVerification: String { callAsFunction("undo.recordVerification") }
    public static var undoAddCitation: String { callAsFunction("undo.addCitation") }
    public static var claimScopeEmpty: String { callAsFunction("claim.scopeEmpty") }
    public static var undoAssertClaim: String { callAsFunction("undo.assertClaim") }
    public static var undoRecordStance: String { callAsFunction("undo.recordStance") }
    public static var statusAnswerSuperseded: String { callAsFunction("status.answerSuperseded") }
    public static var retry: String { callAsFunction("action.retry") }
    public static var retryHint: String { callAsFunction("action.retryHint") }
    public static var cancelHint: String { callAsFunction("action.cancelHint") }
    public static var undoAskClarification: String { callAsFunction("undo.askClarification") }
    public static var undoAnswerClarification: String { callAsFunction("undo.answerClarification") }
    public static var undoMarkUnknown: String { callAsFunction("undo.markUnknown") }
    public static var clarificationEmpty: String { callAsFunction("clarification.empty") }
    public static var clarificationAnswerPlaceholder: String { callAsFunction("clarification.answerPlaceholder") }
    public static var clarificationAnswer: String { callAsFunction("clarification.answer") }
    public static var clarificationUnknown: String { callAsFunction("clarification.unknown") }
    public static var clarificationUnknownHint: String { callAsFunction("clarification.unknownHint") }
    public static var clarificationUnknownDone: String { callAsFunction("clarification.unknownDone") }
    public static func claimScopeTitle(default object: String) -> String {
        String(format: callAsFunction("claim.scopeTitle"), object)
    }
    public static var claimStateHypothesis: String { callAsFunction("claim.hypothesis") }
    public static var claimStateConstraint: String { callAsFunction("claim.constraint") }
    public static var claimStateOpen: String { callAsFunction("claim.open") }
    public static var claimStateSupported: String { callAsFunction("claim.supported") }
    public static var claimStateContradicted: String { callAsFunction("claim.contradicted") }
    public static var claimStateRefuted: String { callAsFunction("claim.refuted") }
    public static var claimStateSatisfied: String { callAsFunction("claim.satisfied") }
    public static var claimStateNotApplicable: String { callAsFunction("claim.notApplicable") }
    public static var claimComposerPrompt: String { callAsFunction("claim.composerPrompt") }
    public static var claimCriterionPlaceholder: String { callAsFunction("claim.criterionPlaceholder") }
    public static var claimScopeHint: String { callAsFunction("claim.scopeHint") }
    public static var claimStateIt: String { callAsFunction("claim.stateIt") }
    public static var claimObservationPlaceholder: String { callAsFunction("claim.observationPlaceholder") }
    public static var claimRecordStance: String { callAsFunction("claim.recordStance") }
    public static func claimScopeCount(_ count: Int) -> String {
        String(format: callAsFunction("claim.scopeCount"), count)
    }
    public static var citationSelectPrompt: String { callAsFunction("citations.selectPrompt") }
    public static var citationSelectHint: String { callAsFunction("citations.selectHint") }
    public static var citationCiteSelection: String { callAsFunction("citations.citeSelection") }
    public static var citationsTitle: String { callAsFunction("citations.title") }
    public static var citationVerify: String { callAsFunction("citations.verify") }
    public static var citationVerifyHint: String { callAsFunction("citations.verifyHint") }
    public static var citationObservationPlaceholder: String { callAsFunction("citations.observation") }
    public static var citationRecord: String { callAsFunction("citations.record") }
    public static var citationUnverified: String { callAsFunction("citations.unverified") }
    public static var citationVerified: String { callAsFunction("citations.verified") }
    public static var citationNeedsReview: String { callAsFunction("citations.needsReview") }
    public static var citationSuperseded: String { callAsFunction("citations.superseded") }
    public static var citationNoPassage: String { callAsFunction("citations.noPassage") }
    public static var citationsEmpty: String { callAsFunction("citations.empty") }
    public static var sourceOpenInReader: String { callAsFunction("source.openInReader") }
    public static var sourceOpenInReaderHint: String { callAsFunction("source.openInReaderHint") }
    /// %lld is how many rows the file really has, so the cap is not a mystery.
    public static func citationTableCapped(_ rows: Int) -> String {
        String(format: callAsFunction("citations.tableCapped"), rows)
    }
    public static func sourceAttached(_ title: String) -> String {
        String(format: callAsFunction("source.attached"), title)
    }
    public static func sourceAttachedWithoutText(_ title: String, _ reason: String) -> String {
        String(format: callAsFunction("source.attachedWithoutText"), title, reason)
    }
    public static func sourceChip(_ title: String) -> String { callAsFunction("source.chip") }
    public static func sourceChipCount(_ title: String, _ count: Int) -> String {
        String(format: callAsFunction("source.chipCount"), title, count)
    }
    public static func sourceChipAccessibility(_ title: String, _ state: String) -> String {
        String(format: callAsFunction("source.chipAccessibility"), title, state)
    }
    public static var sourceStateNotRead: String { callAsFunction("source.state.notRead") }
    public static var sourceStateImporting: String { callAsFunction("source.state.importing") }
    public static var sourceStateReady: String { callAsFunction("source.state.ready") }
    public static var sourceStatePartial: String { callAsFunction("source.state.partial") }
    public static var sourceStateNoText: String { callAsFunction("source.state.noText") }
    public static var sourceStateUnsupported: String { callAsFunction("source.state.unsupported") }
    public static var sourceStateMissing: String { callAsFunction("source.state.missing") }
    public static var sourceStateUnverifiable: String { callAsFunction("source.state.unverifiable") }

    // Status
    public static var statusNoChange: String { callAsFunction("status.noChange") }
    public static var statusKept: String { callAsFunction("status.kept") }
    public static var statusDiscarded: String { callAsFunction("status.discarded") }
    public static var statusSaved: String { callAsFunction("status.saved") }
    public static var statusThinking: String { callAsFunction("status.thinking") }
    /// %lld is how many directions have arrived so far, while the answer streams.
    public static func progressDirections(_ count: Int, languageCode: String) -> String {
        String(format: callAsFunction("progress.directions"), count)
    }
    public static var errorGeneric: String { callAsFunction("error.generic") }
    public static var errorEditConflict: String { callAsFunction("error.editConflict") }
    public static var errorSaveFailed: String { callAsFunction("error.saveFailed") }
    public static var errorLoadFailed: String { callAsFunction("error.loadFailed") }
    public static var submitHint: String { callAsFunction("action.submitHint") }
    public static var sourceOnDevice: String { callAsFunction("source.onDevice") }
    /// %@ is the real reason reported by the framework, in the user's language.
    public static func sourceUnavailable(_ reason: String) -> String {
        String(format: callAsFunction("source.unavailable"), reason)
    }

    // Undo labels
    public static var undoMove: String { callAsFunction("undo.move") }
    public static var actionDuplicateOccurrence: String { callAsFunction("action.duplicateOccurrence") }
    public static var actionDuplicateVariant: String { callAsFunction("action.duplicateVariant") }
    public static var actionRemoveOccurrence: String { callAsFunction("action.removeOccurrence") }
    public static var actionRemoveObject: String { callAsFunction("action.removeObject") }
    public static var actionKeepOccurrence: String { callAsFunction("action.keepOccurrence") }
    public static var actionLoseIdea: String { callAsFunction("action.loseIdea") }
    public static var undoAddNote: String { callAsFunction("undo.addNote") }
    public static var undoCreate: String { callAsFunction("undo.create") }
    public static var undoDuplicateOccurrence: String { callAsFunction("undo.duplicateOccurrence") }
    public static var undoDuplicateVariant: String { callAsFunction("undo.duplicateVariant") }
    public static var undoRemoveOccurrence: String { callAsFunction("undo.removeOccurrence") }
    public static var undoRemoveObject: String { callAsFunction("undo.removeObject") }
    public static var undoKeepProposal: String { callAsFunction("undo.keepProposal") }
    public static var undoSetAside: String { callAsFunction("undo.setAside") }
    public static var undoReopen: String { callAsFunction("undo.reopen") }
    public static var undoEdit: String { callAsFunction("undo.edit") }

    // Menu
    public static var newDocument: String { callAsFunction("menu.newDocument") }
    public static var openDemo: String { callAsFunction("menu.openDemo") }
    public static var save: String { callAsFunction("menu.save") }
    public static var fit: String { callAsFunction("menu.fit") }
    public static var actualSize: String { callAsFunction("menu.actualSize") }
    public static var undo: String { callAsFunction("menu.undo") }
    public static var redo: String { callAsFunction("menu.redo") }
}
