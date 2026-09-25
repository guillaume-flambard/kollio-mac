# L1 — design decisions

## A new document gets a timestamped file, not the default one

**Chosen:** `start(with:)` adopts a new save target, and a launch opens the
default file when one exists, otherwise the most recently written document.

**Rejected:** keeping one `Kollio.kollio`. It makes "New document" destructive on
the first save, which is the kind of failure that loses work silently.

**Rejected:** a document picker on first launch. It adds a decision before the
person has any context, and a launch must not be a modal.

## The first inference is a separate step from the first save

**Chosen:** `start(with:)` persists and returns; the caller then asks for an
exploration.

**Rejected:** one method that does both. If the intelligence source fails, a
single call would either lose the words or hide the failure. Separating them makes
the guarantee testable: the words are on disk before anything can fail.

## Scroll is delivered through AppKit, not invented as a SwiftUI gesture

**Chosen:** an inert `NSView` behind the canvas that forwards `scrollWheel`.

**Rejected:** synthesising a drag from scroll deltas. It would be second-hand and
would fight the system's own phase and momentum handling.

The rule that matters: a scroll inside a text field belongs to the field, so the
catcher reports whether a responder owns the pointer and the canvas only pans
when nobody else wanted it.
