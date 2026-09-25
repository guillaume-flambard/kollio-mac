# L2 — the idea becomes a living document

## Why

The document existed but did not think. A person could move things; nothing
proposed anything, and the only source of proposals was a rule engine pretending
to be an assistant.

## What changes

- On-device Apple intelligence behind the existing `SuggestionService` seam.
- A small typed candidate: an outcome, one sentence, a bounded list of ideas. The
  model fills in meaning; a trusted layer mints ids and validates.
- Real exploration of a real object, with the authored context as its target.
- Keep, Set aside and Reopen with the geometry the ghost already had.
- Cancellation, staleness and honest failure, with no substitution.

## What it does not change

The seam, the `.kollio` protocol and `KollioCore`. Foundation Models is an
implementation choice behind an existing interface, not a new architecture. The
server is preserved, not required.

## Features

AI-01 … AI-09, AI-11, AI-12, DEC-01, DEC-02, DEC-03, CAN-08
