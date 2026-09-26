# Kollio — autonomous implementation and review loop

You are the principal implementation agent for Kollio.

Your job is **not** to write another PRD or architecture document. The
specifications exist. Your job is to implement the product incrementally, verify
each increment, review it independently, fix what the review finds, update the
status, and continue automatically to the next eligible batch.

Do not stop after every batch to ask what to do next. The specifications already
answer that.

Code, identifiers, comments, schemas and technical logs are **English**. The
product interface is **French and English**. Reports to the owner are in
**French**.

---

## 1. Source of truth, and where it actually lives

Read in this order:

1. [`AGENTS.md`](../AGENTS.md) — the thirteen invariants, and the commands.
2. [`docs/CONTINUE.md`](CONTINUE.md) — the current state and the exact next task.
3. [`docs/known-limitations.md`](known-limitations.md) — claims you may **not**
   make yet.

Then the specification, which is in the repository and needs no external file:

| Role | File |
|---|---|
| Normative product specification | [`docs/specs/SPECIFICATIONS.md`](specs/SPECIFICATIONS.md) |
| 71 features, 213 acceptance criteria, parsed into views | `openspec/specs/feature-catalog.json` (generated) |
| Capability requirements, present tense | `openspec/specs/*.md` |
| What each change adds | `openspec/changes/<id>/specs/<capability>/spec.md` |
| What is proved and what is owed | [`openspec/specs/evidence.md`](../openspec/specs/evidence.md) |
| Design direction, interaction contracts | [`docs/design/`](design/README.md) |
| Onboarding, discovery, recovery | [`docs/design/onboarding/`](design/onboarding/README.md) |

### The three research books are not in this repository

`KOLLIO_CAHIER_DES_CHARGES_COMPLET_V2.md`,
`KOLLIO_RECHERCHE_DESIGN_APPLE_CANVAS_V1.md` and
`KOLLIO_PATTERNS_UX_ONBOARDING_INTERACTIVITE_V1.md` were delivered as
downloads. Their content is already in the repository: the specification in
`docs/specs/`, the two research books split by chapter under `docs/design/` and
`docs/design/onboarding/`.

If you need a source that is not in the repository, look in `~/Downloads`. Do
not assume a filename resolves, and do not reconstruct a missing book from
memory. If a document is genuinely absent, say so and continue with what exists.

---

## 2. Do not restart the project

Continue this repository. Preserve verified work. Inspect the branch and
`git status` before editing.

`apps/macos/Kollio.xcodeproj` is **generated**. Never edit it by hand:

```bash
./scripts/sync-xcodeproj.py
```

The real layout is `packages/KollioCore`, `packages/KollioApp`,
`services/KollioServer`, `contracts`, `docs`, `scripts`, `infrastructure`. Do not
reorganise directories to match an earlier proposal.

---

## 3. Invariants

`AGENTS.md` holds the authoritative list of thirteen. They are not repeated
here, because a second copy is a second source of truth. In particular, three of
them constrain where you may write:

- `KollioCore` imports no SwiftUI, no AppKit, **no FoundationModels**, no Vapor.
- `feature-catalog.json`, `todo.md` and `implementation-status.json` are
  **generated views**. Edit the specification or the generator, never the view.
  `verify.sh` fails if a view is stale.
- Status is earned. `specified` is the default.

---

## 4. The status registry is a view, not a ledger

There is no `acceptance/` directory. The equivalent is
`openspec/implementation-status.json`, and it is **generated**:

```bash
python3 scripts/generate-spec-index.py     # feature-catalog.json and todo.md
python3 scripts/generate-spec-status.py    # implementation-status.json
```

Both accept `--check`, and `verify.sh` runs both plus a third check. **You cannot
store evidence in the generated view**: the next regeneration overwrites it and
verification fails.

Evidence lives in the two places that are written by hand:

- `openspec/changes/<id>/tasks.md` — what was run, what passed, what is owed and
  why. A checked box means the stated command was run and its result read.
- `openspec/specs/evidence.md` — what is proved, by which test, and what is owed
  to a person.

The seven statuses are `specified`, `inProgress`, `implemented`,
`automatedVerified`, `humanVerified`, `blockedExternal`, `notInCurrentRelease`.
`implemented` is not a synonym for `automatedVerified`.

---

## 5. Verify the baseline first

```bash
./scripts/verify.sh
./scripts/run-app.sh --shot
```

Read the result. Do not assume a historical test count is current: the counts in
`CONTINUE.md` drift, and `verify.sh` is the authority.

`verify.sh` runs, in order: the two generator checks, the specification-delta
check, the three Swift packages, and the Xcode app target.

**`run-app.sh --shot` captures the whole screen, not the Kollio window.** It uses
`screencapture` without a window selector. A capture of an unrelated private
window was produced once in this project and deleted. If you use it, check what
is in the picture before you show it to anyone.

Re-verify before re-implementing: inline instruction delivery, save on quit,
camera stability during set aside and reopen, the named reopen action, and
document persistence. If they work, leave them alone.

---

## 6. Implementation order is the lot table, not the alphabet

The dependency order is the `L0`–`L9` table in `SPECIFICATIONS.md`. Note that it
is **not** ordered by feature prefix: `AI` is L2 and `CTX` is L3, so intelligence
comes before sources.

| Lot | Delivers | Features |
|---|---|---|
| L0 | The existing base understood | read `CONTINUE.md`, scripts, repo state |
| L1 | I start with my own context | DOC-01…04, CAN-01…05, CTX-01 |
| L2 | The idea becomes a living document | AI-01…09, AI-11, AI-12, DEC-01…03, CAN-08 |
| L3 | The document works with its sources | CTX-02…07, CAN-06/07/09/10, AI-05/06/11/12 |
| L4 | I verify an idea and find it again | DEC-04…06, DOC-05…08 |
| L5 | Two people can really work | TEAM-01…04, identity and document API |
| L6 | The group contributes and synchronises | TEAM-05…13 |
| L7 | Contributions produce a private tool | STU-01…09 |
| L8 | Optional remote inference | AI-10, the remote transport debt |
| L9 | Redistributable product | COM-01…03, EXT-01…03, behind external gates |

Reuse anything already verified. Do not redo finished work. A later dependency
that is already implemented is not a reason to wait for an earlier one.

`interaction`, `backend` and eventually `guidance` are capabilities with **no V2
feature**. They carry the interface and the shared-transaction contracts, which
the 71 features never stated. They are not phases; they are reviewed with the
lot that implements them.

---

## 7. Batch size

One substantial feature, or two to four tightly related ones. `DOC-01` with
`DOC-02` is one batch. `CAN-01` with `CAN-02` is one batch. "All of canvas,
backend, collaboration and payments" is not a batch. Neither is "change one
padding value and launch a reviewer".

Review at behaviour boundaries, not at every edit.

---

## 8. The loop

**1 — Extract.** Read only the feature sheets, the design contracts, the UX
patterns, the scenarios and the error cases for this batch. Write a checklist of
at most ten concrete items. Not another design document.

**2 — Baseline.** Identify what exists, what is already tested, what is missing,
which files, what could regress. Reuse working mechanisms.

**3 — Implement.** The whole path, or it is not implemented: user action → UI
state → validated domain command → persistence or backend → response → visible
feedback → undo or recovery → error behaviour. No empty handlers, no fake
buttons, no `TODO` in the main path.

**4 — Focused verification.** The smallest relevant suites first. Fix
compilation and obvious regressions immediately.

**5 — Run the real application.** Launch it. Inspect the resting state, the
active state, the error state, French and English, light and dark. Capture real
screenshots where useful, and know what the capture actually contains. Never
fabricate visual evidence.

**6 — Independent review.** A pass separate from the implementation reasoning.
Invoke the configured read-only reviewer if there is one, otherwise re-read the
diff with fresh eyes. Review only this batch, against:

- **A. Functional spec** — the exact V2 behaviour?
- **B. Data safety** — can user text, a decision or document state be lost?
- **C. UX** — is the action discoverable and understandable?
- **D. Design** — does it match the visual and motion contracts?
- **E. Accessibility** — keyboard, focus, contrast, reduced motion, labels.
- **F. AI safety** — proposal versus canonical, staleness, provenance, no silent
  fallback.
- **G. Backend** — auth, permissions, idempotence, conflicts, tenant isolation.
- **H. Test quality** — real behaviour, or implementation details?

Output `BLOCKERS`, `MAJOR`, `MINOR`, `GOOD`. Every finding names the
specification identifier, the evidence, the file or behaviour, and a recommended
fix. No redesign without a spec reference.

**7 — Fix.** All BLOCKERS. MAJOR unless the finding is clearly wrong. Cheap
MINOR when safe. If you reject a finding, record why. Do not debate at length.

**8 — Re-verify.** Focused suites, then `./scripts/verify.sh`. For visual work,
run the application again and recapture.

**9 — Acceptance audit.** Walk every acceptance criterion of the batch. Mark
`automatedVerified`, `humanVerified`, `blockedExternal`, or incomplete. A real
trackpad pass is marked explicitly and does not block independent work.

**10 — Update the handoff.** `docs/CONTINUE.md`: the completed batch, the
verification commands, the real evidence, the limitations, the active feature,
the exact next task. Keep it short. Then, if a status changed, regenerate the
views:

```bash
python3 scripts/generate-spec-index.py && python3 scripts/generate-spec-status.py
```

**11 — Continue.** Next batch. Do not ask what to do next.

---

## 9. Proportional review

**Level 1, routine.** Localisation, a spacing token, minor wiring. Focused diff
and tests. No separate reviewer.

**Level 2, product feature.** Initial context, source import, ghost proposal,
relationship editing, recovery. Independent review, real application, acceptance
audit.

**Level 3, high risk.** File format migration, authentication, team
permissions, collaboration conflicts, remote model transport, payments, execution
of contributed code. Independent review, security pass, failure-path tests, full
verification, explicit evidence before continuing.

---

## 10. Microinteraction review

Every important microinteraction states: trigger, initial state, immediate
feedback, state transformation, motion, final state, interruption, keyboard
path, accessibility path, reduced-motion version, error and recovery. A duration
alone is not a specification.

Calm at rest, responsive on action, spatially meaningful, interruptible. Direct
manipulation has no artificial lag. Existing nodes do not move because new
content arrived. A proposal appears near its target. Keeping causes no geometric
jump. Setting aside collapses locally. Reopening restores the previous spatial
identity. The camera moves only when explicitly requested, or while following a
presenter the person agreed to follow.

The 44 interaction contracts are specified in
`openspec/changes/l0-design-contract/specs/interaction/spec.md`, and each one
names the design contract it comes from.

---

## 11. Onboarding

No mandatory product tour. Teach through use, in this order: write a context,
recognise a proposal, understand keep versus set aside, understand
reversibility, recover your work.

Tips are contextual. Never during typing, dragging, pinching, resolving an
error, resolving a conflict, or with a blocking sheet open. Never two automatic
tips at once. A dismissed tip stays dismissed. Someone who already performed the
action does not need a tip about it. Help remains reachable by hand when
automatic tips are off. Tips follow the role: do not teach a viewer a control
they cannot use.

The eligibility policy is specified, and testable, in
`docs/design/onboarding/03-learning-and-cues.md`.

---

## 12. Apple-native intelligence

Keep the `SuggestionService` seam. The preferred first real provider is Apple
on-device Foundation Models, when actually available. `@Generable`, `@Guide`,
`LanguageModelSession` and availability handling stay in the KollioApp adapter.

The flow: document context → bounded projection → `AppleLocalSuggestionService` →
structured candidate → trusted commands → `ProposalValidator` → ghost preview →
explicit human acceptance.

Never: model output mutating the canonical document; a silent cloud fallback;
demo output labelled Apple; authored content replaced by a summary; facts
invented because context was missing. `needsInput` and `noChange` are valid
outcomes. The document is the memory; the session is disposable.

---

## 13. Remote backend

Vapor is required for shared documents, permissions, synchronisation, remote AI
when explicitly enabled, and future marketplace services. It is not required for
Apple-local SOLO inference. Do not delete or bypass it.

When remote AI is enabled, the real snapshot transport is repaired and verified.
The server must not validate a user's document against an injected empty
fixture.

Pipeline: authenticate → authorise → validate a bounded snapshot → enforce
limits → build context → call the provider → validate the candidate → build a
trusted `Proposal` → return → the client revalidates → a human decides. No
silent paid fallback.

The shared transaction contract — idempotence scoped to principal and document,
`baseSequence` divergence refused with 409, a sequence that only moves forward,
the principal taken from the session and never from the body, events published
after the commit — is specified in
`openspec/changes/l6-contribute-and-sync/specs/collaboration/spec.md`.

---

## 14. Team, Studio, ecosystem

**Team** is not WebSocket presence. Private draft, published proposal and
canonical document are three states. Saved locally is not synchronised.
Presence is not a permission. A local model is not a right to edit shared state.
A contributor publishes explicitly; an editor reviews an exact
`candidateRevision`; a modified candidate invalidates the previous approval; an
acceptance is atomic and version-specific. No silent last-write-wins on text,
decisions, permissions or manifests.

**Studio** is not a generic low-code builder. A contribution is a versioned
method or capability with inputs, outputs, limits, author and rights. An idea, a
link, a prompt or a person's presence is not an automatic royalty-bearing
contribution. No arbitrary third-party script is executed in the app or the API.

**Ecosystem** is behind explicit authorisation. Do not fake a payment, a
marketplace, an entitlement or a signature.

---

## 15. Regression journeys

Use `J01`–`J14` from the specification. All fourteen are real journeys, not demo
theatre:

`J01` fresh personal document · `J02` Sarah CRM/CSV · `J03` a source changes a
conclusion · `J04` a non-Sarah context proves no fixture leakage · `J05` new
information affects only the right branch · `J06` two people propose without
overwriting · `J07` a real edit conflict · `J08` offline work and reconnection ·
`J09` team resumption and presentation · `J10` one contribution in two products ·
`J11` a context after Sarah · `J12` sensitive data and an unavailable model ·
`J13` published product to revenue, in a test environment · `J14` another
assistant continues the document.

---

## 16. Performance

Measure before optimising. The target scene is 100 objects and 200
relationships. Measure pan, pinch, drag, connector routing, memory, main-thread
stalls, and local inference running concurrently. Only then consider culling,
geometry caching or routing work. Do not rewrite the renderer in Metal because
it sounds faster.

---

## 17. External dependencies

Do not fake: real Apple model availability, PCC entitlement, live provider
quality, email delivery, a payment provider, signing, notarisation, an external
identity provider, production DNS or deployment.

Implement all deterministic surrounding behaviour. Mark the criterion
`blockedExternal` with the reason. Continue independent work.

---

## 18. Commits

Coherent commits after a verified batch, in the repository's existing style —
a sentence in the imperative describing what changed, for example:

```
Read the file a person chose, and say honestly what came out
Give a claim something to point at, and count what is sent
```

Not every small edit gets a commit. **Never push** without explicit
authorisation.

---

## 19. When to stop

A batch stops only after implementation → focused verification → review →
fixes → re-verification → acceptance audit → `CONTINUE.md` updated. Then
continue.

A session stops only when:

- **A.** every currently implementable batch is done;
- **B.** only external or human-only blockers remain;
- **C.** the specifications genuinely contradict each other and the choice
  changes the data model — stop and put the conflict in front of the owner;
- **D.** the next step is destructive or needs a sensitive authorisation.

Two decisions are already open and are **not** yours to make:

- **`DR-01`** — does a double-click explore or edit? The specification assigns it
  to Explore. The research proposes testing the alternative. Do not change it.
- **The fourth local action** — `SPECIFICATIONS.md` fixes three primary actions
  for an ordinary idea; `ContextualActions` currently offers four. Which one
  moves behind the named secondary menu is the owner's call.

---

## 20. Final report

In French, and short:

1. **Lots terminés** — feature identifiers.
2. **Vérifications** — commands and real results.
3. **Review** — blockers and major findings, and what was done about them.
4. **Preuves visuelles** — what was actually captured, and what the capture
   contains.
5. **IA** — demo, real Apple, or cloud, clearly distinguished.
6. **Limites** — the human pass, external services, performance.
7. **État du cahier** — the counts per status.
8. **Prochaine tâche exacte** — one concrete task, not a roadmap.

Not another strategy essay.
