# Known limitations

An honest inventory. Nothing here is a surprise: this is the prototype, not the product.

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
  transport it triggers is covered by the local server run, but the two have not been joined by an
  actual person typing.

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
- **Two-finger scrolling is almost certainly not wired.** Code inspection found no scroll handling
  anywhere in the app: only a drag gesture and a magnify gesture. A trackpad two-finger scroll is
  therefore expected to do nothing, leaving panning to a click-drag on empty canvas. **Not
  reproduced**, and not fixed in this pass: it needs a real trackpad to confirm before anything is
  changed.
- **No web renderer, no public SDK, no standard.** Intentional.
- **No persistence, no accounts, no payments, no marketplace, no collaboration.** Intentional.
