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
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

# auto_pass requires real test evidence on disk, not just claims
log = os.path.join('${TEST_DIR}', 'test.log')
ex = os.path.join('${TEST_DIR}', 'test.exit')
open(log, 'w').write('all 12 tests passed')
open(ex, 'w').write('0')

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 3,
    'lines_changed': 50,
    'evidence': {'test_log': log, 'test_exit': ex},
})
assert result['verdict'] == 'auto_pass', f'Should auto pass: {result}'
assert result['needs_human'] == False, f'Should not need human: {result}'
print('OK')
")
    assert_equals "OK" "$result" "Low-risk fix with tests pass + evidence should auto_pass"
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

test_ui_no_substring_false_positives() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import is_ui_task

# 'ui' must not match inside 'build'/'guide'; 'form' not inside 'performance'
assert is_ui_task({'issue_title': 'Fix build script for CI'}) == False, 'build != ui'
assert is_ui_task({'issue_title': 'Improve performance of parser'}) == False, 'performance != form'
assert is_ui_task({'issue_title': 'Update setup guide'}) == False, 'guide != ui'
# real UI titles still detected
assert is_ui_task({'issue_title': 'Fix the UI layout'}) == True
assert is_ui_task({'issue_title': 'ボタンの色を変える'}) == True
print('OK')
")
    assert_equals "OK" "$result" "English UI keywords must match on word boundaries"
}
run_test "no substring false positives (build/performance/guide)" test_ui_no_substring_false_positives

test_ui_detection_consistent_across_modules() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import is_ui_task as qa_is_ui
from core.runtime.dispatcher import _is_ui_task as dispatch_is_ui
from core.runtime import issue_generator

titles = [
    'Fix build script for CI',
    'ボタンの色を変える',
    'Add dashboard screen',
    'Refactor API layer',
]
for t in titles:
    qa = qa_is_ui({'issue_title': t})
    dp = dispatch_is_ui({'title': t, 'body': ''})
    ig = issue_generator.title_is_ui(t)
    assert qa == dp == ig, f'inconsistent UI verdicts for {t!r}: qa={qa} dispatcher={dp} issue_gen={ig}'
print('OK')
")
    assert_equals "OK" "$result" "qa_judge / dispatcher / issue_generator must agree on UI detection"
}
run_test "UI detection is consistent across all three modules" test_ui_detection_consistent_across_modules

# ──────────────────────────────────────────────
describe "QA Judge — review verdict whitelist (fail-closed)"

qa_judge_with_evidence() {
    # $1 = extra context fields (python dict entries)
    python3 -c "
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

log = os.path.join('${TEST_DIR}', 'test.log')
ex = os.path.join('${TEST_DIR}', 'test.exit')
open(log, 'w').write('all tests passed')
open(ex, 'w').write('0')

ctx = {
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'files_changed': 2,
    'lines_changed': 20,
    'evidence': {'test_log': log, 'test_exit': ex},
}
ctx.update({$1})
result = judge(ctx)
print(result['verdict'])
"
}

test_review_unknown_is_not_auto_pass() {
    local verdict
    verdict=$(qa_judge_with_evidence "'review_verdict': 'unknown'")
    assert_equals "needs_human" "$verdict" "review_verdict=unknown must not auto_pass (review never ran)"
}
run_test "review_verdict=unknown → needs_human" test_review_unknown_is_not_auto_pass

test_review_pending_is_not_auto_pass() {
    local verdict
    verdict=$(qa_judge_with_evidence "'review_verdict': 'pending'")
    assert_equals "needs_human" "$verdict" "review_verdict=pending must not auto_pass"
}
run_test "review_verdict=pending → needs_human" test_review_pending_is_not_auto_pass

test_review_missing_is_not_auto_pass() {
    local verdict
    verdict=$(qa_judge_with_evidence "")
    assert_equals "needs_human" "$verdict" "missing review_verdict must not auto_pass"
}
run_test "review_verdict missing → needs_human" test_review_missing_is_not_auto_pass

test_review_unparsed_is_not_auto_pass() {
    local verdict
    verdict=$(qa_judge_with_evidence "'review_verdict': 'unparsed'")
    assert_equals "needs_human" "$verdict" "review_verdict=unparsed must not auto_pass"
}
run_test "review_verdict=unparsed → needs_human" test_review_unparsed_is_not_auto_pass

test_warn_without_responses_is_not_auto_pass() {
    local verdict
    verdict=$(qa_judge_with_evidence "'review_verdict': 'warn'")
    assert_equals "needs_human" "$verdict" "warn without recorded responses must not auto_pass"
}
run_test "warn without recorded responses → needs_human" test_warn_without_responses_is_not_auto_pass

test_warn_with_responses_can_auto_pass() {
    local verdict
    verdict=$(qa_judge_with_evidence "'review_verdict': 'warn', 'warn_responses_recorded': True")
    assert_equals "auto_pass" "$verdict" "warn with all responses recorded may auto_pass"
}
run_test "warn with recorded responses → auto_pass" test_warn_with_responses_can_auto_pass

# ──────────────────────────────────────────────
describe "QA Judge — evidence-based judgment"

test_no_evidence_is_not_auto_pass() {
    local verdict
    verdict=$(python3 -c "
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
print(result['verdict'])
")
    assert_equals "needs_human" "$verdict" "claims without test evidence must not auto_pass"
}
run_test "no evidence → needs_human (claims are not proof)" test_no_evidence_is_not_auto_pass

test_nonzero_exit_evidence_overrides_claim() {
    local verdict
    verdict=$(python3 -c "
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

log = os.path.join('${TEST_DIR}', 'test.log')
ex = os.path.join('${TEST_DIR}', 'test.exit')
open(log, 'w').write('2 tests failed')
open(ex, 'w').write('1')

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 20,
    'evidence': {'test_log': log, 'test_exit': ex},
})
print(result['verdict'])
")
    assert_equals "fail" "$verdict" "exit-code evidence must override the self-reported tests_passed=True"
}
run_test "non-zero exit evidence overrides tests_passed claim" test_nonzero_exit_evidence_overrides_claim

test_missing_evidence_files_is_not_auto_pass() {
    local verdict
    verdict=$(python3 -c "
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 20,
    'evidence': {'test_log': os.path.join('${TEST_DIR}', 'nope.log'),
                 'test_exit': os.path.join('${TEST_DIR}', 'nope.exit')},
})
print(result['verdict'])
")
    assert_equals "needs_human" "$verdict" "evidence paths that do not exist must not auto_pass"
}
run_test "missing evidence files → needs_human" test_missing_evidence_files_is_not_auto_pass

test_artifact_path_must_exist() {
    local verdict
    verdict=$(python3 -c "
import os, sys
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
    'has_playwright_artifact': True,
    'playwright_artifact_path': os.path.join('${TEST_DIR}', 'no-such-artifact.png'),
})
print(result['verdict'])
")
    assert_equals "fail" "$verdict" "a claimed artifact whose path does not exist must fail"
}
run_test "nonexistent playwright artifact path → fail" test_artifact_path_must_exist

# ──────────────────────────────────────────────
describe "QA Judge — invariant violations"

test_violated_invariants_fail() {
    local verdict
    verdict=$(python3 -c "
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

log = os.path.join('${TEST_DIR}', 'test.log')
ex = os.path.join('${TEST_DIR}', 'test.exit')
open(log, 'w').write('all tests passed')
open(ex, 'w').write('0')

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 20,
    'evidence': {'test_log': log, 'test_exit': ex},
    'invariants_violated': 1,
})
print(result['verdict'])
")
    assert_equals "fail" "$verdict" "a violated invariant is a broken existing guarantee → fail"
}
run_test "invariants_violated > 0 → fail" test_violated_invariants_fail

test_zero_violations_unchanged() {
    local verdict
    verdict=$(python3 -c "
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge

log = os.path.join('${TEST_DIR}', 'test.log')
ex = os.path.join('${TEST_DIR}', 'test.exit')
open(log, 'w').write('all tests passed')
open(ex, 'w').write('0')

result = judge({
    'labels': ['type:fix', 'risk:low', 'qa:auto'],
    'tests_passed': True,
    'review_verdict': 'pass',
    'files_changed': 2,
    'lines_changed': 20,
    'evidence': {'test_log': log, 'test_exit': ex},
    'invariants_violated': 0,
})
print(result['verdict'])
")
    assert_equals "auto_pass" "$verdict" "0 violations keeps the normal path"
}
run_test "invariants_violated = 0 → unchanged (auto_pass)" test_zero_violations_unchanged

# ──────────────────────────────────────────────
print_summary
