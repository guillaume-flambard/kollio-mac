# L7 — tasks

Nothing in this lot is implemented.

- [ ] An object can be marked presentable, and the mark is a command with a
      transaction.
- [ ] A composition is built from document objects, and says which ones.
- [ ] Editing in place keeps the link back to the source object visible.
- [ ] Authored text is never replaced by a summary. This one is an invariant, and
      it gets a test rather than a review.
- [ ] Interface language changes never translate authored content. Same.
- [ ] A personal template is private by default and says so.

## Two invariants meet in this lot

`STU-04` and `STU-05` are invariants 8 in the flesh. They are the easiest place in
the whole product to break them by accident, because a "smarter" composition
layer is exactly where a summary or a translation would be introduced as a
convenience.
