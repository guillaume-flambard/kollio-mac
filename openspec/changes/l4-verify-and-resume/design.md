# L4 — design decisions

## Camera is saved state, not a view preference

**Chosen:** persist the camera with the document.

**Rejected:** refitting the content on every open. It is predictable, and it throws
away the one thing that makes a resumed document feel resumed: where the person
was looking.

## Export format is deliberately not the working format

**Chosen:** a readable, documented, additive format.

**Rejected:** writing the internal protocol out. It would leak implementation into
a file meant to outlive the implementation, and every schema change would break
every export already on a disk.
