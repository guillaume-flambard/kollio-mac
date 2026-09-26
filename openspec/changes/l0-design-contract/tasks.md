# L0 — tasks

Nothing in this lot is proved. Several contracts already have partial evidence
from earlier lots; that evidence is named below, and it does not close a box
because it was written for another reason.

## One decision is not ours to make, and it is not a task

**DR-01 — does a double-click explore, or edit?** The specification assigns
double-click on an idea to Explore, with Edit behind a menu (`SPECIFICATIONS.md`
§Gestures, CAN-04 and AI-03). The research book records this as an open
amendment and asks for two variants to be tested, because a person who meant to
fix a phrase and triggered a generation has paid for a mistake, and a generation
is not free.

This is a product decision, not an engineering task. It is recorded here so it
stops being a note in a research document, and it is left **undecided**. Nothing
in this lot changes the double-click behaviour, and the requirement
"a gesture never starts intelligence" is written so that it holds under either
answer: selecting and editing never call the model, and only the double-click is
in question.

- [ ] **DR-01 is decided by a person, with evidence.** Owed: two variants, one
      task each, counting accidental generations and time to correct a phrase. Not
      a code change.

A second decision is nearer and smaller. `ContextualActions` offers four actions
for an ordinary idea — Explore, Clarify, Edit, Set aside — where the
specification's U02 fixes three: Explore, Add, Set aside. The requirement
"contextual actions are few, named and reachable" therefore cannot be satisfied
today. Which of the four moves behind the named secondary menu is a decision for
the owner, and it is not a bug to be fixed by an agent.

## A gesture never starts intelligence

- [ ] **No gesture path calls the intelligence seam.** Owed: today no test
      asserts the absence of a call. `VerticalSliceTests` and
      `InteractionReliabilityTests` prove that a composer reaches the source, not
      that a drag or a selection stays away from it. Needs a spy service that
      fails the test on any call, driven by selection, multi-selection, drag,
      title edit, link and source open.
- [ ] **The full editing set works with no destination configured.** Partly
      covered: `InitialContextTests` proves a context is created and persisted
      before any intelligence. Not covered: link, decision, reopen, export.
- [ ] **A double-click on a thought does not generate by surprise.** The V2
      contract assigns double-click to Explore (IX-14, DR-01). The research book
      records this as an unresolved amendment, and `docs/design/01-direction-and-decisions.md`
      keeps it as DR-01. It cannot be a passing requirement until a person
      chooses. Owed to a session, not to a test.

## A result is announced where the person is working

- [ ] **An arriving proposal does not move the camera.** Partly covered:
      `InteractionReliabilityTests` proves set-aside and reopen leave the camera
      alone. Not covered: the moment a proposal *arrives*, which is the case that
      matters. Needs a test that records the camera before and after `explore`.
- [ ] **A destination is named at the anchor while a request runs.** Owed: the
      status string exists, no test reads it, and the design requires the
      *effective* destination rather than a generic spinner.
- [ ] **An off-screen proposal offers a named way to reach it.** Owed: no such
      control exists.

## A proposal shows the geometry the keep will produce

- [ ] **Preview positions and post-keep positions are identical.** Partly
      covered: `VerticalSliceTests` proves a proposed branch does not land on
      existing content. Not covered: that the keep does not then move what the
      preview showed. Needs a before/after position comparison around
      `keepPreview`.
- [ ] **Two occurrences of one object move independently.** Owed: not implemented
      and not specified in the domain yet.

## Closing, setting aside and removing are three acts

- [ ] **Closing a preview is recoverable and revalidates.** Owed:
      `discardPreview` drops the preview with no record, so a closed proposal is
      currently indistinguishable from one that never existed. This is the
      requirement most likely to require new code.
- [ ] **A set-aside reason survives a relaunch.** Partly covered:
      `VerticalSliceTests` proves the direction and its decision survive a save and
      reopen. The reason text itself is not asserted.
- [ ] **No unlabelled cross performs a durable act.** Owed: no close control is
      labelled or unlabelled yet because none exists in the flow.
- [ ] **Removing an occurrence removes only that occurrence.** Owed: not
      implemented.

## Contextual actions are few, named and reachable

- [ ] **At most three primary actions per object kind.** Owed: `ContextualActions`
      currently offers four for a thought (Explore, Clarify, Edit, Set aside),
      which the design caps at three. Either the fourth moves behind the named
      secondary action, or the design is amended. Recorded, not decided.
- [ ] **The control survives the pointer travelling toward it.** Owed: needs
      synthetic mouse-move events over the gap.
- [ ] **The keyboard alone reaches the same actions.** Owed: focus exists, and no
      test drives it.
- [ ] **The control stays inside a small viewport.** Owed: the clamp in
      `anchorPoint()` is untested.

## Reduced motion removes displacement, never meaning

- [ ] **The state change survives with reduced motion on.** Owed: the flag is
      read in four views and no test exercises it. A view-level assertion is
      possible; whether a person still understands the change is not, and is owed
      to a person.
- [ ] **Dragging gains no lag under reduced motion.** Owed.

## Status is never carried by opacity or colour alone

- [ ] **A proposed object states its status in words and shape.** Partly present:
      `GhostNodeView` draws a dashed border and the word Proposition. The test
      does not exist, and the body text is at `0.86` opacity, which
      `docs/design/04-visual-language-and-surfaces.md` measured as passing but
      only just.
- [ ] **Every state named in the requirement meets its contrast floor in both
      themes.** Owed: the design computed twelve ratios from token values. Nothing
      asserts them, and token changes would silently invalidate the measurement.
- [ ] **Focus does not rely on the decorative border token.** Owed.

## Owed to a person, and not to any test in this repository

These cannot be closed by writing a test, and they are the reason the design book
exists.

- [ ] **A person closes a preview, finds it later, and says what happened to
      it.** The requirement is decidable by a test; the understanding is not.
- [ ] **A person reads a proposal as a proposal** rather than as content that
      already exists. Design contract IX-04 of the research book, and the reason
      ghost opacity is a question rather than a value.
- [ ] **A person with reduced motion enabled still understands a state change.**
- [ ] **A person using only the keyboard reaches every contextual action.**

## Discrepancies found while writing this lot

- `docs/design/10-openspec-crosswalk.md` reported 41 requirements and 30 scenarios
  for 71 features. Those counts were computed from `openspec/specs/*.md` and are
  correct as of this change; this file adds 7 requirements and 20 scenarios in a
  new capability, so the crosswalk's first table is now out of date. It is not
  regenerated here: `docs/design/` is a research document, not a generated view,
  and giving it a generator would make it look more authoritative than it is.
- The crosswalk also reported 23 features with "Principes transversaux" instead of
  a dedicated interaction contract. This lot covers the seven that can lose data.
  The other sixteen remain uncovered, and the crosswalk is where that is visible.
