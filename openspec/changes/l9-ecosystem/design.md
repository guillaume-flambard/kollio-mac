# L9 — design decisions

## Export is a feature; a marketplace is a different product

**Chosen:** scope this lot to leaving under the person's control.

**Rejected:** implementing the commerce and ecosystem features while their
underlying decisions are open. It would produce a plausible-looking surface over
an unanswered question, which is more expensive to remove than to defer.

## The never-shared list is code, not documentation

**Chosen:** the exclusions are enforced and tested.

**Rejected:** relying on a policy document. A boundary that is only written down is
a boundary that a future change will cross without noticing.
