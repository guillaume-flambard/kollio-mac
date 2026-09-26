# Batch log

What each verified batch found, in the order it was verified. This is history:
`docs/CONTINUE.md` is the current state and the exact next task, and the commits
are the proof. Nothing here is a source of truth, and nothing here should be
consulted before `CONTINUE.md` and `docs/known-limitations.md`.

A batch was closed only after implementation, focused verification, an
independent review with the BLOCKERS and MAJOR findings fixed, a re-verification,
an acceptance audit against the batch's own criteria, and a run of the real
application.

## Latest batch: CAN-02, selection and the actions it reaches

Escape used to clear the selection, the proposal and the composer in one press.
It now closes one level at a time, and the selection is the last thing it takes,
which is what `CAN-02` AC03 asks for. The order lives in one place,
`KollioModel.dismissOneLevel()`, and the five per-surface `onExitCommand` handlers
that used to mutate model state directly are gone, so one Escape cannot close two
levels. `pruneSelection()` is now the single place that drops a vanished object
from the selection, used by undo and redo.

Verified by `SelectionAndActionsTests` (7 tests): no selection, drag or clear
reaches the intelligence seam; a multiple selection hides a proposal without
applying or refusing it; the Escape order; Escape during a drag drops the offset
instead of committing it; the contextual surface follows the selection and not the
hover. `./scripts/verify.sh` passes: 85 KollioCore, 141 KollioApp, 29 server.

Then the owner settled the open question: **three primary actions is right**, and
`SPECIFICATIONS.md` §U02 already fixed which three. `ContextualActionSet` is now a
model fact with `maximumPrimary` as a `precondition`, so a fourth primary action
is a refused programming error rather than a silently demoted button. An ordinary
idea shows Explore, Add, Set aside; Edit, Add a source and the claim prompt moved
behind one named native `Menu` (new catalog key `canvas.moreActions`). Link,
Comment and Duplicate are not offered at all until they exist.

`CAN-02` stays `specified`, not `automatedVerified`, for one reason: reaching the
bar with a slow pointer is a human observation, and there is no screenshot of the
bar because the application launches with nothing selected and driving a selection
needs the accessibility access this environment refuses.

`./scripts/run-app.sh --shot` was run twice. Both captures were discarded. The
first contained unrelated private windows, because the script captures the whole
screen rather than the Kollio window. The second showed a **stale build**: an
earlier instance was still running and `open` only reactivated it. Quit the app
before capturing, or the evidence is of the previous build. `verify.sh` passes:
85 KollioCore, 144 KollioApp, 29 server.

## Latest batch: CAN-03, moving one instance or a group

The domain accepted a list of moves all along; the application only ever passed
one, so **AC02 was not implemented** and neither was "moving an occurrence does
not move its other occurrences". The fix was addressing, not animation:
`Presentation` gained `instances(of:)`, and the drag state now holds
`InstanceID` instead of `ObjectID`. `Presentation.instance(for:)` still answers
with the first instance, which is right for drawing and wrong for moving.

A group drag is now one `MoveNodeInstances` transaction. An unselected object
dragged while something else is selected moves alone, because "move what I picked"
and "move what I happened to touch" are different intents.

Nine tests in `MovingInstancesTests`. AC01 is asserted with the zoom division
*and* with the three results differing, so the test cannot pass on a constant.
`verify.sh`: 85 KollioCore, 153 KollioApp, 29 server.

## Latest batch: CAN-04, editing content in place

`UpdateObjectText` carried no version and `ContentObject` had none. Two people
editing one title both succeeded and the second silently won. So this was a
**format** change, not a view change: `ContentObject.objectVersion`,
`UpdateObjectText.expectedVersion`, and `DocumentError.staleObjectText`.

`expectedVersion` is optional on purpose. `nil` means "I did not look" and
overwrites; a number means "I saw this version" and a mismatch is refused. The
version advances only when the text actually changes, so re-submitting the same
words cannot make every other writer look stale.

`submitComposer` no longer clears the composer before writing. It could not
afford to: a refusal has to leave the person their text, and clearing first throws
it away on the way to finding out it failed.

### The finding that only the running app produced

Adding a non-optional `Int` made every document written before it **unreadable**:
`keyNotFound: objectVersion`, shown as a red banner over the entry screen. Every
unit test was green at that moment, because every fixture encoded its own version.
Reproduced as a failing test on a legacy payload, then fixed with the idiom already
in `KollioDocument` for `sources` and `claims`: `decodeIfPresent ?? 0`. A default
in an *initializer* is not a migration.

Eleven tests in `EditingContentTests`, two more in `DocumentFormatTests`.
`verify.sh`: 87 KollioCore, 164 KollioApp, 29 server, exit 0.

Owed: the two versions side by side in the conflict surface, and Cmd+Z inside the
field, which is an interaction between two undo systems this repository does not own.

## Latest batch: CAN-05, create, duplicate, remove

The chapter was simply absent from the domain: no command could duplicate anything and
none could remove anything. So there is now a fifth distinction the document keeps, and
the one the rest of the product already implied: an **occurrence** is something drawn,
an **object** is something said. Duplicate and delete each exist twice, and the two are
never the same gesture.

- `DuplicateNodeInstance` / `RemoveNodeInstance` touch only the canvas and do not move
  `semanticRevision`.
- `DuplicateObject` / `RemoveObject` change what the document says and do.
- A variant is linked by `derivedFrom`, so the document can still answer why it exists,
  and starts at version 0 rather than inheriting one.
- `ContentObject.Kind.unclear` lets an idea be written down before its kind is known.
  `createIdea` never calls a model, proved with a service that throws if consulted.

**AC01** holds because a copy carries a *reference* to a contribution, never a second
one: two objects may point at one contribution, and the ledger keeps one record, one
membership and one share.

**Two refusals, not two cleanups.** Removing the last drawing of an idea would leave a
node nothing draws, and the next save would write a document nobody can see, so it is
refused as `lastOccurrence`. Removing an object a decision points at would orphan a
durable record, so it is refused as `objectHasDecision` and the decision is revoked
first. Intelligence is refused both removals outright, next to the existing refusals for
`createScenario` and `removeRelationship`: a proposal that deletes is not a bounded
addition, it is a decision.

Twenty tests in `CreatingAndRemovingTests`. `verify.sh`: 87 KollioCore, 184 KollioApp,
29 server, exit 0.

### Two honest gaps

There is **no command that registers a contribution**. `addContributionToProduct` only
adds a share to one already in the ledger, so AC01 is proved against a seeded ledger and
there is no way yet to earn one from the interface. That is the real gap behind AC01.

And the **menu has not been seen on screen**. `run-app.sh --shot` captures the whole
screen, another application kept taking the foreground back, and a crop to Kollio's
coordinates captured that application instead. The four entries and the confirmation rest
on the twenty tests alone. The script should capture by window id and fail when the
frontmost process is not Kollio.

## Latest batch: CTX-01, add information at a precise place

`Add` was an AI call that spent the sentence. The composer sent the typed text as an
instruction and the model decided what to do with it, so the only place the sentence
existed was inside a request. CTX-01 says the opposite, and the sentence is the whole
argument of the chapter: **Add is not a call that spends the sentence.**

`addNote` now writes the sentence as an authored `.note`, linked by `associatedWith`, in
**one transaction**, locally. It is a note and not a hypothesis because the person has
said where this belongs and not what it *is*; requiring a kind there would put the burden
back on the person. `revealConsequences` is a separate later action, so a refusal, a
thrown error and a slow answer are three separate failures and none of them touches the
note. Proved with a service that throws if consulted: the call count stays at zero.

**AC01** findable after a relaunch, link included, so it is findable as information
about something rather than merely present. **AC02** the target is byte-identical
afterwards, version included. **AC03** a model error leaves the contribution with the
author's provenance intact. A double submission is deduplicated **per target**: the same
sentence about two different objects is two remarks, and merging them would lose where
each was said.

### A defect a test found

The first version stored the *folded* sentence, so a note saved a rewritten version of
what the person typed. That is the one thing this product never does. The folded form
now only compares two submissions; the note keeps the typed text exactly.

### Two tests rewritten rather than deleted

`InteractionReliabilityTests` proved the typed sentence reached the intelligence source,
and that a failed call left the draft in the composer. Both describe the behaviour this
chapter removes. The guarantee underneath is real, so it was rewritten in its new form:
the sentence arrives in the document instead of being on its way to a request, and a
refused write still leaves the draft. Deleting them would have lost "losing work is the
worst failure this app can have" without replacing it.

Fifteen tests in `AddingAtAPlaceTests`. `verify.sh`: 87 KollioCore, 199 KollioApp,
29 server, exit 0.

### The screenshot guard, and why it is not in the code

Three repairs to `run-app.sh --shot` were attempted and all three failed. Focusing Kollio
does not hold, cropping to the window's coordinates captures whatever is drawn there, and
guarding on the frontmost *process* is worse than useless: the guard reported `Kollio`
while another application's window was on top, which is the exact case it existed to
catch. A check that passes on its own failure mode is worse than none, so the script says
plainly that the file is a picture of the whole screen. **The visual evidence for CAN-04,
CAN-05 and CTX-01 rests on the test suites, not on that picture.**

## Latest batch: AI-03, explore a branch

Three things were declared and inert. `Preconditions.readSetFingerprint` existed and was
set nowhere and read nowhere. The request carried no `context` at all. And `noChange` set
`preview = nil`, so an answer that proposed nothing **destroyed the branch already on the
canvas**.

**AC01** was the sharpest: the exact instruction was being *discarded*. The `Explore`
branch of `submitComposer` cleared the composer and called `explore` with no instruction,
so a person who typed a steer and pressed the key had it silently ignored. Now the exact
sentence travels, and a refused send keeps the words in the composer.

**AC02**: `readSet(for:)` carries the target, what it links to, one step beyond, and every
rejected direction **with its reason**. "No budget" and "tried it in March" are different
instructions; a bare list of dead ends reads as a ban rather than as reasoning. A reopened
direction is transmitted as `active`, so the engine cannot refuse a door the person just
opened. And the engine honours only the rejections it was *given*, not the ones it could
find in the document, which would make it look as though it were consulting reasoning when
it was only pattern-matching state.

**The signature is stable** because it sorts before hashing. A fingerprint is only worth
anything if the same read set always gives the same string, and iterating dictionaries then
hashing in order would have made every precondition look stale.

**AC03**: a new proposal supersedes the old one, which is *offered* and kept readable, and
`noChange` takes nothing away at all. Destroying a pending branch because a later question
produced no answer is exactly the bug the criterion names.

### Un défaut trouvé par un test, localisé en mesurant

The read set kept the first mention of each object. A rejected direction that was also a
neighbour arrived with `reason: nil` and the rejection loop skipped it, so the same
document produced different read sets depending on iteration order, and the reason that
made a rejection useful was the thing most likely to be lost. Two failing tests found it;
printing the decisions, the objects and the read set located it, rather than reading the
code a third time.

Seventeen tests in `ExploringABranchTests`. `verify.sh`: 87 KollioCore, 216 KollioApp,
29 server, exit 0.

### Ce qui reste dû

The offer to keep or hide is not on screen: the state and the four functions exist and are
tested, nothing asks. Second-degree reach is a documented guess, not a rule of
applicability. And the read set is bounded by reach but not by a budget.

## Latest batch: CTX-05, understand the impact of new information

`ImpactAssessment` existed nowhere: one sentence in the specification and no type.
It is now a pure function of the document in
`packages/KollioCore/Sources/KollioCore/Domain/ImpactAssessment.swift`, with
`readSet`, `proposedChanges` and `unaffectedRefs` and no provider, no session and
no network anywhere in it. That is what "propagation rules do not depend on the
provider" has to mean to be true rather than aspirational.

**The two lists are both on screen.** A card that named only the problems would
read as "everything is now suspect", which is the opposite of what a scoped
dependency walk established. So the card shows what needs review, what was
examined and left alone, and the reason for each. It also prints what it read
(citations, objects, links) and declares itself truncated when the walk hits its
bound, because a truncated answer that does not say so is a lie of omission.

**A link is walked towards what relies on it, never away from it.** The first
implementation had the direction of `dependsOn` and `supports` inverted, and the
fixture did not catch it: the fixture was self-contradictory, saying the shared
tool both rested on the export and was used by two branches. Fixed in both. The
consequence of getting it wrong is precise and bad, so it is now a named test: a
step somebody else relies on does not move because the person using it changed
their mind, and one branch's evidence must not flag every branch that needs the
same tool. `alternativeTo`, `addresses` and `associatedWith` are not dependencies
at all, and the other end is reported as unaffected **with that reason** rather
than by its absence.

**Nothing here can invert a decision.** `ImpactReason` has three cases and none
of them is a verdict; a bare `Decision(kind: .impacted)` through `RecordDecision`
is refused, so a durable "look again" can only exist with the assessment that
produced it attached. Removing a source marks the citation and leaves the
hypothesis supported, with its observation and its author. Taking a stance
supersedes the mark rather than deleting it, and the citation stays marked: a
position taken on a claim does not put the old revision back.

**Applying is one command, one transaction, one undo**, and it is not a branch
purge: content, relationships and every object's lifecycle come back byte
identical, and the decision names one object rather than the branch it sits in.
Intelligence is refused `applyImpact` in the validator, beside the existing
refusals for removals, stances and citations.

The action is offered only when the document says there is something to say, and
it sits behind the named secondary menu so the three primary actions the
specification fixes are untouched. The mark is drawn on the object, so it is not
only readable in a card that has been closed. Escape closes the card before the
selection, and opening it puts the citations card away rather than stacking two
cards on one object.

Sixteen tests in `ImpactAssessmentTests`, thirteen in
`ImpactReviewInterfaceTests`. `verify.sh`: 127 KollioCore, 259 KollioApp,
29 server, exit 0. 27 `automatedVerified`, 1 `humanVerified`, 43 `specified`.

### What was captured, and what was not

The app was launched twice against a throwaway `HOME`, so the user's document was
never opened or rewritten. `screencapture -l <window id>` with the id read from
`CGWindowListCopyWindowInfo` captured **the Kollio window and nothing else**, in
English and in French, light appearance: `build/kollio-window.png` and
`build/kollio-window-fr.png`. Both were inspected before being reported here.
That is the fourth attempt at an honest capture and the first that worked; the
three before it are described in `known-limitations.md`.

**The review card itself has not been seen on screen.** It needs a selection and
a click, and injection is refused by this environment: an `osascript` keystroke
into the launched entry field produced no text. Dark appearance was not captured
either. Both are owed to a person, and the behaviour rests on the twenty-nine
tests.

## Latest batch: CAN-07, group and fold visually

A named frame with explicit members, moving it moving its occurrences, folding
hiding them in this view and nothing else. `Frame` lives in `Presentation` and
every one of the six commands is `isSemantic == false`, so **a frame cannot
change what the document says** and that is enforced by the command layer rather
than by remembering to be careful. Folding touches neither `lifecycle`, nor the
text, nor a decision, nor a citation; a test asserts a branch a person really set
aside is still set aside after a fold.

**Members are occurrences, not objects.** "Moving the frame moves its
occurrences", and CAN-03 already told the two apart, so a frame holds
`InstanceID`s. A frame holding object ids would drag the second drawing of an
object that somebody had deliberately put on another branch. One drawing belongs
to one frame, and that is **refused** rather than resolved: two overlapping frames
are fine, but a fold would otherwise have to guess which of them owns a drawing.

The frame is drawn behind the nodes, inside the world transform, with a dashed
border, its name, how many drawings it holds, and three controls. Folding turns it
into a chip that counts rather than summarises, because a frame fold is a way of
looking at the canvas and a decision is a way of thinking about the document: the
chip never says a branch was closed. The border and the fill never take a click,
so a tap on empty frame space is still a tap on the canvas, and the header is the
only interactive part.

### Two defects the running app produced and the tests did not

**The frame was drawn in screen space.** It was mounted next to the connectors,
outside the world transform, so it placed world coordinates as if they were screen
coordinates: an empty rectangle in the corner while its three members sat
elsewhere. Every unit test passed, because the domain does not know where anything
is drawn. Caught by looking at the app, fixed by moving the layer inside
`worldLayer`.

**The folded chip clipped a name it could not have shortened.** A fixed 190pt
width cut "Set aside for now" mid-word. The chip is now sized by its own name.

A third finding came from the format itself: a hand-written `.kollio` with
`"sources": {}` is **refused**, because the ledgers encode their collections as
arrays. The app reported it and left the file alone, which is the right behaviour
and a useful piece of evidence, but the demo file had to be written to the real
shape.

Sixteen tests in `FrameTests`, fifteen in `FrameInterfaceTests`.
`verify.sh`: 143 KollioCore, 274 KollioApp, 29 server, exit 0, zero warnings.
28 `automatedVerified`, 1 `humanVerified`, 42 `specified`.

### What was captured, and what was not

`screencapture -l` on Kollio's own window, so the file contains the window and
nothing else: `build/kollio-frames.png`, inspected before being reported. It shows
one unfolded frame with its name, its count and its three controls, surrounding
three nodes, with the connectors passing behind it, and a folded frame drawn as a
chip. Light appearance, English.

**Reaching the frame by hand is still not proved.** The document was seeded
directly to put a frame on screen, because selecting two objects and choosing the
action needs clicks this environment refuses. **Dark appearance is not captured.**
Both are owed to a person.

## Latest batch: AI-05, compare directions without inventing scores

A comparison is a record of what a person weighed against what, and every part of
it exists to stop a number from being smarter than the person who wrote it. A
criterion without a `Measure` **cannot** hold a number, refused in the command
layer as `criterionHasNoMeasure` while words are accepted on the same criterion.
`total(for:)` returns nil the moment one criterion is unmeasured, unweighted or
unrecorded, and a weight nobody typed is an absent weight, never one. A signed sum
over explicitly defined terms, and nothing else: no default weight, no average
over whatever happens to be present, no global score to compare across
comparisons.

**"Not recorded" is a value.** It is a first-class state, so a column of unknowns
can never be read as a column of bad results, and the card says "Non renseigné"
rather than showing a zero or a blank.

**Keeping one direction deletes nothing.** `keptDirectionIDs` is a list, and
every sibling cell and the document itself come back byte-identical afterwards. A
comparison records; it does not decide.

**A change is derived, not flagged.** Each cell stores the fingerprint of every
object it was recorded against and the revision of every source it read. A
comparison whose object has since been edited, or whose source has a newer
revision, says so by walking those references, so it cannot quietly present a
check that was made against different text. A flag could only be set by something
remembering to set it.

### Two defects the review found in my own work

**Setting the criteria silently confirmed the comparison.** The first version had
one command doing both, so typing a single criterion into a draft confirmed the
whole set behind the person's back, which is the exact shortcut a draft exists to
prevent. `SetComparisonCriteria` and `ConfirmComparisonCriteria` are now two
commands, and a test asserts the draft is still a draft after the first press.

**The card displayed measures and weights but could not set them.** A criterion
nobody can measure is a criterion nobody can sum, so the whole of the "total only
when the terms are defined" rule was unreachable from the interface. Each criterion
row now opens one editor for its unit, its direction and its weight, and a blank
unit or a blank weight is stored as an absent one.

The draft's criteria are proposed from the claims already in the selection, in the
person's own words, and say so. Not from a model: a model's criteria would be an
interpretation of the document's reasoning, and this is the place where an invented
question is the whole failure.

Nineteen tests in `ComparisonTests`, sixteen in `ComparisonInterfaceTests`.
`verify.sh`: 162 KollioCore, 290 KollioApp, 29 server, exit 0, **zero warnings**.
29 `automatedVerified`, 1 `humanVerified`, 41 `specified`. `schemaVersion` is now
5, the JSON schema declares the measure, the minimum of two directions and the
value shape, and a cell's value is written as a discriminated kind rather than the
synthesised `{"number":{"_0":3}}` a person cannot read.

### What was captured, and what was not

A document carrying a saved comparison was loaded into the running app and the
canvas is unchanged: no error banner, the frame and its folded chip as before, and
the comparison itself stored and intact. `build/kollio-comparison.png`, captured
by window id and inspected. The file was restored afterwards and its checksum
verified against the backup.

**The comparison card has not been seen on a screen.** Opening it needs two
selected objects and an action behind a menu, and no click can be injected here.
**Dark appearance is not captured.** Both are owed to a person.
