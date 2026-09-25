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

## Streaming is an additional capability, never a replacement

**Chosen:** a second protocol, `StreamingSuggestionService`, that refines
`SuggestionService`. The model asks for it if the source has it.

**Rejected:** changing `SuggestionService.respond` to stream. It would force every
implementation, including the deterministic engine and the remote provider, to
grow a streaming path they cannot honestly support, and a source that pretends to
stream while buffering internally is worse than one that admits it does not.

## A progress can never become a proposal

**Chosen:** `ProposalProgress` carries a sentence, a count and a flag. It has no
identifier, no operation, and no initialiser that could produce one.

**Rejected:** converting the partial decode into real `Command` values and showing
them as ghost objects straight away. A half-decoded direction has no kind the
canvas can trust, its identifier would have to be minted before its text is final,
and it would offer the user something they could act on and that might change or
vanish on the next token. A growing sentence cannot be kept, so it cannot mislead.

## The first progress is expected to be partial

**Chosen:** test that the first update is genuinely incomplete.

**Rejected:** asserting only that progress arrived. A stream that emits one fully
formed progress at the end has technically streamed and has done nothing for the
wait, so the test that matters is the one that fails if the first update is
already the whole answer.
