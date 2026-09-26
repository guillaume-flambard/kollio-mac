#!/bin/bash
# The full proof: every package, plus the Xcode app target.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The spec views are generated. If they are stale, the project is describing
# itself with a second source of truth, which is worse than being out of date.
echo "=== Spec views are current"
python3 "$ROOT/scripts/generate-spec-index.py" --check
python3 "$ROOT/scripts/generate-spec-status.py" --check

# The capability specs are an accumulation. A requirement that arrived without a
# change delta behind it cannot be traced, cannot be reviewed, and will not be
# noticed when it is wrong.
echo "=== Every requirement descends from a change"
python3 "$ROOT/scripts/check-spec-deltas.py"

echo "=== KollioCore"
(cd "$ROOT/packages/KollioCore" && swift test)
echo "=== KollioApp"
(cd "$ROOT/packages/KollioApp" && swift test)
echo "=== KollioServer"
(cd "$ROOT/services/KollioServer" && swift test)
echo "=== Kollio.xcodeproj (Cmd+R target)"
# The derived data path is derived from the repository root, not fixed. A fixed
# /tmp path meant two worktrees verifying at the same time wrote into the same
# DerivedData, which is the collision that has to happen before parallel work
# can be trusted. The name is hashed from the root so two checkouts of the same
# repository still do not share one.
DERIVED="$(printf '%s' "$ROOT" | shasum | cut -c1-12)"
# The whole log is kept, and the warnings in it are read rather than discarded.
# `| tail -1` printed the success line and threw everything else away, which is how
# two real warnings in this very target survived several rounds of "zero warnings":
# the SwiftPM suites do not compile the app target with Xcode's settings, so nothing
# else in this script was looking at them.
XCODE_LOG="${TMPDIR:-/tmp}/kollio-xcodebuild-$$.log"
xcodebuild -project "$ROOT/apps/macos/Kollio.xcodeproj" -scheme Kollio \
  -configuration Debug -destination "platform=macOS" \
  -derivedDataPath "${TMPDIR:-/tmp}/kollio-verify-$DERIVED" build \
  | tee "$XCODE_LOG" | tail -1

# Only diagnostics that name a source file of this repository. Xcode's own tools
# write their own warnings into the same log, and failing on those would make this
# script a weather report for the toolchain.
OUR_WARNINGS="$(grep -E "warning: " "$XCODE_LOG" | grep -E "/kollio-mac/(packages|services)/.*\.swift:" || true)"
if [ -n "$OUR_WARNINGS" ]; then
  echo "error: the Xcode app target builds with warnings:" >&2
  echo "$OUR_WARNINGS" >&2
  rm -f "$XCODE_LOG"
  exit 1
fi
rm -f "$XCODE_LOG"
