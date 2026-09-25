#!/bin/bash
# Runs every test suite: domain, canvas, backend.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for package in packages/KollioCore packages/KollioApp services/KollioServer; do
  echo "=== $package"
  (cd "$ROOT/$package" && swift test)
done
