#!/bin/bash

# VibeFlow Test: v5 — QA Judgment Automation (Issue #60)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "QA Judge — module exists"

test_judge_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/qa_judge.py" \
        "core/runtime/qa_judge.py must exist"
}
run_test "qa_judge.py exists" test_judge_exists

# ──────────────────────────────────────────────
describe "QA Judge — interface"

test_has_judge() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/qa_judge.py" \
        "def judge" "Should have judge function"
}
run_test "has judge function" test_has_judge

# ──────────────────────────────────────────────
describe "QA Judge — auto pass"

test_auto_pass() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 3,
    'lines_changed': 50,
})
assert result['verdict'] == 'auto_pass', f'Should auto pass: {result}'
assert result['needs_human'] == False, f'Should not need human: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Low-risk fix with tests pass should auto_pass"
}
run_test "auto pass for low-risk fix" test_auto_pass

# ──────────────────────────────────────────────
describe "QA Judge — needs human for UI"

test_needs_human_ui() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:dev', 'risk:low', 'qa:manual'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 3,
    'lines_changed': 50,
    'has_ui_changes': True,
    'playwright_passed': True,
    'has_playwright_artifact': True,
})
assert result['needs_human'] == True, f'UI changes should need human: {result}'
assert result['is_ui_task'] == True, f'Should detect UI task: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "UI changes should require human check"
}
run_test "needs human for UI changes" test_needs_human_ui

# ──────────────────────────────────────────────
describe "QA Judge — needs human for high risk"

test_needs_human_high_risk() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:dev', 'risk:high', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 3,
    'lines_changed': 50,
})
assert result['needs_human'] == True, f'High risk should need human: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "High risk should require human check"
}
run_test "needs human for high risk" test_needs_human_high_risk

# ──────────────────────────────────────────────
describe "QA Judge — fail on test failure"

test_fail_on_test_failure() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': False,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 20,
})
assert result['verdict'] == 'fail', f'Should fail on test failure: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should fail when tests fail"
}
run_test "fails on test failure" test_fail_on_test_failure

# ──────────────────────────────────────────────
describe "QA Judge — fail on review failure"

test_fail_on_review_failure() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'fail',
    'files_changed': 2,
    'lines_changed': 20,
})
assert result['verdict'] == 'fail', f'Should fail on review failure: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should fail when review fails"
}
run_test "fails on review failure" test_fail_on_review_failure

# ──────────────────────────────────────────────
describe "QA Judge — large diff needs human"

test_large_diff_needs_human() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:dev', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 10,
    'lines_changed': 500,
})
assert result['needs_human'] == True, f'Large diff should need human: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Large diff should require human check"
}
run_test "large diff needs human" test_large_diff_needs_human

# ──────────────────────────────────────────────
describe "QA Judge — reason provided"

test_provides_reason() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 20,
})
assert 'reason' in result, f'Should provide reason: {result}'
assert len(result['reason']) > 0, 'Reason should not be empty'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should include a reason"
}
run_test "provides judgment reason" test_provides_reason

# ──────────────────────────────────────────────
describe "QA Judge — Playwright mandatory for UI tasks"

test_ui_fail_without_playwright() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:dev', 'risk:low'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 30,
    'has_ui_changes': True,
    'playwright_passed': None,
})
assert result['verdict'] == 'fail', f'UI without Playwright should fail: {result}'
assert 'Playwright' in result['reason'], f'Reason should mention Playwright: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "UI task should fail if Playwright not run"
}
run_test "UI task fails without Playwright" test_ui_fail_without_playwright

test_ui_fail_playwright_failed() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:dev', 'risk:low'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 30,
    'has_ui_changes': True,
    'playwright_passed': False,
})
assert result['verdict'] == 'fail', f'UI with failed Playwright should fail: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "UI task should fail if Playwright fails"
}
run_test "UI task fails when Playwright fails" test_ui_fail_playwright_failed

test_ui_fail_no_artifact() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:dev', 'risk:low'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 30,
    'has_ui_changes': True,
    'playwright_passed': True,
    'has_playwright_artifact': False,
})
assert result['verdict'] == 'fail', f'UI without artifact should fail: {result}'
assert 'artifact' in result['reason'], f'Reason should mention artifact: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "UI task should fail without Playwright artifact"
}
run_test "UI task fails without artifact" test_ui_fail_no_artifact

test_ui_detect_by_files() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import is_ui_task

assert is_ui_task({'changed_files': ['src/App.tsx', 'src/main.ts']}) == True
assert is_ui_task({'changed_files': ['src/utils.ts', 'src/api.ts']}) == False
assert is_ui_task({'issue_title': 'ダッシュボード画面を追加'}) == True
assert is_ui_task({'issue_title': 'APIリファクタリング'}) == False
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "is_ui_task should detect UI tasks by files and keywords"
}
run_test "is_ui_task detection" test_ui_detect_by_files

# ──────────────────────────────────────────────
print_summary
