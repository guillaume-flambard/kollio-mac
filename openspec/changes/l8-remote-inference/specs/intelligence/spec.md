# Capability: intelligence (delta from L8)

Reconstructed from `proposal.md` and `tasks.md`. The seam exists; the interface
that would let a person see which provider answered does not. That is the honest
state, and it is why the lot is `inProgress` rather than `implemented`.

---

Statut : 0 exigence(s) appliquée(s), 4 exigence(s) en attente.

En attente, donc non opposables :
- the choice is visible at the moment of use
- what may leave the machine is stated before it leaves
- a remote failure is a remote failure
- a key never enters the document or a log

## ADDED Requirements

### Requirement: the choice is visible at the moment of use
A person SHALL be able to see which provider is answering, at the request, and not
only in a settings screen.

#### Scenario: the request says who answered
- **GIVEN** a request in progress
- **WHEN** the person looks at it
- **THEN** the effective provider is named there

#### Scenario: the setting nobody opened
- **GIVEN** a provider configured in settings
- **WHEN** a proposal arrives
- **THEN** the proposal itself says which provider produced it

### Requirement: what may leave the machine is stated before it leaves
A remote request SHALL state what it is about to send and SHALL NOT transmit
anything that was not included in that statement.

#### Scenario: the boundary is shown first
- **WHEN** a person is about to use a remote provider
- **THEN** the content that would leave the machine is shown before it does

#### Scenario: the projection is the payload
- **GIVEN** a remote request
- **WHEN** it is sent
- **THEN** what was sent is exactly what the projection listed, and no more

### Requirement: a remote failure is a remote failure
A failure of the remote path SHALL be reported as itself, with its own reason, and
SHALL NOT render as a local result, an empty success, or a demo output.

#### Scenario: the provider times out
- **WHEN** a remote request times out
- **THEN** the failure names the timeout and the provider, and no proposal is
      added

#### Scenario: the provider is absent
- **GIVEN** a remote provider with no key
- **WHEN** a request would use it
- **THEN** it is disabled, and it is not silently replaced by the local engine

### Requirement: a key never enters the document or a log
A provider credential SHALL live outside the document, SHALL NOT appear in an
export, and SHALL NOT be written to a log.

#### Scenario: exporting a document
- **WHEN** a document that used a remote provider is exported
- **THEN** the export contains no credential

#### Scenario: reading a log
- **WHEN** a request is logged
- **THEN** the entry names the operation, the duration and the outcome, and
      contains neither the key nor the document's text
