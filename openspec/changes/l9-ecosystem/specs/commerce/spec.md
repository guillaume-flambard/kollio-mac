# Capability: commerce (delta from L9)

Reconstructed from `proposal.md` and `tasks.md`. Nothing here is implemented and
nothing here is authorised: identity, hosting and liability are undecided, and
three of the six features in this lot have no agreed meaning yet.

---

Statut : 3 exigence(s) appliquée(s), 9 exigence(s) en attente.

En attente, donc non opposables :
- a purchase is confirmed by the provider, not by the browser
- money is computed, never asserted
- a refund is a reversal, not an erasure
- a buyer's data is not the seller's to read
- a test never moves real money
- a distribution is exact or absent
- an agreement is versioned and its history is fixed
- support keeps its own record
- reporting is separate from support

## ADDED Requirements

### Requirement: nothing in this capability is authorised
No code in this capability SHALL be started without an explicit decision on
identity, hosting and liability.

### Requirement: nothing leaves without the person
Any export or publication SHALL be initiated by the person, SHALL preserve
authored text, and SHALL be something the person owns outside the application.

#### Scenario: opening a share surface sends nothing
- **WHEN** a person opens the sharing surface and then cancels
- **THEN** nothing was sent, and the document is still private

#### Scenario: the person owns what left
- **WHEN** something was published
- **THEN** the person has it as a file they keep, not only as a state in the
      application

### Requirement: the never-shared list is enforced
The documented exclusions SHALL be enforced in code and covered by a test, not
only stated in documentation.

#### Scenario: something not explicitly permitted
- **WHEN** an item on the never-shared list reaches a publication path
- **THEN** the test proves it is refused

### Requirement: a purchase is confirmed by the provider, not by the browser
An access right SHALL be granted only on a confirmation verified from the payment
provider, and a return to the application SHALL NOT by itself grant anything.

#### Scenario: the browser returns but the provider did not confirm
- **WHEN** the person returns from a checkout with no verified confirmation
- **THEN** no access is granted, and the state says what is still pending

#### Scenario: the same confirmation arrives twice
- **WHEN** the provider reports the same payment twice
- **THEN** one purchase is recorded, not two

### Requirement: money is computed, never asserted
A revenue figure SHALL be computed from recorded amounts and an explicit split,
and SHALL NOT be displayed as a claim about money received.

#### Scenario: a split that does not add up
- **WHEN** the shares do not total the whole
- **THEN** the figure is not presented, and the discrepancy is named

#### Scenario: costs not yet final
- **WHEN** a cost is an estimate
- **THEN** it is labelled as an estimate in the same place as the number

### Requirement: a refund is a reversal, not an erasure
A refund SHALL be recorded as an event linked to the original purchase, and the
original purchase record SHALL remain readable.

#### Scenario: after a refund
- **WHEN** a purchase is refunded
- **THEN** both the purchase and its reversal are readable, and neither is deleted

### Requirement: a buyer's data is not the seller's to read
A buyer's inputs to a product SHALL NOT be visible to the seller by default, and
access SHALL require an explicit, revocable grant.

#### Scenario: the seller looks at a run
- **WHEN** the publisher inspects a product they sold
- **THEN** the buyer's inputs are not shown, and the absence is stated rather than
      left ambiguous

### Requirement: a test never moves real money
Every purchase path SHALL run against a provider sandbox by default, and a test
run SHALL NOT create a real charge, a real entitlement backed by a real charge,
or a real transfer.

#### Scenario: the suite runs
- **WHEN** the deterministic suite exercises a purchase
- **THEN** the provider is the sandbox, and no real payment instrument is touched

#### Scenario: a real provider without authorisation
- **GIVEN** a production provider that has not been authorised
- **WHEN** a purchase is attempted
- **THEN** it is refused, rather than run against the real provider to see

#### Scenario: a test entitlement
- **WHEN** a test grants access
- **THEN** the access is recognisably a test access and cannot be mistaken for a
      paid one

### Requirement: a distribution is exact or absent
A distribution SHALL total the distributable amount exactly, in minor units, with
a deterministic rounding rule, and SHALL NOT be presented when it does not.

#### Scenario: a hundred less ten
- **GIVEN** a sale of 100 and costs of 10
- **WHEN** the distribution is computed
- **THEN** the distributable total is exactly 90, and the parts sum to 90

#### Scenario: a remainder that has to be rounded
- **WHEN** the shares do not divide the total evenly
- **THEN** the rounding rule is stated and applied the same way every time, and
      the parts still sum to the total

#### Scenario: two currencies
- **WHEN** amounts in two currencies would be added
- **THEN** they are not added, unless a conversion is documented and shown

### Requirement: an agreement is versioned and its history is fixed
A distribution SHALL cite the agreement version that produced it, and a later
agreement SHALL NOT change what an earlier sale distributed.

#### Scenario: a new agreement after a sale
- **GIVEN** a sale distributed under one agreement
- **WHEN** a new agreement takes effect
- **THEN** the earlier sale still shows the figures its own agreement produced

#### Scenario: two products sharing a contribution
- **GIVEN** two products that reuse the same contribution
- **WHEN** their revenues are consulted
- **THEN** they are two distinct lines, because they are two sales

### Requirement: support keeps its own record
A support request, a refund request and a moderation report SHALL be separate
records, and none SHALL rewrite the purchase it concerns. Attachments SHALL be
explicitly selected by the person, and a duplicated request SHALL NOT have a
double effect.

#### Scenario: attachments
- **WHEN** a support request is sent
- **THEN** only the attachments the person selected are attached

#### Scenario: the same request twice
- **WHEN** a support request is submitted twice
- **THEN** one case exists, with the second attempt recognised as the same

#### Scenario: a product is withdrawn
- **WHEN** a product is withdrawn from sale
- **THEN** earlier purchases, their receipts and their support remain reachable

### Requirement: reporting is separate from support
A report about a product SHALL NOT create a refund, and a support request SHALL
NOT be treated as a moderation action.

#### Scenario: reporting a product
- **WHEN** a person reports a product
- **THEN** a moderation case exists, and no money moved
