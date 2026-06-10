#!/bin/bash

# Tests the runaway budget + same-failure fingerprint guards in
# loop_control — the standard 11-step loop had no pre-emptive scope
# budget (qa_judge's 5-file/200-line check is a post-hoc needs_human,
# not a stop), and 'same approach max 3 times' was prose with nothing
# detecting a repeating failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

LC="${FRAMEWORK_DIR}/core/runtime/loop_control.py"

py() {
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime import loop_control as lc
$1
"
}

# ──────────────────────────────────────────────
describe "budget guard — scope explosion escalates"

test_over_budget_escalates() {
    local out
    out=$(py "print(lc.check_budget(files_changed=60, lines_changed=4000)['action'])")
    assert_equals "escalate" "$out" "a 60-file / 4000-line diff must escalate, not proceed"
}
run_test "scope over budget → escalate" test_over_budget_escalates

test_within_budget_ok() {
    local out
    out=$(py "print(lc.check_budget(files_changed=3, lines_changed=80)['action'])")
    assert_equals "proceed" "$out" "a small diff stays within budget"
}
run_test "small diff → proceed" test_within_budget_ok

# ──────────────────────────────────────────────
describe "fingerprint guard — same failure repeating"

test_same_fingerprint_twice_changes_approach() {
    local out
    out=$(py "
lc.record_attempt('${TEST_DIR}', 50, '5_implementation', 'fail', 'samefp')
lc.record_attempt('${TEST_DIR}', 50, '5_implementation', 'fail', 'samefp')
print(lc.consecutive_fingerprint('${TEST_DIR}', 50))
")
    assert_equals "2" "$out" "the same failure fingerprint twice must be counted"
}
run_test "same fingerprint twice is detected" test_same_fingerprint_twice_changes_approach

test_different_fingerprint_resets_streak() {
    local out
    out=$(py "
lc.record_attempt('${TEST_DIR}', 51, '5_implementation', 'fail', 'fpA')
lc.record_attempt('${TEST_DIR}', 51, '5_implementation', 'fail', 'fpB')
print(lc.consecutive_fingerprint('${TEST_DIR}', 51))
")
    assert_equals "1" "$out" "a different fingerprint resets the consecutive streak"
}
run_test "different fingerprint resets the streak" test_different_fingerprint_resets_streak

test_should_retry_flags_repeat() {
    local out
    out=$(py "
lc.record_attempt('${TEST_DIR}', 52, '5_implementation', 'fail', 'fp')
lc.record_attempt('${TEST_DIR}', 52, '5_implementation', 'fail', 'fp')
d = lc.should_retry('${TEST_DIR}', 52)
print(d.get('repeated_failure'))
")
    assert_equals "True" "$out" "should_retry must flag a repeating same-failure so the agent changes approach"
}
run_test "should_retry flags a repeating failure" test_should_retry_flags_repeat

print_summary
