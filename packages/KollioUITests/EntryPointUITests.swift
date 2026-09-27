import Foundation
import XCTest

/// The entry point, as a person reaches it.
///
/// This is the pass that was owed and could not be automated. Every other batch in
/// this repository has either driven the model directly or captured a state opened
/// for review, and both leave the same gap: nobody had ever typed into the field
/// and watched what the window did.
///
/// This drives the real application over the real accessibility bridge, so a pass
/// here is a pass a person would recognise. It clicks the field, types a French
/// sentence, presses the action, and reads the canvas back by name.
///
/// It is deliberately **not** part of `verify.sh`, and the reason is the same as the
/// reason it exists: this needs a window, and a window needs somebody at the
/// machine. Run it with:
///
///     xcodebuild test -project apps/macos/Kollio.xcodeproj -scheme Kollio \
///         -destination 'platform=macOS,arch=arm64' -only-testing:KollioUITests
///
/// One fact about this machine is recorded in the test below, because it will
/// otherwise look like a bug in it: the window opens on the second display, and
/// every element in a snapshot is reported `Disabled` because of it. Clicks and
/// keystrokes still arrive, which is why these tests pass, and the frames in the
/// tree are not to be read as "this element cannot be touched".
final class EntryPointUITests: XCTestCase {
    /// The sentence the pass types. Not a fixture: a question, in the interface's
    /// own language, so the run is the thing a person would do.
    private let sentence = "Réduire l'inscription de neuf étapes à trois avant la fin du trimestre."

    /// Half the sentence, for looking for on the canvas.
    ///
    /// A predicate over the whole sentence has to match every character the keyboard
    /// may have changed, which makes a test of the keyboard. Half is enough to say
    /// the words arrived, and no character in it is one a keyboard would touch.
    private let distinctiveFragment = "neuf étapes à trois"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// The application, launched the way a person launches it: from nothing.
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["KOLLIO_SERVICE"] = "demo"
        app.launch()
        return app
    }

    func testATypedSentenceBecomesAnObjectOnTheCanvas() throws {
        let app = launch()

        // The invitation, the field and the action, found by what they are.
        let field = app.textViews.firstMatch
        XCTAssertTrue(
            field.waitForExistence(timeout: 20),
            "the entry field never appeared; the window did not come up"
        )
        XCTAssertTrue(
            app.buttons["kollio.entry.explore"].exists,
            "the primary action is not on screen, so the invitation cannot be submitted"
        )

        // The gesture itself. A click first, because a person clicks before typing,
        // and a keystroke into a field nobody focused would pass for the wrong
        // reason.
        field.click()
        field.typeText(sentence)

        // What the field now holds is the sentence as it was typed, which is the
        // only claim worth making before the action is pressed.
        XCTAssertEqual(
            foldPunctuation(field.value as? String), foldPunctuation(sentence),
            "the field does not hold what was typed; these words are the part that cannot be reconstructed"
        )

        app.buttons["kollio.entry.explore"].click()

        // The canvas is there, named once, and the invitation is gone.
        let canvas = app.groups["kollio.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 20), "the canvas did not replace the invitation")
        XCTAssertFalse(
            app.textViews["kollio.entry.field"].exists,
            "the invitation is still on screen after the action was pressed"
        )

        // And the sentence is on the canvas as an object, named by its identity and
        // carrying what was typed. Not a status line and not a log.
        let node = canvas.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'kollio.node.'"))
            .firstMatch
        XCTAssertTrue(node.waitForExistence(timeout: 20), "no object on the canvas is named as one")
        XCTAssertTrue(
            foldPunctuation((node.label as? String) ?? "").contains(distinctiveFragment),
            "the object on the canvas does not carry the sentence: \(node.label ?? "no label")"
        )
    }

    /// The second claim, and the one that is easy to believe and hard to prove: the
    /// document was saved because the app quit, not because somebody remembered to.
    func testTheDocumentSurvivesAQuitWithNoSave() throws {
        let app = launch()
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.click()
        field.typeText(sentence)
        app.buttons["kollio.entry.explore"].click()
        XCTAssertTrue(app.groups["kollio.canvas"].waitForExistence(timeout: 20))

        // No `Cmd+S` anywhere in this test. That is the claim.
        app.terminate()
        app.launch()

        let canvas = app.groups["kollio.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 20), "the document did not come back after a quit")
        let node = canvas.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'kollio.node.'"))
            .firstMatch
        XCTAssertTrue(
            node.waitForExistence(timeout: 20) && foldPunctuation(node.label as? String ?? "").contains(distinctiveFragment),
            "the document came back without the sentence in it"
        )
    }

    /// Typographic punctuation, folded to the ASCII it came from.
    ///
    /// Not a normalisation the product does: the document stores exactly what was
    /// typed, curly apostrophe included. This compares two things that were typed on
    /// the same keyboard, and it is here so the comparison is about the words.
    private func foldPunctuation(_ text: String?) -> String {
        (text ?? "")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
    }
}
