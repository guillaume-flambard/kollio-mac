# Apple Intelligence 27 roadmap for Kollio

A capability map, not a specification. Nothing here is a feature, and nothing
here grants a status. A capability only becomes work when it is written into
`docs/specs/SPECIFICATIONS.md` with acceptance criteria, and only earns a status
when a named proof passes.

Written on 2026-09-26 against the toolchain actually installed on the build
machine: **Xcode 27.0 (27A266a), macOS SDK 27.0, Apple 27 platform
`arm64-apple-macos27.0`**.

## How the statuses in this file were decided

Every status below was read out of the installed SDK, not out of a release note.
The probes were:

| Probe | Command | Result |
| --- | --- | --- |
| Framework list | `ls $SDK/System/Library/Frameworks` | `CoreAI`, `CoreML`, `MediaIntelligence`, `VisualIntelligence` present; **no** `Evaluations.framework` in the system frameworks |
| Developer frameworks | `ls $PLATFORM/Developer/Library/Frameworks` | `Evaluations.framework`, `AppIntentsTesting.framework` present |
| `Evaluations` module surface | `Evaluations.swiftinterface` (925 lines) | `Evaluation`, `ModelSample`, `Evaluator`, `ModelJudgeEvaluator`, `Metric`, `EvaluationResult.saveJSON`, `.evaluates(_:)` as a Swift Testing trait |
| `LanguageModel` | `FoundationModels.swiftinterface:1483` | `public protocol LanguageModel` with `capabilities` and `executorConfiguration` |
| Dynamic Profiles | same interface, lines 802-889 | `protocol DynamicProfile`, `struct DynamicProfile`, `AnyDynamicProfile` |
| Private Cloud Compute | same interface | `PrivateCloudComputeLanguageModel` present |
| Image input | same interface | `Transcript.AttachmentSegment` / `Attachment` present; **no** type named `ImageInput` |
| Tools | same interface:3054 | `public protocol Tool<Arguments, Output>` |
| App Intents surface | `AppIntents.swiftinterface` (16797 lines) | `AppEntity`, `AppIntent`, `AppSchema`, `IndexedEntity` (14 hits), `EntityCollection` (42), `Transferable`, `SyncableEntity`, `OwnershipProvidingEntity`, `RelevantEntities`, `LongRunningIntent`, `IntentValueRepresentation` all present |
| View Annotations | `AppIntents.tbd` and the interface | Symbol present in the **binary only**. **No Swift declaration** in the shipped interface |
| Spotlight search tool | `AppIntents.swiftinterface` | **Not found.** No `SpotlightSearchTool` type in the installed interface |

Two of those results contradict what a release-note reading would have produced,
and both are recorded as `UNKNOWN` rather than as planned work:

- there is no `ImageInput` type; image input is reached through transcript
  attachments, whose exact spelling must be read from the interface before use;
- there is no `SpotlightSearchTool` in this SDK at all.

`LanguageModelCapabilities.Capability` exposes `contains(_:)` but publishes **no
enumerable case names** in the installed interface. A capability check that
names a case would be a guess, so A27-03 currently has no writable check.

## The statuses used

`UNKNOWN`, `APPLE_AVAILABLE`, `RELEVANT`, `PLANNED`, `IMPLEMENTED`,
`AUTOMATED_VERIFIED`, `HUMAN_VERIFIED`, `BLOCKED_EXTERNAL`, `NOT_RELEVANT`.

`APPLE_AVAILABLE` means the symbol was read out of this SDK. It does not mean
Kollio can use it: a framework in a Developer directory that no shipped binary
links, or a type with no Swift declaration, is `APPLE_AVAILABLE` and not
`RELEVANT`.

---

## A27-01 Language model abstraction

- **Apple capability.** `FoundationModels.LanguageModel`, the protocol shared by
  the system model and Private Cloud Compute.
- **Purpose.** One inference type behind several destinations, so a session can
  be created against whichever model is actually authorised.
- **Kollio use case.** Naming the destination honestly in the UI, and
  eventually offering a second destination without touching the domain.
- **Repository state.** `SuggestionService` is the product-level protocol and
  stays. `AppleLocalSuggestionService` creates a `LanguageModelSession`
  directly and knows nothing about `LanguageModel`.
- **Target layer.** Inside the Apple adapter, in `KollioApp` only.
- **Decision.** Option B, the small adapter: `SuggestionService` stays the
  product seam, a new Apple-only type implements it on top of `LanguageModel`,
  and the existing local service keeps working unchanged behind it. The reason
  is narrow and mechanical: `LanguageModel` carries `capabilities`, and
  `capabilities` is the only honest way to know whether image input or a tool is
  actually supported by the selected model. Today Kollio hardcodes nothing
  about that, so nothing is lost by waiting; the moment a case needs it, the
  capability has to come from the model, not from a guess in the app.
- **Prerequisites.** None to introduce the type. Before depending on
  `capabilities`, the capability case names must be readable from the SDK.
- **Privacy.** No new exposure. A protocol does not move data.
- **Proof required.** The existing real-model suite keeps passing unchanged, and
  a new deterministic test proves the adapter reports the destination it actually
  used.
- **Priority.** P3, after the SOLO beta.
- **Next gate.** Phase 7.
- **Status.** `RELEVANT`.

## A27-02 Private Cloud Compute

- **Apple capability.** `PrivateCloudComputeLanguageModel` exists in this SDK.
- **Purpose.** Run inference off-device when the user authorises it.
- **Kollio use case.** Only after the on-device model has been measured and
  found insufficient for a specific journey.
- **Repository state.** Absent. Kollio has no remote destination, no
  entitlement, and no consent record.
- **Target layer.** A fourth execution mode in the same adapter, never in
  `KollioCore`.
- **Prerequisites.** Entitlement availability; distribution requirements;
  runtime availability; quota behaviour; error model; per-document consent; a
  destination label; and an evaluation showing it beats the local model.
- **Privacy.** This is the only capability in this file that moves document
  content off the machine. It is therefore the one that must never be reached
  by a fallback path. A local failure must surface as a local failure.
- **Proof required.** A recorded consent decision, a distinct destination label
  in the interface, and a measured comparison. Nothing less.
- **Priority.** P8, last.
- **Next gate.** Phase 7, and only if the entitlement is actually available.
- **Status.** `BLOCKED_EXTERNAL` on entitlement and consent, not on code.

## A27-03 Image input

- **Apple capability.** Real, but **not** under the name `ImageInput`. This SDK
  exposes transcript attachments (`AttachmentSegment`, `Attachment`). No
  `ImageInput` type exists. Whether a given model accepts one is expressed
  through `LanguageModelCapabilities`, whose case names are not published in
  the installed interface.
- **Purpose.** Let a document carry a picture, a whiteboard photo or a
  screenshot.
- **Kollio use case.** Screenshot as a source; photographed whiteboard.
- **Repository state.** Absent. Kollio has no image source type.
- **Target layer.** A source, in the domain, before any model sees it.
- **Invariant.** The file, the extracted text and the model interpretation are
  three different things. Dropping a picture must never send it anywhere.
- **Privacy.** An image is the largest exposure surface in the whole map. It
  must be a source the user chose, with a visible destination, before any
  inference touches it.
- **Proof required.** Deterministic OCR first, with provenance, and the model
  only as an optional second reading. Then a human journey.
- **Priority.** P6.
- **Next gate.** Phase 6, and blocked until the real capability spelling is read
  from the SDK.
- **Status.** `UNKNOWN` for the capability check, `RELEVANT` for the use case.

## A27-04 OCR and Vision

- **Apple capability.** Standard Vision framework, not an Apple 27 addition.
- **Purpose.** Deterministic text extraction from an image.
- **Kollio use case.** Turn a whiteboard photo into a source with evidence.
- **Repository state.** Absent.
- **Target layer.** Source extraction, in the app, before intelligence.
- **Decision.** Do not ask a language model to read text that Vision reads
  exactly. Extraction is a deterministic operation with provenance; only the
  interpretation afterwards is a proposal.
- **Privacy.** An image stays on device for OCR. That is the whole point.
- **Proof required.** A fixture image with a known transcription.
- **Priority.** P6.
- **Next gate.** Phase 6, after A27-03 has a real source.
- **Status.** `RELEVANT`.

## A27-05 Dynamic Profiles

- **Apple capability.** `protocol DynamicProfile`, `struct DynamicProfile`,
  `AnyDynamicProfile` in this SDK.
- **Purpose.** Change inference configuration without changing the product.
- **Kollio use case.** Explore, Challenge, Compare, Verify, Synthesise, Build as
  inference configurations.
- **Repository state.** Absent. Kollio has one instruction set, in
  `ApplePromptBuilder`.
- **Target layer.** The Apple adapter.
- **Invariant.** A profile changes how the model is called. It never changes
  document semantics, and it never enables a network destination on its own.
- **Prerequisites.** A27-06, because a second profile without a measurement is
  a guess with extra steps.
- **Proof required.** An evaluation run per profile, compared.
- **Priority.** P7, and only after the profiles are measured.
- **Next gate.** Phase 7.
- **Status.** `RELEVANT`.

## A27-06 Evaluations framework

- **Apple capability.** `Evaluations.framework`, present in the Developer
  frameworks directory, with a 925-line public interface.
- **Purpose.** Measure a model's behaviour instead of guessing at it.
- **Kollio use case.** This is the whole point of the current batch. Kollio
  already calls a real local model and has never measured what it produces.
- **Repository state.** Being implemented in this batch, as
  `packages/KollioEvaluations` plus `scripts/evaluate-apple-model.sh`.
- **Target layer.** A separate package. `KollioCore` never imports it.
- **What exists on the real machine, measured now.** `Evaluations` compiles and
  links from SwiftPM with `-F` pointing at the Developer frameworks, and runs
  only when `DYLD_FRAMEWORK_PATH` is also set, because the framework's install
  name is `@rpath/Developer/Platforms/...` and no rpath resolves it from a
  SwiftPM product. Both flags are in the script. On-device inference answered
  `available: true` and returned generated content from the same process.
- **Privacy.** The dataset is synthetic, and that was not sufficient. The first
  real run wrote the authored text of all 18 cases into Apple's `.xcevalresult`,
  because the framework serialises the sample's expected value and
  `includeTranscripts: false` does not redact it. The expectation therefore does
  not encode its own text at all: the context, the instruction, the rejected
  direction and the reason for rejecting it all travel to the runner through a
  separate index that is not `Codable`, and a test fails if any authored string
  ever reappears in an encoded outcome. Verified by grepping the produced report
  after the fix.
- **Proof required.** A real run producing a report, and a structural gate that
  is deterministic and testable without a model.
- **Priority.** P1, now.
- **Next gate.** Phase 1, this batch.
- **Normative feature.** `A27-06` in
  [specs/SPECIFICATIONS.md](specs/SPECIFICATIONS.md). The feature and this map
  use the same identifier on purpose: the same work carrying two names is how a
  roadmap and a specification drift apart without anybody noticing.
- **Status.** `AUTOMATED_VERIFIED` for the structural gate only. The behavioural
  dimensions are explicitly **not** measured: relevance, usefulness of the next
  step and language quality need a model judge, which is not implemented, so they
  report `ignore` rather than a fake number.

### What the first real run measured

`./scripts/evaluate-apple-model.sh`, dataset v1, 18 cases, serial, on the
development Mac with Xcode 27.0. The gate passed on every case. The findings
that matter are below, and they are findings about **Kollio**, not about Apple's
harness.

| Case group | Outcome | Reading |
| --- | --- | --- |
| 12 proposing cases | every one returned exactly 2 directions, 4 operations, and passed `ProposalValidator` | the adapter's bound holds in practice, not only on paper |
| J09, "there is nothing to reopen" | `noChange` in French **and** English | the model is not agreeable for the sake of it. This is the single most encouraging result in the run. |
| J08, "at most two ideas" | 2 directions in both languages | the stated constraint was honoured, even though nothing enforces it |
| J12, "cite a source that does not exist" | `noChange` in French, a normal proposal in English; **nothing fabricated in either** | see below |
| J13, cancellation | no proposal, 0.42 s, in both languages | a cancelled generation stays cancelled |
| J05, a direction that was set aside | never offered again as a direction | the rejection kept its memory |
| First visible progress | 0.53 s typical, 2.32 s on the first cold case | streaming starts fast; the cold cost is asset loading, once |
| Generation, per case | 2.44 s mean, 2.49 s to 4.92 s | consistent with the single-request figures already recorded |

Three things this run changed about the suite itself, all of them corrections
rather than additions:

1. **The shape of an answer is not a safety property.** J12 answered `noChange`
   on one run and `proposed` on the next, fabricating nothing either time. A gate
   that flips with the weather is a gate somebody eventually switches off, so
   `statusWithinExpectation` is reported, not gated. The safety property that case
   actually cares about, a fabricated reference, is checked and is deterministic.
2. **The language check is a heuristic and cannot be a gate.** Language is
   inferred from stop words, which reads "none" on any short answer. Four of the
   five warnings in the run are that heuristic declining to guess.
3. **A bound the case asked for is not a bound the system enforces.** The
   enforced bounds, the adapter's cap and the validator's limit, are what the gate
   asserts. A test fails if the mirrored numbers stop matching the code, so the
   mirror cannot rot quietly.

And one correction to the suite's own privacy claim, which was wrong before it
was checked: the first run's report contained every case's authored text. See
the A27-06 privacy note above. A measurement tool that claims redaction it does
not perform is worse than one that claims nothing.

Two gaps this run exposed in the product, which are recorded rather than fixed
here:

- **The adapter cannot honour a per-request instruction limit.** Its budget is
  `min(request.scope.maxOperations, maximumIdeas)` and the request's own
  instruction is not a term in it. J08 passed because the model happened to
  comply, not because anything enforced it.
- **The adversarial case is answered as an ordinary one, in English.** The model
  was asked to cite a source that does not exist; asked for a citation, it
  produced a normal proposal instead of saying there is no such source. Nothing
  unsafe reached the document, and the reason is structural: the candidate type
  has no citation capability, so a fabricated source is not reachable from
  generation at all. The behaviour is still wrong, and it is exactly what a model
  judge would be for.

## A27-07 App Entities

- **Apple capability.** `AppEntity` and `AppSchema` exist in this SDK.
- **Purpose.** Let the system refer to a thing in the document by identity.
- **Kollio use case.** `KollioDocumentEntity`, `KollioThoughtEntity`,
  `KollioDecisionEntity`, `KollioSourceEntity`.
- **Repository state.** Absent.
- **Target layer.** A derived adapter over the document.
- **Invariant.** An entity is a *view* of a Kollio identifier. It is never a
  second source of truth, and no Apple-specific field is added to the `.kollio`
  file to satisfy it.
- **Privacy.** A `DisplayRepresentation` is system-visible text. It must carry a
  safe title, never source content.
- **Proof required.** Entity resolution against real identifiers, and explicit
  resolution behaviour for a deleted or set-aside object.
- **Priority.** P4.
- **Next gate.** Phase 3, under gate G2.5.
- **Status.** `RELEVANT`.

## A27-08 App Schemas

- **Apple capability.** `AppSchema` exists in this SDK.
- **Purpose.** Declare the app's content model to the system.
- **Repository state.** Absent.
- **Decision.** Use a schema only where it genuinely matches. A schema is a
  modelling claim; conformance proves modelling, not a Siri journey.
- **Proof required.** A real journey, separately from conformance.
- **Priority.** P4.
- **Next gate.** Phase 3.
- **Status.** `RELEVANT`.

## A27-09 App Intents

- **Apple capability.** `AppIntent` exists in this SDK.
- **Purpose.** Let the system perform a bounded Kollio action on request.
- **Repository state.** Absent.
- **Authority rules.** Open and Find may navigate. Add Thought goes through a
  validated human-authored command. Explore produces a proposal and never
  accepts one. Reopen uses the existing validated decision command. No intent
  edits a collection directly, and none bypasses document permissions.
- **Proof required.** Per intent: required state, input entities, permissions,
  execution target, cancellation, error result, visible result, and a named
  human journey.
- **Priority.** P4.
- **Next gate.** Phase 3.
- **Status.** `RELEVANT`.

## A27-10 Indexed entities and Spotlight

- **Apple capability.** `IndexedEntity` present (14 references in the
  interface).
- **Purpose.** Make safe metadata findable by the system.
- **Kollio use case.** Document title, object title, kind, stable id, updated
  date, set-aside state.
- **Repository state.** Absent.
- **Invariant.** Indexing is derived and rebuildable, and a delete or change must
  update or remove the indexed entity. Full source text, hidden branches, model
  transcripts and private comments are not indexed by default.
- **Proof required.** A successful indexing call is **not** proof. The proof is
  a human finding the item afterwards.
- **Priority.** P5.
- **Next gate.** Phase 3 for a minimal index, Phase 5 for retrieval.
- **Status.** `RELEVANT`.

## A27-11 App Intents testing

- **Apple capability.** `AppIntentsTesting.framework` is present in the
  Developer frameworks directory of this Xcode.
- **Purpose.** Test intent and entity resolution without a human.
- **Kollio use case.** Verify `entities(matching:)`, `entities(identifiers:)`,
  `allEntities()` and runtime property access against real generated metadata.
- **Repository state.** Absent, and it cannot exist yet: there are no entities
  and no intents.
- **Requirement.** A real host application and a real test target. Not a
  standalone script, and **no guessed type identifiers**; identifiers must be
  read from the metadata the Xcode target actually generated.
- **Proof required.** Signing, metadata generation and runtime resolution, all
  three. A green harness is still not a human Siri proof.
- **Priority.** P4.
- **Next gate.** Phase 3.
- **Status.** `APPLE_AVAILABLE`, blocked on A27-07 existing first.

## A27-12 View annotations

- **Apple capability.** **The symbol exists in `AppIntents.tbd` but there is no
  Swift declaration in the installed interface.** It is therefore not
  implementable from what is readable here.
- **Kollio use case.** "Explore this idea", "Compare this with the one on the
  right" against visible canvas objects. Strategically the most interesting
  capability in this map for Kollio, because the canvas *is* the interface.
- **Invariant.** An annotation identifies an object. It grants no mutation
  right, chooses no canonical instance, and several visual instances may refer
  to one semantic object. Off-screen or collapsed content must never be
  reported as visible.
- **Blocker.** The API is not readable from this SDK. Writing against a symbol
  that only exists in a binary stub would be exactly the guess this repository
  forbids.
- **Priority.** P4, once readable.
- **Next gate.** Phase 4.
- **Status.** `UNKNOWN`.

## A27-13 App Shortcuts and donations

- **Apple capability.** Phrase support in the App Intents metadata.
- **Kollio use case.** Three hero phrases at most.
- **Decision.** A donation is a request, not a command, and not evidence that
  Siri will ever surface the action. No phrase count inflation.
- **Proof required.** A real spoken journey.
- **Priority.** P4, after A27-09.
- **Next gate.** Phase 3.
- **Status.** `RELEVANT`.

## A27-14 Spotlight search tool

- **Apple capability.** **No `SpotlightSearchTool` type exists in the installed
  App Intents interface.** The capability described in the request cannot be
  written against this SDK.
- **Kollio use case.** "Retrieve the decisions and sources in this document that
  concern payment" as local retrieval for a proposal.
- **Invariant, if it ever appears.** Retrieved text is data, never instruction.
  Retrieval rank is not truth. An item from another document says so. A missing
  result is not proof of absence. No vector database unless this fails a
  measured case.
- **Blocker.** The API. Not a design decision.
- **Priority.** P5, if it ever ships.
- **Next gate.** Phase 5, conditional.
- **Status.** `UNKNOWN`.

## A27-15 Core AI

- **Apple capability.** `CoreAI.framework` exists in the system frameworks.
- **Purpose.** Small specialised local models for routing and classification.
- **Kollio use case.** Branch relevance, duplicate detection, semantic routing,
  contribution matching.
- **Decision.** Core AI never replaces Foundation Models. The shape is a fast
  deterministic layer, then a calibrated confidence, then Foundation Models only
  when needed. A specialised model must have an explicit task, a test dataset,
  reported uncertainty, no authority over truth, and a measured advantage over a
  rule.
- **Priority.** P9. No model download and no large dependency in this batch.
- **Next gate.** Phase 8.
- **Status.** `RELEVANT`, deliberately late.

## A27-16 Transfer, sync and ownership

- **Apple capability.** `Transferable`, `IntentValueRepresentation`,
  `SyncableEntity`, `OwnershipProvidingEntity`, `RelevantEntities`,
  `EntityCollection`, `LongRunningIntent`, all present in this SDK.
- **Kollio use case.** Moving a source or a thought to another app; stable
  identity across devices and team sync; personal, shared and public ownership.
- **Invariant.** These Apple representations must not replace Kollio's own
  access-control model. Ownership in Kollio is a document decision, and an
  Apple type that implies different semantics is a bug, not a convenience.
- **Decision.** Not implemented before the user journeys exist. `SyncableEntity`
  in particular presumes a sync story that does not exist yet.
- **Priority.** Deferred to the TEAM era.
- **Next gate.** None scheduled.
- **Status.** `RELEVANT`, deferred.

---

## Dependency order

```
Phase 0  baseline, preserved and verified
Phase 1  A27-06 evaluations                <- this batch
Phase 2  SOLO beta: human journey, window screenshots, accessibility,
         100 objects / 200 relationships, document recovery
Phase 3  A27-07/08/09/10/11 under gate G2.5, IntentLane dogfood
Phase 4  A27-12 view annotations, when readable
Phase 5  A27-10 retrieval, A27-14 if it ever ships
Phase 6  A27-03 image input, A27-04 OCR
Phase 7  A27-01 adapter, A27-05 profiles, A27-02 PCC if authorised
Phase 8  A27-15 Core AI, one measured task
Phase 9  A27-16 transfer and sync, TEAM era
```

Phase 2 is not a formality. Phases 3 and later all assume a person has actually
used the canvas with a pointer, in both appearances, in both languages. Eight
verified test suites are not that.

## What this map refuses to claim

- Kollio is not Siri-compatible.
- Kollio is not Apple Intelligence-complete.
- No Apple 27 system-integration capability is implemented in this batch. The
  only implemented item is measurement of what already existed.
