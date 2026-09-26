# Capability: decisions (delta from L4)

Reconstructed from `proposal.md` and `tasks.md`.

---

Statut : 0 exigence(s) appliquée(s), 3 exigence(s) en attente.

En attente, donc non opposables :
- verification is a dated record
- a rejected direction is still a direction
- the history explains, it does not replay

## ADDED Requirements

### Requirement: verification is a dated record
A verification SHALL record what was checked, against what, by whom and when, and
SHALL survive a reload.

#### Scenario: reloading after a verification
- **GIVEN** a claim verified today
- **WHEN** the document is saved and reopened
- **THEN** the verification is still there with its date and its author

#### Scenario: verifying nothing
- **WHEN** a person marks a claim verified without an observation
- **THEN** the verification is refused

### Requirement: a rejected direction is still a direction
A direction that was set aside SHALL remain listed, SHALL remain reopenable, and
SHALL continue to say that it was set aside and why.

#### Scenario: listing after a rejection
- **GIVEN** a direction set aside a month ago
- **WHEN** the person lists directions
- **THEN** it appears, marked, with its reason

#### Scenario: reopening long after
- **WHEN** the person reopens it
- **THEN** the objects, the relationships and the positions return, and no
      intelligence is called to do it

### Requirement: the history explains, it does not replay
A history view SHALL present decisions, changes and their reasons in order, and
SHALL NOT present a replay of intermediate states as if it were the present.

#### Scenario: reading how a decision was reached
- **GIVEN** a decision taken after several changes
- **WHEN** the person opens its history
- **THEN** the sequence and the reasons are readable, and returning to the present
      does not change the document

#### Scenario: restoring is a new action
- **WHEN** a person restores an earlier version
- **THEN** it is recorded as a new action, not as a silent rewind that others
      would inherit
