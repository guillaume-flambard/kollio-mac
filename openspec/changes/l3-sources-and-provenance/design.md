# L3 — design decisions

## A source is a reference, never a copy

**Chosen:** store a kind, a locator and a title; read the bytes on demand.

**Rejected:** importing source content into the document. It duplicates the user's
files, doubles the size, and creates a second copy that can disagree with the
first. A quote is the exception, because a quote is meant to be a copy of a
sentence.

## Retrieval returns an absence explicitly

**Chosen:** the result type carries both the found items and an explicit empty
state with a reason.

**Rejected:** an empty array. An empty array cannot be distinguished from a bug, a
missing index or a filter that matched nothing, and the user is the only one who
can tell those apart. A silent empty result is how a product loses trust in its
own intelligence.

## Derived views, single source

**Chosen:** the context view and the knowledge view read from the store and are
recomputed.

**Rejected:** storing a rendered summary of the context. It would be a second
truth, and it would drift from the context on the first edit.
