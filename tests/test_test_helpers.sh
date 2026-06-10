#!/bin/bash

# Tests for the test framework itself (tests/test_helpers.sh).
#
# Each case writes a small fixture script that sources test_helpers.sh,
# runs it in a subprocess, and asserts on its combined output and exit
# code — so bugs in the runner cannot mask themselves.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

HELPERS_PATH="$SCRIPT_DIR/test_helpers.sh"

# Write a fixture script (helpers + body) and run it in a subprocess.
# Sets FIXTURE_OUT / FIXTURE_CODE.
run_fixture() {
    local fixture="$TEST_DIR/fixture.sh"
    {
        echo '#!/bin/bash'
        echo 'set -euo pipefail'
        echo "source \"$HELPERS_PATH\""
        printf '%s\n' "$1"
    } > "$fixture"
    FIXTURE_CODE=0
    FIXTURE_OUT=$(bash "$fixture" 2>&1) || FIXTURE_CODE=$?
}

# ──────────────────────────────────────────────
# Baseline behaviour
# ──────────────────────────────────────────────

test_passing_test_passes() {
    run_fixture '
ok() { return 0; }
run_test "ok" ok
print_summary
'
    [ "$FIXTURE_CODE" -eq 0 ] || { fail "clean fixture should exit 0, got $FIXTURE_CODE: $FIXTURE_OUT"; return 1; }
    echo "$FIXTURE_OUT" | grep -q "All 1 tests passed" || { fail "expected all-passed summary, got: $FIXTURE_OUT"; return 1; }
}

test_failing_assert_fails() {
    run_fixture '
bad() { assert_equals "1" "2" "intentional"; }
run_test "bad" bad
print_summary
'
    [ "$FIXTURE_CODE" -ne 0 ] || { fail "failing fixture should exit non-zero"; return 1; }
    echo "$FIXTURE_OUT" | grep -q "1 of 1 tests failed" || { fail "expected 1 of 1 failed, got: $FIXTURE_OUT"; return 1; }
}

# ──────────────────────────────────────────────
# Silent-pass holes
# ──────────────────────────────────────────────

test_nonzero_return_without_fail_is_counted() {
    run_fixture '
silent_failure() { return 1; }
run_test "silently failing test" silent_failure
print_summary
'
    [ "$FIXTURE_CODE" -ne 0 ] || { fail "non-zero return without fail() must not exit 0 (silent pass)"; return 1; }
    echo "$FIXTURE_OUT" | grep -q "1 of 1 tests failed" || { fail "expected 1 of 1 failed, got: $FIXTURE_OUT"; return 1; }
}

test_set_e_reenable_inside_test_does_not_abort_file() {
    run_fixture '
sets_e_then_fails() {
    set +e
    true
    set -e
    assert_equals "1" "2" "intentional mismatch"
}
later_test() { return 0; }
run_test "re-enables errexit then fails assert" sets_e_then_fails
run_test "subsequent test still runs" later_test
print_summary
'
    echo "$FIXTURE_OUT" | grep -q "subsequent test still runs" || { fail "file aborted: later test did not run. out: $FIXTURE_OUT"; return 1; }
    echo "$FIXTURE_OUT" | grep -q "1 of 2 tests failed" || { fail "expected 1 of 2 failed, got: $FIXTURE_OUT"; return 1; }
}

test_multiple_failing_asserts_count_as_one_failed_test() {
    run_fixture '
double_failure() {
    assert_equals "a" "b" "first"
    assert_equals "c" "d" "second"
}
ok_test() { return 0; }
run_test "two failing asserts" double_failure
run_test "ok" ok_test
print_summary
'
    echo "$FIXTURE_OUT" | grep -q "1 of 2 tests failed" || { fail "two asserts in one test must count once, got: $FIXTURE_OUT"; return 1; }
}

test_fail_then_zero_return_is_not_also_a_pass() {
    run_fixture '
fails_but_returns_zero() {
    fail "explicit failure"
    return 0
}
run_test "fails but returns zero" fails_but_returns_zero
print_summary
'
    [ "$FIXTURE_CODE" -ne 0 ] || { fail "fixture should exit non-zero"; return 1; }
    echo "$FIXTURE_OUT" | grep -q "1 of 1 tests failed" || { fail "expected 1 of 1 failed, got: $FIXTURE_OUT"; return 1; }
    if echo "$FIXTURE_OUT" | grep -q "✓"; then
        fail "a failed test must not also print a pass mark"
        return 1
    fi
}

# ──────────────────────────────────────────────
# Crash / accounting guards
# ──────────────────────────────────────────────

test_crash_before_summary_is_flagged() {
    run_fixture '
ok_test() { return 0; }
run_test "ok" ok_test
false
print_summary
'
    [ "$FIXTURE_CODE" -ne 0 ] || { fail "crashed fixture should exit non-zero"; return 1; }
    echo "$FIXTURE_OUT" | grep -q "ABORTED before summary" || { fail "expected ABORTED marker, got: $FIXTURE_OUT"; return 1; }
}

test_accounting_mismatch_is_detected() {
    run_fixture '
it "orphan test counted in RUN but never resolved"
print_summary
'
    [ "$FIXTURE_CODE" -ne 0 ] || { fail "accounting mismatch should exit non-zero"; return 1; }
    echo "$FIXTURE_OUT" | grep -qi "mismatch" || { fail "expected accounting mismatch message, got: $FIXTURE_OUT"; return 1; }
}

# ──────────────────────────────────────────────
# Run
# ──────────────────────────────────────────────

describe "test_helpers.sh — runner integrity"
run_test "passing test passes and exits 0" test_passing_test_passes
run_test "failing assert fails and exits non-zero" test_failing_assert_fails
run_test "non-zero return without fail() is counted as failure" test_nonzero_return_without_fail_is_counted
run_test "set -e re-enabled inside a test cannot abort the file" test_set_e_reenable_inside_test_does_not_abort_file
run_test "multiple failing asserts count as one failed test" test_multiple_failing_asserts_count_as_one_failed_test
run_test "fail() then return 0 is not double-counted as pass" test_fail_then_zero_return_is_not_also_a_pass
run_test "crash before summary is flagged as ABORTED" test_crash_before_summary_is_flagged
run_test "TESTS_RUN vs counted outcome mismatch is detected" test_accounting_mismatch_is_detected

print_summary
