#!/bin/bash

# Tests for core/runtime/loop_control.py — the machine that makes the
# "max 3 retries → escalate" / agent-fallback rules real (they were prose
# only; no code counted attempts, so the recovery strategy never fired).

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

test_module_exists() {
    assert_file_exists "$LC" "core/runtime/loop_control.py must exist"
}
run_test "loop_control.py exists" test_module_exists

test_first_attempts_retry_claude() {
    local out
    out=$(py "
lc.record_attempt('${TEST_DIR}', 42, '5_implementation', 'fail', 'fp1')
d = lc.should_retry('${TEST_DIR}', 42)
print(d['action'], d.get('agent',''))
")
    assert_equals "retry claude_code" "$out" "attempt 1 failure should retry with claude_code"
}
run_test "attempt 1 → retry (claude_code)" test_first_attempts_retry_claude

test_third_attempt_switches_agent() {
    local out
    out=$(py "
for _ in range(2):
    lc.record_attempt('${TEST_DIR}', 43, '5_implementation', 'fail', 'fp')
d = lc.should_retry('${TEST_DIR}', 43)
print(d['action'], d.get('agent',''))
")
    assert_equals "switch_agent codex" "$out" "after 2 failures the 3rd attempt should switch to codex"
}
run_test "attempt 3 → switch_agent (codex)" test_third_attempt_switches_agent

test_fourth_attempt_escalates() {
    local out
    out=$(py "
for _ in range(3):
    lc.record_attempt('${TEST_DIR}', 44, '5_implementation', 'fail', 'fp')
d = lc.should_retry('${TEST_DIR}', 44)
print(d['action'])
")
    assert_equals "escalate" "$out" "after 3 failures the loop must escalate to a human"
}
run_test "after 3 failures → escalate" test_fourth_attempt_escalates

test_count_persists_across_processes() {
    # record in one process, read in another — state must persist in the
    # session YAML, not in memory.
    py "lc.record_attempt('${TEST_DIR}', 45, '5_implementation', 'fail', 'fp')"
    py "lc.record_attempt('${TEST_DIR}', 45, '5_implementation', 'fail', 'fp')"
    py "lc.record_attempt('${TEST_DIR}', 45, '5_implementation', 'fail', 'fp')"
    local out
    out=$(py "print(lc.should_retry('${TEST_DIR}', 45)['action'])")
    assert_equals "escalate" "$out" "attempt count must persist across processes (session YAML)"
}
run_test "attempt count persists across processes" test_count_persists_across_processes

test_success_resets() {
    local out
    out=$(py "
lc.record_attempt('${TEST_DIR}', 46, '5_implementation', 'fail', 'fp')
lc.record_attempt('${TEST_DIR}', 46, '5_implementation', 'fail', 'fp')
lc.record_attempt('${TEST_DIR}', 46, '7_acceptance_test', 'pass', 'fp')
d = lc.should_retry('${TEST_DIR}', 46)
print(d['action'], d.get('agent',''))
")
    assert_equals "retry claude_code" "$out" "a passing attempt resets the failure count"
}
run_test "a success resets the count" test_success_resets

test_cli_should_retry() {
    py "lc.record_attempt('${TEST_DIR}', 47, '5_implementation', 'fail', 'fp')"
    local out
    out=$(VIBEFLOW_PROJECT_DIR="${TEST_DIR}" python3 "$LC" should-retry 47 --project-dir "${TEST_DIR}" 2>/dev/null)
    echo "$out" | grep -q "retry" || { fail "CLI should-retry must print the action, got: $out"; return 1; }
}
run_test "CLI should-retry prints the action" test_cli_should_retry

test_skill_wires_loop_control() {
    local skill="${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md"
    assert_file_contains "$skill" "loop_control" \
        "execute-issue must call loop_control on failure (not just prose 'retry 3 times')"
}
run_test "execute-issue wires loop_control on failure" test_skill_wires_loop_control

print_summary
