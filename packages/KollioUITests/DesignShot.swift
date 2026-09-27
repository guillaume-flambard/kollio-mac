import AppKit
import Foundation
import XCTest

/// A capture channel, not a product test.
///
/// The shell cannot see this application's window: it opens on a second display
/// behind everything, and `screencapture` reports whatever is in front instead.
/// XCUITest can, so the honest way to look at Kollio is from inside the pass that
/// drives it. Every state here is reached the way a person would reach it, and the
/// picture is taken of the screen the window is actually on.
///
/// This file is a tool. It is deleted once the visual pass is finished.
final class DesignShot: XCTestCase {
    /// Where the runner is allowed to write, and where the shell collects from.
    private static let outputDirectory = NSTemporaryDirectory()

    private struct Variant {
        let language: String
        let style: String
    }

    private func launch(_ variant: Variant) -> XCUIApplication {
        let documents = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("kollio-shot-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: documents) }
        let app = XCUIApplication()
        app.launchEnvironment["KOLLIO_SERVICE"] = "demo"
        app.launchEnvironment["KOLLIO_DOCUMENTS"] = documents.path
        app.launchArguments += ["-AppleLanguages", "(\(variant.language))"]
        // No appearance argument: an NSArgumentDomain value outranks the system
        // appearance and this app does not read it, so passing it pinned the
        // window to light. Theme is driven by the machine, set from outside.
        app.launch()
        return app
    }

    /// Every screen, because XCUIScreen exposes no geometry to choose with: the
    /// window opens on whichever display is not the main one, and picking the
    /// wrong screen produces a confident picture of something else. All of them are
    /// written and the right one is chosen by looking.
    /// The window, cropped out of its display, and nothing else.
    ///
    /// Two things are wrong with photographing the whole screen. The first is
    /// obvious in hindsight: the picture contains whatever else is on that
    /// display, which on a working machine is somebody's email. The second is
    /// that the window is often not the thing being looked at anyway.
    ///
    /// `XCUIScreen` deliberately exposes no geometry, so the mapping from a
    /// window frame to a display is made here with `NSScreen`, which does: the
    /// display that contains the window, matched to the screenshot of the same
    /// pixel size, cropped to the window's offset within it.
    private func shoot(_ app: XCUIApplication, _ name: String) throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 25), "no window to photograph")
        // Existence is not appearance. A window can be in the tree and not yet
        // composited, and the photograph of that is a blank rectangle which is
        // worse than no photograph because it looks like a result.
        sleep(3)

        let frame = window.frame
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(frame) }) else {
            XCTFail("the window at \(frame) is on no display this process can see")
            return
        }
        let scale = screen.backingScaleFactor
        // `window.frame` is an XCUIRect, whose members are Double; CoreGraphics
        // wants CGFloat. Converting once, here, is clearer than at every use.
        let crop = CGRect(
            x: CGFloat(frame.origin.x - screen.frame.origin.x) * scale,
            y: CGFloat(frame.origin.y - screen.frame.origin.y) * scale,
            width: CGFloat(frame.width) * scale,
            height: CGFloat(frame.height) * scale
        )

        // The display whose pixels match is the one holding the window. Matching
        // by size rather than by index, because nothing promises the two lists
        // are in the same order.
        let wanted = NSSize(
            width: screen.frame.width * scale,
            height: screen.frame.height * scale
        )
        guard let match = XCUIScreen.screens.first(where: { candidate in
            let image = candidate.screenshot().image
            return abs(image.size.width - wanted.width) < 1.0
                && abs(image.size.height - wanted.height) < 1.0
        }) else {
            XCTFail("no reported display matches \(wanted) pixels; the window's display is not photographable")
            return
        }

        let full = match.screenshot().image
        guard let source = full.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            XCTFail("the display produced no bitmap")
            return
        }
        let fullHeight = CGFloat(source.height)
        guard let cropped = source.cropping(
            to: CGRect(
                x: crop.origin.x,
                // Image coordinates count from the top left, window coordinates
                // from the bottom left of the display. Without this flip the crop
                // is the right size and the wrong part of the screen.
                y: fullHeight - crop.origin.y - crop.height,
                width: crop.width,
                height: crop.height
            )
        ) else {
            XCTFail("the window at \(frame) produced no image on a \(wanted) display")
            return
        }

        let bitmap = NSBitmapImageRep(cgImage: cropped)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("the crop could not be encoded")
            return
        }
        let path = Self.outputDirectory + "v3-\(name).png"
        try png.write(to: URL(fileURLWithPath: path))
        // A crop of nothing is a few kilobytes, and a file that small is not a
        // screenshot. Without this the pass reports success on a blank image.
        XCTAssertGreaterThan(
            png.count, 60_000,
            "\(name) wrote \(png.count) bytes to \(path): the window was not on screen when it was photographed"
        )
    }

    private func start(_ app: XCUIApplication) {
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 25), "the window did not come up")
        field.click()
        field.typeText("Sarah hesite au troisième entretien")
        app.buttons["kollio.entry.explore"].click()
        XCTAssertTrue(app.groups["kollio.canvas"].waitForExistence(timeout: 25), "no canvas after the first sentence")
    }

    /// Selecting an object, with the proposal settled first.
    ///
    /// The local actions are deliberately hidden while a proposal preview is open:
    /// a person who is being asked to keep or set aside a direction should not
    /// also be offered three other ways to change the document. So the proposal
    /// is decided before the actions are looked for, which is the order a person
    /// would do it in anyway.
    private func select(_ app: XCUIApplication) {
        let setAside = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Écarter", "Set aside"])
        ).firstMatch
        if setAside.waitForExistence(timeout: 10) {
            setAside.click()
        }

        let node = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'kollio.node.'"))
            .firstMatch
        XCTAssertTrue(node.waitForExistence(timeout: 20), "no object on the canvas is named as one")
        node.click()

        XCTAssertTrue(
            app.descendants(matching: .any)["kollio.actions"].waitForExistence(timeout: 15),
            "selecting an object did not reveal its local actions"
        )
    }

    func testEmptyStateLightFrench() throws {
        try shoot(launch(.init(language: "fr", style: "Light")), "empty-light-fr")
    }
    func testEmptyStateDarkEnglish() throws {
        try shoot(launch(.init(language: "en", style: "Dark")), "empty-dark-en")
    }

    func testCanvasLightFrench() throws {
        let app = launch(.init(language: "fr", style: "Light"))
        start(app)
        sleep(2)
        try shoot(app, "canvas-light-fr")
    }

    func testCanvasDarkEnglish() throws {
        let app = launch(.init(language: "en", style: "Dark"))
        start(app)
        sleep(2)
        try shoot(app, "canvas-dark-en")
    }

    func testContextualActionsLightFrench() throws {
        let app = launch(.init(language: "fr", style: "Light"))
        start(app)
        select(app)
        sleep(1)
        try shoot(app, "contextual-light-fr")
    }

    func testContextualActionsDarkEnglish() throws {
        let app = launch(.init(language: "en", style: "Dark"))
        start(app)
        select(app)
        sleep(1)
        try shoot(app, "contextual-dark-en")
    }
}
