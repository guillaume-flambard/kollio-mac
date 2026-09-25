import SwiftUI
import AppKit
import KollioCore

/// A trackpad scroll, delivered to SwiftUI.
///
/// SwiftUI on macOS has no scroll gesture of its own, so two-finger scrolling
/// over the canvas does nothing at all without this. The event is delivered
/// through an `NSViewRepresentable` that sits on top of the canvas and claims a
/// hit only while the event being routed is a scroll. Every other event, a click
/// and a drag included, passes straight through to the canvas, which keeps its own
/// hit testing and its own gestures.
///
/// One rule matters here. A scroll inside a text field belongs to the field, and
/// the canvas must not fight it for the gesture, so the catcher steps aside
/// entirely while a text responder holds the pointer.
struct ScrollCatcher: NSViewRepresentable {
    /// Called with a screen-space delta for each scroll event the canvas owns.
    let onScroll: (Position) -> Void
    /// Whether a text-editing responder currently holds the pointer.
    let isEditingText: Bool

    func makeNSView(context: Context) -> ScrollView {
        let view = ScrollView(frame: .zero)
        view.onScroll = onScroll
        view.isEditingText = isEditingText
        return view
    }

    func updateNSView(_ view: ScrollView, context: Context) {
        view.onScroll = onScroll
        view.isEditingText = isEditingText
    }

    final class ScrollView: NSView {
        var onScroll: ((Position) -> Void)?
        var isEditingText: Bool = false

        /// The event AppKit is currently routing. Injectable so the routing can
        /// be proved without a trackpad; nil means the ambient event, which is
        /// re-read for every hit because it changes with every event.
        var injectedEvent: NSEvent?

        private var routingEvent: NSEvent? { injectedEvent ?? NSApp?.currentEvent }

        // No responder overrides: this view never accepts a click, a key or the
        // focus. It is on top so that AppKit's own hit testing can reach it, and
        // it claims a hit only while the event being routed is a scroll.
        override func hitTest(_ point: NSPoint) -> NSView? {
            // A text-editing responder outranks the canvas, so a scroll inside a
            // field belongs to the field. Stepping aside here is what keeps a long
            // field readable instead of panning the world underneath it.
            if isEditingText { return nil }
            guard let event = routingEvent,
                  event.type == .scrollWheel else { return nil }
            let local = convert(point, from: superview)
            return bounds.contains(local) ? self : nil
        }

        override func scrollWheel(with event: NSEvent) {
            // Inside a text field the scroll belongs to the field. The canvas
            // stays still, which is what makes a long field readable.
            if isEditingText == false, let onScroll {
                // `scrollingDeltaY` follows the fingers on a trackpad, so the
                // content follows the hand the same way a drag does.
                let horizontal = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : 0
                let vertical = event.scrollingDeltaY
                // Precise trackpad deltas are small; a line-based wheel is not.
                // One point per pixel keeps both feeling like the same gesture.
                onScroll(Position(x: horizontal, y: vertical))
                return
            }
            super.scrollWheel(with: event)
        }
    }
}
