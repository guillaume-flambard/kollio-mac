# L0 — The design contracts become requirements

## Why

`docs/design/` holds 44 interaction contracts (IX-01 to IX-44), 8 behaviour
storyboards and 8 measured contrast pairs. None of them is a requirement. The
capability specs in `openspec/specs/` describe what the document *is*; almost none
describes what a gesture, a proposal or a status change *looks like while it
happens*.

That gap is not cosmetic. Three of the costliest mistakes in the specification are
interaction mistakes, and none of them can currently fail a test:

- A selection that starts a generation. The person clicked to look; the model was
  called anyway, and the cost was theirs.
- A proposal that arrives and takes the viewport. The work did not move, but the
  view did, and the person lost their place to read a result they did not ask to
  be moved toward.
- A preview closed and a direction rejected wearing the same control. One is a
  reversible display state, the other is a durable decision with a remembered
  reason. Conflating them loses a decision without ever recording one.

`docs/design/10-openspec-crosswalk.md` counts the gap: 41 requirements and 30
scenarios for 71 features, and not one requirement about motion, contrast,
announcement or target size.

## What changes

A new `interaction` capability, specified in `specs/interaction/spec.md`, with
seven requirements. Each is written so that a single test can decide it, and each
names the interaction contract from `docs/design/` it comes from.

- A gesture never starts intelligence. Selecting, moving, editing, linking and
  opening a source all work with the model unavailable.
- Intelligence announces its destination where the person is working, and never
  moves the camera to show a result.
- A ghost shows the geometry the keep will produce, and the keep does not move it.
- Closing a preview, setting a direction aside and removing it from the canvas are
  three different acts, with three different reversals.
- A contextual control offers at most three named primary actions, and stays
  reachable while the pointer travels toward it.
- Reduced motion removes displacement, never the state change itself.
- A status is never carried by opacity or colour alone, and text authored by a
  person is never rendered below the contrast floor.

## What it does not change

No document format, no command, no session model, no capability that already has
requirements. This lot adds the interaction layer that was missing; it does not
reopen the domain.

It adds no feature identifier. The 71 V2 features and their 213 acceptance
criteria are untouched, which is why this capability carries no entry in
`feature-catalog.json`.

## Evidence

See `tasks.md`. Every box is unchecked. The contracts in `docs/design/` are
proposals until a test or a person decides them, and several of them will need
code that does not exist yet.
