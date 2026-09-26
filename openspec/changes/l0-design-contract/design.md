# L0 — design decisions

## Why a new capability and not more requirements elsewhere

The alternative was to append interaction requirements to `canvas`,
`intelligence` and `decisions`. That was rejected for a specific reason: those
three files are already the accumulated present tense of their domain, and a
gesture rule filed under `intelligence` would be read as a statement about
intelligence. It is a statement about the interface. Splitting it out keeps the
question "what does this capability promise" answerable, and lets the whole
capability be judged at once instead of piecemeal.

It also makes the omission visible. A capability with no features in
`feature-catalog.json` is unusual, and that unusual shape is the honest signal:
the product specified 71 features and no interaction contracts.

## The seven, and what each one excludes

The selection is not the 44 contracts of the atlas. It is the seven that can
change what a person loses. Ordered by the cost of being wrong:

1. **A gesture never starts intelligence.** The most expensive mistake available,
   because it spends a resource and hides the fact.
2. **A result is announced where the person is working.** Second, because losing
   your place is the failure the person notices last.
3. **Status is never carried by opacity or colour alone.** Third, because it is
   invisible to the person it excludes.
4. **Closing, setting aside and removing are three acts.** Fourth, because a lost
   decision cannot be recovered by any later fix.
5. **A proposal shows the geometry the keep will produce.** Fifth, because
   accepting result A to obtain result B is a broken promise.
6. **Contextual actions are few, named and reachable.** Sixth: friction, not data
   loss.
7. **Reduced motion removes displacement, never meaning.** Seventh: an
   accessibility floor, and the one most likely to be quietly broken by a later
   animation.

## A scenario is a thing a test can decide

Every requirement here is written so that one test decides it, and no requirement
depends on a duration, a colour value or a layout being pleasant. Where a number
exists in `docs/design/` it is treated as a starting value, not as the
requirement. "Reduced motion removes displacement" is testable; "the reveal lasts
140 ms" is not, and is not written.

## What is deliberately not in this lot

- **The 37 remaining contracts.** IX-01 to IX-44 minus the seven above. They are
  written down and not yet required. Adding them in one pass would produce a
  requirement file nobody reads.
- **The measured contrast pairs.** `docs/design/04-visual-language-and-surfaces.md`
  computes twelve ratios. They are proposals about tokens, and token values change;
  the *requirement* is the floor, not the number.
- **The 8 storyboards.** SB-01 to SB-08 are observation protocols. They belong to
  a human session, and a requirement derived from one would be a requirement
  proved by a person who has not been recruited.
- **Anything about a duration, a spring or a stagger.** The atlas gives starting
  values. A requirement that fixes one would be satisfied by a screenshot and
  broken by a redesign.

## The two places this lot will be wrong

**A test that proves the contract without the person.** A reduced-motion test can
prove that a translation is absent. It cannot prove that a person still
understands what changed. The requirement is written to be decidable, and that
means it is decidable by something other than a person. The gap is recorded in
`tasks.md` rather than hidden.

**A contract that is only a design intention.** "Closing a preview revalidates its
preconditions" describes a freshness check that may not exist. It is written as a
requirement because it should, and the box stays unchecked until it does.

## Where the design text lives

This change does not move the atlas. `docs/design/06-interaction-atlas.md` stays
the design reference, `docs/design/10-openspec-crosswalk.md` stays the comparison
that found the gap. When a contract graduates from the atlas to a requirement, the
requirement is authoritative and the atlas is the history. Editing the atlas to
disagree with a requirement would reintroduce exactly the two-sources problem this
lot exists to close.
