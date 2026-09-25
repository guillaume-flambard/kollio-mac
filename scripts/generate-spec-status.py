#!/usr/bin/env python3
"""Generate openspec/implementation-status.json from the feature catalog.

The catalog is itself generated from the specification, so this file inherits its
single source of truth. It answers one question per capability: what is proved,
what is written down, and what is waiting on a person or on an authorisation.
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "openspec" / "specs" / "feature-catalog.json"
STATUS = ROOT / "openspec" / "implementation-status.json"

# Capability -> the lot that delivers it, its spec file, and the change that owns
# the work. Adding a capability means adding a line here, not editing JSON.
CAPABILITIES = {
    "documents": ("L1", "specs/documents.md", "changes/l1-entry-and-canvas"),
    "canvas": ("L1", "specs/canvas.md", "changes/l1-entry-and-canvas"),
    "context": ("L1", "specs/context.md", "changes/l3-sources-and-provenance"),
    "intelligence": ("L2", "specs/intelligence.md", "changes/l2-living-document"),
    "decisions": ("L2", "specs/decisions.md", "changes/l2-living-document"),
    "collaboration": ("L5", "specs/collaboration.md", "changes/l5-team-identity"),
    "studio": ("L7", "specs/studio.md", "changes/l7-studio"),
    "commerce": ("L9", "specs/commerce.md", "changes/l9-ecosystem"),
    "ecosystem": ("L9", "specs/ecosystem.md", "changes/l9-ecosystem"),
}

# The status a capability is *delivered* at, judged by its weakest unproved part
# rather than its best. A capability with one unproved feature is not delivered.
DELIVERED = {
    "documents": "implemented",
    "canvas": "automatedVerified",
    "context": "specified",
    "intelligence": "automatedVerified",
    "decisions": "automatedVerified",
    "collaboration": "blockedExternal",
    "studio": "specified",
    "commerce": "blockedExternal",
    "ecosystem": "blockedExternal",
}

# What is still owed to a person, per capability. Never inferred from a test.
OWED = {
    "documents": [
        "Type a sentence and watch a proposal arrive: keystroke injection needs "
        "accessibility access this environment refuses.",
    ],
    "canvas": [
        "A real two-finger scroll on a trackpad, and its feel. The routing and the "
        "maths are proved; the gesture is not.",
    ],
    "context": [],
    "intelligence": [
        "Warm latency and a second identical call, to separate cold asset loading "
        "from generation. Cold is 9 to 15 s.",
        "The 'at most 3 ideas' bound and the refused-kind rule against a real "
        "model, not only the converter.",
        "A real proposal kept, set aside and reopened by a person.",
    ],
    "decisions": [
        "A real proposal kept, set aside and reopened by hand.",
    ],
    "collaboration": [],
    "studio": [],
    "commerce": [],
    "ecosystem": [],
}

# What blocks a capability, stated as a fact rather than a feeling.
BLOCKED_ON = {
    "collaboration": [
        "An identity decision the user has not made. It changes the format of every "
        "shared document, so coding first would be guessing at the schema.",
    ],
    "commerce": [
        "Identity, hosting and liability are undecided. Three of the six features "
        "have no agreed meaning yet.",
    ],
    "ecosystem": [
        "No authorisation to introduce an upload, an account or a marketplace.",
    ],
}

RANK = {
    "notInCurrentRelease": 0, "blockedExternal": 1, "specified": 2,
    "inProgress": 3, "implemented": 4, "humanVerified": 5, "automatedVerified": 6,
}


def main() -> int:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    by_capability: dict[str, list[dict]] = {}
    for feature in catalog["features"]:
        by_capability.setdefault(feature["capability"], []).append(feature)

    unknown = set(by_capability) - set(CAPABILITIES)
    if unknown:
        print(f"error: unknown capabilities {sorted(unknown)}", file=sys.stderr)
        return 1

    capabilities = {}
    for name, (lot, spec, change) in CAPABILITIES.items():
        features = sorted(by_capability.get(name, []), key=lambda f: f["id"])
        counts: dict[str, int] = {}
        for feature in features:
            counts[feature["status"]] = counts.get(feature["status"], 0) + 1
        entry = {
            "lot": lot,
            "spec": spec,
            "change": change,
            "delivered": DELIVERED[name],
            "features": len(features),
            "acceptanceCriteria": sum(len(f["acceptanceCriteria"]) for f in features),
            "byStatus": dict(sorted(counts.items())),
            "proved": sorted(
                f["id"] for f in features if f["status"] == "automatedVerified"
            ),
            "writtenOnly": sorted(
                f["id"] for f in features if f["status"] == "specified"
            ),
        }
        if OWED.get(name):
            entry["owedToAPerson"] = OWED[name]
        if BLOCKED_ON.get(name):
            entry["blockedOn"] = BLOCKED_ON[name]
            entry["authorisation"] = "none: explicit authorisation required"
        capabilities[name] = entry

    document = {
        "$comment": (
            "Generated by scripts/generate-spec-status.py. A view over "
            "openspec/specs/feature-catalog.json, which is generated from "
            "docs/specs/SPECIFICATIONS.md. Never a second source of truth."
        ),
        "specification": "docs/specs/SPECIFICATIONS.md",
        "evidence": "openspec/specs/evidence.md",
        "statusVocabulary": {
            "specified": "Written down. Nothing implemented.",
            "inProgress": "Some code exists, no complete evidence.",
            "implemented": "Code exists and builds. No test evidence.",
            "automatedVerified": "A test proves the stated behaviour.",
            "humanVerified": "A person did it.",
            "blockedExternal": "Blocked on a capability or an authorisation.",
            "notInCurrentRelease": "Deliberately out of this product.",
        },
        "verification": {
            "command": "./scripts/verify.sh",
            "note": (
                "Deterministic suites never require Apple Intelligence, a key or a "
                "network. Real-model evidence is opt-in and separately marked."
            ),
        },
        "capabilities": capabilities,
        "totals": {
            "features": catalog["counts"]["features"],
            "acceptanceCriteria": catalog["counts"]["acceptanceCriteria"],
            "byStatus": catalog["counts"]["byStatus"],
        },
    }

    rendered = json.dumps(document, indent=2, ensure_ascii=False) + "\n"

    if "--check" in sys.argv:
        if not STATUS.exists() or STATUS.read_text(encoding="utf-8") != rendered:
            print("error: openspec/implementation-status.json is stale", file=sys.stderr)
            return 1
        print("implementation status is up to date")
        return 0

    STATUS.write_text(rendered, encoding="utf-8")
    proved = sum(len(c["proved"]) for c in capabilities.values())
    print(
        f"wrote {STATUS.relative_to(ROOT)}: {len(capabilities)} capabilities, "
        f"{proved} proved features"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
