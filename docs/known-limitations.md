# Known limitations

An honest inventory. Nothing here is a surprise: this is the prototype, not the product.

## Implemented and tested

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

## Simulated or approximated

- The offline "intelligence" is a rule engine with authored demo content, not a language model. It is
  deterministic and state-reactive, which is what the prototype needs, and it is not evidence that a
  real model produces good proposals.
- `GroqProvider` is implemented against the documented HTTP API and is exercised only by unit tests of
  its disabled and malformed paths. **It has never been called with a real key.** Treat its output
  quality as unknown.
- The server validates against a document the host injects. A production version would load the
  client's snapshot by revision; the current shape is a deliberate simplification, not an oversight.

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
- **No web renderer, no public SDK, no standard.** Intentional.
- **No persistence, no accounts, no payments, no marketplace, no collaboration.** Intentional.
