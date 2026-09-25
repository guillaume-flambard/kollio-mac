# Capability: intelligence

Intelligence proposes. It never rewrites the world, never assigns its own
identifiers, and never substitutes itself for an answer it did not produce.

## Requirements

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
own authority.

#### Scenario: the model invents an identifier
- **WHEN** the model returns its own identifier
- **THEN** the trusted layer replaces it with a minted one

#### Scenario: too many ideas
- **WHEN** the model returns more ideas than the bound allows
- **THEN** the branch is reduced to the bound and the rest is dropped

#### Scenario: an unrenderable kind
- **WHEN** the model returns a kind the canvas cannot show
- **THEN** it is dropped and the rest of the branch survives

### Requirement: outcomes are preserved as themselves
`noChange` and `needsInput` SHALL survive as themselves, and an unknown outcome
SHALL NOT be interpreted.

### Requirement: local and cloud are never silently interchangeable
A failure of one provider SHALL NOT become the output of another, and a demo
substitute SHALL NOT be presented as a result.

### Requirement: deterministic tests never need a model
Every deterministic test SHALL request its engine by name, SHALL NOT contact a
network, and SHALL complete in under two seconds.

#### Scenario: a Mac with a usable model
- **WHEN** the deterministic suite runs
- **THEN** it uses the offline engine and its duration does not depend on the
      machine's model availability

### Requirement: real-model evidence is separate
Evidence from a real model SHALL live in an explicitly marked suite that is
opt-in and skipped by default.

#### Scenario: default verification
- **WHEN** `./scripts/verify.sh` runs
- **THEN** no test requires Apple Intelligence, a key or a network
