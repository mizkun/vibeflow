#!/bin/bash

# VibeFlow Test: v5 — Issue Auto-Close (Issue #64)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Auto Close — module exists"

test_module_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/auto_close.py" \
        "core/runtime/auto_close.py must exist"
}
run_test "auto_close.py exists" test_module_exists

# ──────────────────────────────────────────────
describe "Auto Close — interface"

test_has_should_auto_close() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/auto_close.py" \
        "def should_auto_close" "Should have should_auto_close function"
}
run_test "has should_auto_close function" test_has_should_auto_close

test_has_close_issue() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/auto_close.py" \
        "def close_issue" "Should have close_issue function"
}
run_test "has close_issue function" test_has_close_issue

test_has_generate_summary() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/auto_close.py" \
        "def generate_summary" "Should have generate_summary function"
}
run_test "has generate_summary function" test_has_generate_summary

# ──────────────────────────────────────────────
describe "Auto Close — qa:auto issues"

test_auto_close_qa_auto() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.auto_close import should_auto_close

result = should_auto_close({
    'labels': ['qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'pr_merged': True,
})
assert result['can_close'] == True, f'qa:auto with all pass should auto close: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "qa:auto with all checks passed should auto-close"
}
run_test "qa:auto auto-closes" test_auto_close_qa_auto

# ──────────────────────────────────────────────
describe "Auto Close — qa:manual needs human"

test_manual_needs_human() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.auto_close import should_auto_close

result = should_auto_close({
    'labels': ['qa:manual'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'pr_merged': True,
})
assert result['can_close'] == False, f'qa:manual should not auto close: {result}'
assert result['needs_human'] == True, f'Should need human: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "qa:manual should wait for human"
}
run_test "qa:manual waits for human" test_manual_needs_human

# ──────────────────────────────────────────────
describe "Auto Close — cannot close without PR merge"

test_no_close_without_merge() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.auto_close import should_auto_close

result = should_auto_close({
    'labels': ['qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'pr_merged': False,
})
assert result['can_close'] == False, f'Should not close without merge: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Cannot close without PR merge"
}
run_test "no close without PR merge" test_no_close_without_merge

# ──────────────────────────────────────────────
describe "Auto Close — summary generation"

test_generate_summary() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.auto_close import generate_summary

summary = generate_summary({
    'issue_number': 42,
    'title': 'Add login feature',
    'agent': 'codex',
    'pr_number': 43,
    'tests_passed': True,
    'review_verdict': 'pass',
})
assert '42' in summary, f'Should mention issue: {summary}'
assert 'login' in summary.lower(), f'Should mention title: {summary}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Summary should include issue details"
}
run_test "generates closure summary" test_generate_summary

# ──────────────────────────────────────────────
describe "Auto Close — status update"

test_has_status_update() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/auto_close.py" \
        "STATUS\|project_state\|status" "Should update project status"
}
run_test "updates project status" test_has_status_update

# ──────────────────────────────────────────────
print_summary
