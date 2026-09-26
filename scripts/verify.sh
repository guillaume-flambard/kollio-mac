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
xcodebuild -project "$ROOT/apps/macos/Kollio.xcodeproj" -scheme Kollio \
  -configuration Debug -destination "platform=macOS" -derivedDataPath /tmp/kollio-verify build \
  | tail -1
