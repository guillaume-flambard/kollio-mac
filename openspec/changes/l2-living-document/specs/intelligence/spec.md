# Capability: intelligence (delta from L2)

Reconstructed from `proposal.md` and the accumulated present tense in
`openspec/specs/intelligence.md`.

---

Statut : 7 exigence(s) appliquée(s), 4 exigence(s) en attente.

En attente, donc non opposables :
- the candidate is smaller than the document
- a session is disposable
- a progress can never become a proposal
- a rejected direction is not proposed again

## ADDED Requirements

### Requirement: the seam is the contract
All proposals SHALL cross a `SuggestionService` seam, and a provider SHALL NOT be
distinguishable from another provider's output unless the person was told which
one produced it.

#### Scenario: local then remote
- **WHEN** a proposal is produced by a remote provider
- **THEN** the result names that provider

### Requirement: an unavailable model is a refusal
An unavailable model SHALL produce a refusal that names its own reason, and SHALL
NOT fall back to another engine, call the network, or produce claimed output.

#### Scenario: the model is not available
- **GIVEN** any unavailability reason reported by the system
- **WHEN** a proposal is requested
- **THEN** the request is refused with that reason and nothing is generated

### Requirement: the model fills in meaning only
The trusted layer SHALL mint identifiers, SHALL reject kinds it cannot render,
SHALL bound the number of proposed ideas, and SHALL NOT let the model choose its
own authority, scope or ownership.

#### Scenario: the model invents an identifier
- **WHEN** the model returns its own identifier
- **THEN** the trusted layer replaces it with a minted one

#### Scenario: too many ideas
- **WHEN** the model returns more ideas than the bound allows
- **THEN** the branch is reduced to the bound and the rest is dropped

#### Scenario: an unrenderable kind
- **WHEN** the model returns a kind the canvas cannot show
- **THEN** it is dropped and the rest of the branch survives

### Requirement: the candidate is smaller than the document
A generated candidate SHALL carry an outcome, a short summary, brief reasons and
bounded new items, and SHALL NOT carry a whole document, a permission, an owner
or an executable payload.

#### Scenario: an output that passes a schema but means nothing renderable
- **WHEN** a candidate decodes but carries no operation the canvas can show
- **THEN** it is refused rather than applied

### Requirement: a session is disposable
Each request SHALL run in its own model session, and a failed, refused or
cancelled generation SHALL NOT affect the next request.

#### Scenario: a refusal then a new request
- **GIVEN** a request the model refused
- **WHEN** the person asks again
- **THEN** the second request is unaffected by the first one's failure

### Requirement: a progress can never become a proposal
A streamed answer SHALL produce progress that carries no identifier and no
operation, and a partial answer SHALL NOT add anything to the document.

#### Scenario: the first progress is already complete
- **WHEN** the first progress update of a stream already contains the whole
      answer
- **THEN** the streaming capability is not claimed for that provider

#### Scenario: a stream is interrupted
- **GIVEN** a stream cut in the middle
- **WHEN** the person keeps working
- **THEN** nothing half-decoded is on the canvas

### Requirement: deterministic tests never need a model
Every deterministic test SHALL request its engine by name, SHALL NOT contact a
network, and SHALL complete in under two seconds.

#### Scenario: a Mac with a usable model
- **WHEN** the deterministic suite runs
- **THEN** it uses the offline engine and its duration does not depend on the
      machine's model availability

#### Scenario: two suites at once
- **WHEN** the real-model suite runs without `--no-parallel`
- **THEN** any latency it reports is contention, and the figure is not used as a
      model measurement

### Requirement: real-model evidence is separate
Evidence from a real model SHALL live in an explicitly marked suite that is
opt-in and skipped by default.

#### Scenario: default verification
- **WHEN** `./scripts/verify.sh` runs
- **THEN** no test requires Apple Intelligence, a key or a network

### Requirement: outcomes are preserved as themselves
`noChange` and `needsInput` SHALL survive as themselves, and an unknown outcome
SHALL NOT be interpreted as one of them.

#### Scenario: nothing new to propose
- **WHEN** the model returns `noChange`
- **THEN** the document is unchanged and the answer is shown as a refusal to
      propose, not as an empty success

#### Scenario: a question instead of a proposal
- **WHEN** the model returns `needsInput`
- **THEN** the question is asked and no proposal is created

#### Scenario: an outcome nobody knows
- **WHEN** the model returns an outcome outside the known set
- **THEN** it is refused rather than mapped onto a known one

### Requirement: local and cloud are never silently interchangeable
A failure of one provider SHALL NOT become the output of another, and a demo
substitute SHALL NOT be presented as a result.

#### Scenario: the local model is unavailable
- **WHEN** a local request fails and a remote provider is configured
- **THEN** nothing is sent remotely and no remote output appears

#### Scenario: a demo engine
- **GIVEN** the deterministic demo engine
- **WHEN** it produces something
- **THEN** it is labelled as the demo, and never as a model result

### Requirement: a rejected direction is not proposed again
A direction that was set aside SHALL carry a signature of what it was and why,
and a new request SHALL receive that signature so the model does not repeat it
without a changed premise.

#### Scenario: the same direction twice
- **GIVEN** a direction that was set aside with a reason
- **WHEN** the same branch is explored again
- **THEN** the proposal is either different or is a `noChange`, never a repeat of
      the set-aside branch

#### Scenario: the premise changed
- **GIVEN** a set-aside direction and new information that contradicts its
      premise
- **WHEN** the branch is explored
- **THEN** reconsidering it is possible, and it is presented as a proposal rather
      than as a reopening
