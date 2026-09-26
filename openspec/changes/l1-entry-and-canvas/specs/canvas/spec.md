# Capability: canvas (delta from L1)

Reconstructed from `proposal.md` and the accumulated present tense in
`openspec/specs/canvas.md`.

---

Statut : 4 exigence(s) appliquée(s), 1 exigence(s) en attente.

En attente, donc non opposables :
- a collapsed direction is reachable by name

## ADDED Requirements

### Requirement: the canvas takes the gestures a person expects
The canvas SHALL pan on a two-finger scroll, SHALL zoom with a pinch, and SHALL
pan on a drag, all without a permanent sidebar, toolbar or inspector.

#### Scenario: a two-finger scroll
- **GIVEN** the canvas is showing
- **WHEN** the person scrolls with two fingers
- **THEN** the content moves with the fingers, in screen space, at any zoom

#### Scenario: a scroll inside a text field
- **GIVEN** a text field holds the pointer
- **WHEN** the person scrolls
- **THEN** the field scrolls and the canvas stays still

#### Scenario: a click and a drag still belong to the canvas
- **GIVEN** the scroll catcher is present
- **WHEN** the person clicks or drags
- **THEN** the canvas handles the gesture and no other view claims it

### Requirement: the camera is presentation
The camera SHALL NOT alter the document, and SHALL NOT move on its own when a
local decision is recorded.

#### Scenario: setting a direction aside
- **WHEN** a direction is set aside
- **THEN** the camera is identical before and after

#### Scenario: reopening
- **WHEN** a set-aside direction is reopened
- **THEN** the camera is identical before and after

#### Scenario: fitting is still explicit
- **WHEN** the person asks the canvas to fit its content
- **THEN** the view changes, because the person asked and nothing else did

### Requirement: the camera round-trips
Screen and world coordinates SHALL convert both ways at any zoom, and zoom SHALL
stay within a usable range with its anchor visually still.

#### Scenario: zooming
- **WHEN** the person pinches
- **THEN** the point under the fingers does not move

#### Scenario: beyond the range
- **WHEN** the zoom is pushed past its bound
- **THEN** it is clamped and stays at the bound

#### Scenario: dragging at any zoom
- **WHEN** an object is dragged at 80, 100 and 180 per cent
- **THEN** it follows the pointer at each of them, with the same world delta

### Requirement: a gesture is a presentation event
A drag, a pan, a pinch and a selection SHALL NOT change the document's meaning,
and SHALL produce at most one transaction when they end.

#### Scenario: one drag, one transaction
- **GIVEN** several objects are selected and dragged together
- **WHEN** the person releases
- **THEN** one undo restores every position they had

### Requirement: a collapsed direction is reachable by name
A set-aside direction SHALL be reopenable from a named action exposed to assistive
technology, and not only from a double-click.

#### Scenario: reopening without a pointer
- **GIVEN** a set-aside direction
- **WHEN** a person navigates by keyboard and assistive technology
- **THEN** the reopen action is offered and named
