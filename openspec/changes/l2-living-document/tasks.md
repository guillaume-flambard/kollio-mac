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
- [ ] **Warm latency and a second identical call, to tell cold asset loading from
      generation.** Owed. Cold is 9–15 s, which is the blocking finding.
- [ ] **A real proposal kept, set aside and reopened by a person.** Owed.
- [ ] The `at most 3 ideas` bound and the refused-kind rule exercised against a
      real model, not only the converter.
- [ ] `AI-12` context budgeting: no implementation beyond the model's own limit.

## Findings, not assumptions

Cold latency of 9 to 15 seconds on this class of Mac. It is a real path working,
and it is far too slow to feel interactive. A pending state that lasts ten seconds
is the next thing a user will complain about, and the cause is not yet separated
into asset loading versus generation.
