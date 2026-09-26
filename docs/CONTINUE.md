# Continue Kollio

Paste this into the agent working in the `Kollio.xcworkspace` window.

---

You are continuing **Kollio**, a macOS prototype: a living visual document that humans and AI build,
question and evolve together. The canvas is the application. A `.kollio` document is the product
model. An intelligence source proposes a patch; it never regenerates the world.

The direction is [PRODUCT_BLUEPRINT.md](PRODUCT_BLUEPRINT.md). Read it once, not every task.

## Active milestone: G0, real entry point and on-device Apple intelligence

**Status: G0-A and G0-B both reached. The human gesture pass is still owed.**

Verified 2026-09-25 on arm64, macOS 27.0 (26A428), Xcode 27.0, SDK 27.0.
`SystemLanguageModel.default.availability` is `.available`, 24 languages, 8192-token context. This
was probed directly, not inferred from the SDK being installed.

| Criterion | State |
|---|---|
| Fresh input instead of automatic Sarah | Done, tested |
| Authored context persisted before any request | Done, tested |
| Inline instruction delivered | Done, tested |
| New-document isolation, unreadable document reported | Done, tested |
| Save on quit wired | Done, tested end to end |
| `AppleLocalSuggestionService` behind the seam | Done, tested with a stub |
| Two distinct non-Sarah contexts reach the adapter | Done, real model, FR and EN |
| Keep / Undo / save / reopen without a server | Done, tested |
| Real on-device generation produces a valid proposal | Done, real model |
| No network socket held by the running app | Done, `lsof` against the app pid |
| **Human trackpad and pointer pass** | **Owed** |
| **Ghost branch from the real model, captured on screen** | **Owed** |
| Warm latency, three calls in one process | Done, real model: 2.50 s, 2.68 s, 2.29 s |
| A streaming answer reports progress and stays non-blocking | Done, real model: 54 updates in 5.1 s |
| Sources attach, cite and verify as atomic commands | Done, tested, and refused to intelligence |
| A claim shows a chip for the state of its sources | Done, tested |
| Context budget measured, required items never dropped | Done, on the real request path |
| **Network-disabled run after system resources exist** | **Not done**: it needs the firewall changed, which is the owner's call |

The deterministic suite never touches a real model, and stays under two seconds. Reproduce the
real-model check:

```bash
KOLLIO_REAL_MODEL=1 swift test --package-path packages/KollioApp --filter RealOnDeviceModelTests
```

Measured latency for a small candidate, serially on this Mac: the first call in a fresh process
is **3.6 s**, later calls are **2.2 to 2.7 s**. A three-call series in one process runs
2.50 s, 2.68 s, 2.29 s, so the cost is mostly per call and not a large one-off asset load.

An earlier round reported 9 to 15 s and treated it as the dominant finding. **That number does not
reproduce and the cause is unconfirmed.** The likely explanation is contention: the real-model suite
runs in parallel by default, and two tests hitting the same on-device model pushed the first measured
call to 7.08 s. Measure it with `--no-parallel`:

```bash
KOLLIO_REAL_MODEL=1 swift test --package-path packages/KollioApp \
  --filter RealOnDeviceModelTests --no-parallel
```

What survives the correction is the conclusion rather than the figure: 2.3 s is still too slow to
feel interactive on its own. The wait is now filled, though, because the answer streams.

## The answer streams, and a progress is never a proposal

`AppleLocalSuggestionService` now conforms to `StreamingSuggestionService`, so the sentence the model
is writing appears as it is written. Measured on a real model: **54 progress updates over 5.1 s**, the
rationale growing a few words at a time. The proposal is still minted once, at the end, and goes
through the same converter and the same `ProposalValidator` as before.

The rule that makes this safe is that a progress carries no identifier, no operation and no way to
become a command. `ProposalProgress` has no initialiser that could mint one, so a half-received answer
cannot become something the user could keep. It is cleared the moment the request ends, whatever the
outcome, including a cancellation.

`StreamingSuggestionService` is an **additional** capability. The seam stays `SuggestionService`, and a
source that cannot stream simply does not conform, so the offline engine and the remote provider are
unaffected.

## Where the code is

```
kollio/
├── apps/macos/Kollio.xcodeproj   generated, app target only, for Cmd+R and the debugger
├── packages/KollioCore           domain, document format, commands, proposals, validation
├── packages/KollioApp            the app sources, and the tests
├── services/KollioServer         Vapor API
├── contracts/                    JSON schemas + the reference .kollio fixture
├── docs/                         architecture, format, action protocol, backend, limitations
│   └── specs/SPECIFICATIONS.md   the normative specification: 71 features, 213 criteria
├── openspec/                     the decomposition, in capabilities and lots
└── scripts/                      run-app.sh, verify.sh, sync-xcodeproj.py,
                                 generate-spec-index.py, generate-spec-status.py
```

`apps/macos/Kollio.xcodeproj` is **generated** by `scripts/sync-xcodeproj.py`. Never edit it by hand.
After adding or removing a file under `packages/KollioApp/Sources`, run:

```bash
./scripts/sync-xcodeproj.py
```

## Verify before believing anything

```bash
./scripts/verify.sh     # the spec views, 3 test suites (415 tests), the Xcode app target
./scripts/run-app.sh --shot   # builds, launches, screenshots into build/
```

`KOLLIO_REVIEW=explore|kept|setaside|reopened ./scripts/run-app.sh` opens the app in a given state so
one step of the vertical slice can be captured in a screenshot. Use it instead of guessing what a state
looks like.

Note: `run-app.sh --shot` prints a path whether or not the capture worked, and it captures the whole
screen rather than the Kollio window. Check the file exists and shows the app before trusting it.
Capturing **only** Kollio's window does work, by hand: read the window id from
`CGWindowListCopyWindowInfo` and pass it to `screencapture -l`. See the CTX-05 batch below for two
captures made that way and inspected.

## The specification is decomposed, and the views are generated

`docs/specs/SPECIFICATIONS.md` is the normative source: 71 features, 213 acceptance criteria.
`openspec/` decomposes it twice, and both decompositions are generated from that prose so they cannot
drift out of sync with it:

```bash
python3 scripts/generate-spec-index.py     # openspec/specs/feature-catalog.json + openspec/todo.md
python3 scripts/generate-spec-status.py    # openspec/implementation-status.json
```

`./scripts/verify.sh` runs both with `--check` first, so a stale view fails verification. The honest
state today, per capability: `canvas`, `intelligence` and `decisions` are `automatedVerified`;
`documents` is `implemented`; `context` and `studio` are `specified`; `collaboration`, `commerce` and
`ecosystem` are `blockedExternal` and need an explicit authorisation.

`openspec/specs/evidence.md` is the short honest answer to "what is actually proved", including the
things that are wrong and the things owed to a person.

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

## Verified batches, in order

CAN-02, CAN-03, CAN-04, CAN-05, CTX-01, AI-03, CTX-05, CAN-07, AI-05, and the
earlier DOC-01..04, CAN-01, AI-01, AI-02, AI-04, CTX-02..04, CTX-06, CTX-07, DEC-01..03
and CAN-06. What each one found is in [batch-log.md](batch-log.md); the current
state and the exact next task are below and in the table above.

## The next things worth doing, in this order

1. The human pass, which is owed and which no test substitutes for. Three things
   only a person can settle: **type a sentence into the entry point and
   press the action**, **scroll with two fingers** (the code says it does nothing; confirm or
   refute), and **watch a real-model proposal arrive and be kept**. Then drag, double-click to
   explore, contextual buttons, `Cmd+0` / `Cmd+1` / `Cmd+Z` / `Cmd+S`, and quit without `Cmd+S`.
3. Latency, because it is the blocking finding: measure a warm call, a second identical call, and
   whether the first cost is asset loading or generation. A pending state that lasts ten seconds is
   the next thing the user will complain about.
4. Relationship selection: a label, a wider hit area than the visible stroke, and a contextual action.
5. Performance: generate 100 objects and 200 relationships, measure pan, zoom and drag, then use the
   camera's visible rectangle to cull. Connector routing samples its curve, so this is where the
   cost will show.
6. Keyboard traversal between objects, so the canvas is usable without a pointer.
7. **AI-06, synthesise and prepare a deliverable**, then AI-11, AI-12, CAN-09 and
   CAN-10. Those are the remaining L3 lots, and each one now has the layer it
   needs: a comparison is a reading, a synthesis is a derivative that must never
   replace its sources.
8. Only then, and only with explicit permission: a small live Groq test, or a PCC eligibility check.
   Everything the transport needs is in place and mocked; what is missing is evidence about a live
   model, not plumbing.
