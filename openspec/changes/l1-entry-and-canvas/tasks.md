# L1 — tasks

Ordered, each item verifiable. Checked boxes mean the stated command was run and
its result read, not merely that code was written.

- [x] A launch with no stored document shows the input, not Sarah.
      `swift test --filter InitialContextTests`
- [x] A stored document is restored, an unreadable one reported and not
      overwritten. Same suite.
- [x] The typed context keeps the exact authored words, with a stable identity.
      Same suite.
- [x] The context is persisted before any intelligence is requested, so a dead
      backend cannot cost the user their words. Same suite.
- [x] A new document gets its own save target and cannot overwrite the previous
      file. Same suite.
- [x] Save on quit is wired to the model the window is showing, and a failure is
      reported rather than swallowed. `swift test --filter InteractionReliabilityTests`
- [x] Inline text reaches the request as its instruction, and a failed call keeps
      the draft. Same suite.
- [x] Two-finger scroll pans the canvas in screen space at any zoom.
      `ScrollCatcher`; `swift test --filter CameraTests`
- [x] A local decision no longer reframes the camera. Same reliability suite.
- [x] A collapsed direction is selectable and reopening is a named accessibility
      action. Same reliability suite.
- [ ] **A human types a sentence, presses the action, and watches a proposal
      arrive.** Owed: keystroke injection needs accessibility access this
      environment refuses.
- [ ] **A human drags, pinches, scrolls and explores with a trackpad.** Owed, and
      it is the only evidence that the gesture *feel* is right.
- [ ] Two-finger scroll verified on hardware. The wiring is tested; the physical
      gesture is not.

## Discrepancies found and left visible

- `scripts/run-app.sh --shot` prints a path whether or not the capture worked,
  and captures the whole screen rather than the Kollio window. Not yet corrected;
  a screenshot of the wrong window has already been produced once in this
  project and was deleted.
- The document save path keys on "most recent file in the directory", so two
  documents saved within the same second could collide. Fixed with a short
  uniquifier, noted because the directory is the index.

## CAN-02, selection and the actions it reaches

- [x] Selecting, extending, clearing and dragging reach no intelligence service
      at all. `SelectionAndActionsTests`; a counting service that also throws.
- [x] A multiple selection hides a proposal without applying it and without
      recording a decision. Same suite.
- [x] Escape closes one level, then the next, and the selection is the last thing
      it takes. `KollioModel.dismissOneLevel`, same suite.
- [x] Escape with nothing transient left does nothing, rather than reaching into
      the document. Same suite.
- [x] Closing a composer keeps the draft and records no decision. Same suite.
- [x] Escape during a drag drops the offset instead of committing it. Same suite.
- [x] The contextual surface follows the selection, not the hover. Same suite.
- [x] One authority for Escape. Five per-surface `onExitCommand` handlers in
      `ContextualViews.swift` mutated model state directly, so a single Escape
      could have closed two levels. They now all route through the model.
- [ ] **The contextual bar is comfortable to reach with a slow pointer.** Owed,
      and the only evidence that the *gap* between object and bar is small. The
      test proves the bar is tied to the selection; it cannot prove a person can
      cross the gap without rushing.
- [ ] **An object removed remotely clears the selection and explains if an edit
      was active.** Owed: the domain has no delete command, so an object cannot
      leave the document except by undo. `pruneSelection()` is now the single
      place the rule lives, and the remote path will use it when it exists.

### Owner decision taken: three primary actions

The owner answered the open question: **three is right.** `SPECIFICATIONS.md` §U02
already fixed which three — Explore, Add, Set aside — so that is what is shown.

- [x] `ContextualActionSet` is the model's fact, not a layout. `maximumPrimary` is
      a `precondition`, so a fourth primary action is a refused programming error
      rather than a silently demoted button.
- [x] An ordinary idea offers exactly `[.explore, .add, .setAside]`, with Edit,
      Add a source and the claim prompt behind one named control. The test asserts
      the three by name, not only the count: counting alone would pass for any
      three.
- [x] A set-aside direction offers only Reopen, and no secondary control at all,
      because there is one thing to do with it.
- [x] No action is offered twice, and Link, Comment and Duplicate are not offered
      at all until they are implemented. An action that exists and does nothing is
      worse than an absent one.
- [x] The secondary control is a native SwiftUI `Menu`, reachable by keyboard, so
      it cannot be confused with a tooltip that happens to contain buttons. New
      catalog key `canvas.moreActions` (Plus / More).
- [ ] **The contextual bar is comfortable to reach with a slow pointer.** Owed, and
      the only evidence that the gap between object and bar is small. The test
      proves the bar is tied to the selection; it cannot prove a person can cross
      the gap without rushing.
- [ ] **A screenshot of the bar showing three actions and one menu.** Owed: the
      application launches with nothing selected, and driving a selection needs a
      click or accessibility access this environment refuses — the same limitation
      already recorded for keystroke injection. Two earlier captures were
      discarded: one contained unrelated private windows, and one showed a stale
      build because a previous instance was still running and `open` only
      reactivated it.

## CAN-03, moving one instance or a group

The domain already accepted a list of moves; the application layer only ever
passed one. So AC02 was not implemented, and neither was the second half of
"moving an occurrence does not move its other occurrences".

- [x] A group drag is one `MoveNodeInstances` transaction, so one undo restores
      the group. `KollioModel.moveInstances`, `MovingInstancesTests`.
- [x] Relative positions inside the group are preserved, and an unselected object
      dragged while something else is selected moves alone. Same suite.
- [x] AC01: 80, 100 and 180 per cent produce the world move the zoom implies,
      and the test also asserts the three differ, so it cannot pass on a constant.
- [x] A cumulative gesture update replaces the delta instead of adding to it, and
      a different anchor is refused rather than merged. Same suite.
- [x] AC03: a move leaves content, relationships and `semanticRevision` untouched.
- [x] Cancelling a gesture writes nothing, and a sub-pixel drag writes nothing.
- [x] **Two occurrences of one object move independently.** Owed until now, and
      the fix was in the addressing, not the animation: `Presentation` gained
      `instances(of:)`, and the drag state addresses `InstanceID` rather than
      `ObjectID`. `instance(for:)` answers with the first instance, which is the
      right answer for drawing and the wrong one for moving.
- [ ] **The drag feels direct.** Owed: a human on a trackpad. The test proves the
      arithmetic, not the absence of lag.

### Discrepancy found and left visible

`ObjectNodeView` reports `isDragging` for the instance under the pointer only, so
in a group drag one object looks anchored and the others look merely lifted. That
is deliberate, but whether it reads correctly is a human question.

## CAN-04, editing content in place

`UpdateObjectText` carried no version, and `ContentObject` had none to carry. Two
people editing one title both succeeded and the second one silently won, which is
the single outcome this chapter forbids. The gap was in the format, not in the view.

- [x] `ContentObject.objectVersion`, incremented only when the stored text or
      detail actually changes. A re-submission of the same words is a no-op and
      leaves the version alone, so it cannot make every other writer look stale.
      `DocumentFormatTests`, `EditingContentTests`.
- [x] `UpdateObjectText.expectedVersion`. `nil` means "I did not look" and
      overwrites; a number means "I saw this version" and a mismatch is refused.
      The distinction is the difference between overwriting and asking.
- [x] `DocumentError.staleObjectText`, named apart from `staleProposal`: the
      recovery is a person choosing between two texts, not recalculating a branch.
- [x] AC01: the exact characters typed are stored, long, multi-line, accented and
      punctuated. Nothing summarises them, and the object keeps its kind.
- [x] AC01: an edit is one transaction, so one undo restores it.
- [x] AC02: while a draft is open the document's undo cannot reach it, because a
      draft is not part of the document. Reopening after a close starts from what
      is really on the canvas.
- [x] AC03: changing the interface language leaves authored text byte-identical,
      and a document written in French reads back identically under `en`.
- [x] A conflict keeps the draft, keeps the current text readable beside it, and
      says so before the person presses the key, not only after.

### A regression found by running the app, not by a test

Adding a non-optional `Int` made every document written before it unreadable:
`keyNotFound: objectVersion`. `scripts/run-app.sh --shot` showed it as a red
banner over the entry screen. The unit tests were all green at that moment,
because every fixture encoded its own object version. Reproduced first as a failing
test on a legacy payload, then fixed with the idiom already used for `sources` and
`claims` in `KollioDocument`: `decodeIfPresent ?? 0`, with the reason in a comment.
A field with a default in its *initializer* is not a migration.

### Owed

- [ ] **Cmd+Z inside the field.** The part of AC02 the repository cannot decide:
      it is the interaction between the field's own undo and the document's. What
      is proved here is only that the document cannot touch the draft.
- [ ] **Showing both versions side by side.** The conflict is reported and the
      draft is kept, but the current text is still shown by the surrounding
      canvas rather than next to the draft. The specification asks for both, and
      that is interface work with a human reading it.
- [ ] **Undoing moves a version backwards.** An undo restores an earlier snapshot,
      so `objectVersion` decreases. A draft open across an undo is therefore
      reported as a conflict, which is honest (its text is against text that is no
      longer there) but is untested with a real person deciding.
