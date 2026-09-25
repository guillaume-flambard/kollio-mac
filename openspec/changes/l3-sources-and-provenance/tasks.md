# L3 — tasks

Nothing in this lot is implemented. It is written to be implementable, and every
item below is still unchecked on purpose.

- [ ] A source has a kind, a locator and a stable id, and attaching it is a
      validated command in one transaction.
- [ ] A quote keeps a locator that survives the source moving.
- [ ] A context view lists sources and quotes, and reads only from the store.
- [ ] A knowledge view is derived, never authored twice.
- [ ] A claim can be verified, and the verification is recorded with its date.
- [ ] Retrieval returns its result *and* its absence, so "nothing found" is a
      first-class answer rather than an empty screen.
- [ ] A presentable object carries an external link that opens outside the app.
- [ ] The context budget is measured, not assumed: a real run records what was
      in the prompt and what was dropped, so a truncation is visible.

## Design pressure worth recording now

`AI-12` is the lot's hardest item and has no code. On-device context is measured
at 8192 tokens, and the real Apple run already sits at 9 to 15 seconds cold. A
retrieval step that grows the prompt will make that worse before it makes the
product better, so budgeting belongs in this lot rather than after it.
