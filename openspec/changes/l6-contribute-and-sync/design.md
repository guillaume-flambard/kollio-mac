# L6 — design decisions

## Refuse, do not merge

**Chosen:** detect, refuse, and let a person decide.

**Rejected:** automatic three-way merge. It is the right default for text and the
wrong default here, because the document's meaning lives in structure and in what
was deliberately set aside.

## Local first, sync as a transport

**Chosen:** a document is correct and complete on one machine before any transport
exists.

**Rejected:** designing around a server. It would make the single-player case pay
for a multi-player design, and the single-player case is the one that exists.
