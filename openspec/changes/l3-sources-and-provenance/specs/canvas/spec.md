# Capability: canvas (delta from L3)

Reconstructed from `proposal.md`. L3 is the lot that gives the canvas its
relationships, its groups and its search.

---

Statut : 1 exigence(s) appliquée(s), 3 exigence(s) en attente.

En attente, donc non opposables :
- the direction of a relationship is readable
- grouping is presentation
- finding does not change a status

## ADDED Requirements

### Requirement: relationships are drawn, not implied
A relationship SHALL be a routed path between its endpoints, SHALL follow its
objects when they move, and SHALL avoid an obstacle it cannot cross. Proximity on
the canvas SHALL NOT become a logical relation.

#### Scenario: an obstacle between the ends
- **WHEN** a relationship would cross another object
- **THEN** it is routed around it and labelled at the point it actually took

#### Scenario: two objects placed side by side
- **GIVEN** two objects with no relationship
- **WHEN** they are placed next to each other
- **THEN** they are not related, and no edge appears

#### Scenario: one end moves
- **WHEN** an endpoint of a relationship is dragged
- **THEN** the path follows it

### Requirement: the direction of a relationship is readable
A relationship SHALL name which end acts on which, and modifying it SHALL change
that meaning explicitly rather than only its arrow.

#### Scenario: reading the direction
- **GIVEN** a relationship between two objects
- **WHEN** the person reads its label
- **THEN** it says which object acts on which

### Requirement: grouping is presentation
A group SHALL hold its members for display, SHALL NOT create a business relation,
and folding a group SHALL NOT change the status of anything inside it.

#### Scenario: folding a group
- **WHEN** a person folds a group
- **THEN** the members keep their status and remain findable

#### Scenario: an object used elsewhere
- **GIVEN** an object that belongs to a group
- **WHEN** the group is folded
- **THEN** the object's other occurrence is unaffected

### Requirement: finding does not change a status
A search SHALL find content whatever its status, and opening a result SHALL NOT
reopen, un-set-aside or otherwise alter a decision.

#### Scenario: a reason inside a set-aside direction
- **GIVEN** a reason recorded on a direction that was set aside
- **WHEN** the person searches for it and opens the result
- **THEN** the reason is readable and the direction is still set aside

#### Scenario: no results
- **WHEN** a search matches nothing
- **THEN** the search says so, and the previous state is left alone
