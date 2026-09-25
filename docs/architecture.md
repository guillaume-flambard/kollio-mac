# Architecture

## Three layers, one document

```
                 KOLLIO DOCUMENT  (.kollio)
                         |
                  DOMAIN SEMANTICS
                         |
                  ACTION PROTOCOL
                         |
        +----------------+----------------+
        |                                 |
  macOS renderer                    web renderer
  SwiftUI / AppKit                  (not built)
        |                                 |
        +----------------+----------------+
                         |
                   Kollio backend
                   (Vapor, separate process)
```

The document and the action semantics know nothing about the renderer. A future web renderer reads
the same JSON and runs the same validator, which is the only reason a `.kollio` file can ever become
a portable output format rather than a screenshot of one app.

## KollioCore

Swift and Foundation only. It does not import SwiftUI, AppKit, Vapor or Fluent, and it compiles
independently:

```bash
cd packages/KollioCore && swift test
```

It owns:

- **Domain**: `ContentObject`, `Relationship`, `Decision`, `NodeInstance`, `ContributionRecord`,
  `ProductComposition`. Stable identity, never regenerated.
- **Document**: `KollioDocument`, the versioned envelope, plus `revision` and `semanticRevision`.
- **Commands**: every mutation is a validated `Command`. `DocumentStore` applies a transaction to a
  value copy and publishes it only if every command succeeded, so a transaction is atomic by
  construction.
- **Decisions**: durable project memory, kept apart from `UndoHistory`.
- **Proposals**: `Proposal`, `ProposalRequest`, `ProposalResponse`, and `ProposalValidator`.
- **Suggestion sources**: the `SuggestionService` protocol and the offline `LocalDemoSuggestionService`.
- **Serialization**: `DocumentCodec` (pretty printed, sorted keys, ISO 8601, millisecond precision) and
  `DocumentBuilder` for fixtures and the first experience.

## KollioApp

SwiftUI, with AppKit only where the platform demands it. It owns rendering, the camera, gestures,
the contextual UI and the networking adapter. It never mutates the document behind the model's back:
`KollioModel` wraps `KollioSession`, which wraps `DocumentStore`.

**The canvas is a camera, not a giant view.** World coordinates live in the document, the camera is a
pure `Camera` value (`screen = world * zoom + translation`), and two layers consume it:

- the **world layer** holds the object views, transformed by the camera;
- the **relationship layer** is drawn in *screen* space, so a connector keeps a constant stroke and a
  constant label at any zoom, and can never be clipped by the extent of the content.

Object sizes are measured by SwiftUI and reported back through a preference key, so hit testing,
framing and connector endpoints all use real frames. An estimate is used only before the first
measurement.

## KollioServer

A separate process. It is **not** authoritative for the local document: the client owns it, sends a
scoped context with every request, and validates the answer again before showing it. The server
validates a third time before answering. See [backend.md](backend.md).

## Why the document is not a view

`presentation` holds instances (position, optional size) and nothing else. Hover, focus, selection and
dragging are editor-session state and are never written to disk. Moving an object bumps `revision` and
not `semanticRevision`; changing what the document *means* bumps both. That difference is what lets a
proposal be checked for staleness without being confused by someone tidying the canvas.
