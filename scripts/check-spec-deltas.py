#!/usr/bin/env python3
"""Check that the accumulated capability specs still descend from a change delta.

`openspec/specs/*.md` is the accumulated present tense. `openspec/changes/<id>/specs/
<capability>/spec.md` carries the delta each change introduced. The README promises
that shape; nothing enforced it, and six requirements had drifted into the present
tense with no delta behind them, so nobody could ask where a rule came from.

Three things are checked, and all three fail rather than warn:

1. **No orphan requirement.** Every requirement in the present tense must appear
   in some delta for the same capability. A requirement with no delta is a rule
   that arrived from nowhere; it is not wrong, it is untraceable.
2. **A delta belongs to a capability that exists.** A `specs/<name>/spec.md` whose
   capability has no accumulated spec, or is not named in
   `scripts/generate-spec-status.py`, is a delta nobody will ever merge.
3. **The status block in a delta is true.** Each delta states how many of its
   requirements are already applied and which are still pending. That block is
   written by hand, so it can lie, and a delta that claims to be applied while its
   requirements are missing from the present tense is worse than no status at all.

Deliberately *not* checked: that every requirement has a scenario. Several
accumulated requirements are one-liners whose scenario lives in another lot's
delta, and demanding a scenario here would push prose into scenarios to satisfy a
linter. Scenario coverage is a review question, not a lint.

Usage:
    python3 scripts/check-spec-deltas.py           # report and fail on any problem
    python3 scripts/check-spec-deltas.py --quiet   # one line, for a hook
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPECS = ROOT / "openspec" / "specs"
CHANGES = ROOT / "openspec" / "changes"
STATUS_SCRIPT = ROOT / "scripts" / "generate-spec-status.py"

# evidence.md is not a capability: it is the record of what has been proved.
NOT_A_CAPABILITY = {"evidence"}

REQUIREMENT = re.compile(r"^### Requirement: (?P<title>.+?)\s*$", re.M)
SCENARIO = re.compile(r"^#### Scenario", re.M)
# The one machine-readable line each delta carries. Hand-written, therefore checked.
STATUS = re.compile(
    r"^Statut : (?P<applied>\d+) exigence\(s\) appliquée\(s\), "
    r"(?P<pending>\d+) exigence\(s\) en attente\.\s*$",
    re.M,
)


def accumulated() -> dict[str, list[str]]:
    """Capability -> requirement titles currently in the present tense."""
    out: dict[str, list[str]] = {}
    for path in sorted(SPECS.glob("*.md")):
        if path.stem in NOT_A_CAPABILITY:
            continue
        out[path.stem] = [m.group("title") for m in REQUIREMENT.finditer(path.read_text("utf-8"))]
    return out


def deltas() -> dict[str, list[tuple[pathlib.Path, list[str]]]]:
    """Capability -> [(delta file, requirement titles)]."""
    out: dict[str, list[tuple[pathlib.Path, list[str]]]] = {}
    for path in sorted(CHANGES.rglob("spec.md")):
        out.setdefault(path.parent.name, []).append(
            (path, [m.group("title") for m in REQUIREMENT.finditer(path.read_text("utf-8"))])
        )
    return out


def known_capabilities() -> set[str]:
    text = STATUS_SCRIPT.read_text("utf-8")
    block = text.split("CAPABILITIES = {", 1)[1].split("\n}", 1)[0]
    return set(re.findall(r'^\s{4}"([a-z]+)":', block, re.M))


def main() -> int:
    quiet = "--quiet" in sys.argv
    acc = accumulated()
    dlt = deltas()
    known = known_capabilities()
    problems: list[str] = []

    # 1. No orphan requirement in the present tense.
    for capability, titles in acc.items():
        provided = {t for _, ts in dlt.get(capability, []) for t in ts}
        for title in titles:
            if title not in provided:
                problems.append(
                    f"{capability}: the requirement {title!r} is in "
                    f"openspec/specs/{capability}.md with no delta behind it"
                )

    # 2. Every delta targets a capability that is registered.
    #    The accumulated spec file is deliberately *not* required: a change that
    #    introduces a new capability has a delta before it has a present tense.
    #    What is required is that the capability is known to the status map,
    #    otherwise it gets no status and its absence is invisible.
    for capability in sorted(dlt):
        if capability not in known:
            problems.append(
                f"{capability}: a delta exists but the capability is not in "
                f"generate-spec-status.py CAPABILITIES, so it has no status and no "
                f"lot; add a line there"
            )

    # 3. The hand-written status block in each delta is true.
    for capability, files in sorted(dlt.items()):
        for path, titles in files:
            if capability not in acc:
                continue
            applied = [t for t in titles if t in acc[capability]]
            pending = [t for t in titles if t not in acc[capability]]
            text = path.read_text("utf-8")

            claimed = STATUS.search(text)
            if not claimed:
                problems.append(
                    f"{path.relative_to(ROOT)}: no machine-readable status line, "
                    f"expected 'Statut : N exigence(s) appliquée(s), M exigence(s) en attente.'"
                )
            else:
                if int(claimed.group("applied")) != len(applied):
                    problems.append(
                        f"{path.relative_to(ROOT)}: the status line claims "
                        f"{claimed.group('applied')} applied requirement(s), "
                        f"{len(applied)} are actually in openspec/specs/{capability}.md"
                    )
                if int(claimed.group("pending")) != len(pending):
                    problems.append(
                        f"{path.relative_to(ROOT)}: the status line claims "
                        f"{claimed.group('pending')} pending requirement(s), "
                        f"{len(pending)} are actually pending"
                    )

            # A pending requirement must be listed by name, or the block is a
            # number without a handle.
            for title in pending:
                if f"- {title}" not in text:
                    problems.append(
                        f"{path.relative_to(ROOT)}: pending requirement {title!r} "
                        f"is not listed in the status block"
                    )

    total = sum(len(v) for v in acc.values())
    if problems:
        for problem in problems:
            print(f"error: {problem}", file=sys.stderr)
        print(f"{len(problems)} problem(s) in the spec deltas", file=sys.stderr)
        return 1

    if not quiet:
        total_deltas = sum(len(ts) for files in dlt.values() for _, ts in files)
        print(
            f"spec deltas are sound: {total} accumulated requirement(s), "
            f"{total_deltas} in deltas, {len(acc)} capabilit(ies), no orphan"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
