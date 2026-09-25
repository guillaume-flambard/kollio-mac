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

The conclusion did not change, only the size of the number: streaming partial output to the canvas is
the fix, and it is not built.
