# Capability: collaboration (delta from L6)

Reconstructed from `proposal.md` and `tasks.md`. L6 is the lot where a shared
document either becomes trustworthy or loses work quietly.

---

Statut : 2 exigence(s) appliquée(s), 11 exigence(s) en attente.

En attente, donc non opposables :
- an offline change is queued, not lost
- a conflict is shown to a person
- the authoritative copy has a named owner
- the authoritative copy is one copy
- a transaction is all or nothing
- the same request twice is one change
- a diverged base is refused, never merged
- the sequence only moves forward
- the principal comes from the session, not the body
- an event is published after the commit, and can be recovered
- presence is not a lock and is not a sequence

## ADDED Requirements

### Requirement: concurrency is refused, not merged
Two concurrent edits SHALL be detected, and the second SHALL be refused with a
clear message rather than merged or overwritten.

#### Scenario: two people, one object
- **GIVEN** two people editing the same object
- **WHEN** both save
- **THEN** one succeeds, the other is told, and nothing is lost silently

#### Scenario: the second person retries correctly
- **GIVEN** a refused second save
- **WHEN** that person reloads and re-applies their change deliberately
- **THEN** it succeeds, and the reload did not silently discard their draft

### Requirement: an offline change is queued, not lost
A change made without a connection SHALL be queued durably, SHALL survive a
restart, and SHALL be reconciled on return.

#### Scenario: quitting while offline
- **GIVEN** an offline change not yet sent
- **WHEN** the application is quit and relaunched
- **THEN** the change is still queued

#### Scenario: the same change sent twice
- **WHEN** a queued change is sent again after an uncertain first attempt
- **THEN** it is applied at most once

### Requirement: a conflict is shown to a person
A conflict SHALL present the current version and the person's own version
together, and SHALL require a choice. Nothing SHALL merge by default.

#### Scenario: choosing between two texts
- **GIVEN** two versions of the same text
- **WHEN** the person resolves the conflict
- **THEN** they choose, and both contributions remain attributed

#### Scenario: unrelated edits proceed
- **GIVEN** a conflict on one object
- **WHEN** the person edits a different object
- **THEN** that edit is not blocked by the unresolved conflict

### Requirement: a rejected direction survives a conflict
A conflict resolution SHALL NOT remove a direction because it was rejected or set
aside.

#### Scenario: a merge across a rejected branch
- **WHEN** a conflict is resolved by accepting a version from elsewhere
- **THEN** the rejected direction is still there, still marked, and still reopenable

### Requirement: the authoritative copy has a named owner
A shared document SHALL name the owner of its authoritative copy, and that owner
SHALL be visible in the interface.

#### Scenario: looking for the owner
- **GIVEN** a shared document
- **WHEN** the person asks who owns it
- **THEN** one identity is named

### Requirement: the authoritative copy is one copy
Two clients editing the same document SHALL NOT each believe their own copy is
authoritative, and the interface SHALL NOT present an unsynchronised local state
as if it were the shared truth.

#### Scenario: disconnected but shown as shared
- **GIVEN** a shared document with pending changes
- **WHEN** the interface shows its state
- **THEN** it says what is local and what is not yet shared

## ADDED Requirements, second tranche

The six above are what a person sees. The seven below are the shared transaction
contract from `SPECIFICATIONS.md` §Backend, which nothing in any delta stated.
That asymmetry is deliberate in the specification — the server is treated as
infrastructure — and wrong for this one thing, because a transaction contract
that is only prose is discovered by two people losing work.

### Requirement: a transaction is all or nothing
A transaction SHALL write the current snapshot, the new revision, the transaction
record and the event to be broadcast in one commit. A failure at any point SHALL
leave the document exactly as it was, and SHALL NOT leave a revision without its
transaction or a transaction without its event.

#### Scenario: the commit fails halfway
- **WHEN** writing the transaction fails after the snapshot would have been written
- **THEN** neither the snapshot nor the revision changed, and the next read returns
      the state before the attempt

#### Scenario: a validation failure
- **WHEN** an operation is refused while being applied
- **THEN** nothing is written, and the refusal names the operation rather than the
      transaction as a whole

### Requirement: the same request twice is one change
A transaction SHALL carry a client mutation identifier scoped to the principal and
the document. Replaying it with the same body SHALL return the original result
without applying anything twice. Replaying it with a different body SHALL be
refused.

#### Scenario: a lost acknowledgement
- **GIVEN** a transaction whose response never arrived
- **WHEN** the client sends the identical transaction again
- **THEN** the original sequence is returned, and no second change exists

#### Scenario: the same key, a different body
- **GIVEN** a transaction already committed under an identifier
- **WHEN** a different body is sent under that identifier
- **THEN** it is refused, and the committed transaction is untouched

#### Scenario: two people, same identifier
- **GIVEN** two principals that happen to choose the same identifier
- **WHEN** each sends a transaction
- **THEN** both apply, because the scope includes the principal

### Requirement: a diverged base is refused, never merged
A transaction SHALL carry the sequence it was built against. If that sequence is
not the current one, the server SHALL refuse it and return the current sequence.
It SHALL NOT merge automatically and SHALL NOT resolve by last write. A client MAY
rebuild its commit once, and only if every precondition it read or wrote still
holds.

#### Scenario: the second save of two people
- **GIVEN** two people who both built a commit from the same sequence
- **WHEN** both save
- **THEN** the first applies and the second is refused with the current sequence,
      and the second person's text is still theirs to keep

#### Scenario: a legitimate rebuild
- **GIVEN** a refused commit whose objects were not touched by the other change
- **WHEN** the client rebuilds it against the new sequence
- **THEN** it applies, because the preconditions still hold

#### Scenario: a rebuild that is no longer valid
- **GIVEN** a refused commit on an object the other change did touch
- **WHEN** the client rebuilds it
- **THEN** it is refused again, and a person chooses instead

#### Scenario: the same text
- **GIVEN** two people editing the same text
- **WHEN** both save
- **THEN** it opens the conflict, and no character-level merge is attempted

### Requirement: the sequence only moves forward
The shared sequence SHALL increase on every committed transaction, SHALL increase
even when the transaction is a compensation for an earlier one, and SHALL NOT be
reused or reordered. A rejected transaction SHALL NOT consume a sequence.

#### Scenario: undoing a shared change
- **GIVEN** a committed change
- **WHEN** it is undone as a new transaction
- **THEN** the sequence has increased again, and the two events are ordered

#### Scenario: a refused transaction
- **WHEN** a transaction is refused
- **THEN** the sequence is unchanged, so the next client is not told about a change
      that did not happen

### Requirement: the principal comes from the session, not the body
The acting person SHALL be derived from the authenticated session. A body that
names an actor SHALL NOT grant that actor's rights, and a workspace role SHALL NOT
by itself grant access to a private document.

#### Scenario: a body that names someone else
- **GIVEN** a request whose body claims an actor who is not the session's
- **WHEN** it is submitted
- **THEN** the session's principal is used, and the body's claim is ignored

#### Scenario: an administrator and a private document
- **GIVEN** a workspace administrator who is not a member of the document
- **WHEN** they try to read it
- **THEN** they cannot, and the refusal says why rather than reporting it as absent

### Requirement: an event is published after the commit, and can be recovered
No event SHALL be broadcast before its transaction is committed. A broadcast that
fails SHALL leave a durable record so the event can be delivered later, and a
client SHALL be able to catch up by asking for what it has not seen.

#### Scenario: the broadcast fails
- **GIVEN** a committed transaction whose broadcast failed
- **WHEN** the client asks for events after its last sequence
- **THEN** it receives the event, without the transaction being applied again

#### Scenario: a compacted history
- **WHEN** a client asks for events that no longer exist
- **THEN** it is told a resynchronisation is required, rather than being given a
      partial answer that looks complete

### Requirement: presence is not a lock and is not a sequence
Presence SHALL be ephemeral, SHALL NOT change the document sequence, and SHALL NOT
be recorded as a modification. Receiving a colleague's position SHALL NOT stop the
person from editing the same object.

#### Scenario: a colleague is looking at the same object
- **GIVEN** two people viewing the same object
- **WHEN** one of them edits it
- **THEN** the edit is not blocked, and the presence of the other is not stored
      with the document

#### Scenario: presence after a disconnection
- **WHEN** a person disconnects
- **THEN** their presence expires without removing their contributions or their
      name from anything they wrote
