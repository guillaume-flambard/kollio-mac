# Capability: ecosystem (delta from L9)

Reconstructed from `proposal.md` and `tasks.md`. No upload, no account, no
marketplace: the lot is scoped to leaving under the person's control.

---

Statut : 3 exigence(s) appliquée(s), 5 exigence(s) en attente.

En attente, donc non opposables :
- an imported proposal is a proposal
- an imported proposal is validated exactly like a local one
- importing grants no right and fetches nothing
- a system command is the same path as the manual one
- the never-shared list is enforced in code

## ADDED Requirements

### Requirement: nothing in this capability is authorised
No upload, account or marketplace behaviour SHALL be started without an explicit
authorisation.

### Requirement: publication preserves the authored text
A published or public presentation SHALL carry the person's authored words exactly
as written, in the language they were written in.

#### Scenario: a public presentation
- **WHEN** a document is presented publicly
- **THEN** the authored words are unchanged and untranslated

#### Scenario: what was left out
- **WHEN** a document is published with parts excluded
- **THEN** the exclusions are stated before publication, not discovered afterwards

### Requirement: leaving is under the person's control
Any outward movement SHALL be initiated by the person, SHALL be visible before it
happens, and SHALL be traceable afterwards.

#### Scenario: the destination is named first
- **WHEN** a document is about to leave the machine
- **THEN** the destination and the content are shown before it does

#### Scenario: afterwards
- **WHEN** something left
- **THEN** the person can see that it happened, and what was sent

### Requirement: an imported proposal is a proposal
A proposal arriving from another assistant SHALL be validated and reviewed exactly
like a local one, SHALL grant no right by being imported, and SHALL NOT be executed
on arrival.

#### Scenario: opening an imported proposal
- **WHEN** a proposal file is opened
- **THEN** nothing has changed in the document, and the same review applies

#### Scenario: a name that claims authority
- **GIVEN** an imported file naming a well-known model
- **WHEN** it is opened
- **THEN** the name grants nothing, and the provenance is recorded as declared

#### Scenario: the document it targeted is gone
- **WHEN** a proposal targets a document or version that no longer exists
- **THEN** it is refused or recalculated explicitly, never applied to whatever is
      open instead

### Requirement: an imported proposal is validated exactly like a local one
A proposal arriving from outside SHALL pass the same validation, the same
preconditions and the same review as one produced locally, and SHALL be
distinguishable in its provenance without that difference granting it any
authority.

#### Scenario: the same rules apply
- **GIVEN** an imported proposal and a locally produced one with the same content
- **WHEN** both are reviewed
- **THEN** the same rules accept or refuse both, and the origin is recorded
      separately from the judgement

#### Scenario: an imported operation outside the vocabulary
- **WHEN** an imported proposal carries an operation the application does not
      define
- **THEN** it is refused, exactly as a local one would be

#### Scenario: no integration is claimed that does not exist
- **GIVEN** a capability that has not been implemented
- **WHEN** the product describes it
- **THEN** it is described as absent, and no document or interface claims a native
      integration that is not there

### Requirement: importing grants no right and fetches nothing
Opening an imported proposal SHALL NOT execute it, SHALL NOT follow the URLs it
contains, and SHALL NOT run any script it carries. A model named inside a file
SHALL grant nothing.

#### Scenario: a URL inside the proposal
- **GIVEN** an imported proposal containing links
- **WHEN** it is opened
- **THEN** nothing was fetched

#### Scenario: a script inside the proposal
- **GIVEN** an imported proposal carrying code
- **WHEN** it is opened
- **THEN** the code was not run, and the refusal is explicit

#### Scenario: a name claiming authority
- **GIVEN** an imported file naming a well-known model or service
- **WHEN** it is opened
- **THEN** the name grants nothing, and the provenance is recorded as declared
      rather than verified

### Requirement: a system command is the same path as the manual one
A native command or share extension SHALL produce the same result as the
equivalent action taken in the interface, SHALL NOT perform a sensitive mutation
invisibly, and SHALL NOT obtain an authorisation the manual path would require.

#### Scenario: the same result
- **GIVEN** a document opened from a system share
- **WHEN** a person opens it
- **THEN** the result matches opening it from the File menu

#### Scenario: nothing happens invisibly
- **WHEN** a system command is invoked
- **THEN** any change it causes is visible, and a destructive change takes the
      same confirmation path as the interface

#### Scenario: an intent that would need more rights
- **GIVEN** a system invocation that would need an authorisation the session does
      not hold
- **WHEN** it is invoked
- **THEN** it is refused, and the refusal names the missing right

### Requirement: the never-shared list is enforced in code
The documented exclusions SHALL be enforced in code and covered by a test, not
only stated in documentation.

#### Scenario: a capability that is not on the list
- **WHEN** something not explicitly permitted is about to be shared
- **THEN** it is refused, and the test proves the refusal
