#!/bin/bash

# Tests for tests/run_all.sh — the aggregate test runner.
#
# run_all.sh accepts an optional target directory (default: tests/), so
# these cases point it at fixture directories of fake test files and
# assert on aggregate exit codes and output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

RUNNER="$SCRIPT_DIR/run_all.sh"

run_runner() {
    RUNNER_CODE=0
    RUNNER_OUT=$(bash "$RUNNER" "$1" 2>&1) || RUNNER_CODE=$?
}

test_runner_exists() {
    assert_file_exists "$RUNNER" "tests/run_all.sh should exist"
}

test_all_green_dir_exits_zero() {
    mkdir -p "$TEST_DIR/fix"
    printf '#!/bin/bash\nexit 0\n' > "$TEST_DIR/fix/test_a.sh"
    printf '#!/bin/bash\nexit 0\n' > "$TEST_DIR/fix/test_b.sh"
    run_runner "$TEST_DIR/fix"
    assert_equals "0" "$RUNNER_CODE" "all-green dir should exit 0: $RUNNER_OUT"
}

test_one_failure_exits_nonzero_and_lists_file() {
    mkdir -p "$TEST_DIR/fix"
    printf '#!/bin/bash\nexit 0\n' > "$TEST_DIR/fix/test_ok.sh"
    printf '#!/bin/bash\necho boom\nexit 1\n' > "$TEST_DIR/fix/test_bad.sh"
    run_runner "$TEST_DIR/fix"
    [ "$RUNNER_CODE" -ne 0 ] || { fail "one failing file must make run_all exit non-zero"; return 1; }
    echo "$RUNNER_OUT" | grep -q "test_bad.sh" || { fail "failing file should be listed, got: $RUNNER_OUT"; return 1; }
}

test_crashing_file_counts_as_failure() {
    mkdir -p "$TEST_DIR/fix"
    printf '#!/bin/bash\nset -e\nfalse\necho never\n' > "$TEST_DIR/fix/test_crash.sh"
    run_runner "$TEST_DIR/fix"
    [ "$RUNNER_CODE" -ne 0 ] || { fail "crashing file must count as failure"; return 1; }
    echo "$RUNNER_OUT" | grep -q "test_crash.sh" || { fail "crashing file should be listed, got: $RUNNER_OUT"; return 1; }
}

test_helpers_file_is_excluded() {
    mkdir -p "$TEST_DIR/fix"
    printf '#!/bin/bash\nexit 0\n' > "$TEST_DIR/fix/test_ok.sh"
    # would fail if executed — must be skipped by name
    printf '#!/bin/bash\nexit 1\n' > "$TEST_DIR/fix/test_helpers.sh"
    run_runner "$TEST_DIR/fix"
    assert_equals "0" "$RUNNER_CODE" "test_helpers.sh must be excluded from the run: $RUNNER_OUT"
}

describe "run_all.sh — aggregate runner"
run_test "run_all.sh exists" test_runner_exists
run_test "all-green directory exits 0" test_all_green_dir_exits_zero
run_test "one failure exits non-zero and lists the file" test_one_failure_exits_nonzero_and_lists_file
run_test "crashing file counts as failure" test_crashing_file_counts_as_failure
run_test "test_helpers.sh is excluded" test_helpers_file_is_excluded

print_summary
