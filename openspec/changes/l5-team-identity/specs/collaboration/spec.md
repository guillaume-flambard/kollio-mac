# Capability: collaboration (delta from L5)

Reconstructed from `proposal.md` and `tasks.md`. Nothing in this file is
implemented, and nothing in it may be started without an explicit authorisation
to introduce an identity or an account.

---

Statut : 3 exigence(s) appliquée(s), 3 exigence(s) en attente.

En attente, donc non opposables :
- a person is stable and exportable
- a contribution is attributed where it was made
- an access decision is auditable

## ADDED Requirements

### Requirement: nothing in this capability is authorised yet
No code in this capability SHALL be started without an explicit authorisation to
introduce an identity or an account.

### Requirement: a person is stable and exportable
A local person SHALL have a stable identifier, SHALL be exportable, and SHALL be
wipeable together with everything derived from it.

#### Scenario: exporting a person
- **WHEN** a person exports their local identity
- **THEN** the export is complete enough to be removed and recreated, and it says
      what it does not carry

#### Scenario: wiping a person
- **WHEN** a person wipes their identity
- **THEN** their contributions remain attributed to a name they chose, and their
      access is gone

### Requirement: consent is per purpose
A consent record SHALL name what it allows, SHALL be revocable, and its history
SHALL be readable by the person it concerns.

#### Scenario: revoking
- **WHEN** a person revokes one consent
- **THEN** only that purpose stops and the rest are untouched

#### Scenario: reading one's own history
- **WHEN** a person asks what they have consented to
- **THEN** every consent, its purpose and its date are listed, including the ones
      already revoked

### Requirement: sharing names a person
A share SHALL target an identified person, SHALL be revocable, and SHALL leave no
silent partial share behind.

#### Scenario: a share that fails halfway
- **WHEN** a share cannot be completed
- **THEN** either the whole share happened or none of it did, and the person is
      told which

#### Scenario: revoking a share
- **WHEN** a share is revoked
- **THEN** access stops, and what history remains is stated rather than implied to
      be erased

### Requirement: a contribution is attributed where it was made
A contribution SHALL carry the identity of the person who made it, on the object
they touched.

#### Scenario: reading who changed this
- **GIVEN** an object two people contributed to
- **WHEN** the person looks at it
- **THEN** each contribution names its author

### Requirement: an access decision is auditable
A refusal SHALL be explicit about what was refused and why, and SHALL NOT be
reported as a technical failure.

#### Scenario: a refused action
- **WHEN** a person attempts something their access does not allow
- **THEN** the message names the decision, not a transport error
