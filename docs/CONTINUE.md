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
./scripts/verify.sh     # 3 test suites (134 tests) + the Xcode app target
./scripts/run-app.sh --shot   # builds, launches, screenshots into build/
```

`KOLLIO_REVIEW=explore|kept|setaside|reopened ./scripts/run-app.sh` opens the app in a given state so
one step of the vertical slice can be captured in a screenshot. Use it instead of guessing what a state
looks like.

Note: `run-app.sh --shot` prints a path whether or not the capture worked, and it captures the whole
screen rather than the Kollio window. Check the file exists and shows the app before trusting it.

## Which intelligence source is in use

Chosen by environment variable, never by UI. `KOLLIO_SERVICE=server` with a token in the Keychain
(`dev.kollio.app` / `api-token`) points the app at a local backend; without them it uses the offline
engine. The status line names the source when it is not the offline default.

```bash
# terminal 1: the local backend, offline provider
KOLLIO_API_TOKEN=$(openssl rand -hex 32) swift run --package-path services/KollioServer kollio-server

# terminal 2: the app, pointed at it
security add-generic-password -a "api-token" -s "dev.kollio.app" -w "$TOKEN"   # once
KOLLIO_SERVICE=server KOLLIO_SERVER_URL=http://127.0.0.1:8080 ./scripts/run-app.sh
```

The Groq key is the server's, in its environment, and never reaches the app or the repository. The
Kollio token and the Groq key are different things and live in different places.

## What is built and tested

- The entry point: no stored document shows the initial input, a stored one is restored, an unreadable
  one is reported and never overwritten, and Sarah is only ever reached through an explicit menu
  action. A new document gets its own file, so saving it cannot destroy the previous one.
- The typed context becomes a real object with a stable identity, shown on the canvas and persisted
  before any intelligence is asked for, and it can be edited in place without moving anything else.
- `.kollio`: versioned JSON, exact round trip, greppable object keys, no renderer type in the file.
  Schema in `contracts/schemas/`, reference file in `contracts/fixtures/sarah/sarah.kollio`.
- Commands, atomic transactions, undo and redo, redo tail dropped after a new action.
- Durable decisions: set aside collapses a branch without deleting it, reopen restores the exact
  objects, relationships and positions. A decision survives save, quit and reload.
- Proposals validated three times: provider output, server, client. Staleness, unknown ids, operation
  budget and forbidden operations are all rejected.
- A request-bound document snapshot: bounded, layout-free, reference-checked, refused when oversized
  or inconsistent. The server reasons about exactly that and is never authoritative.
- Canvas: pure `Camera` geometry, world and screen transforms, zoom around an anchor, drag at any
  zoom, screen-space connectors, selection, contextual actions, ghost branches, inline composer.
- Connectors detour around any object between their ends, keeping a fixed clearance, and the
  relationship label follows the curve. A clear connector keeps the exact curve it had before.
- The whole loop: Sarah → Explore → ghost branch → Keep → Cmd+Z → Explore again → Écarter with a reason
  → Rouvrir → save → quit → reopen, as one integration test on the real model and the real file.
- Server: routes, bearer auth, scoping, provider swap, timeout, cancellation, rate limit, malformed
  output, refusal, disabled remote provider. Plus the client flow through real routes and real JSON,
  and a run against a **separate local server process** carrying non-Sarah documents.
- The provider wire contract, against a mocked transport and no key: the documented `response_format`
  field, a schema matching the decoded DTO, and every malformed, truncated, refusing, unknown-reference
  and quota case rejected.
- FR and EN from a native String Catalog, no key ever visible. `L10n` resolves the bundle for both
  SwiftPM and Xcode.

## What is not done, and what that means

Read `docs/known-limitations.md` before promising anything. The short version:

- **No pointer-level UI automation.** The model behind each gesture is tested and the states were
  captured, but real clicks were not driven by a test. A human pass with a trackpad is still owed,
  and it is now the only thing standing between the prototype and a trustworthy verdict on feel.
- **The entry point has never been typed into by a person.** The screen is verified, and the model
  behind it is tested, but keystroke injection needs accessibility access this environment refuses.
  Two-finger scrolling is not wired anywhere in the app either: see `known-limitations.md`. Both are
  inspection or partial evidence, not reproduced bugs.
- **`GroqProvider` has never run with a real key.** Its wire contract is tested with a mock, which says
  nothing about a live model's output quality. Do not describe its quality.
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

1. A human pass, and the two things only a human can settle: **type a sentence into the entry point
   and press the action**, and **scroll with two fingers**. Drag, double-click to explore, contextual
   buttons, `Cmd+0` / `Cmd+1` / `Cmd+Z` / `Cmd+S`, then quit without `Cmd+S` and relaunch. The code
   says two-finger scrolling does nothing; confirm or refute it.
2. Relationship selection: a label, a wider hit area than the visible stroke, and a contextual action.
3. Performance: generate 100 objects and 200 relationships, measure pan, zoom and drag, then use the
   camera's visible rectangle to cull. Connector routing samples its curve, so this is where the
   cost will show.
4. Keyboard traversal between objects, so the canvas is usable without a pointer.
5. Only then, and only with explicit permission and a key kept server-side: a small live Groq test
   behind the existing seam. Everything the transport needs is already in place and mocked; what is
   missing is evidence about a real model's output, not plumbing.
