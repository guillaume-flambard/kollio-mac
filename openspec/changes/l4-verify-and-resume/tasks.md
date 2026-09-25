# L4 — tasks

Nothing in this lot is implemented.

- [ ] A document reopens on the view it was left in, and the camera is part of
      the saved state rather than a fresh fit.
- [ ] A verification is a record with a date and a subject, and it survives a
      reload.
- [ ] A rejected direction is still listed, still reopenable, and still says it
      was rejected.
- [ ] Export produces a file a person can read without Kollio.
- [ ] Import of that file restores the document, and reports what it could not
      restore rather than guessing.
- [ ] A backup is written on a schedule the user can see, and a failed backup is
      reported.

## Discrepancy to resolve before coding

The `save on quit` path in L1 saves to a file chosen by "most recent in the
directory". Adding a backup on top of that heuristic would inherit its race. The
last-known-good path has to be an explicit property of the document before backup
exists, otherwise a backup can silently target the wrong file.
