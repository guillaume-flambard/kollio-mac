# Known limitations

An honest inventory. Nothing here is a surprise: this is the prototype, not the product.

## Verified on this machine

Recorded 2026-09-25, on an arm64 Mac, macOS 27.0 (26A428), Xcode 27.0, SDK 27.0.

- **The on-device model is genuinely available here.** `SystemLanguageModel.default.availability`
  is `.available`, 24 supported languages, a context size of 8192 tokens. This was probed directly
  rather than inferred from the SDK being installed.
- **Real generation works, in French and English, on two distinct non-Sarah contexts.** Through the
  adapter, not a standalone script: a French context and an English context each produced a small
  proposal, and both passed the same `ProposalValidator` as any other proposal. Cold latency observed
  between roughly 9 and 15 seconds, which is far too slow to feel interactive and is the clearest
  finding of this round. Reproduce with
  `KOLLIO_REAL_MODEL=1 swift test --package-path packages/KollioApp --filter RealOnDeviceModelTests`.
- **The running app holds no network socket.** Checked with `lsof` against the app's own pid. This is
  evidence about the on-device path specifically, not a claim that no Mac feature the user turns on
  will ever reach the network.

## Implemented and tested

- The entry point: a launch with no stored document shows the initial input, a stored document is
  restored, and an unreadable one is reported without being overwritten. Sarah is only ever reached
  through the explicit demo menu action. Tested.
- The typed context: the authored sentence is preserved exactly, becomes a real context object with a
  stable identity, is shown on the canvas, and is persisted **before** any intelligence is requested.
  A dead backend cannot cost the user their words. Tested.
- Editing the context: one object changes, keeps its identity, bumps only the semantic revision, and
  undoes as one action. Nothing else in the document moves. Tested.
- The request-bound document snapshot: bounded, layout-free, reference-checked, and rejected when
  oversized, incomplete, of the wrong document version, or inconsistent. It rebuilds a real narrow
  document on the server rather than a fixture. Tested in the domain.
- The proposal route, exercised against a **separate local server process** with the demo provider:
  two different client documents answered separately, in English and in French; a stale revision is a
  409; a snapshot from another document, an unknown target and a missing snapshot are 400s; a bad
  token is a 401. Verified over real HTTP.
- The provider wire contract, with a mocked transport and no key: the documented `response_format`
  field with a named `json_schema`, a schema that matches the DTO actually decoded, a valid candidate
  assembled by the server, and missing fields, truncated output, unknown references, unknown kinds,
  refusal, quota errors and timeouts all rejected. Tested.
- The sentence typed in the inline composer reaches the intelligence source as the request's
  instruction, and a failed call leaves the draft in the composer instead of discarding it. Tested with
  a capturing fake source.
- The document is saved when the app quits normally, with no Cmd+S: the app delegate is connected to
  the model the window is showing, and both quit hooks report a failure rather than swallowing it.
  Tested through the real delegate, and confirmed end to end by quitting the launched app and finding
  the document on disk afterwards.
- A local decision, set aside or reopen, leaves the camera exactly where the user left it. `Cmd+0`
  remains the explicit reframe. Tested.
- A collapsed direction is selectable, so its contextual "Reopen" button is reachable by click, and
  reopening is also a named accessibility action rather than a double-click only.
- The on-device adapter behind the existing `SuggestionService` seam: a compact `@Generable`
  candidate, a trusted conversion that mints identifiers and refuses kinds the canvas cannot render,
  a branch bounded to a few ideas, and `noChange` / `needsInput` passed through as themselves. Tested
  with a stubbed probe, so every unavailable state is reachable and no test needs Apple Intelligence.
- Availability is read from the reasons the SDK actually reports, and each maps to a distinct
  explanation. An unavailable model is a refusal: the app never falls back to the demo engine, never
  calls a network, and never claims an answer it did not get. Tested.
- Service selection: with no preference a usable on-device model is preferred over the offline engine;
  an explicit `demo` is respected even when the model works; `server` without a token falls back and
  says so. Tested.
- The deterministic suite never touches a real model. It runs in under two seconds and passes
  identically on a Mac with and without a usable system model, because every test pins the engine
  explicitly.
- `.kollio` document: versioned JSON, exact round-trip, stable ids, portable geometry, no renderer type
  in the file. Tested.
- Commands, transactions, atomicity, undo and redo. Tested.
- Durable decisions: set aside, collapse without deletion, reopen with the exact positions, survival of
  save and reload. Tested.
- Proposals: validation of ids, invariants, operation budget, staleness, forbidden operations. Tested
  in the domain, again in the client, and again in the server.
- The offline engine reacts to the real document state rather than replaying a sequence. Tested.
- Canvas geometry: world/screen round-trip, pan, zoom around an anchor, drag at several zoom levels,
  framing, connector endpoints. Tested.
- Connector obstacle avoidance: a connector never crosses an object that sits between its ends. A
  clear connector keeps the exact curve it had before, a blocked one detours around the side needing
  the smaller excursion with a fixed clearance, and the relationship label follows the curve. Tested.
- The vertical slice: Sarah, Explore, ghost branch, Keep, Undo, Explore again, Set aside with a reason,
  Reopen, save, quit, reopen. Tested end to end through the real model and the real file.
- The server: routes, bearer auth, scoping, provider swap, timeouts, cancellation, rate limiting, and
  the safety cases (malformed output, refusal, disabled remote provider). Tested.
- The server-backed client flow, through the real routes and the real JSON. Tested.
- French and English interface, from a native String Catalog, with no key ever visible.

## Implemented, seen on screen, but not automated

- Real pointer interaction: dragging, double-clicking to explore, pressing the contextual buttons. The
  model behind each of these is covered by tests and the resulting states were captured as screenshots,
  but the click coordinates themselves were not driven by an automated UI test, because this
  environment does not grant UI scripting access. A human should still do a pass with a trackpad.
- The entry point as a user reaches it: the invitation, the multiline field and the primary action were
  seen in the launched app (`build/01-entry.png`). **Typing a sentence and pressing the action was not
  done by a human or a script**: keystroke injection needs accessibility access, which this
  environment refuses. The behaviour behind it is covered by tests against the real model, and the
  transport it triggers is covered separately, but the two have not been joined by an actual person
  typing.
- A full run with a ghost branch proposed by the **real on-device model** has not been captured. The
  generation, the conversion and the validation are each verified; the assembled screenshot is not.

## Simulated or approximated

- **The offline "intelligence"** is a rule engine with authored demo content, not a language model. It
  is deterministic and state-reactive, which is what the prototype needs, and it is not evidence that
  a real model produces good proposals.
- **`GroqProvider` has never been called with a real key.** Its wire contract is now correct and
  tested against a mocked transport, which is evidence about the request and the decoding, and
  **nothing at all** about the quality, latency or reliability of a live model. Treat its output
  quality as unknown until a small live test is authorised.
- The server validates against the snapshot the client sent, scoped to the requested neighbourhood.
  It validates the operations in that slice and nothing else: it does not see the rest of the
  document, and it is not authoritative. A partial snapshot is reported as partial rather than
  validated as if it were whole.
- A service is chosen by environment variable, not by UI. A `server` mode with no token in the
  Keychain falls back to the offline engine, and the status line says which source is in use. There is
  no provider control panel, and a live-mode error is reported rather than silently downgraded.
- **On-device generation is slow enough to need streaming, and an earlier 9 to 15
  second figure does not reproduce.** Measured 2026-09-26 on the same Mac, serially:
  the first call in a fresh process is 3.6 s, later calls are 2.2 to 2.7 s, and a
  three-call series in one process runs 2.50 s, 2.68 s, 2.29 s. So the cost is
  mostly per call rather than a large one-off asset load.
  An earlier round reported 9 to 15 s and called it the dominant finding. That
  number is not reproducible and the cause is unconfirmed. The most likely
  explanation is contention: the real-model suite runs in parallel by default and
  two tests hit the same on-device model at once, which pushed the first
  measured call to 7.08 s. Real-model latency must therefore be measured with
  `--no-parallel`.
  What survives is the conclusion, not the number: 2.3 s is still far too slow to
  feel interactive. The wait is now filled, because the answer streams: 54 progress
  updates over 5.1 s on a real model, the rationale arriving a few words at a time.
- **Streaming shows progress, not a forming proposal.** Only the rationale text and a
  count of directions are shown. A half-decoded direction is never drawn on the
  canvas, because it has no identifier, no kind the canvas can trust, and no way to be
  validated. The ghost branch still appears all at once at the end. Streaming the
  actual objects is not built.
- **Streaming is proven on the on-device path only.** The remote provider does not
  conform to `StreamingSuggestionService`, so a server round trip still waits for the
  whole answer. The seam allows it; nobody has done it.
- The on-device candidate is a small, fixed shape: an outcome, one sentence, and a bounded list of
  ideas. It cannot propose decisions, question existing objects, or edit a relationship's meaning,
  because the adapter does not yet convert those. This is a limitation of the conversion, not of the
  model.
- **Apple Private Cloud Compute is not implemented and not evaluated.** Entitlement, distribution
  route, quota and runtime availability are all unverified on this machine. No request leaves the Mac
  today, and nothing in the code path would send anything.

## Not built


Everything in the non-goals, and also, honestly:

- **Relationship selection.** A connector has a label and a hit area in the design, but selecting a
  relationship is not implemented.
- **Keyboard traversal of the canvas.** Nodes are focusable and actions are reachable, but there is no
  arrow-key navigation between objects.
- **Reduced motion and increased contrast** are honoured in the motion and border tokens, and have not
  been walked through with a human eye under those settings.
- **No performance measurement.** 100 objects and 200 relationships is the stated target; nothing has
  been measured. Off-screen culling is available on the camera and unused.
- **Two-finger scrolling is wired and its routing is tested; the gesture is not verified by a
  person.** An earlier version placed the catcher in `.background` with `.allowsHitTesting(false)`,
  which cannot work: SwiftUI drops that subtree from hit testing, so AppKit never routes a scroll to
  it. It is now a topmost overlay that claims a hit only while a scroll event is being routed, and
  `ScrollDeliveryTests` proves three things: a scroll reaches the canvas, a click does not, and a
  text field outranks both. **Still owed:** a real trackpad scroll and its feel, which no test
  substitutes for.
- **The specification is written down; most of it is not built.** 71 features and 169 acceptance
  criteria exist in [specs/SPECIFICATIONS.md](specs/SPECIFICATIONS.md). 11 are `automatedVerified`,
  1 is `humanVerified`, 59 are `specified`, which means written down and nothing more. Read
  [../openspec/specs/evidence.md](../openspec/specs/evidence.md) for the proved, the owed and the
  wrong.
- **No web renderer, no public SDK, no standard.** Intentional.
- **No persistence, no accounts, no payments, no marketplace, no collaboration.** Intentional.
