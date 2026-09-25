# L2 — design decisions

## A candidate, not a command

**Chosen:** `@Generable` with an outcome, a rationale and a bounded list of ideas.

**Rejected:** asking the model for the document's command enum. A small on-device
model should not reconstruct a protocol, and a model must not choose its own
authority, identifiers or ownership.

## One session per request, discarded

**Chosen:** a fresh `LanguageModelSession` per exploration.

**Rejected:** a long-lived session per document. It would leak context between
documents and branches, and a failed or refused generation would poison the next
one. The document is the memory; the session is disposable.

## No tools at all

**Chosen:** no shell, browser or filesystem tools.

**Rejected:** tool use for sources or files. It converts a document into an
attack surface, and none of it is needed to propose a branch. Document content is
data, and the instructions say so.

## The deployment target stays where it is

**Chosen:** `@available(macOS 26.0, *)` guards on the adapter, with a compile-time
gate and a runtime availability check.

**Rejected:** raising the whole application to macOS 27 to use a newer feature.
A compile-time guard and a runtime check are different checks, and conflating
them would make the app claim a capability it cannot have on an older Mac.

## Determinism is explicit, never inherited

**Chosen:** every deterministic test asks for the offline engine by name.

**Rejected:** letting tests inherit the launch default. The first version of this
did exactly that, and the suite took 35 seconds and started failing on a Mac with
a usable model. A test that depends on the machine is not a test.
