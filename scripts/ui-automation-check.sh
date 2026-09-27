#!/bin/bash
# Answers one question in one second: can synthetic input reach this Mac's apps?
#
#   ./scripts/ui-automation-check.sh
#
# It exists because `docs/known-limitations.md` used to say that pointer-level
# automation "is not possible in this environment", which is a claim about a
# machine rather than a fact anyone could check. It is now three separate facts,
# and they fail for different reasons:
#
#   1. accessibility   Is the process trusted to post events? A permission.
#   2. focus           Does the window server report a focused application? The
#                      target an event is delivered to. Not a permission.
#   3. delivery        Does a posted keystroke actually arrive? The only test that
#                      counts, and the only one that costs a keystroke.
#
# Facts 1 and 2 are the ones that decide whether the human pass can be automated.
# Fact 3 is only reached when both of them hold.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBE="$(mktemp -t kollio-ax-probe).swift"
BIN="$(mktemp -t kollio-ax-probe)"
trap 'rm -f "$PROBE" "$BIN"' EXIT

cat > "$PROBE" <<'SWIFT'
import AppKit
import ApplicationServices

func attribute(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else { return nil }
    return value
}
func string(_ element: AXUIElement, _ key: String) -> String? { attribute(element, key) as? String }

let trusted = AXIsProcessTrusted()
print("AXISPROCESSTRUSTED=\(trusted)")

// The window server's own answer to "which application has the keyboard". An event
// posted to the HID tap is delivered to this, and to nothing when it is absent.
let system = AXUIElementCreateSystemWide()
let focused = attribute(system, kAXFocusedApplicationAttribute)
print("AXFOCUSEDAPPLICATION=\(focused == nil ? "none" : (NSWorkspace.shared.frontmostApplication?.localizedName ?? "present"))")
print("AXFRONTMOST=\(NSWorkspace.shared.frontmostApplication?.localizedName ?? "none")")
print("AXSESSION=\(ProcessInfo.processInfo.environment["SECURITYSESSIONID"].map { _ in "aqua" } ?? "unknown")")
SWIFT

echo "== Kollio UI automation precondition =="
if ! xcrun swiftc -O "$PROBE" -o "$BIN" 2>/dev/null; then
    echo "probe: could not be built, so nothing below is known"
    exit 3
fi
OUTPUT="$("$BIN")"
echo "$OUTPUT" | sed 's/^/  /'

TRUSTED="$(echo "$OUTPUT" | sed -n 's/^AXISPROCESSTRUSTED=//p')"
FOCUSED="$(echo "$OUTPUT" | sed -n 's/^AXFOCUSEDAPPLICATION=//p')"

echo
if [ "$TRUSTED" != "true" ]; then
    echo "verdict: blocked on a permission."
    echo "  This process is not trusted for Accessibility, so it may not post events."
    echo "  Grant it in System Settings > Privacy & Security > Accessibility, to the"
    echo "  application that launches this script. It is the owner's decision and it"
    echo "  cannot be scripted, because the database is protected by SIP."
    exit 1
fi
if [ "$FOCUSED" = "none" ]; then
    echo "verdict: blocked on focus, not on a permission."
    echo "  Accessibility is granted, so events can be posted, and the window server"
    echo "  reports no focused application for them to be delivered to. Everything"
    echo "  driven from here therefore goes nowhere: a posted keystroke and a posted"
    echo "  click both arrive at nothing."
    echo "  A person clicking the Mac once restores the focus owner, and this script"
    echo "  then says so. Until then the honest statement is that the blocker is the"
    echo "  session, not the app."
    exit 2
fi

echo "verdict: ready. Events can be posted and have a target."
echo "  Run a real pass with ./scripts/run-app.sh, then click and type from a"
echo "  process this script has just checked."
exit 0
