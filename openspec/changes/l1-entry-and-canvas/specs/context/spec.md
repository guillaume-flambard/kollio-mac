# Capability: context (delta from L1)

Reconstructed from `proposal.md` and the accumulated present tense in
`openspec/specs/context.md`. L1 contributes only the authored-context
requirement; the rest of the capability arrives with L3.

---

Statut : 1 exigence(s) appliquée(s), 1 exigence(s) en attente.

En attente, donc non opposables :
- adding information is one transaction

## ADDED Requirements

### Requirement: context is authored, never generated
The context SHALL hold the person's own words exactly as written, and no
component SHALL replace them with a summary or a translation.

#### Scenario: the intelligence source is unavailable
- **GIVEN** a typed context and a source that fails
- **WHEN** the person begins
- **THEN** the context is unchanged and the failure is reported against the
      request, not against the text

#### Scenario: changing the interface language
- **WHEN** the interface language changes
- **THEN** the authored context is unchanged and untranslated

### Requirement: adding information is one transaction
Information added at a chosen place SHALL be attached to that place, SHALL keep
its author's words, and SHALL survive a later failure of any intelligence
request.

#### Scenario: the request that followed failed
- **GIVEN** an information added to an object
- **WHEN** a later exploration of that object fails
- **THEN** the information is still there, attached to the same object
