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
./scripts/verify.sh     # the spec views, 3 test suites (154 tests), the Xcode app target
./scripts/run-app.sh --shot   # builds, launches, screenshots into build/
```

`KOLLIO_REVIEW=explore|kept|setaside|reopened ./scripts/run-app.sh` opens the app in a given state so
one step of the vertical slice can be captured in a screenshot. Use it instead of guessing what a state
looks like.

Note: `run-app.sh --shot` prints a path whether or not the capture worked, and it captures the whole
screen rather than the Kollio window. Check the file exists and shows the app before trusting it.

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

## Latest batch: CAN-02, selection and the actions it reaches

Escape used to clear the selection, the proposal and the composer in one press.
It now closes one level at a time, and the selection is the last thing it takes,
which is what `CAN-02` AC03 asks for. The order lives in one place,
`KollioModel.dismissOneLevel()`, and the five per-surface `onExitCommand` handlers
that used to mutate model state directly are gone, so one Escape cannot close two
levels. `pruneSelection()` is now the single place that drops a vanished object
from the selection, used by undo and redo.

Verified by `SelectionAndActionsTests` (7 tests): no selection, drag or clear
reaches the intelligence seam; a multiple selection hides a proposal without
applying or refusing it; the Escape order; Escape during a drag drops the offset
instead of committing it; the contextual surface follows the selection and not the
hover. `./scripts/verify.sh` passes: 85 KollioCore, 141 KollioApp, 29 server.

Then the owner settled the open question: **three primary actions is right**, and
`SPECIFICATIONS.md` §U02 already fixed which three. `ContextualActionSet` is now a
model fact with `maximumPrimary` as a `precondition`, so a fourth primary action
is a refused programming error rather than a silently demoted button. An ordinary
idea shows Explore, Add, Set aside; Edit, Add a source and the claim prompt moved
behind one named native `Menu` (new catalog key `canvas.moreActions`). Link,
Comment and Duplicate are not offered at all until they exist.

`CAN-02` stays `specified`, not `automatedVerified`, for one reason: reaching the
bar with a slow pointer is a human observation, and there is no screenshot of the
bar because the application launches with nothing selected and driving a selection
needs the accessibility access this environment refuses.

`./scripts/run-app.sh --shot` was run twice. Both captures were discarded. The
first contained unrelated private windows, because the script captures the whole
screen rather than the Kollio window. The second showed a **stale build**: an
earlier instance was still running and `open` only reactivated it. Quit the app
before capturing, or the evidence is of the previous build. `verify.sh` passes:
85 KollioCore, 144 KollioApp, 29 server.

## Latest batch: CAN-03, moving one instance or a group

The domain accepted a list of moves all along; the application only ever passed
one, so **AC02 was not implemented** and neither was "moving an occurrence does
not move its other occurrences". The fix was addressing, not animation:
`Presentation` gained `instances(of:)`, and the drag state now holds
`InstanceID` instead of `ObjectID`. `Presentation.instance(for:)` still answers
with the first instance, which is right for drawing and wrong for moving.

A group drag is now one `MoveNodeInstances` transaction. An unselected object
dragged while something else is selected moves alone, because "move what I picked"
and "move what I happened to touch" are different intents.

Nine tests in `MovingInstancesTests`. AC01 is asserted with the zoom division
*and* with the three results differing, so the test cannot pass on a constant.
`verify.sh`: 85 KollioCore, 153 KollioApp, 29 server.

## Latest batch: CAN-04, editing content in place

`UpdateObjectText` carried no version and `ContentObject` had none. Two people
editing one title both succeeded and the second silently won. So this was a
**format** change, not a view change: `ContentObject.objectVersion`,
`UpdateObjectText.expectedVersion`, and `DocumentError.staleObjectText`.

`expectedVersion` is optional on purpose. `nil` means "I did not look" and
overwrites; a number means "I saw this version" and a mismatch is refused. The
version advances only when the text actually changes, so re-submitting the same
words cannot make every other writer look stale.

`submitComposer` no longer clears the composer before writing. It could not
afford to: a refusal has to leave the person their text, and clearing first throws
it away on the way to finding out it failed.

### The finding that only the running app produced

Adding a non-optional `Int` made every document written before it **unreadable**:
`keyNotFound: objectVersion`, shown as a red banner over the entry screen. Every
unit test was green at that moment, because every fixture encoded its own version.
Reproduced as a failing test on a legacy payload, then fixed with the idiom already
in `KollioDocument` for `sources` and `claims`: `decodeIfPresent ?? 0`. A default
in an *initializer* is not a migration.

Eleven tests in `EditingContentTests`, two more in `DocumentFormatTests`.
`verify.sh`: 87 KollioCore, 164 KollioApp, 29 server, exit 0.

Owed: the two versions side by side in the conflict surface, and Cmd+Z inside the
field, which is an interaction between two undo systems this repository does not own.

## Latest batch: CAN-05, create, duplicate, remove

The chapter was simply absent from the domain: no command could duplicate anything and
none could remove anything. So there is now a fifth distinction the document keeps, and
the one the rest of the product already implied: an **occurrence** is something drawn,
an **object** is something said. Duplicate and delete each exist twice, and the two are
never the same gesture.

- `DuplicateNodeInstance` / `RemoveNodeInstance` touch only the canvas and do not move
  `semanticRevision`.
- `DuplicateObject` / `RemoveObject` change what the document says and do.
- A variant is linked by `derivedFrom`, so the document can still answer why it exists,
  and starts at version 0 rather than inheriting one.
- `ContentObject.Kind.unclear` lets an idea be written down before its kind is known.
  `createIdea` never calls a model, proved with a service that throws if consulted.

**AC01** holds because a copy carries a *reference* to a contribution, never a second
one: two objects may point at one contribution, and the ledger keeps one record, one
membership and one share.

**Two refusals, not two cleanups.** Removing the last drawing of an idea would leave a
node nothing draws, and the next save would write a document nobody can see, so it is
refused as `lastOccurrence`. Removing an object a decision points at would orphan a
durable record, so it is refused as `objectHasDecision` and the decision is revoked
first. Intelligence is refused both removals outright, next to the existing refusals for
`createScenario` and `removeRelationship`: a proposal that deletes is not a bounded
addition, it is a decision.

Twenty tests in `CreatingAndRemovingTests`. `verify.sh`: 87 KollioCore, 184 KollioApp,
29 server, exit 0.

### Two honest gaps

There is **no command that registers a contribution**. `addContributionToProduct` only
adds a share to one already in the ledger, so AC01 is proved against a seeded ledger and
there is no way yet to earn one from the interface. That is the real gap behind AC01.

And the **menu has not been seen on screen**. `run-app.sh --shot` captures the whole
screen, another application kept taking the foreground back, and a crop to Kollio's
coordinates captured that application instead. The four entries and the confirmation rest
on the twenty tests alone. The script should capture by window id and fail when the
frontmost process is not Kollio.

## Latest batch: CTX-01, add information at a precise place

`Add` was an AI call that spent the sentence. The composer sent the typed text as an
instruction and the model decided what to do with it, so the only place the sentence
existed was inside a request. CTX-01 says the opposite, and the sentence is the whole
argument of the chapter: **Add is not a call that spends the sentence.**

`addNote` now writes the sentence as an authored `.note`, linked by `associatedWith`, in
**one transaction**, locally. It is a note and not a hypothesis because the person has
said where this belongs and not what it *is*; requiring a kind there would put the burden
back on the person. `revealConsequences` is a separate later action, so a refusal, a
thrown error and a slow answer are three separate failures and none of them touches the
note. Proved with a service that throws if consulted: the call count stays at zero.

**AC01** findable after a relaunch, link included, so it is findable as information
about something rather than merely present. **AC02** the target is byte-identical
afterwards, version included. **AC03** a model error leaves the contribution with the
author's provenance intact. A double submission is deduplicated **per target**: the same
sentence about two different objects is two remarks, and merging them would lose where
each was said.

### A defect a test found

The first version stored the *folded* sentence, so a note saved a rewritten version of
what the person typed. That is the one thing this product never does. The folded form
now only compares two submissions; the note keeps the typed text exactly.

### Two tests rewritten rather than deleted

`InteractionReliabilityTests` proved the typed sentence reached the intelligence source,
and that a failed call left the draft in the composer. Both describe the behaviour this
chapter removes. The guarantee underneath is real, so it was rewritten in its new form:
the sentence arrives in the document instead of being on its way to a request, and a
refused write still leaves the draft. Deleting them would have lost "losing work is the
worst failure this app can have" without replacing it.

Fifteen tests in `AddingAtAPlaceTests`. `verify.sh`: 87 KollioCore, 199 KollioApp,
29 server, exit 0.

### The screenshot guard, and why it is not in the code

Three repairs to `run-app.sh --shot` were attempted and all three failed. Focusing Kollio
does not hold, cropping to the window's coordinates captures whatever is drawn there, and
guarding on the frontmost *process* is worse than useless: the guard reported `Kollio`
while another application's window was on top, which is the exact case it existed to
catch. A check that passes on its own failure mode is worse than none, so the script says
plainly that the file is a picture of the whole screen. **The visual evidence for CAN-04,
CAN-05 and CTX-01 rests on the test suites, not on that picture.**

## Latest batch: AI-03, explore a branch

Three things were declared and inert. `Preconditions.readSetFingerprint` existed and was
set nowhere and read nowhere. The request carried no `context` at all. And `noChange` set
`preview = nil`, so an answer that proposed nothing **destroyed the branch already on the
canvas**.

**AC01** was the sharpest: the exact instruction was being *discarded*. The `Explore`
branch of `submitComposer` cleared the composer and called `explore` with no instruction,
so a person who typed a steer and pressed the key had it silently ignored. Now the exact
sentence travels, and a refused send keeps the words in the composer.

**AC02**: `readSet(for:)` carries the target, what it links to, one step beyond, and every
rejected direction **with its reason**. "No budget" and "tried it in March" are different
instructions; a bare list of dead ends reads as a ban rather than as reasoning. A reopened
direction is transmitted as `active`, so the engine cannot refuse a door the person just
opened. And the engine honours only the rejections it was *given*, not the ones it could
find in the document, which would make it look as though it were consulting reasoning when
it was only pattern-matching state.

**The signature is stable** because it sorts before hashing. A fingerprint is only worth
anything if the same read set always gives the same string, and iterating dictionaries then
hashing in order would have made every precondition look stale.

**AC03**: a new proposal supersedes the old one, which is *offered* and kept readable, and
`noChange` takes nothing away at all. Destroying a pending branch because a later question
produced no answer is exactly the bug the criterion names.

### Un défaut trouvé par un test, localisé en mesurant

The read set kept the first mention of each object. A rejected direction that was also a
neighbour arrived with `reason: nil` and the rejection loop skipped it, so the same
document produced different read sets depending on iteration order, and the reason that
made a rejection useful was the thing most likely to be lost. Two failing tests found it;
printing the decisions, the objects and the read set located it, rather than reading the
code a third time.

Seventeen tests in `ExploringABranchTests`. `verify.sh`: 87 KollioCore, 216 KollioApp,
29 server, exit 0.

### Ce qui reste dû

The offer to keep or hide is not on screen: the state and the four functions exist and are
tested, nothing asks. Second-degree reach is a documented guess, not a rule of
applicability. And the read set is bounded by reach but not by a budget.

## The next things worth doing, in this order

1. A human pass. Three things only a human can settle: **type a sentence into the entry point and
   press the action**, **scroll with two fingers** (the code says it does nothing; confirm or
   refute), and **watch a real-model proposal arrive and be kept**. Then drag, double-click to
   explore, contextual buttons, `Cmd+0` / `Cmd+1` / `Cmd+Z` / `Cmd+S`, and quit without `Cmd+S`.
2. Latency, because it is the blocking finding: measure a warm call, a second identical call, and
   whether the first cost is asset loading or generation. A pending state that lasts ten seconds is
   the next thing the user will complain about.
3. Relationship selection: a label, a wider hit area than the visible stroke, and a contextual action.
4. Performance: generate 100 objects and 200 relationships, measure pan, zoom and drag, then use the
   camera's visible rectangle to cull. Connector routing samples its curve, so this is where the
   cost will show.
5. Keyboard traversal between objects, so the canvas is usable without a pointer.
6. Only then, and only with explicit permission: a small live Groq test, or a PCC eligibility check.
   Everything the transport needs is in place and mocked; what is missing is evidence about a live
   model, not plumbing.
