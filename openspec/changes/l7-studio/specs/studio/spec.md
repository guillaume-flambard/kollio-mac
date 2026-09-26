# Capability: studio (delta from L7)

Reconstructed from `proposal.md` and `tasks.md`. Two invariants meet in this
lot, and they get tests rather than reviews.

---

Statut : 3 exigence(s) appliquée(s), 1 exigence(s) en attente.

En attente, donc non opposables :
- being presentable is a command

## ADDED Requirements

### Requirement: being presentable is a command
Marking an object presentable SHALL be a validated command in a transaction, and
SHALL be reversible like any other change.

#### Scenario: marking and unmarking
- **WHEN** a person marks an object presentable and then undoes
- **THEN** the mark is gone and the object is unchanged

### Requirement: composition references, it does not copy
A presentable object SHALL reference the document objects it composes, and
editing it SHALL keep the link to those objects visible.

#### Scenario: the source changes
- **WHEN** a composed object is edited in the document
- **THEN** the presentation shows the change and still names its source

#### Scenario: naming what it is made of
- **GIVEN** a composition
- **WHEN** the person inspects it
- **THEN** it lists the document objects it uses

### Requirement: authored text is opaque to the product
No component SHALL summarise, tighten, rewrite or translate authored text, in any
language configuration.

#### Scenario: a presentable object is produced
- **WHEN** a presentable object is created
- **THEN** its authored text is byte-for-byte the person's own

#### Scenario: changing the interface language
- **GIVEN** a presentable object with authored text
- **WHEN** the interface language changes
- **THEN** the authored text is unchanged and untranslated

#### Scenario: a long text
- **GIVEN** an authored text longer than the object's box
- **WHEN** it is presented
- **THEN** the full text is reachable, and is never shortened to fit

### Requirement: templates are personal
A template SHALL belong to the person who made it and SHALL NOT be shared by
default.

#### Scenario: using someone else's template
- **WHEN** a person uses a template they did not make
- **THEN** the template's owner is named, and it is not modified in place

#### Scenario: a template that has not been shared
- **GIVEN** a personal template
- **WHEN** a document is shared with someone
- **THEN** the template is not included
