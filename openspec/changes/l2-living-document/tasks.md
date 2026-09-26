# L2 — tasks

- [x] Model availability read from the reasons the SDK actually reports, each
      mapped to its own explanation. `swift test --filter AppleAdapterTests`
- [x] An unavailable model is a refusal: no fallback to the engine, no network
      call, no claimed answer. Same suite.
- [x] A compile-time gate and a runtime check are both present and are not
      confused. The deployment target is unchanged.
- [x] The model fills in meaning only. The adapter mints ids, refuses
      unrenderable kinds and bounds the branch. Same suite.
- [x] `noChange` and `needsInput` survive as themselves; an unknown outcome is
      never interpreted. Same suite.
- [x] The deterministic suite never touches a real model and stays under two
      seconds. Every test pins the engine explicitly.
- [x] Two distinct non-Sarah contexts, French and English, produce a small valid
      proposal through the adapter, passing the same `ProposalValidator` as any
      other. `KOLLIO_REAL_MODEL=1 swift test --filter RealOnDeviceModelTests`
- [x] The running application holds no network socket, checked against its own
      pid.
- [x] A set-aside direction keeps its memory and reopens with a named action.
      `swift test --filter InteractionReliabilityTests`
- [x] One Keep undoes as one action. `swift test --filter VerticalSliceTests`
- [x] **Warm latency: three identical calls in one process.** 2.50 s, 2.68 s, 2.29 s,
      measured serially. Mostly a per-call cost, not a large one-off asset load.
- [x] **The answer streams, and progress is not a proposal.** 54 progress updates over
      5.1 s on a real model, the rationale arriving a few words at a time. The
      proposal is minted once at the end and validated exactly as before.
      `AppleAdapterTests`, `RealOnDeviceModelTests.realStreaming`
- [ ] **Streaming watched by a person.** The updates are proved to arrive; whether a
      sentence growing for five seconds feels good is not a test's judgement.
- [ ] **Streaming the branch itself, not only the sentence.** The ghost still appears
      all at once, because a half-decoded direction has no identifier and no kind the
      canvas can trust.
- [ ] **A real proposal kept, set aside and reopened by a person.** Owed.
- [ ] The `at most 3 ideas` bound and the refused-kind rule exercised against a
      real model, not only the converter.
- [ ] `AI-12` context budgeting: no implementation beyond the model's own limit.

## Findings, not assumptions

Steady-state latency is about 2.3 s, and the first call in a fresh process is about 3.6 s. That is
the real cost of generation on this class of Mac, and it is too slow to feel interactive. Nothing is
streamed, so a person waits on a pending state for seconds.

An earlier round measured 9 to 15 s and recorded it as the blocking finding. It does not reproduce.
The identified confounder is parallel execution: the suite runs tests concurrently by default and two
of them share one on-device model. Every latency figure in this project must be taken with
`--no-parallel`, and the earlier figure should be treated as an unconfirmed one-off, most likely the
very first load of the model assets on the machine.

The conclusion did not change, only the size of the number. The wait is now filled, because the answer
streams and the sentence appears as it is written. What is still missing is streaming the branch itself:
the ghost objects still appear all at once, because a half-decoded direction has no identifier, no kind
the canvas can trust and no way to be validated. Showing it early would mean showing something that
cannot be kept and might not survive the next token, which is worse than showing a sentence growing.

## AI-03, explore a branch

Three things were declared and inert. `ProposalRequest.Preconditions.readSetFingerprint`
existed and was **set nowhere and read nowhere**; the request carried no `context` at all;
and `noChange` set `preview = nil`, so an answer that proposed nothing destroyed the branch
that was already on the canvas.

- [x] **AC01: the exact instruction is transmitted.** It was being *discarded*: the
      `Explore` branch of `submitComposer` cleared the composer and called `explore` with
      no instruction, so a person who typed a steer and pressed the key had it silently
      ignored. A refused send now also keeps the words in the composer.
- [x] `readSet(for:)`: the target, what it links to, one step beyond, and every
      direction already rejected. A constraint three branches away is not applicable and
      would only spend the context budget.
- [x] **AC02: rejected directions are consulted, with their reasons.** `ContextItem`
      gained a `reason`, because "no budget" and "tried it in March" are different
      instructions and a bare list of dead ends reads as a ban rather than as reasoning.
      No reason invented when none was given.
- [x] A reopened direction is transmitted as `active`, not as still rejected, so the
      engine cannot refuse a door the person just opened.
- [x] The engine honours only the rejections **it was given** in the read set, not the
      ones it could find in the document. Reading the whole document would make it look
      as though it were consulting the reasoning when it was only pattern-matching state,
      and would quietly forgive a client that forgot to transmit.
- [x] **The rejection signature is stable.** Computed by sorting before hashing, because
      a fingerprint is only worth anything if the same read set always gives the same
      string; iterating dictionaries and hashing in order would have made every
      precondition look stale. The reason is folded in, so identical text rejected for
      two different reasons is two different contexts.
- [x] **AC03: a new exploration does not erase the previous proposal.** A new proposal
      supersedes the old one, which is *offered* through `supersededProposal` and kept
      readable in `keptProposals`, and `noChange` takes nothing away at all: nothing
      arrived, so nothing is lost.
- [x] A rejected branch is not reopened by the engine: a set-aside target yields
      `noChange`, and the decision is untouched.
- [x] A repetitive loop yields `noChange` rather than duplicating itself, and the test
      asserts no two objects in the document say the same thing.
- [x] Exploring does not change the parent's status: the parent is byte-identical, the
      decision count is unchanged, and nothing is written.

### A defect found by a test, and located by measuring

The read set kept the *first* mention of each object. A rejected direction that happened
to be a neighbour too arrived with `reason: nil` and the rejection loop then skipped it,
so the same document produced different read sets depending on iteration order, and the
reason that made a rejection useful was the thing most likely to be lost. Found by two
failing tests, then located by printing the decisions, the objects and the read set rather
than by reading the code again. The fix upgrades an existing entry instead of skipping it,
and emits the set sorted.

### Owed

- [ ] **The offer to keep or hide is not on screen.** `supersededProposal`,
      `keptProposals`, `keepPreviousProposal` and `hidePreviousProposal` exist and are
      tested; nothing yet asks the question. The specification requires it to be
      *offered*, which is interface work.
- [ ] **Second-degree reach is a guess.** One step beyond the direct neighbours is a
      placeholder for "applicable", and a real notion of applicability is owed. It is
      documented in the code as such rather than presented as a rule.
- [ ] **The read set grows with the neighbourhood.** Bounded by reach, but not by a
      budget: a dense document could produce a large `context`. The server rebuilds it
      from the snapshot, so this is a transport concern, not yet a correctness one.
