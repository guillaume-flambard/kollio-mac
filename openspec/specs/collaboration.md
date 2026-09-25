# Capability: collaboration

More than one person, deliberately. This capability is a target. It requires an
identity decision the user has not made, and it starts with consent, not with
transport.

## Requirements

### Requirement: nothing in this capability is authorised yet
No code in this capability SHALL be started without an explicit authorisation to
introduce an identity or an account.

### Requirement: consent is per purpose
A consent record SHALL name what it allows, SHALL be revocable, and its history
SHALL be readable by the person it concerns.

#### Scenario: revoking
- **WHEN** a person revokes one consent
- **THEN** only that purpose stops and the rest are untouched

### Requirement: sharing names a person
A share SHALL target an identified person, SHALL be revocable, and SHALL leave no
silent partial share behind.

### Requirement: concurrency is refused, not merged
Two concurrent edits SHALL be detected, and the second SHALL be refused with a
clear message rather than merged or overwritten.

#### Scenario: two people, one object
- **GIVEN** two people editing the same object
- **WHEN** both save
- **THEN** one succeeds, the other is told, and nothing is lost silently

### Requirement: a rejected direction survives a conflict
A conflict resolution SHALL NOT remove a direction because it was rejected or set
aside.
