# L7 — design decisions

## Composition references, it does not copy

**Chosen:** a presentable object points at the document objects it composes.

**Rejected:** materialising a copy for editing. It is the single change most likely
to silently break the link between an artefact and the thinking behind it, and the
copy would then be edited forever with no way back.

## Authored text is opaque to the product

**Chosen:** the authored words are passed through, never rewritten.

**Rejected:** a "tighten this" feature. It is a nice demo of intelligence and a
direct violation of invariant 8. The value of the product is the person's own
wording.
