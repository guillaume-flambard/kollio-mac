# Capability: context (delta from L3)

Reconstructed from `proposal.md` and the accumulated present tense in
`openspec/specs/context.md`. L3 is the lot that makes a document rooted.

---

Statut : 3 exigence(s) appliquée(s), 6 exigence(s) en attente.

En attente, donc non opposables :
- a quote points into a version
- verification needs an observation and an author
- a replaced source keeps the previous version
- removing a source does not remove the claim
- a local-only projection cannot be sent
- the ledger is derived from the store

## ADDED Requirements

### Requirement: a source is a reference
A source SHALL be stored as a kind, a locator and a stable identifier, and its
content SHALL be read on demand rather than copied.

#### Scenario: the source moves
- **WHEN** a source is no longer where it was
- **THEN** the failure is reported and the existing quotes remain

#### Scenario: a link, not a file
- **GIVEN** a pasted URL
- **WHEN** it is attached
- **THEN** a reference is created and nothing is fetched in the background

### Requirement: a quote points into a version
A quote SHALL record the source, the version it was taken from, and a locator into
that version, so that opening it returns the passage that was cited.

#### Scenario: the file changed
- **GIVEN** a quote taken from version 1
- **WHEN** the source is replaced by version 2
- **THEN** the quote still opens version 1 and the claim it supports is marked as
      needing review

#### Scenario: a quote toward nothing
- **WHEN** a quote references a source that no longer exists
- **THEN** it is refused rather than created

### Requirement: verification needs an observation and an author
A claim SHALL be marked verified only against a recorded observation and a named
author, and attaching a source SHALL NOT verify anything by itself.

#### Scenario: a source is attached
- **WHEN** a source is attached to a claim
- **THEN** the claim is unverified

#### Scenario: a verification is recorded
- **WHEN** a person records an observation against a claim
- **THEN** the claim is verified, and the observation and its author are readable

### Requirement: a replaced source keeps the previous version
A new version of a source SHALL NOT remove the version a citation depends on, and
a failed extraction SHALL leave the previous version active.

#### Scenario: the new file will not parse
- **GIVEN** a source at version 1
- **WHEN** a replacement at version 2 fails to extract
- **THEN** version 1 remains the active version and nothing is lost

### Requirement: removing a source does not remove the claim
Removing a source SHALL leave every claim that cited it in place, with its
citation marked as pointing at something unavailable.

#### Scenario: the claim outlives its evidence
- **WHEN** a cited source is removed
- **THEN** the claim is still there and says its evidence is gone

### Requirement: the context budget is measured
The intelligence request SHALL record what was included and what was dropped, so
a truncation is visible rather than silent.

#### Scenario: the context exceeds the model's limit
- **WHEN** the assembled context is too large for the model
- **THEN** what was dropped is recorded and shown

#### Scenario: a required item does not fit
- **GIVEN** a constraint that cannot be dropped
- **WHEN** the budget cannot hold it
- **THEN** the request is refused and the person is asked to narrow the scope,
      rather than the constraint being dropped

#### Scenario: a small model
- **GIVEN** a model whose whole window is smaller than the budget
- **WHEN** the projection is built
- **THEN** the budget is clamped to the window, so a truncation is detectable

### Requirement: a local-only projection cannot be sent
A projection marked local-only SHALL NOT be transmitted, and narrowing a request's
scope SHALL NOT widen the rights attached to it.

#### Scenario: a workspace policy forbids sending
- **GIVEN** a document whose policy is local-only
- **WHEN** a remote request is attempted
- **THEN** it is refused before any transmission

### Requirement: retrieval returns its absence
A retrieval SHALL return an explicit empty result with a reason, and SHALL NOT
present an empty result as if it were a completed search.

#### Scenario: nothing matches
- **WHEN** a retrieval matches nothing
- **THEN** the result says so and does not look like a success with no items

#### Scenario: a source was never indexed
- **WHEN** a search would have to look inside a source that was not loaded
- **THEN** the scope of the search is stated rather than presented as complete

### Requirement: the ledger is derived from the store
Contexts, provenance and knowledge SHALL be views over the document's own store,
and SHALL NOT be a second copy that can disagree with it.

#### Scenario: the two disagree
- **WHEN** a view and the store would show different content
- **THEN** the store wins and the difference is a defect to fix, not a state to
      reconcile at runtime
