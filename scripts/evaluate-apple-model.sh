#!/usr/bin/env bash
# Measures the real on-device model against Kollio's intelligence pipeline.
#
# This is opt-in evidence about this Mac. It is never part of verify.sh, because
# ordinary CI must not depend on Apple Intelligence.
#
# What it promises, and how:
#
#   exit 0  the structural gate held on every case
#   exit 1  a safety property of the pipeline failed
#   exit 2  the suite did not actually run, or the harness itself broke
#   exit 3  the on-device model is not usable on this machine
#
# The distinction between 1, 2 and 3 is the point. A suite that cannot tell
# "the model is absent" from "the model broke a rule" will eventually treat one
# as the other, and a measurement nobody can trust is worse than none.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

output_dir="${KOLLIO_EVAL_OUTPUT:-$root/build/evaluations}"

# `Evaluations.framework` is a Developer framework. Two things are needed and
# both were found the hard way on this toolchain:
#
#   -F                    at build time, so the module can be found at all
#   DYLD_FRAMEWORK_PATH   at run time, because the framework's install name is
#                         @rpath/Developer/Platforms/... and no rpath on a
#                         SwiftPM test bundle resolves it
developer_dir="$(xcode-select -p)"
developer_frameworks="$developer_dir/Platforms/MacOSX.platform/Developer/Library/Frameworks"

if [ ! -d "$developer_frameworks/Evaluations.framework" ]; then
  echo "evaluate-apple-model: Evaluations.framework is not in this Xcode." >&2
  echo "  looked in: $developer_frameworks" >&2
  echo "  This script measures with Apple's own harness. Without it, use the" >&2
  echo "  deterministic gate instead: swift test --package-path packages/KollioApp" >&2
  echo "  --filter StructuralAssessorTests" >&2
  exit 2
fi

# The suite writes where the script reads. `swift test` runs with the package as
# its working directory, so a relative path would put the report somewhere the
# script never looks, and the script would then report "nothing was measured"
# about a run that in fact happened.
export KOLLIO_EVAL_OUTPUT="$output_dir"
export KOLLIO_DEVELOPER_FRAMEWORKS="$developer_frameworks"
export DYLD_FRAMEWORK_PATH="$developer_frameworks"
export KOLLIO_EVALUATE=1

echo "evaluate-apple-model"
echo "  xcode:           $(xcodebuild -version | head -1)"
echo "  frameworks:      $developer_frameworks"
echo "  output:          $output_dir"
echo "  execution:       serial, one process, one case at a time"
echo ""

# --no-parallel is not optional. There is one on-device model, so a parallel run
# measures contention between cases instead of the model's behaviour.
log="$(mktemp -t kollio-evaluate)"
swift test --package-path packages/KollioApp \
  --filter AppleModelEvaluationTests \
  --no-parallel > "$log" 2>&1
status=$?

# A filter that matches nothing exits zero. That is the exact failure this
# script exists to make impossible, so it is checked before anything else.
if grep -q "No matching test cases were run" "$log"; then
  echo "evaluate-apple-model: the evaluation suite did not run." >&2
  sed 's/^/  /' "$log" | tail -20 >&2
  rm -f "$log"
  exit 2
fi

sed 's/^/  /' "$log" | grep -E "EVALUATION|error:|Test run|✘|Issue recorded" || true

summary="$output_dir/kollio-evaluation-summary.json"
if [ ! -f "$summary" ]; then
  echo "" >&2
  echo "evaluate-apple-model: no summary was written, so nothing was measured." >&2
  echo "  expected: $summary" >&2
  rm -f "$log"
  exit 2
fi

rm -f "$log"
exit $status
