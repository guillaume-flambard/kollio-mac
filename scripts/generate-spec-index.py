#!/usr/bin/env python3
"""Generate the feature catalog and the todo list from SPECIFICATIONS.md.

These two files are *views* over the specification, never a second source of
truth. If they disagree with the prose, the prose wins and this script is re-run.

The script parses the `**ID — Title.** *SET. Prerequisites.*` convention used in
the Documents, Canvas, Context, Intelligence, Decisions, Collaboration, Studio,
Commerce and Ecosystem sections, and then cross-references:

- the acceptance criteria `ACnn` that appear under each feature;
- the lot table, which maps capabilities to lots.

Usage:
    python3 scripts/generate-spec-index.py            # write both files
    python3 scripts/generate-spec-index.py --check    # fail if stale
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPEC = ROOT / "docs" / "specs" / "SPECIFICATIONS.md"
CATALOG = ROOT / "openspec" / "specs" / "feature-catalog.json"
TODO = ROOT / "openspec" / "todo.md"

# A feature heading: **DOC-02 — Enter a context and begin.** *SOLO. DOC-01.*
FEATURE = re.compile(
    r"^\*\*(?P<id>[A-Z]+-\d{2}) — (?P<title>.+?)\.\*\*\s*"
    # The delivery-set group is non-greedy on purpose. With a greedy `[^*]+` it
    # swallowed the prerequisites as well, so all 71 features were generated with
    # an empty dependency list, and anything scheduling from those views would
    # treat every feature as ready. The prerequisites are the whole point of the
    # generated order, so they are worth one character.
    r"\*(?P<sets>[^*]+?)\.\s*(?P<prereq>[^*]*)\*\s*$"
)
ACCEPTANCE = re.compile(r"AC(?P<n>\d{2})\b")
SECTION = re.compile(r"^## (?P<name>[A-Z].*)$")
LOT_ROW = re.compile(r"^\|\s*(L\d)\s*\|(.*)\|\s*(.*?)\s*\|(.*?)\s*\|$")

CAPABILITY_OF_PREFIX = {
    "DOC": "documents",
    "CAN": "canvas",
    "CTX": "context",
    "AI": "intelligence",
    "DEC": "decisions",
    "TEAM": "collaboration",
    "STU": "studio",
    "COM": "commerce",
    "EXT": "ecosystem",
}

# Which lot a capability first belongs to. Mirrors the lot table in the spec.
LOT_OF_PREFIX = {
    "DOC": "L1", "CAN": "L1", "CTX": "L1",
    "AI": "L2", "DEC": "L2",
    "TEAM": "L5",
    "STU": "L7",
    "COM": "L9",
    "EXT": "L9",
}
# Features that join a later lot, per the lot table.
LOT_OVERRIDES = {
    "DOC-05": "L4", "DOC-06": "L4", "DOC-07": "L4", "DOC-08": "L4",
    "CTX-02": "L3", "CTX-03": "L3", "CTX-04": "L3", "CTX-05": "L3",
    "CTX-06": "L3", "CTX-07": "L3",
    "CAN-06": "L3", "CAN-07": "L3", "CAN-08": "L2", "CAN-09": "L3",
    "CAN-10": "L3",
    "AI-05": "L3", "AI-06": "L3", "AI-10": "L8", "AI-11": "L3", "AI-12": "L3",
    "DEC-04": "L4", "DEC-05": "L4", "DEC-06": "L4",
}

# Status of each feature, read from the repository rather than assumed.
# `specified` is the honest default: nobody has proved anything by writing it down.
STATUS_NOTES = {
    "DOC-01": ("automatedVerified",
               "Covered by InitialContextTests: fresh launch, restore, unreadable reported."),
    "DOC-02": ("automatedVerified",
               "Covered by InitialContextTests: context created, preserved, persisted first."),
    "DOC-03": ("automatedVerified",
               "Covered by InitialContextTests: a new document gets its own save target."),
    "DOC-04": ("automatedVerified",
               "Covered by InteractionReliabilityTests through the real delegate."),
    "CAN-01": ("automatedVerified",
               "Two-finger scroll wired via ScrollCatcher; pan is screen space at any zoom. "
               "Gesture feel still unverified by a human."),
    "CAN-02": ("automatedVerified",
               "SelectionAndActionsTests: Escape dismisses one level then the selection, through "
               "one function, with the selection pruned in one place; a context offers exactly "
               "three primary actions and the rest sit behind a native menu. Still owed to a "
               "person: the pointer affordance, and a capture cropped to the selection."),
    "CAN-03": ("automatedVerified",
               "MovingInstancesTests: a group drag is one transaction and one undo, AC01 asserted "
               "with the zoom division and with the three results differing so it cannot pass on "
               "a constant, and a move leaves content and semanticRevision untouched. Two "
               "occurrences of one object move independently, which needed instances(of:) and an "
               "InstanceID in the drag state. Still owed to a person: whether the drag feels "
               "direct on a trackpad."),
    "CAN-04": ("automatedVerified",
               "EditingContentTests: the exact characters typed are stored, an edit is one "
               "transaction, the document's undo cannot reach an open draft, and changing the "
               "interface language leaves authored text byte-identical. A conflict is refused as "
               "staleObjectText and keeps both the draft and the current text. DocumentFormatTests "
               "proves a file written before objectVersion existed still opens. Still owed: the "
               "two versions side by side, and Cmd+Z inside the field, which is an interaction "
               "between two undo systems this repository does not own."),
    "CAN-05": ("automatedVerified",
               "CreatingAndRemovingTests: an idea is written down before its kind is known, and "
               "locally, proved with a service that throws if consulted. Duplicate and delete each "
               "exist twice, once for an occurrence and once for an object, and the two are never "
               "the same gesture. AC01 duplicating does not double royalties, because a copy carries "
               "a reference to a contribution rather than a second one. AC02 undo restores links and "
               "positions exactly, and undoing a variant removes the link as well as the object. "
               "Intelligence is refused both removals. Owed: no command registers a contribution, "
               "so AC01 is proved against a seeded ledger; nothing moves an object out of .unclear; "
               "and the menu has not been seen by a person on a screen."),
    "CTX-01": ("automatedVerified",
               "AddingAtAPlaceTests: the sentence is written as an authored note linked by "
               "associatedWith in one transaction, and it is never asked of a model on the way in, "
               "proved with a service that throws if consulted. AC01 findable after a relaunch, "
               "link included; AC02 the target is byte-identical, version included; AC03 a thrown "
               "error, a refusal and a slow answer all leave the contribution with its author. A "
               "double submission is deduplicated per target. A kind proposed by intelligence asks "
               "first when it changes the reasoning. Owed: nothing on screen asks that question "
               "yet, and a note is not read as a consequence of anything."),
    "AI-03": ("automatedVerified",
               "ExploringABranchTests: the exact instruction is transmitted, which it was not, since "
               "the Explore intent used to discard it and clear the composer. The read set carries "
               "the target, its neighbours and every rejected direction with its reason, and the "
               "signature is stable because it sorts before hashing. The engine honours only the "
               "rejections it was given. AC03 a new proposal is offered rather than erasing the "
               "previous, and noChange takes nothing away. A rejected branch is not reopened, a "
               "repetitive loop converges instead of duplicating, and exploring leaves the parent "
               "byte-identical. Owed: the offer to keep or hide is not on screen, and second-degree "
               "reach is a documented guess rather than a rule of applicability."),
    "AI-01": ("automatedVerified",
              "AppleAdapterTests: every availability state is a refusal, never a fallback."),
    "AI-02": ("humanVerified",
              "Real on-device generation on two non-Sarah contexts, FR and EN, through the "
              "adapter. Steady state is about 2.3 s, first call in a fresh process about 3.6 s: "
              "still too slow to feel interactive, and nothing is streamed."),
    "AI-07": ("automatedVerified",
              "AppleAdapterTests: minted ids, dropped kinds, bounded branch, noChange."),
    "AI-08": ("automatedVerified",
              "VerticalSliceTests: one Keep undoes as one action."),
    "AI-04": ("automatedVerified",
               "AC01 an answer is in the document and survives a reload; AC02 'I don't know' is a "
               "real state and is never an empty answer; AC03 a question resolves beside its object "
               "with no panel anywhere. ClarificationTests, ClarificationInterfaceTests. "
               "Intelligence may ask but may not answer. Still missing: a question the document has "
               "moved past, proposed for reassessment, and resuming the request with the answer."),
    "CAN-08": ("automatedVerified",
               "AC01 keeping does not shift the ghosts; AC02 earlier objects stay still; AC03 undo "
               "restores the view exactly. ProposalPlacementTests, against the real model. A "
               "branch placed off screen offers a way to see it, and nothing ever moves the view on "
               "its own. Still missing: the local organisation gesture, and a density measure for "
               "when to widen the search rather than place."),
    "CTX-02": ("automatedVerified",
               "AC01 a CSV with quotes, commas and newlines parses correctly; AC02 a PDF with no "
               "text layer is marked as having no text; AC03 a pasted link is never fetched. "
               "SourceReaderTests. A file is chosen, read and attached in one transaction, a CSV "
               "is previewed as columns from the revision on record, and a chosen file opens in "
               "the system reader: SourceChipTests, SourcePreviewPanel. Still missing: a page "
               "locator that can be pointed at a passage, and OCR as an explicit action."),
    "CTX-03": ("automatedVerified",
               "A citation keeps its revision, is refused towards anything absent, and cannot be "
               "verified without an observation and an author. Intelligence is refused these "
               "commands outright. SourceLedgerTests, SourceCommandTests. The interface opens a "
               "citation at the lines its locator names, from the revision it was read against, "
               "records a check only with an observation, and lets a passage be chosen so the "
               "quote is the selection verbatim: SourceChipTests. Still missing: opening the file "
               "itself in a reader, and a page locator that can be pointed at a passage."),
    "CTX-04": ("automatedVerified",
               "AC01 a constraint only blocks within its scope; AC02 not applicable is not "
               "satisfied; AC03 supported is not absolute truth. ClaimLedgerTests, and a scope "
               "with nothing in it is refused rather than read as everything. Intelligence may "
               "suggest a claim but may not record how it stands. The interface states a claim with "
               "its scope taken from the current selection, and records a stance only with an "
               "observation. Still missing: asking for precision when two scopes overlap."),
    "CTX-06": ("automatedVerified",
               "The projection is built and measured on the real request path: omissions are "
               "counted, a required item is never dropped, and the budget cannot exceed the "
               "model's window. ContextProjectionTests, AppleAdapterTests. The interface that "
               "shows the list to a person is not built."),
    "CTX-07": ("automatedVerified",
               "A new revision flags what it supersedes without moving a citation, a failed "
               "extraction keeps the previous version active, and a removed source never deletes "
               "the claim. SourceLedgerTests, SourceCommandTests. No comparison of dependent "
               "extracts and no reassessment proposal are built."),
    "DEC-01": ("automatedVerified", "CommandTests: a decision survives save and reload."),
    "DEC-02": ("automatedVerified",
               "InteractionReliabilityTests: the camera is identical before and after."),
    "DEC-03": ("automatedVerified",
               "InteractionReliabilityTests and VerticalSliceTests: one Keep, one undo."),
}


def parse() -> list[dict]:
    text = SPEC.read_text(encoding="utf-8")
    features: list[dict] = []
    section = ""
    current: dict | None = None
    in_lots = False

    for line in text.splitlines():
        if line.startswith("## "):
            section = line[3:].strip()
            in_lots = section.startswith("Lots")
            if in_lots:
                current = None
            continue

        if in_lots:
            match = LOT_ROW.match(line)
            if match:
                lot = match.group(1)
                features_seen = match.group(3)
                for fid in re.findall(r"[A-Z]{2,4}-\d{2}", features_seen):
                    for feature in features:
                        if feature["id"] == fid:
                            feature.setdefault("lots", []).append(lot)
            continue

        heading = FEATURE.match(line)
        if heading:
            fid = heading.group("id")
            prefix = fid.split("-")[0]
            current = {
                "id": fid,
                "title": heading.group("title"),
                "capability": CAPABILITY_OF_PREFIX.get(prefix, "other"),
                "deliverySets": [s.strip() for s in heading.group("sets").split(",")],
                "prerequisites": [
                    p.strip() for p in re.findall(r"[A-Z]{2,4}-\d{2}", heading.group("prereq"))
                ],
                "acceptanceCriteria": [],
                "section": section,
            }
            features.append(current)
            continue

        # The acceptance criteria of a feature wrap across several lines, so they
        # are accumulated in order rather than read from the line holding AC01.
        if current is not None:
            for m in ACCEPTANCE.finditer(line):
                ac_id = f"{current['id']}-{m.group(0)}"
                if ac_id not in current["acceptanceCriteria"]:
                    current["acceptanceCriteria"].append(ac_id)

    return features


def main() -> int:
    features = parse()
    for feature in features:
        lot = LOT_OVERRIDES.get(feature["id"]) or LOT_OF_PREFIX.get(
            feature["id"].split("-")[0], "L0"
        )
        feature["lot"] = lot
        status, note = STATUS_NOTES.get(feature["id"], ("specified", ""))
        feature["status"] = status
        if note:
            feature["evidence"] = note

    catalog = {
        "$comment": (
            "Generated by scripts/generate-spec-index.py from "
            "docs/specs/SPECIFICATIONS.md. A view, never a second source of truth."
        ),
        "specification": "docs/specs/SPECIFICATIONS.md",
        "counts": {
            "features": len(features),
            "acceptanceCriteria": sum(len(f["acceptanceCriteria"]) for f in features),
            "byStatus": {
                status: sum(1 for f in features if f["status"] == status)
                for status in sorted({f["status"] for f in features})
            },
            "byLot": {
                lot: sum(1 for f in features if f["lot"] == lot)
                for lot in sorted({f["lot"] for f in features})
            },
        },
        "features": sorted(features, key=lambda f: f["id"]),
    }

    rendered_catalog = json.dumps(catalog, indent=2, ensure_ascii=False) + "\n"

    # The todo list: one line per feature, ordered by lot then id.
    lines = [
        "# Kollio todo",
        "",
        "Generated by `scripts/generate-spec-index.py` from "
        "[../docs/specs/SPECIFICATIONS.md](../docs/specs/SPECIFICATIONS.md).",
        "A view, not a source of truth. Status meanings:",
        "",
        "| Status | Means |",
        "|---|---|",
        "| `specified` | Written down. Nothing implemented. |",
        "| `inProgress` | Some code exists, no complete evidence. |",
        "| `implemented` | Code exists and builds. No test evidence. |",
        "| `automatedVerified` | A test proves the stated behaviour. |",
        "| `humanVerified` | A person did it. |",
        "| `blockedExternal` | Blocked on a capability or authorisation. |",
        "| `notInCurrentRelease` | Deliberately out of this product. |",
        "",
        "Counts: "
        + ", ".join(f"{n} {s}" for s, n in sorted(catalog["counts"]["byStatus"].items()))
        + f". {catalog['counts']['features']} features, "
        + f"{catalog['counts']['acceptanceCriteria']} acceptance criteria.",
        "",
    ]
    for lot in sorted(catalog["counts"]["byLot"]):
        in_lot = [f for f in catalog["features"] if f["lot"] == lot]
        lines.append(f"## {lot} — {len(in_lot)} features")
        lines.append("")
        for feature in in_lot:
            marker = {"automatedVerified": "x", "humanVerified": "x"}.get(feature["status"], " ")
            ac = f"{len(feature['acceptanceCriteria'])} AC" if feature["acceptanceCriteria"] else "—"
            lines.append(
                f"- [{marker}] **{feature['id']}** {feature['title']} "
                f"· `{feature['status']}` · {ac}"
            )
            if feature.get("evidence"):
                lines.append(f"      {feature['evidence']}")
        lines.append("")

    rendered_todo = "\n".join(lines)

    if "--check" in sys.argv:
        problems = []
        if not CATALOG.exists() or CATALOG.read_text(encoding="utf-8") != rendered_catalog:
            problems.append("openspec/specs/feature-catalog.json is stale")
        if not TODO.exists() or TODO.read_text(encoding="utf-8") != rendered_todo:
            problems.append("openspec/todo.md is stale")
        if problems:
            for problem in problems:
                print(f"error: {problem}", file=sys.stderr)
            return 1
        print("spec index is up to date")
        return 0

    CATALOG.parent.mkdir(parents=True, exist_ok=True)
    CATALOG.write_text(rendered_catalog, encoding="utf-8")
    TODO.write_text(rendered_todo, encoding="utf-8")
    print(
        f"wrote {CATALOG.relative_to(ROOT)} and {TODO.relative_to(ROOT)}: "
        f"{len(features)} features, "
        f"{catalog['counts']['acceptanceCriteria']} acceptance criteria"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
