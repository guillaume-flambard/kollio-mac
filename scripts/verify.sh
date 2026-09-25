#!/bin/bash
# The full proof: every package, plus the Xcode app target.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
