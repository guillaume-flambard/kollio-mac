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
| A source is a reference; a link fetches nothing | `SourceLedgerTests` | L3 |
| A citation keeps its revision, and is refused towards nothing | `SourceLedgerTests` | L3 |
| Verification needs an observation and an author | `SourceLedgerTests` | L3 |
| A new revision flags without moving a citation | `SourceLedgerTests` | L3 |
| A failed extraction keeps the previous version | `SourceLedgerTests` | L3 |
| A removed source does not delete the claim | `SourceLedgerTests` | L3 |
| The context budget is measured, required items are never dropped | `ContextProjectionTests`, `AppleAdapterTests` | L3 |
| A local-only projection cannot be sent | `ContextProjectionTests` | L3 |
| Attaching a source is transactional and atomic | `SourceCommandTests` | L3 |
| Intelligence may not attach or verify evidence | `SourceCommandTests` | L3 |
| A chip shows the state of a claim's sources | `SourceChipTests` | L3 |
| The codec and the published schema agree | `SourceCommandTests` | L3 |
| AC01 a CSV with quotes and newlines parses correctly | `SourceReaderTests` | L3 |
| AC02 a PDF with no text layer says so | `SourceReaderTests` | L3 |
| AC03 a pasted link is never fetched | `SourceReaderTests` | L3 |
| A chosen file is read and attached in one transaction | `SourceChipTests` | L3 |
| A file with no text is attached and labelled, not announced as read | `SourceChipTests` | L3 |
| A citation opens at the lines its locator points at | `SourceChipTests` | L3 |
| A page locator shows no passage rather than a wrong one | `SourceChipTests` | L3 |
| A verification is recorded only with an observation | `SourceChipTests` | L3 |
| A chosen passage becomes the quote and the locator, verbatim | `SourceChipTests` | L3 |

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
- A test for an impossible selection used an inverted range, `3..<1`. That is a
  trap in Swift rather than a value that can be passed and refused, so the test took
  the whole test process down with it. The case cannot exist, and the test now says
  so rather than pretending to cover it.
- `importRevision` originally **refused** an extraction that produced no text, which
  was right for CTX-07 and wrong for CTX-02: refusing it meant the chip could never
  show "no text", because the fact was never stored. Both hold now that the attempt
  is always recorded and only *currentness* is decided separately. A usable earlier
  revision stays the one being read; a first attempt that yields nothing becomes
  current, because then it is the best information there is.
- The CSV parser had a bug that would have corrupted every citation made from a
  table. Three separate faults, each found by a test rather than by reading: a
  trailing newline made it return an empty table and discard every row it had
  already parsed; a CRLF pair is a *single* Swift `Character`, so a Windows file
  walked past both `case "\r"` and `case "\n"` and became one single column; and
  an unterminated quote returned half a table that looked complete. All three are
  fixed and each has a test named after the failure.
- The first attempt to build a PDF fixture used a `PDFPage` with a text
  *annotation*. That does not work and never did: annotations are not page
  content, so `page.string` finds nothing. Building through a `CGPDFContext` is
  what actually produces a text layer.
- `SourceReader.read` touched the file before checking whether it was a link, so
  an https URL failed with a file error instead of the rule that refused it. The
  check now comes first.
- The published `.kollio` schema had drifted twice without anything noticing: it
  declared `additionalProperties: false` while the codec had never been compared
  against it, and its `required` list demanded a top-level `provenance` that has
  never existed in the format. A test now compares the two, which is not full JSON
  Schema validation and does not claim to be.
- `Citation` did not record which claim it supported, so nothing could answer "what
  is this object based on". The chip could not have been written without it, and my
  first attempt at `sourceChips` contained a filter that was always true because of
  it. The pairing now lives on the citation, where it survives.
- `KollioModel` exposed no way to run a command from outside, because every existing
  mutation had its own hand-written method. `perform(_:label:)` is now the single
  path, which is also what a source action in the interface will use.
- The context budget had a 2000-character floor that could exceed a small model's
  whole window, so it would have claimed more room than existed and truncation would
  have gone undetected. It is now clamped to the window, and a test covers 64, 300,
  1000 and 8192 tokens.
- `importRevision` originally left already-verified citations alone when a source
  gained a revision, so a check on a superseded file kept looking current. A
  verified citation is now flagged like any other: the observation is not erased,
  but it is no longer presented as current.
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
