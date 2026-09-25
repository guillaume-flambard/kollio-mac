# Kollio — invariants and commands

Read [docs/CONTINUE.md](docs/CONTINUE.md) for the active milestone and
[docs/known-limitations.md](docs/known-limitations.md) for what is actually true
right now. [docs/PRODUCT_BLUEPRINT.md](docs/PRODUCT_BLUEPRINT.md) is the
direction; it is not injected into every small task.

## Verify

```bash
./scripts/verify.sh          # 3 suites + the Xcode app target
./scripts/run-app.sh --shot  # build, launch, screenshot into build/
```

Real on-device model, opt-in and skipped otherwise:

```bash
KOLLIO_REAL_MODEL=1 swift test --package-path packages/KollioApp --filter RealOnDeviceModelTests
```

`run-app.sh --shot` prints a path whether or not the capture worked. Check the
file exists and shows the app. Protect the user's documents before any demo
launch.

## Invariants

1. `packages/KollioCore` imports no SwiftUI, no AppKit, **no FoundationModels**,
   no Vapor. `@Generable` types and provider instructions live in the app's
   `Intelligence/Apple` adapter.
2. Every mutation is a validated command in an atomic transaction. Views never
   mutate the document.
3. Intelligence proposes a bounded patch. It never regenerates the world, never
   assigns its own identifiers, and never moves what already exists.
4. A rejected direction keeps its memory. Rejected is not deleted.
5. No permanent chrome: no sidebar, toolbar, inspector or chat panel. Interaction
   appears where the user is working; system commands live in native menus.
6. Design tokens only. Interface strings live in the String Catalog.
7. Local and cloud are never silently interchangeable. An unavailable model does
   not become demo output or a network call.
8. Authored text is never replaced by a summary, and changing the interface
   language never machine-translates it.
9. `apps/macos/Kollio.xcodeproj` is generated. Use `scripts/sync-xcodeproj.py`.
10. Code, identifiers, comments and docs in English. Interface in FR and EN.
    Reports to the owner in French.
11. Deterministic tests never require Apple Intelligence, a key or a network.
    Real-model evidence is a separate, explicitly marked suite.
