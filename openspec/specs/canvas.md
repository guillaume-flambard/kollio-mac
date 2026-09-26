# Capability: canvas

The canvas is the application. It shows the document, it takes the gestures, and
it has no permanent furniture of its own.

## Requirements

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

#### Scenario: a decision changes nothing on screen
- **WHEN** a decision is recorded locally
- **THEN** the camera is identical before and after

### Requirement: the camera round-trips
Screen and world coordinates SHALL convert both ways at any zoom, and zoom SHALL
stay within a usable range with its anchor visually still.

#### Scenario: zooming
- **WHEN** the person pinches
- **THEN** the point under the fingers does not move

### Requirement: relationships are drawn, not implied
A relationship SHALL be a routed path between its endpoints, SHALL follow its
objects when they move, and SHALL avoid an obstacle it cannot cross.

#### Scenario: an obstacle between the ends
- **WHEN** a relationship would cross another object
- **THEN** it is routed around it and labelled at the point it actually took

### Requirement: a gesture is a presentation event
A drag, a pan, a pinch and a selection SHALL NOT change the document's meaning,
and SHALL produce at most one transaction when they end.

#### Scenario: one drag, one transaction
- **GIVEN** several objects are selected and dragged together
- **WHEN** the person releases
- **THEN** one undo restores every position they had
