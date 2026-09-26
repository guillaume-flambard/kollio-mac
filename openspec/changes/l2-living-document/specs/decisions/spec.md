# Capability: decisions (delta from L2)

Reconstructed from `proposal.md` and the accumulated present tense in
`openspec/specs/decisions.md`.

---

Statut : 4 exigence(s) appliquée(s), 2 exigence(s) en attente.

En attente, donc non opposables :
- the reason belongs to the person
- a proposal is decided against the version it was computed on

## ADDED Requirements

### Requirement: keeping is one action
Keeping a proposal SHALL apply the branch and its geometry as a single action, and
undoing it SHALL revert exactly that.

#### Scenario: undo after a keep
- **GIVEN** a proposal was kept
- **WHEN** the person undoes
- **THEN** the document returns to its state before the keep

#### Scenario: undo twice
- **GIVEN** a proposal was kept and then something else was changed
- **WHEN** the person undoes twice
- **THEN** the second undo reverses only the later change

### Requirement: a set-aside direction keeps its memory
A direction that was set aside SHALL remain in the document, SHALL say it was set
aside, and SHALL be reopenable by a named accessibility action as well as by a
double-click.

#### Scenario: reopening
- **WHEN** the person reopens a set-aside direction
- **THEN** it returns with the geometry it had

#### Scenario: setting aside twice
- **GIVEN** a direction already set aside
- **WHEN** the person sets it aside again
- **THEN** there is one active decision, not two

### Requirement: the reason belongs to the person
The reason for setting a direction aside SHALL be asked of the person, and SHALL
NOT be composed by the machine.

#### Scenario: the composer is cancelled
- **WHEN** the person closes the reason field without answering
- **THEN** no decision is recorded

### Requirement: rejection is not deletion
Nothing in the application SHALL delete a direction because it was rejected, and
a rejected direction SHALL remain listable.

### Requirement: a local decision is local
A decision made on the machine SHALL NOT be reported as synchronised, and no
network call SHALL be implied by it.

### Requirement: a proposal is decided against the version it was computed on
A proposal SHALL be kept only while its preconditions still hold, and a proposal
whose inputs changed SHALL be marked stale rather than applied.

#### Scenario: the document moved on
- **GIVEN** a proposal computed against version 3
- **WHEN** the document is now at version 4 and the person tries to keep it
- **THEN** it is refused as stale, with the reason, and the candidate is still
      readable

#### Scenario: the camera moved
- **GIVEN** a proposal computed against version 3
- **WHEN** only the camera changed and the person keeps it
- **THEN** it is applied, because panning is not a change of meaning
