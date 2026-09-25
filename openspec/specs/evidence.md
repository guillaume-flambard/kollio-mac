# Evidence

What has actually been shown, and how. This file exists so that no claim in the
project outruns its proof.

## Rules

1. A checked task means the stated command was run and its result read. Not that
   code was written.
2. A test that depends on the machine is not a test. Every deterministic test pins
   its engine.
3. `specified` is the honest default for anything written down.
4. Real-model evidence lives in a separate, explicitly marked suite.

## What is proved

| What | How | Where |
|---|---|---|
| Launch, restore, unreadable reported | `InitialContextTests` | L1 |
| Context persisted before any inference | `InitialContextTests` | L1 |
| A new document cannot overwrite the previous file | `InitialContextTests` | L1 |
| Save on quit wired and reported | `InteractionReliabilityTests` | L1 |
| Inline text is an instruction, a failure keeps the draft | `InteractionReliabilityTests` | L1 |
| A local decision does not move the camera | `InteractionReliabilityTests` | L1 |
| Set aside, then reopen with a named action | `InteractionReliabilityTests` | L1 |
| Two-finger scroll reaches the canvas and only the canvas | `ScrollDeliveryTests` | L1 |
| A scroll pans in screen space at any zoom | `CameraTests` | L1 |
| Every availability reason is its own refusal | `AppleAdapterTests` | L2 |
| Ids minted, kinds refused, branch bounded | `AppleAdapterTests` | L2 |
| Deterministic suite is offline and fast | `AppleAdapterTests` | L2 |
| A real model produced a valid proposal, FR and EN | `RealOnDeviceModelTests` | L2 |
| The running app holds no network socket | `netstat` against the app's pid | L2 |
| Steady-state latency, three calls in one process | `RealOnDeviceModelTests`, `--no-parallel` | L2 |
| A real answer streams, and progress is not a proposal | `RealOnDeviceModelTests.realStreaming` | L2 |
| A half-written answer yields progress only, never commands | `AppleAdapterTests` | L2 |
| Streamed and non-streamed answers convert identically | `AppleAdapterTests` | L2 |
| One keep undoes as one action | `VerticalSliceTests` | L2 |

## What is owed to a person

These cannot be automated here, and no line of code substitutes for them.

- Typing a sentence and seeing a proposal arrive. Owed: keystroke injection needs
  accessibility access that this environment refuses.
- A real two-finger scroll on a trackpad, and the feel of it. The wiring is
  proved; the gesture is not.
- Keeping, setting aside and reopening a real proposal by hand.

## Known discrepancies, left visible

- `scripts/run-app.sh --shot` prints a path whether or not the capture worked, and
  captures the whole screen rather than the Kollio window. A screenshot of an
  unrelated private window was produced once in this project and deleted.
- The save path keys on "most recent file in the directory", which is a race when
  two documents are written in the same second. A short uniquifier was added; the
  directory is still acting as an index, which is fragile and should become an
  explicit property of the document.
- The latency reported in an earlier round, 9 to 15 s, does not reproduce. Measured serially it is
  3.6 s for the first call in a fresh process and 2.2 to 2.7 s afterwards. The identified confounder
  is that the real-model suite runs its tests in parallel by default, so two of them hit the same
  on-device model at once. Any latency figure taken without `--no-parallel` is measuring contention,
  not the model. The conclusion is unchanged and the number is smaller than reported.
- A previous version of the deterministic suite inherited the launch default
  engine, took 35 seconds and started failing on a Mac with a usable model. Fixed
  by pinning the engine in every test; recorded because it is the failure mode
  this project is most likely to repeat.
- The first draft of the streaming test proved the projection against malformed
  JSON, which the framework cannot produce: `GeneratedContent(json:)` refuses to
  parse it. The test now covers the case that can actually happen, valid JSON in an
  unexpected shape, rather than a fictional one.
- The first draft of the latency test printed a verdict that separated asset
  loading from generation and fired on a margin of one hundredth of a second. It now
  prints the series and names no cause.
- `ScrollCatcher` was first placed in `.background` with
  `.allowsHitTesting(false)`. That combination cannot work: SwiftUI excludes the
  subtree from hit testing, so AppKit never routes a scroll to it. The view is now
  a topmost overlay that claims a hit only while a scroll event is being routed,
  proved by `ScrollDeliveryTests`.
