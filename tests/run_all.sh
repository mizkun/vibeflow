#!/bin/bash

# VibeFlow aggregate test runner.
#
# Runs every test_*.sh in the target directory (default: this directory),
# aggregates exit codes, and exits non-zero if any file fails — including
# files that crash before printing a summary.
#
# Usage:
#   bash tests/run_all.sh            # run the real suite
#   bash tests/run_all.sh <dir>      # run fake suites (used by tests)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$TESTS_DIR}"
REPO_ROOT="$(dirname "$TESTS_DIR")"

cd "$REPO_ROOT"

# Per-file timeout (GNU coreutils timeout, or gtimeout via Homebrew).
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"
if [ -z "$TIMEOUT_BIN" ]; then
    echo "warning: no timeout/gtimeout found — running without per-file timeout" >&2
fi
PER_FILE_TIMEOUT=300

PASSED=0
FAILED_COUNT=0
FAILED_LIST=""

for f in "$TARGET_DIR"/test_*.sh; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    # shared library, not a test file
    [ "$name" = "test_helpers.sh" ] && continue

    if [ -n "$TIMEOUT_BIN" ]; then
        out="$("$TIMEOUT_BIN" "$PER_FILE_TIMEOUT" bash "$f" 2>&1)"; code=$?
    else
        out="$(bash "$f" 2>&1)"; code=$?
    fi

    if [ "$code" -eq 0 ]; then
        PASSED=$((PASSED + 1))
        echo "PASS       $name"
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_LIST="${FAILED_LIST}  - ${name} (exit ${code})
"
        echo "FAIL(${code})  $name"
        printf '%s\n' "$out" | tail -15 | sed 's/^/    | /'
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "run_all: ${PASSED} files passed, ${FAILED_COUNT} failed"
if [ "$FAILED_COUNT" -gt 0 ]; then
    printf '%s' "$FAILED_LIST"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
