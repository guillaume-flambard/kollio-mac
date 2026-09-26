# Capability: documents (delta from L1)

Reconstructed from `proposal.md` and the accumulated present tense in
`openspec/specs/documents.md`. No `spec.md` was committed when this lot was
written; this file restores the delta, and it is the delta as the lot stated it,
not as the code later drifted.

---

Statut : 5 exigence(s) appliquée(s), 1 exigence(s) en attente.

En attente, donc non opposables :
- two windows are two sessions

## ADDED Requirements

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

#### Scenario: the intelligence source is unavailable
- **GIVEN** a typed context and a source that fails
- **WHEN** the person begins
- **THEN** the words are on disk and the failure is reported

#### Scenario: editing in place
- **GIVEN** a context already on the canvas
- **WHEN** the person edits its text
- **THEN** the identifier is unchanged and the authored words are the ones saved

### Requirement: authored text reaches the intelligence as an instruction
Text typed inline SHALL be sent as the request's instruction, and a failed
request SHALL leave the draft intact.

#### Scenario: the request fails
- **WHEN** a request made from typed text fails
- **THEN** the typed text is still there to retry

#### Scenario: the instruction is not the document
- **GIVEN** a typed instruction and a document
- **WHEN** the request is built
- **THEN** the instruction travels as the instruction and is not merged into the
      document's content

### Requirement: a new document cannot destroy the previous one
A new document SHALL receive its own save target, and saving it SHALL NOT write
over an existing document.

#### Scenario: saving a new document
- **GIVEN** a document created this session
- **WHEN** it is saved
- **THEN** the previous document's file is unchanged

#### Scenario: two documents in the same second
- **GIVEN** two documents written within one second
- **WHEN** both are saved
- **THEN** they occupy different files

### Requirement: nothing is lost on quit
The application SHALL save on quit, SHALL report a failure to save, and SHALL
NOT report a save that did not happen.

#### Scenario: the save fails
- **WHEN** saving on quit fails
- **THEN** the failure is shown rather than swallowed

#### Scenario: a document with no delegate
- **GIVEN** a document edited without a window delegate attached
- **WHEN** it is saved
- **THEN** the bytes reach the disk

### Requirement: two windows are two sessions
Two open documents SHALL NOT exchange proposals, drafts or results, and a result
produced for one SHALL NOT appear in the other.

#### Scenario: a late answer
- **GIVEN** a request running in window A
- **WHEN** the person switches to window B and the answer arrives
- **THEN** nothing from that request is added to B
