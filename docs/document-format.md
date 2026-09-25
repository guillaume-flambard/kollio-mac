# The `.kollio` document

A versioned JSON file. Readable, inspectable, portable, and completely independent of SwiftUI,
AppKit and the renderer. The schema is in
[contracts/schemas/kollio-document.schema.json](../contracts/schemas/kollio-document.schema.json).

## Envelope

```json
{
  "schemaVersion": 1,
  "documentId": "0F1C...",
  "revision": 12,
  "semanticRevision": 5,
  "createdAt": "2026-09-25T17:12:04.412Z",
  "updatedAt": "2026-09-25T17:14:51.008Z",
  "content": { "...": "semantic objects" },
  "relationships": { "...": "relationships" },
  "decisions": { "...": "durable decisions" },
  "contributions": {},
  "products": {},
  "presentation": { "instances": [] }
}
```

`revision` counts every accepted mutation. `semanticRevision` counts only the mutations that changed
what the document means. An intelligence request carries the `semanticRevision` it reasoned about, so
an answer computed against a document that has since changed meaning is rejected as stale. A proposal
that merely wants to move something on the canvas does not invalidate anything.

Timestamps are normalised to millisecond precision on the way in, so save and reopen is an exact
round-trip rather than a near-equality.

## Content

A `contentObject` is a semantic object. Its `kind` is meaningful and stable, even though the interface
never prints it:

```
context  need  method  technicalBlock  product  hypothesis
constraint  question  evidence  scenario  decision  note  contribution
```

The renderer derives one of three visual families from the kind, so the user understands the graph
before reading any metadata:

| Kind | Form | Appearance |
|---|---|---|
| product, method, technicalBlock | `richResult` | a substantial surface, expandable |
| evidence, contribution | `reference` | compact, icon, provenance |
| everything else | `thought` | typography, almost no container at rest |

`lifecycle` is `active` or `setAside`. A set-aside object keeps `setAsideByDecision`, which is how
the interface knows which durable reason to show.

### Authored text

```json
"text": {
  "text": "Export CSV depuis l’outil source",
  "variants": { "en": "CSV export from the source tool" }
}
```

`text` is the source value. `variants` holds only variants a human actually authored, which is how
the Sarah fixture exists in both languages. Kollio never machine-translates user content when the
interface language changes.

## Relationships

```json
"relationship:sarah-l4": {
  "from": "object:sarah-csv",
  "to": "object:sarah-viable",
  "kind": "supports",
  "label": { "text": "ouvre", "variants": { "en": "enables" } },
  "fromAnchor": { "unitX": 0.5, "unitY": 1 },
  "toAnchor": { "unitX": 0.5, "unitY": 0 }
}
```

Kinds: `addresses`, `uses`, `dependsOn`, `constrains`, `supports`, `contradicts`, `alternativeTo`,
`derivedFrom`, `associatedWith`. The existence of a connector never implies truth.

Anchors are stored in object-local unit space, which is why a connector follows its object while the
object moves, and why the interface can be re-rendered by another client without recomputing geometry.

## Decisions

```json
"decision:...": {
  "kind": "setAside",
  "targetObjectID": "object:sarah-csv",
  "branchObjectIDs": ["object:sarah-csv", "object:sarah-viable", "object:sarah-question"],
  "rationale": { "text": "On garde l’export pour plus tard" },
  "status": "active",
  "createdAt": "..."
}
```

A decision is project memory, not editing history. It survives quitting, reloading and the loss of
the undo stack. `branchObjectIDs` is the set of objects the decision covered, which is what makes
reopening exact rather than approximate. Only the objects that were *exclusive* to the direction are
collapsed, so an object shared with another branch stays visible.

## Presentation

```json
"presentation": {
  "instances": [
    { "id": "instance:object:sarah-csv", "objectID": "object:sarah-csv",
      "position": { "x": 270, "y": 210 }, "hidden": false }
  ]
}
```

One semantic object may have several instances. That is how a reusable contribution can appear in two
products without becoming two contributions, two owners, or two royalty claims.

Geometry is stored as plain numbers. Never a `CGPoint`, a `Color`, a class name, a view type or a
platform callback. A test asserts that none of those strings can appear in the file.

## What is deliberately not in the file

Hover, focus, selection, drag in progress, the camera, the open panel, the interface language, and
anything about how the document is currently rendered.
