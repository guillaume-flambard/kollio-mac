# Capability: documents (delta from L4)

Reconstructed from `proposal.md` and `tasks.md`. L4 is the lot where a document
has to survive a month and a crash.

---

Statut : 0 exigence(s) appliquée(s), 6 exigence(s) en attente.

En attente, donc non opposables :
- the document reopens where it was left
- the last known good path is a property of the document
- export is a file a person can read without Kollio
- import reports what it could not restore
- a failed backup is reported
- a recovery is identified as a recovery

## ADDED Requirements

### Requirement: the document reopens where it was left
A document SHALL restore the view it was left in, including its camera, and
restoring SHALL NOT be a fresh fit of the content.

#### Scenario: quit and relaunch
- **GIVEN** a document panned away from its origin
- **WHEN** it is reopened
- **THEN** the camera is the one it was left with

#### Scenario: the target moved while the document was closed
- **WHEN** a restored camera points at a region with nothing in it
- **THEN** the view is restored as saved, and the absence is reported rather than
      silently reframed

### Requirement: the last known good path is a property of the document
A document SHALL know its own last-known-good location, and backup SHALL target
that property rather than inferring a file from a directory listing.

#### Scenario: two documents written in one second
- **GIVEN** two documents in the same directory saved within one second
- **WHEN** a backup runs
- **THEN** each document is backed up from its own recorded path

### Requirement: export is a file a person can read without Kollio
An export SHALL be readable with no application, SHALL preserve authored text
exactly, and SHALL state what it does not contain.

#### Scenario: reading the export
- **GIVEN** an exported document
- **WHEN** a person opens it without Kollio
- **THEN** the text, the relationships and the decisions are readable

#### Scenario: an asset that could not be included
- **WHEN** an export cannot include a referenced file
- **THEN** the export says so and names it, rather than dropping it silently

### Requirement: import reports what it could not restore
An import SHALL restore what the format carries, and SHALL list what it did not
restore rather than guessing or inventing.

#### Scenario: a field this version does not know
- **WHEN** an imported document carries a field the current version does not have
- **THEN** the field is preserved or reported, and never dropped without a word

### Requirement: a failed backup is reported
A backup that fails SHALL be reported and SHALL NOT be replaced by a success
message, and the previous backup SHALL remain intact.

#### Scenario: the backup destination is unavailable
- **WHEN** a scheduled backup cannot write
- **THEN** the failure is visible and the earlier backup is still readable

### Requirement: a recovery is identified as a recovery
A recovered version SHALL be labelled as such, SHALL NOT open automatically as if
it were the document, and SHALL NOT replace the original file.

#### Scenario: opening after an interrupted write
- **WHEN** the application finds a recovery alongside the document
- **THEN** the person is offered the recovery explicitly, and the original file
      is untouched until they choose
