# Kollio — invariants and commands

Read [docs/CONTINUE.md](docs/CONTINUE.md) for the active milestone and
[docs/known-limitations.md](docs/known-limitations.md) for what is actually true
right now. [docs/PRODUCT_BLUEPRINT.md](docs/PRODUCT_BLUEPRINT.md) is the
direction; it is not injected into every small task.

[docs/specs/SPECIFICATIONS.md](docs/specs/SPECIFICATIONS.md) is the normative
specification: 71 features, 213 acceptance criteria. [openspec/README.md](openspec/README.md)
decomposes it into capabilities and lots.

[docs/AGENT-LOOP.md](docs/AGENT-LOOP.md) is the implementation and review loop
for a session that is allowed to build: batch order, the review levels, the
onboarding rules, and the two decisions that belong to the owner.

## Verify

```bash
./scripts/verify.sh          # spec views + 3 suites + the Xcode app target
./scripts/run-app.sh --shot  # build, launch, screenshot into build/
```

Real on-device model, opt-in and skipped otherwise:

```bash
KOLLIO_REAL_MODEL=1 swift test --package-path packages/KollioApp \
  --filter RealOnDeviceModelTests --no-parallel
```

`--no-parallel` is not optional when the number matters. The suite runs tests
concurrently by default and there is only one on-device model, so a parallel run
measures contention instead of latency.

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
12. `openspec/specs/feature-catalog.json`, `openspec/todo.md` and
    `openspec/implementation-status.json` are **generated**. Edit the
    specification or the two generator scripts, never those files. `verify.sh`
    fails if they are stale.
13. Status is earned, never assumed. `specified` is the default; a feature is
    `automatedVerified` only when a named test passes.

## Committing when more than one agent is in this repository

More than one session may be working in the same working tree at the same time.
The index is shared, so the rules below are not style, they are the only thing
standing between two agents and a commit that contains neither one's work.

1. **Never `git add -A`, and never `git add .`.** Stage the exact paths you
   changed, by name. A blanket add will commit whatever another agent happened to
   have open, including a half-written file. This happened once already: a commit
   whose message described one thing and carried ten files from elsewhere.
2. **Commit with explicit paths**: `git commit -m "..." -- <paths>`. Passing
   paths makes the commit ignore everything else sitting in the index, which is
   usually somebody else's staged work that is not ready.
3. **If another agent's files are already staged, leave them staged.** They are
   not yours to commit and not yours to unstage.
4. **Read back what you committed**: `git show --format="" --name-only HEAD`.
   Count the files against the list you passed. A count you did not expect means
   something leaked in.
5. **Shared files need care.** `docs/CONTINUE.md`, `docs/known-limitations.md` and
   `AGENTS.md` can carry both agents' edits in one working-tree copy. If you edited
   one, say so in the report rather than pretending the whole file is yours.
6. **Never push.** Rule 7 applies, and a shared `main` means a push publishes
   another agent's unfinished work along with yours.
