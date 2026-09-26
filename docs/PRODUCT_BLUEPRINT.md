# Kollio product blueprint

Version 1.2, 2026-09-26. Apple-native first. This is the direction, not a
permission to build every part of it at once. The active milestone, the tasks
left and the evidence collected live in [CONTINUE.md](CONTINUE.md), which is the
document a new session should read. The Apple system-integration landscape is
mapped capability by capability, with the state of each one read out of the
installed SDK, in [apple-intelligence-27-roadmap.md](apple-intelligence-27-roadmap.md).

## What Kollio is

A living visual document that humans and intelligence sources build, question and
evolve together. The canvas is the application. The `.kollio` document is the
durable product model. Intelligence proposes changes; it never regenerates the
world.

The essential loop:

```
context → exploration → local proposal → human decision → persistent evolution
```

The first user must be able to begin with their own text, not only manipulate a
scripted demonstration.

"An enterprise target" means dependable work, isolation, traceability,
interoperability and operability. It does not mean more panels, microservices,
or a production-readiness claim.

## The one priority change in v1.1

Complete the real initial input, and evaluate on-device Apple inference,
**before** making a running Vapor server, an external API key or Groq a
prerequisite. The server and its tests are preserved, not deleted. Enterprise
services stay in the roadmap.

The consequence: an unavailable on-device model, a running server and a Groq key
are three different things. None of them may be silently substituted for
another, and none of them is a prerequisite for a working local product.

## Four execution modes, one product contract

| Mode | Where inference happens | Needs |
|---|---|---|
| `demo` | Nowhere: a deterministic rule engine | nothing |
| `apple` | On this Mac, via Foundation Models | an eligible Mac |
| `applePCC` | Apple's Private Cloud Compute | entitlement, distribution, quota |
| `server` | The Vapor backend, which may call Groq | server running, token in Keychain |

`applePCC` and a real Groq call are **conditional and deferred**. The Groq key
belongs to the server, in its environment. The Kollio API token belongs to the
client, in the Keychain. They are different things in different places.

"Uses Foundation Models" does not by itself mean on-device. "Local" is ambiguous
for an API that forwards data to the internet, so the interface says **"On this
Mac / Sur ce Mac"** when that is the truth.

An unavailable model does not authorize a transition to cloud or demo. The
manual editor stays available, and the real condition is shown.

## Layers

```
packages/KollioCore     domain, commands, decisions, validation, serialization
packages/KollioApp      the macOS application, and the Apple adapter
services/KollioServer   the optional remote-inference service
contracts/              JSON schemas and reference fixtures
docs/                   this blueprint, CONTINUE.md, known-limitations.md
scripts/                verification and project generation
```

`KollioCore` imports no SwiftUI, no AppKit, **no FoundationModels**, no Vapor. The
`@Generable` candidate types and the provider instructions live in the adapter,
never on a portable document or command type. A `.kollio` file stays readable on
a Mac with no Apple model at all.

The `.kollio` format never serialises a `LanguageModelSession` or its transcript.
The document is the memory; a session is disposable inference state.

## Domain and document contract

- `.kollio` is versioned, portable JSON with stable ids, explicit enums and
  renderer-independent geometry. No executable callbacks, no platform classes,
  no embedded credentials.
- Semantic state, presentation and transient editor state are separate. A
  semantic object may have several visual instances; duplicating a view never
  duplicates authorship or rights.
- Evidence records origin and verification status. An uploaded assertion is not
  proof. A scoped decision is not universal truth.
- JSON schema validity and business validity are distinct, and both are tested.
- An unsupported future version is rejected safely, or read in read-only mode.
  Unknown content is never silently discarded.

## Commands, revisions and history

Every meaningful mutation is a validated command in an atomic transaction. Views
never patch several domain collections independently. A human edit is direct and
undoable; an AI mutation requires explicit acceptance.

Monotonic mutation generations prevent an old response becoming valid again
because an undo moved a revision counter back. Edit → undo → new edit with an
outstanding request is a tested case.

Undo history, durable decisions and the operational audit log are three different
mechanisms. "Durable" means the decision survives a restart, not that it can
never be deleted.

## Proposals are provider-neutral

The path, on-device:

```
context → scoped immutable input → AppleLocalSuggestionService
        → typed candidate → trusted conversion → ProposalValidator
        → ghost branch → human acceptance → command transaction
```

The same seam carries `server`. Foundation Models is an implementation choice
behind `SuggestionService`, not a replacement for the `.kollio` protocol.

The model fills in meaning only. The trusted layer assigns request association,
final identifiers and execution metadata. A model never assigns its own
authority, verified status or ownership. Validation happens before the preview
and again before acceptance, against the live client document.

The optional HTTP path keeps `POST /v1/proposals` and sends a bounded
layout-free snapshot. Snapshots are client-authored input, never a trusted
server database.

## Safety and security

The on-device path needs no credential and no backend login. The app never
enables Apple Intelligence, never downloads model assets, and never edits an
account. If the model is unavailable it says exactly why, in the SDK's own terms,
and keeps working.

Document content is data, never instructions, and the prompts say so. No shell,
no browser, no filesystem, no network fetches of anything the document contains.

Logs carry counts, correlation ids and status. They never carry the document's
words, a transcript, reasoning text or a key. Content diagnostics are opt-in and
redacted.

Secrets stay out of source control and artifacts. A request cannot choose an
arbitrary provider endpoint. The software stays useful offline when cloud
services fail.

## Apple Intelligence 27 direction

Apple 27 extends this architecture. It does not replace it, and most of it is
not yet reachable from Kollio at all. What follows is the shape of the
direction; the per-capability status, the SDK evidence and the dependency order
are in [apple-intelligence-27-roadmap.md](apple-intelligence-27-roadmap.md).

- **Foundation Models stays behind `SuggestionService`.** The domain never sees a
  session, a model, or a destination. `KollioCore` imports no Foundation Models
  type, and adding a `LanguageModel` adapter changes nothing about that.
- **Apple system integration is a later product gate, not a current one.** App
  Entities, intents and indexing come after the SOLO beta, not before it. A person
  who cannot reliably drag an object has not got a product that a Siri surface
  would rescue.
- **IntentLane is the integration and verification tooling** for that gate, and
  its capabilities are checked before anything is hand-written here.
- **App Entities are derived views over Kollio ids.** An entity is a way for the
  system to name something that already exists. It is never a second source of
  truth, and no Apple-specific field enters the `.kollio` file to satisfy one.
- **App Intents call validated Kollio commands.** Open and Find navigate. Add
  Thought is a validated human-authored command. Explore produces a proposal and
  never accepts one. Reopen uses the existing decision command. No intent edits a
  collection or skips a permission.
- **Explore creates proposals, not accepted mutations.** The distinction is the
  product: the model proposes, a person decides, and the document keeps the
  memory of the refusal.
- **Spotlight indexing is safe, derived and rebuildable.** Titles, kinds, stable
  ids and dates. Not full source text, not hidden branches, not transcripts. A
  successful indexing call is not proof; a person finding the item is.
- **View annotations expose identity, not authority.** An annotation says which
  object is on screen. It does not grant a mutation, does not pick a canonical
  instance, and never reports off-screen or folded content as visible. The API is
  currently not readable from the installed SDK, so no code is written against it.
- **Evaluations precede prompt and profile expansion.** A second prompt without a
  measurement is a guess with extra steps. The evaluation suite exists first, and
  the three dimensions it cannot yet judge are named as unmeasured rather than
  quietly scored.
- **Private Cloud Compute is explicit and conditional.** It is a destination a
  person chooses with a label attached, never a fallback that a local failure
  triggers. Local intelligence failing is a local failure.
- **Core AI is specialised and later.** A small measured task, behind a fast
  deterministic layer, with calibrated confidence. It never decides truth and
  never bypasses `ProposalValidator`.

Two capabilities in that request are not in the installed SDK at all under the
names given: there is no `ImageInput` type, and there is no `SpotlightSearchTool`.
Both are recorded as unknown rather than planned, because writing against a name
that does not exist is how a codebase acquires fiction.

## Gates

**G0 — real entry + on-device Apple intelligence.** The active milestone.

**G1 — useful native intelligence and interaction confidence.** A compact FR/EN
reference set, real gestures, measured latency and usefulness.

**Remote activation — conditional.** Evaluate PCC eligibility, or repair and
verify the server transport. Never a prerequisite for local success.

**G2 — distributable native beta.** File recovery, relationship selection,
keyboard and accessibility, a measured 100/200 workload, signing.

**G2.5 — Apple system intelligence / IntentLane dogfood.** Added in v1.2, and
placed before nothing. It opens only after G2's human journey is done. It is one
small package: a document entity, a thought entity, open, find, add thought, safe
indexing, and an App Intents testing harness using identifiers read from real
generated metadata. One verified journey before a second intent. No Siri claim
without a person saying the words.

**G3 — organization pilot.** Tenancy, PostgreSQL where justified, sharing and
conflicts, policy, runbooks.

**G4 — enterprise readiness.** Federation, policy enforcement, measured service
objectives, incident and restore drills.

**G5 — interoperability and contribution economy.** A read-only web viewer
first; payments and third-party code execution only behind independent legal and
security gates.

These gates are not time estimates, and none of them is required before testing
the canvas with users.

## What this document is not

It is not a claim that any gate has been passed, that a model works on every Mac
that can open the editor, that PCC is available, or that Groq has been called.
Those are claims with evidence requirements, recorded in
[known-limitations.md](known-limitations.md).

## References

Apple documentation is not proof that a capability is installed, entitled or
verified on any particular Mac. Live SDK declarations are rechecked when
implementing.

- [A1](https://developer.apple.com/documentation/foundationmodels) Foundation Models overview
- [A2](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation) guided generation
- [A3](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models) availability
- [A4](https://developer.apple.com/videos/play/wwdc2026/319/) on-device and PCC differences, context inspection
- [A5](https://developer.apple.com/private-cloud-compute/) PCC eligibility
- [A6](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute) PCC integration
- [A7](https://developer.apple.com/videos/play/wwdc2026/241/) Foundation Models additions
- [A8](https://developer.apple.com/documentation/foundationmodels/languagemodelsession) session API
