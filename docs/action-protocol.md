# The action protocol

Three different things, deliberately kept apart:

| | Undo (Cmd+Z) | Decision | Proposal |
|---|---|---|---|
| what it is | editing history | project memory | a suggestion |
| where it lives | `UndoHistory`, in memory | the document | transient, until kept |
| survives a restart | no | yes | no |
| who decides | the user | the user | the source proposes, the user decides |

## Commands

Every meaningful mutation is a validated command. Views never mutate several pieces of state at once.

```
createObject        updateObjectText     addRelationship
removeRelationship  moveNodeInstances    createScenario
recordDecision      revokeDecision       addContributionToProduct
applyProposal       rejectProposal
```

`moveNodeInstances` is the only presentation-only command: it bumps `revision` and leaves
`semanticRevision` alone.

A transaction applies to a copy of the document and is published only if every command succeeded. One
invalid relationship in a list of ten leaves the document byte-for-byte unchanged; a test asserts it.

Applying a proposal is one command, so it is undone as one coherent action.

## Decisions

```swift
.recordDecision(.init(id: …, kind: .setAside, targetObjectID: …, rationale: …))
.recordDecision(.init(id: …, kind: .reopened, targetObjectID: …))
```

`setAside` marks the direction and its *exclusive* descendants as set aside. Nothing is deleted, no
position changes, and the rationale is stored with the decision. `reopened` restores exactly the set
recorded in the previous decision, so the branch comes back where it was rather than being regenerated.
A new decision supersedes the previous active one on the same target, and the current reason is always
the last word.

Setting a *proposal* aside is different: it was never added to the document, so it is simply
discarded. Setting a *direction* aside happens from the direction's own contextual action, which asks
for the reason first.

## What a proposal may do

A proposal is a patch: a list of commands plus placement hints. It is validated three times, by three
different parties, and the last word belongs to the client.

```text
Canvas → request → provider → proposal → server validation
       → client validation → ghost branch → user Keeps
       → one local transaction → save → undo possible
```

Allowed: create objects, add relationships, record or revoke a decision.

Refused: creating a scenario, nesting an `applyProposal` inside a proposal, a proposal that exceeds
the operation budget, a proposal that references an object which does not exist, a proposal whose
`baseSemanticRevision` is behind, a proposal with a rationale longer than the budget, anything outside
the requested scope.

Placement is intent, never pixels. A generator says "this object goes 170 points below its parent", and
the client decides the exact position, including pushing a proposed object down when it would land on
top of existing work. A proposal is never allowed to move what is already on the canvas.

## The request

```json
{
  "requestId": "…",
  "documentId": "…",
  "baseSemanticRevision": 5,
  "intent": "explore",
  "targetIds": ["object:sarah-csv"],
  "instruction": null,
  "contentLocale": "fr",
  "preconditions": { "semanticRevision": 5 },
  "scope": { "maxOperations": 8, "allowNewObjects": true }
}
```

Intents: `explore`, `add`, `setAside`, `reopen`, `clarify`. The schema is in
[contracts/schemas/kollio-action.schema.json](../contracts/schemas/kollio-action.schema.json).

The answer is one of three statuses: `proposed`, `needsInput`, `noChange`. `noChange` is a real
answer, not a failure: the offline engine returns it when the branch already exists, and when a
direction has been set aside it is `reopen`, not `explore`, that can move it.

## Offline intelligence

`LocalDemoSuggestionService` is deterministic and offline. It is not a recorded screenshot sequence:
it reads the current document, so rejecting, reopening, keeping or editing a direction genuinely
changes the next answer. A test proves that exploring, keeping, and exploring again returns
`noChange` the second time.
