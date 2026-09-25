# Capability: documents

What a person gets when they open Kollio: a document that is theirs, that
survives, and that never pretends to be someone else's story.

## Requirements

### Requirement: a launch begins with the person, not a demonstration
The application SHALL open the initial input when no document is stored, restore
the stored document when one is, and report an unreadable document without
overwriting it.

#### Scenario: first launch
- **GIVEN** no stored document
- **WHEN** the application launches
- **THEN** the initial input is shown and the demonstration is not

#### Scenario: a stored document
- **GIVEN** a stored document
- **WHEN** the application launches
- **THEN** that document is restored with its content and its camera

#### Scenario: an unreadable document
- **GIVEN** a stored document that cannot be read
- **WHEN** the application launches
- **THEN** the failure is reported and the file on disk is left untouched

### Requirement: an authored context is durable
A context entered by a person SHALL be persisted before any intelligence is
requested, and SHALL be editable in place without changing its identity.

#### Scenario: the backend is unavailable
- **GIVEN** a typed context and an intelligence source that fails
- **WHEN** the person begins
- **THEN** the words are on disk and the failure is reported

### Requirement: a new document cannot destroy the previous one
A new document SHALL receive its own save target, and saving it SHALL NOT write
over an existing document.

#### Scenario: saving a new document
- **GIVEN** a document created this session
- **WHEN** it is saved
- **THEN** the previous document's file is unchanged

### Requirement: nothing is lost on quit
The application SHALL save on quit, SHALL report a failure to save, and SHALL
NOT report a save that did not happen.

#### Scenario: the save fails
- **WHEN** saving on quit fails
- **THEN** the failure is shown rather than swallowed

### Requirement: authored text reaches the intelligence as an instruction
Text typed inline SHALL be sent as the request's instruction, and a failed
request SHALL leave the draft intact.

#### Scenario: the request fails
- **WHEN** a request made from typed text fails
- **THEN** the typed text is still there to retry
