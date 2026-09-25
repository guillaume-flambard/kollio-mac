# Continue Kollio

Paste this into the agent working in the `Kollio.xcworkspace` window.

---

You are continuing **Kollio**, a macOS prototype: a living visual document that humans and AI build,
question and evolve together. The canvas is the application. A `.kollio` document is the product
model. An intelligence source proposes a patch; it never regenerates the world.

## Where the code is

```
kollio/
├── apps/macos/Kollio.xcodeproj   generated, app target only, for Cmd+R and the debugger
├── packages/KollioCore           domain, document format, commands, proposals, validation
├── packages/KollioApp            the app sources, and the tests
├── services/KollioServer         Vapor API
├── contracts/                    JSON schemas + the reference .kollio fixture
├── docs/                         architecture, format, action protocol, backend, limitations
└── scripts/                      run-app.sh, test-all.sh, verify.sh, sync-xcodeproj.py
```

`apps/macos/Kollio.xcodeproj` is **generated** by `scripts/sync-xcodeproj.py`. Never edit it by hand.
After adding or removing a file under `packages/KollioApp/Sources`, run:

```bash
./scripts/sync-xcodeproj.py
```

## Verify before believing anything

```bash
./scripts/verify.sh     # 3 test suites (88 tests) + the Xcode app target
./scripts/run-app.sh --shot   # builds, launches, screenshots into build/
```

`KOLLIO_REVIEW=explore|kept|setaside|reopened ./scripts/run-app.sh` opens the app in a given state so
one step of the vertical slice can be captured in a screenshot. Use it instead of guessing what a state
looks like.

## What is built and tested

- `.kollio`: versioned JSON, exact round trip, greppable object keys, no renderer type in the file.
  Schema in `contracts/schemas/`, reference file in `contracts/fixtures/sarah/sarah.kollio`.
- Commands, atomic transactions, undo and redo, redo tail dropped after a new action.
- Durable decisions: set aside collapses a branch without deleting it, reopen restores the exact
  objects, relationships and positions. A decision survives save, quit and reload.
- Proposals validated three times: provider output, server, client. Staleness, unknown ids, operation
  budget and forbidden operations are all rejected.
- Canvas: pure `Camera` geometry, world and screen transforms, zoom around an anchor, drag at any
  zoom, screen-space connectors, selection, contextual actions, ghost branches, inline composer.
- Connectors detour around any object between their ends, keeping a fixed clearance, and the
  relationship label follows the curve. A clear connector keeps the exact curve it had before.
- The whole loop: Sarah → Explore → ghost branch → Keep → Cmd+Z → Explore again → Écarter with a reason
  → Rouvrir → save → quit → reopen, as one integration test on the real model and the real file.
- Server: routes, bearer auth, scoping, provider swap, timeout, cancellation, rate limit, malformed
  output, refusal, disabled remote provider. Plus the client flow through real routes and real JSON.
- FR and EN from a native String Catalog, no key ever visible. `L10n` resolves the bundle for both
  SwiftPM and Xcode.

## What is not done, and what that means

Read `docs/known-limitations.md` before promising anything. The short version:

- **No pointer-level UI automation.** The model behind each gesture is tested and the states were
  captured, but real clicks were not driven by a test. A human pass with a trackpad is still owed.
- **`GroqProvider` has never run with a real key.** Do not describe its output quality.
- **No performance measurement** of the 100 object / 200 relationship target.
- The offline "intelligence" is a deterministic rule engine, not a model.

## Rules for continuing

1. **Do not start a feature before the current one is verified.** Build, run, look, then extend.
2. **The domain stays renderer independent.** `KollioCore` must not import SwiftUI, AppKit, Vapor or
   Fluent. If a change needs one of those, the change is in the wrong layer.
3. **Every mutation is a validated command**, applied in a transaction that fully succeeds or leaves
   the document untouched. Views never mutate the document directly.
4. **Never regenerate the world.** An intelligence source returns operations. The client decides
   placement, and it must not move what already exists.
5. **Rejected work keeps its memory.** Set aside is a durable decision, not a deletion and not undo.
6. **No permanent chrome.** No sidebar, no toolbar, no inspector, no chat panel. Interaction appears
   where the user is working. System commands live in native menus.
7. **Design tokens only.** Views never use a raw colour. Light and dark are both defined.
8. **Interface strings live in the String Catalog** with semantic keys. User content is never machine
   translated.
9. **Report honestly.** Separate what is implemented and tested, what is implemented but not visually
   verified, what is simulated, what is configured but not called live, and what is future work. Never
   claim production readiness.
10. **All code, identifiers, comments and logs in English.** The interface is FR and EN.

## The next things worth doing, in this order

1. A human pass with a trackpad: drag, double-click to explore, contextual buttons, pinch and scroll
   to pan, `Cmd+0` / `Cmd+1` / `Cmd+Z` / `Cmd+S`. Report what feels wrong.
2. Relationship selection: a label, a wider hit area than the visible stroke, and a contextual action.
3. Performance: generate 100 objects and 200 relationships, measure pan, zoom and drag, then use the
   camera's visible rectangle to cull. Connector routing samples its curve, so this is where the
   cost will show.
4. Keyboard traversal between objects, so the canvas is usable without a pointer.
5. Only then: a real model behind the existing `SuggestionService` seam, with the key kept in the
   Keychain on the client and in the environment on the server.
