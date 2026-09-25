# L6 — tasks

Nothing in this lot is implemented.

- [ ] Two concurrent edits are detected, and the second is refused with a clear
      message instead of overwriting.
- [ ] An offline change is queued, survives a restart, and reconciles on return.
- [ ] A conflict is shown to a person, who chooses. Nothing merges by default.
- [ ] The authoritative copy has a named owner, and it is visible in the app.
- [ ] A rejected direction is never resolved by a merge. It stays, marked.

## Why this lot refuses automatic merging

Automatic merge is attractive because it is invisible, and invisible is the
problem. This product keeps the memory of a rejected direction; a merge that
quietly drops one is not a data race, it is a violation of invariant 4 wearing a
convenient hat.
