# Capability: context

A context is what the person brought. It is authored, it is durable, and it
points at its own sources.

## Requirements

### Requirement: context is authored, never generated
The context SHALL hold the person's own words exactly as written, and no
component SHALL replace them with a summary or a translation.

#### Scenario: changing the interface language
- **WHEN** the interface language changes
- **THEN** the authored context is unchanged and untranslated

### Requirement: a source is a reference
A source SHALL be stored as a kind, a locator and a stable identifier, and its
content SHALL be read on demand rather than copied.

#### Scenario: the source moves
- **WHEN** a source is no longer where it was
- **THEN** the failure is reported and the existing quotes remain

### Requirement: retrieval returns its absence
A retrieval SHALL return an explicit empty result with a reason, and SHALL NOT
present an empty result as if it were a completed search.

#### Scenario: nothing matches
- **WHEN** a retrieval matches nothing
- **THEN** the result says so and does not look like a success with no items

### Requirement: the context budget is measured
The intelligence request SHALL record what was included and what was dropped, so
a truncation is visible rather than silent.

#### Scenario: the context exceeds the model's limit
- **WHEN** the assembled context is too large for the model
- **THEN** what was dropped is recorded and shown

### Requirement: adding information is one transaction
Information added at a chosen place SHALL be attached to that place in the same
transaction, SHALL keep its author's words exactly as written, and SHALL survive a
later failure of any intelligence request.

#### Scenario: the request that followed failed
- **GIVEN** an information added to an object
- **WHEN** a later exploration of that object fails
- **THEN** the information is still there, attached to the same object
