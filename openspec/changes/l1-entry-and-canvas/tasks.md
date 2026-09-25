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
