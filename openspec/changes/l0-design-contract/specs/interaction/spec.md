# L0 — the interaction capability

These are the contracts that `docs/design/` states and no requirement states.
They are written as requirements because a design document cannot fail a build
and a wish cannot fail a test.

The identifier suffix is the design contract each one comes from.

- a gesture never starts intelligence
- a result is announced where the person is working
- a proposal shows the geometry the keep will produce
- closing, setting aside and removing are three acts
- contextual actions are few, named and reachable
- reduced motion removes displacement, never meaning
- status is never carried by opacity or colour alone

---

Statut : 0 exigence(s) appliquée(s), 21 exigence(s) en attente.

En attente, donc non opposables :
- a gesture never starts intelligence
- a result is announced where the person is working
- a proposal shows the geometry the keep will produce
- closing, setting aside and removing are three acts
- contextual actions are few, named and reachable
- reduced motion removes displacement, never meaning
- status is never carried by opacity or colour alone
- typed input becomes durable before anything else
- navigation moves the view and nothing else
- a relationship is selectable and readable
- a proposal can be corrected before it is decided
- a cancelled request ends, and a late answer does not arrive
- a failure is recoverable and local
- a source keeps its versions
- finding and switching do not change the document
- sharing says what leaves, before it leaves
- a contribution is private until it is published
- losing the network or the access is visible
- reopening restores what was there
- trying a small tool produces a real result
- readability and language change without touching content

## ADDED Requirements

### Requirement: a gesture never starts intelligence
Selecting, moving, editing in place, linking, opening a source and reading a
decision SHALL all succeed with no intelligence available, and SHALL NOT request a
proposal. A person who clicked to look SHALL NOT pay for a generation.

Design contract: IX-04, IX-09, IX-14, DR-05 (never triggered by a gesture).

#### Scenario: selecting several objects
- **GIVEN** an intelligence source that is unavailable or slow
- **WHEN** the person selects several objects, or drags them, or edits a title
- **THEN** the work completes and no proposal is requested

#### Scenario: the model is switched off entirely
- **GIVEN** no intelligence destination is configured
- **WHEN** the person creates, moves, edits, links and decides
- **THEN** every one of those actions is available and none is refused

### Requirement: a result is announced where the person is working
An intelligence request SHALL show its effective destination next to its anchor,
and SHALL NOT move the camera to reveal a result. A result that arrives outside the
viewport SHALL offer a named way to go to it, and going SHALL be the person's
decision.

Design contract: IX-17, IX-18, IX-12, chapter 03 on invariants.

#### Scenario: a branch arrives off screen
- **GIVEN** a proposal whose placement is outside the visible world
- **WHEN** it becomes available
- **THEN** the camera is unchanged and a named control points at the proposal

#### Scenario: the destination is named
- **GIVEN** four possible destinations
- **WHEN** a request is running
- **THEN** the effective one is named at the anchor, not merely in settings

### Requirement: a proposal shows the geometry the keep will produce
A proposal preview SHALL place its objects at the position the keep will commit,
and keeping SHALL NOT move them. Two occurrences of the same object SHALL keep
independent geometry.

Design contract: IX-18, IX-20, CAN-08, SB-01.

#### Scenario: comparing before and after a keep
- **GIVEN** a proposal preview with placements
- **WHEN** the positions of the preview are recorded and the proposal is kept
- **THEN** every kept object is at the position the preview showed

#### Scenario: an object used twice
- **GIVEN** one object shown in two places
- **WHEN** one occurrence is moved
- **THEN** the other occurrence does not move

### Requirement: closing, setting aside and removing are three acts
Closing a preview SHALL hide it and keep it recoverable with its freshness
re-checked. Setting a direction aside SHALL record a durable decision with a
remembered reason. Removing an occurrence from the canvas SHALL remove only that
occurrence. No control SHALL perform two of these, and none SHALL be a bare
unlabelled cross.

Design contract: IX-21, IX-22, IX-08, DR-08, AI-08.

#### Scenario: closing is not rejecting
- **GIVEN** a preview that is closed
- **WHEN** the person returns to it later
- **THEN** it is still a proposal, not a rejected direction, and it revalidates
      its preconditions before it can be kept

#### Scenario: a set-aside reason survives
- **GIVEN** a direction set aside with a reason
- **WHEN** the application is quit and relaunched
- **THEN** the reason is still readable and the direction is still reopenable

#### Scenario: the cross is named
- **GIVEN** a control that closes a preview
- **WHEN** it is inspected
- **THEN** it carries a name that says it closes, not one that says it discards

### Requirement: contextual actions are few, named and reachable
A contextual control SHALL offer at most three primary named actions for the
object under the pointer, SHALL place the rest behind one named secondary
action, and SHALL remain present and hit-testable while the pointer travels from
the object toward it. No capability SHALL exist only on hover.

Design contract: IX-06, IX-05, DR-02, chapter 12 on levels of interface.

#### Scenario: the pointer crosses the gap
- **GIVEN** a contextual control shown for a selected object
- **WHEN** the pointer moves from the object toward the control
- **THEN** the control is still present and still receives the click

#### Scenario: the keyboard alone
- **GIVEN** no pointer is used at all
- **WHEN** an object is focused
- **THEN** the same actions are reachable and the focus is visible

#### Scenario: a window too small for the control
- **GIVEN** a viewport where the control does not fit at its preferred position
- **THEN** it is placed inside the viewport and stays associated with its object

### Requirement: reduced motion removes displacement, never meaning
With reduced motion enabled, decorative translation, rebound and animated camera
movement SHALL be absent, and the state change SHALL remain visible through
opacity, outline, text and labels. Direct manipulation SHALL remain immediate.

Design contract: IX-20, chapter 20 on interruption, chapter 23.

#### Scenario: the same change, two settings
- **GIVEN** a proposal that becomes available
- **WHEN** it is shown with reduced motion on and then off
- **THEN** the same content, the same status and the same actions are present in
      both, and only the displacement differs

#### Scenario: dragging is untouched
- **GIVEN** reduced motion is enabled
- **WHEN** the person drags an object
- **THEN** the object follows the pointer with no added lag

### Requirement: status is never carried by opacity or colour alone
A proposed, set-aside, stale, saved-locally, synchronised, missing-source or
inaccessible state SHALL be stated by at least one of a word, a shape or a
dotted outline, in addition to any tint. Body text SHALL reach a contrast ratio
of at least 4.5:1 against its own background, and an essential non-text
indicator at least 3:1, in both themes. A decorative border SHALL NOT be the only
means of recognising a field, a control or the focus.

The two ratios are the ones the specification already fixes; this requirement
only makes them checkable. They are floors, not targets, and they apply to what
is actually rendered behind the text rather than to a token in isolation.

Design contracts: chapter 11 measured contrasts, DR-04, IX-18.

#### Scenario: the proposal is still readable
- **GIVEN** a proposed object
- **WHEN** it is rendered
- **THEN** its text is legible, and a dotted outline and the word Proposition
      carry the status rather than a reduced opacity

#### Scenario: the two themes
- **GIVEN** the light theme and the dark theme
- **WHEN** every state above is rendered, including on a busy background
- **THEN** text reaches 4.5:1 and essential indicators reach 3:1 in both, measured
      against what is behind them

#### Scenario: a token changes
- **GIVEN** a colour token is changed
- **WHEN** the contrast is recomputed
- **THEN** a pair that falls below its floor fails the check rather than being
      noticed by a person

#### Scenario: the focus is not a thin border
- **GIVEN** a focused control
- **WHEN** it is rendered
- **THEN** it is recognisable without relying on the decorative border token


- 0 exigence(s) déjà présente(s) dans `openspec/specs/interaction.md` — le delta est appliqué.
- 7 exigence(s) absente(s) du présent accumulé — le delta est en attente.

- a gesture never starts intelligence
- a result is announced where the person is working
- a proposal shows the geometry the keep will produce
- closing, setting aside and removing are three acts
- contextual actions are few, named and reachable
- reduced motion removes displacement, never meaning
- status is never carried by opacity or colour alone
## ADDED Requirements, second tranche

The seven above were the contracts that can lose data. The thirty-two below are
the rest of the atlas, grouped by what they change rather than one requirement per
contract: a requirement file nobody reads is not a specification. Each names the
contracts it absorbs, so the atlas remains traceable in both directions.

### Requirement: typed input becomes durable before anything else
A typed sentence SHALL become a stored context or a stored piece of information
before any intelligence is requested, SHALL keep the exact words typed, and SHALL
survive a storage failure, a late restoration and a second submission. Editing
existing text SHALL NOT request a proposal, and a cancelled edit SHALL keep its
draft.

Design contracts: IX-01, IX-02, IX-03, IX-07, IX-13.

#### Scenario: the words are typed before the answer exists
- **GIVEN** a person typing a context
- **WHEN** they submit it
- **THEN** the words are stored and retrievable, and the intelligence request is a
      separate event that can fail without touching them

#### Scenario: storage fails while submitting
- **WHEN** the document cannot be written
- **THEN** the typed text is still present, the failure is named, and the
      application does not claim to have saved

#### Scenario: submitted twice
- **WHEN** the same submission is triggered twice
- **THEN** one context exists, and the second trigger joins it rather than
      creating another

#### Scenario: a late restoration
- **GIVEN** a person who has already typed
- **WHEN** a stored document finishes restoring
- **THEN** the typed words are not replaced

#### Scenario: editing existing text
- **WHEN** a person edits a title in place
- **THEN** no proposal is requested, the text is selectable and copyable, and the
      undo inside the field undoes the typing before it undoes anything else

#### Scenario: closing an edit on purpose
- **WHEN** the person closes an edit without saving
- **THEN** the draft is kept and is found again on reopening the same target

#### Scenario: creating a neighbour
- **WHEN** a person creates an object at an empty place
- **THEN** it appears where the entry was made, and being near another object
      creates no dependency between them

### Requirement: navigation moves the view and nothing else
Panning, pinching, folding and reframing SHALL change the view only. The document
SHALL NOT change, momentum SHALL NOT be applied twice, a bound SHALL NOT oscillate,
and a local gesture SHALL interrupt an animated camera or a voluntary follow
immediately.

Design contracts: IX-10, IX-11, IX-12, IX-16.

#### Scenario: a scroll over a long text
- **GIVEN** the pointer is inside a long text
- **WHEN** the person scrolls
- **THEN** the text scrolls and the canvas does not move

#### Scenario: a scroll over the canvas
- **WHEN** the person scrolls with two fingers
- **THEN** the content moves once, by the same amount in screen space at any zoom,
      and no object's stored position changes

#### Scenario: pinching near an edge with a selection
- **WHEN** the person pinches near the edge of the viewport
- **THEN** the point under the fingers stays put, and the selection survives

#### Scenario: pushing past the zoom bound
- **WHEN** the zoom is pushed past its limit
- **THEN** it stops at the limit without bouncing or oscillating

#### Scenario: interrupting an animated reframe
- **GIVEN** the view is moving to a requested target
- **WHEN** the person pans or pinches
- **THEN** the movement stops at the current position and does not resume

#### Scenario: folding a group
- **WHEN** a group is folded
- **THEN** the members keep their status, their positions are restorable, and the
      same content shown elsewhere is unaffected

### Requirement: a relationship is selectable and readable
A relationship SHALL be selectable by its line, its label or its accessible
equivalent, SHALL be announced with its direction, and SHALL offer its actions
without the pointer having to trace the curve. Two crossing relationships SHALL be
distinguishable rather than one being chosen arbitrarily.

Design contracts: IX-15, IX-14.

#### Scenario: selecting a thin line
- **WHEN** the person clicks near a relationship rather than exactly on it
- **THEN** the relationship is selected, because its hit area is wider than its
      stroke

#### Scenario: hearing the direction
- **GIVEN** a relationship between two objects
- **WHEN** it is focused
- **THEN** its direction is announced, not only drawn

#### Scenario: two relationships crossing
- **GIVEN** two relationships crossing near the pointer
- **WHEN** the person selects
- **THEN** the candidates can be told apart, and one is not picked silently

### Requirement: a proposal can be corrected before it is decided
A person SHALL be able to correct a candidate's text before keeping it, the
correction SHALL keep the candidate a proposal, and the whole group SHALL be
revalidated afterwards. A proposal whose inputs changed SHALL be marked stale
rather than applied, and the reason SHALL be shown.

Design contracts: IX-19, IX-25, IX-24.

#### Scenario: correcting a candidate
- **WHEN** a person edits the text of a proposed item
- **THEN** it is still a proposal, and the correction does not reach the document

#### Scenario: the inputs moved on
- **GIVEN** a proposal computed against an earlier version of the document
- **WHEN** the person tries to keep it
- **THEN** it is refused as stale, the changed inputs are named, and the candidate
      is still readable

#### Scenario: something to review
- **GIVEN** new information that contradicts a hypothesis
- **WHEN** the person asks what it affects
- **THEN** the affected items are named with their reasons, and unaffected branches
      are not marked

### Requirement: a cancelled request ends, and a late answer does not arrive
Cancelling a request SHALL end its visible cycle, SHALL keep the context and the
draft, and SHALL cause a later answer to be discarded rather than added. A new
request SHALL be a new request.

Design contracts: IX-26, IX-17.

#### Scenario: cancelling, then the answer arrives
- **GIVEN** a request that was cancelled
- **WHEN** its answer arrives late
- **THEN** nothing is added to the document

#### Scenario: cancelling then asking again
- **WHEN** the person cancels and then starts a new request
- **THEN** the new request is identifiable as its own, and the cancelled one does
      not come back

#### Scenario: the answer adds nothing while it is arriving
- **GIVEN** a request still in flight
- **WHEN** a partial answer exists
- **THEN** no half-formed object is on the canvas

### Requirement: a failure is recoverable and local
A failure SHALL be attached to the operation that failed, SHALL keep the person's
text, SHALL offer an action that is true, and SHALL NOT be reported as a success.
A save failure and a generation failure SHALL be distinguishable, and neither
SHALL silently become the other's.

Design contracts: IX-27, IX-32.

#### Scenario: the model is unavailable
- **WHEN** a request fails because the model is unavailable
- **THEN** the message says the model is unavailable, the typed text is still
      there, and no remote request is made instead

#### Scenario: saving fails
- **WHEN** the document cannot be written
- **THEN** the document is not reported as saved, and the recovery remains
      reachable

#### Scenario: the failure is repeated
- **GIVEN** a visible failure
- **WHEN** the person retries
- **THEN** the retry is explicit, and one retry does not become two requests

### Requirement: a source keeps its versions
A source SHALL keep the version a citation depends on when a newer version arrives,
SHALL state when only part of it was read, and SHALL keep its title and references
when the file becomes unavailable. A citation SHALL open the version it was taken
from.

Design contracts: IX-28, IX-29, IX-08.

#### Scenario: a replaced file
- **GIVEN** a source at version 1 with a citation
- **WHEN** version 2 arrives
- **THEN** the citation still opens version 1, and what it supported is marked as
      needing review

#### Scenario: a file that will not parse
- **WHEN** a replacement cannot be read
- **THEN** version 1 stays active, and the failure is visible

#### Scenario: the file disappears
- **WHEN** a source is no longer readable
- **THEN** its title and its references remain, marked unavailable, and the claims
      that used it are not deleted

#### Scenario: reading a long source
- **GIVEN** a source too long to read in place
- **WHEN** the person opens it
- **THEN** a reading surface carries the source, its place in the document and a
      way back to where they were

### Requirement: finding and switching do not change the document
Searching SHALL find content whatever its status, and opening a result SHALL NOT
reopen, un-set-aside or otherwise alter a decision. Switching document or window
SHALL keep each session's own camera, drafts and results, and a result produced for
one document SHALL NOT appear in another.

Design contracts: IX-30, IX-31.

#### Scenario: a reason inside a set-aside direction
- **WHEN** a person searches for a reason recorded on a set-aside direction
- **THEN** it is found and readable, and the direction is still set aside

#### Scenario: no results
- **WHEN** a search matches nothing
- **THEN** it says so, and the previous state is left alone

#### Scenario: two windows
- **GIVEN** a request running in one window
- **WHEN** the person works in another and the answer arrives
- **THEN** nothing from that request appears in the second window

### Requirement: sharing says what leaves, before it leaves
Opening a share surface SHALL send nothing. Confirming it SHALL name the
destination, the people and the scope first, SHALL be cancellable, and a failure
SHALL leave the local document usable and SHALL NOT present a link as working when
the content is not yet available.

Design contracts: IX-33, IX-34, IX-43.

#### Scenario: opening and cancelling
- **WHEN** a person opens the share surface and cancels
- **THEN** nothing was sent, and the document is still private

#### Scenario: a share that cannot complete
- **WHEN** a share fails partway
- **THEN** either all of it happened or none of it, and no link is offered as
      usable

#### Scenario: an invitation
- **GIVEN** an invitation addressed to a person
- **WHEN** they open it
- **THEN** the document and the role they would get are shown before they accept,
      and accepting grants exactly that role

#### Scenario: an invitation that expired
- **WHEN** an expired invitation is opened
- **THEN** the refusal says it expired, rather than reporting a sign-in failure

### Requirement: a contribution is private until it is published
A contributor's private work SHALL NOT be visible to others as content, publishing
SHALL be a separate act with a version, and the version a reviewer accepted SHALL
be the version they were shown. A conflict SHALL show both versions and require a
choice.

Design contracts: IX-35, IX-36, IX-37, IX-08.

#### Scenario: writing without publishing
- **GIVEN** a contributor editing a draft
- **WHEN** a colleague opens the document
- **THEN** the colleague sees no trace of the draft

#### Scenario: publishing, then revising
- **GIVEN** a published proposal
- **WHEN** its author publishes a correction
- **THEN** the earlier view says a new version exists, and accepting the old
      version is refused rather than silently upgraded

#### Scenario: two people, one title
- **GIVEN** two people who both edited the same title
- **WHEN** the second saves
- **THEN** both versions are shown, the person chooses, and no words are lost

### Requirement: losing the network or the access is visible
Losing the connection SHALL leave local work readable and queued, and SHALL NOT be
presented as synchronised. Losing access SHALL be distinct from losing the file, and
SHALL stop further writes rather than queue them forever. Resuming SHALL not replay
the session as animation.

Design contracts: IX-38, IX-39, IX-40, IX-41.

#### Scenario: offline, then quitting
- **GIVEN** an unsent change
- **WHEN** the application is quit without a connection
- **THEN** the change is still queued when it returns

#### Scenario: following someone, then moving yourself
- **GIVEN** a person following another's view
- **WHEN** they pan or zoom
- **THEN** they stop following immediately, and the presenter is not moved

#### Scenario: access revoked
- **GIVEN** access removed while working offline
- **WHEN** the connection returns
- **THEN** no further change is sent, the work is kept, and the message says the
      access changed rather than that the file was deleted

#### Scenario: coming back to a shared document
- **WHEN** a person reopens a document they have read before
- **THEN** a short summary of what changed is available on request, and choosing
      an item goes to it

### Requirement: reopening restores what was there
Reopening a set-aside direction SHALL return its objects, its relationships and
their positions, SHALL keep the earlier reason readable, and SHALL record the
reopening as a new decision. It SHALL NOT call intelligence and SHALL NOT
rearrange what it restores. A referenced element that is missing SHALL be reported
rather than invented.

Design contracts: IX-23, IX-22.

#### Scenario: reopening after a restart
- **GIVEN** a direction set aside and the application quit
- **WHEN** it is reopened after a relaunch
- **THEN** the objects and their positions return, no intelligence is called, and
      the original reason is still readable

#### Scenario: something it needed is gone
- **WHEN** a referenced element no longer exists
- **THEN** the limit is stated, and nothing is invented to fill it

### Requirement: trying a small tool produces a real result
Trying a product SHALL run the capabilities that are actually available, SHALL
change its result when its inputs change, SHALL place an input error next to the
input, and SHALL NOT present a recorded figure as a computation. Cancelling a run
SHALL NOT alter the document it came from.

Design contracts: IX-42.

#### Scenario: two different inputs
- **GIVEN** a product with two inputs
- **WHEN** the person changes one and runs it again
- **THEN** the output differs accordingly, and the previous output is no longer
      presented as the current one

#### Scenario: a missing column
- **WHEN** an input a step needs is absent
- **THEN** the error appears beside that input and names it, and no success is
      shown

#### Scenario: an unsupported capability
- **WHEN** a product includes something that cannot run here
- **THEN** it is refused as unsupported, and no unknown script is executed

### Requirement: readability and language change without touching content
Changing the interface language, the theme or the reading size SHALL change the
labels and the tokens only. Authored content SHALL stay in the language it was
written in. A reading size large enough to need more room SHALL be given that room
rather than truncating the text. A change SHALL keep the reading position and the
focus, and SHALL NOT reset an edit in progress.

Design contracts: IX-44, IX-08.

#### Scenario: French to English and back, while editing
- **GIVEN** a person editing a sentence written in French
- **WHEN** the interface language changes twice
- **THEN** the sentence is byte-for-byte identical, the labels are whole, and the
      focus stays where it was

#### Scenario: a larger reading size
- **WHEN** the reading size grows
- **THEN** the content reflows and stays complete, and nothing is cut to preserve a
      fixed box

#### Scenario: the theme changes
- **GIVEN** content authored in one theme
- **WHEN** the theme changes
- **THEN** the text and every functional indicator still meet their contrast floor
      in the new theme
