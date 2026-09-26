# OpenSpec

Every feature in [../../docs/specs/SPECIFICATIONS.md](../../docs/specs/SPECIFICATIONS.md)
is a change proposal here. A change is a directory; a capability is a spec.

```
openspec/
├── specs/                  the capabilities, in the present tense
│   ├── documents.md        entry, context, saving, recovery
│   ├── canvas.md           navigation, manipulation, relations, scroll
│   ├── context.md          authored content, sources, provenance, budget
│   ├── intelligence.md     availability, proposals, local and remote
│   ├── decisions.md        keep, set aside, reject, reopen, undo
│   ├── collaboration.md    identity, consent, sharing, conflicts
│   ├── studio.md           presentable objects and composition
│   ├── commerce.md         a target, not a plan
│   ├── ecosystem.md        a target, not a plan
│   ├── interaction.md      not yet written; its delta is in changes/l0
│   ├── backend.md          not yet written; its delta is in changes/l6
│   ├── evidence.md         what is proved, what is owed, what is wrong
│   ├── feature-catalog.json   generated view of all 71 features
│   └── implementation-status.json  generated view per capability
├── todo.md                 generated, one line per feature
```

Two capabilities are registered in `implementation-status.json` and have **no
accumulated spec file yet**, because their deltas are not applied:

- **`interaction`** (L0) — the 44 interaction contracts. The product specified 71
  features and no interface contract; this is where that gap lives.
- **`backend`** (L6) — the shared transaction contract. The specification treats
  the server as infrastructure, which is right for Vapor and PostgreSQL and wrong
  for idempotence, `baseSequence` and the sequence, so those live in the L6
  collaboration delta.

Both are registered so their absence is counted rather than invisible. Their spec
files appear when their change is applied.

```
└── changes/                one directory per lot, in implementation order
    ├── l0-design-contract/   gestures, proposals, status, motion, contrast
    ├── l1-entry-and-canvas/      real entry point, canvas, saving, scroll
    ├── l2-living-document/       on-device intelligence, keep and set aside
    ├── l3-sources-and-provenance/  sources, quotes, retrieval, budget
    ├── l4-verify-and-resume/     verification, resume, export, backup
    ├── l5-team-identity/         identity and consent
    ├── l6-contribute-and-sync/   concurrency and reconciliation
    ├── l7-studio/                presentable objects
    ├── l8-remote-inference/      the remote provider, opt-in
    └── l9-ecosystem/             leaving, under the person's control
```

## The shape of a change

```
changes/<id>/
├── proposal.md     why, what changes, and what it does not
├── tasks.md        the checklist, in order, each item verifiable
├── design.md       decisions and the alternatives that were rejected
└── specs/<capability>/spec.md
                      ## ADDED Requirements
                      ### Requirement: …
                      #### Scenario: …
```

Requirements use `#### Scenario:` because a scenario is the smallest thing a
test can prove. The `specs/` directories carry the accumulated present tense;
a change carries its own delta.

## Rules that keep this honest

1. **A scenario is evidence, not a wish.** If no command can demonstrate it, it
   is written as a future requirement, not a passing one.
2. **A mock proves the contract, never the service.** A deterministic test
   covers the shape of a request; only a real run covers a real model.
3. **A prepared screenshot is not a pointer test.** Static evidence and human
   evidence are recorded separately, in different words.
4. **Status is earned.** `implemented` means code exists. `automatedVerified`
   means a test passes. `humanVerified` means a person did it. A skipped
   real-model test is never reported as a pass.
5. **A change is never closed while a criterion is owed.** The outstanding item
   is written in `tasks.md` as an unchecked box, with the reason.
6. **Scope is restricted.** An empty stub that looks like a feature is worse
   than an absent feature, because it is counted in the wrong direction.
7. **No push, no deployment, no paid call, no entitlement** without the owner's
   explicit agreement for that specific action.

## Generated views, and why they cannot drift

`specs/feature-catalog.json`, `todo.md` and `implementation-status.json` are
generated from the specification by two scripts:

```bash
python3 scripts/generate-spec-index.py     # the catalog and the todo list
python3 scripts/generate-spec-status.py    # the per-capability status map
python3 scripts/check-spec-deltas.py      # every requirement traces to a change
```

They are views, never a second source of truth. If they disagree with
`docs/specs/SPECIFICATIONS.md`, the specification wins and the view is
regenerated. Both scripts accept `--check`, and `./scripts/verify.sh` runs both,
so a stale view fails verification instead of quietly misleading the next
reader. The 71 features and their 213 acceptance criteria are parsed from the
prose, which is why a feature can never exist in the todo list without existing
in the specification.

`check-spec-deltas.py` checks a different thing. The capability specs are an
accumulation, so a requirement can be added to the present tense without anyone
being able to say which change introduced it or what it replaced. Six had
drifted in that way. The script fails when a requirement has no delta behind it,
when a delta targets a capability nothing knows about, or when a delta's own
status line no longer matches reality. It does not require a scenario per
requirement: scenario coverage is a review question, and a linter would only
push prose into scenarios to satisfy it.

## Where the truth lives

| Question | File |
|---|---|
| What must the product do? | [../../docs/specs/SPECIFICATIONS.md](../../docs/specs/SPECIFICATIONS.md) |
| What is proved, and what is owed? | `specs/evidence.md` |
| What is the state of each capability? | `specs/implementation-status.json` |
| What is left to do, in order? | `todo.md` |
| What does it do today? | [../../docs/known-limitations.md](../../docs/known-limitations.md) |
| What is the direction? | [../../docs/PRODUCT_BLUEPRINT.md](../../docs/PRODUCT_BLUEPRINT.md) |
| Which files prove it? | `changes/<id>/tasks.md` |
