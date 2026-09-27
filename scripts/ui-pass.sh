#!/bin/bash
# The pass that was owed: the real window, driven as a person drives it.
#
#   ./scripts/ui-pass.sh
#
# It types a sentence into the entry point, presses the action, checks the canvas
# reports the object by name, quits with no save, and checks the document comes back.
# Every one of those is a real click or a real keystroke over the accessibility
# bridge, into the real application.
#
# It is separate from `verify.sh` for one reason: it needs a window. `verify.sh`
# must pass on a machine with no display, and a command that fails because nobody
# was sitting at the keyboard is a command people learn to skip.
#
# It found two product bugs on its first run, both of which every other suite in
# the repository had passed: an empty document on disk was shadowing every real
# document, and an empty document was being written on every quit with nothing in
# it. `docs/known-limitations.md` has the shape of the failure.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/apps/macos/Kollio.xcodeproj"
RESULT="${KOLLIO_UI_RESULT:-$ROOT/build/ui-pass.xcresult}"
DESTINATION="${KOLLIO_UI_DESTINATION:-platform=macOS}"

cd "$ROOT"
python3 scripts/sync-xcodeproj.py

rm -rf "$RESULT"
echo "== the interface pass =="
xcodebuild test \
    -project "$PROJECT" \
    -scheme Kollio \
    -destination "$DESTINATION" \
    -only-testing:KollioUITests \
    -resultBundlePath "$RESULT" > /dev/null 2>&1
STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo "the pass failed. What the window said, in order:"
    xcrun xcresulttool get test-results tests --path "$RESULT" 2>/dev/null \
        | /usr/bin/python3 -c "
import json, sys
try:
    report = json.load(sys.stdin)
except Exception:
    print('  the result bundle could not be read; the run log has the failure')
    raise SystemExit(0)

def walk(node):
    if node.get('nodeType') == 'Failure Message':
        print('  ' + node.get('name', ''))
    for child in node.get('children', []):
        walk(child)
walk(report)
"
    echo
    echo "result bundle: $RESULT"
    exit $STATUS
fi

xcrun xcresulttool get test-results tests --path "$RESULT" 2>/dev/null \
    | /usr/bin/python3 -c "
import json, sys
report = json.load(sys.stdin)
def walk(node):
    if node.get('nodeType') == 'Test Case':
        print('  %-6s %s (%ss)' % (
            node.get('result', '?'), node.get('name', '?'),
            node.get('durationInSeconds', '?')))
    for child in node.get('children', []):
        walk(child)
walk(report)
"

echo
echo "verdict: the pass is green. Typed, submitted, kept, quit with no save, reopened."
echo "result bundle: $RESULT"
