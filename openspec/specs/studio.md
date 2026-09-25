# Capability: studio

Turning a document into something usable, without leaving the app and without
losing the link back to why.

## Requirements

### Requirement: composition references, it does not copy
A presentable object SHALL reference the document objects it composes, and
editing it SHALL keep the link to those objects visible.

#### Scenario: the source changes
- **WHEN** a composed object is edited in the document
- **THEN** the presentation shows the change and still names its source

### Requirement: authored text is opaque to the product
No component SHALL summarise, tighten, rewrite or translate authored text, in any
language configuration.

#### Scenario: a presentable object is produced
- **WHEN** a presentable object is created
- **THEN** its authored text is byte-for-byte the person's own

### Requirement: templates are personal
A template SHALL belong to the person who made it and SHALL NOT be shared by
default.
