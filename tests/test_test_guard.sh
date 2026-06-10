#!/bin/bash

# Tests for TestGuard — blocks weakening/deleting existing tests to pass
# the gate (reward hacking via test edits, SpecBench/ImpossibleBench).
#
# Two layers:
#  - validate_step7a.py blocks gh pr create when the branch deletes
#    tests, drops test cases, or adds skips — unless a human approved it.
#  - qa_judge denies auto_pass when the diff weakened tests.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py"
PR_CMD='{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'

run_hook() {
    local rc=0
    echo "$PR_CMD" | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK" 2>/dev/null || rc=$?
    return $rc
}

create_state_with_issue() {
    mkdir -p "${TEST_DIR}/.vibe"
    cat > "${TEST_DIR}/.vibe/state.yaml" << YAML
current_issue: "${1}"
current_step: 7
YAML
}
create_qa_auto_checkpoint() {
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "auto-approved:qa:auto" > "${TEST_DIR}/.vibe/checkpoints/${1}-qa-approved"
}
create_human_checkpoint() {
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "approved" > "${TEST_DIR}/.vibe/checkpoints/${1}-qa-approved"
    echo "# packet" > "${TEST_DIR}/.vibe/checkpoints/${1}-packet.md"
}

# base 'main' has a test file with two cases; the feature branch mutates it
seed_main_with_tests() {
    cd "$TEST_DIR"
    mkdir -p tests
    cat > tests/sample.test.js << 'JS'
test('a', () => { expect(1).toBe(1); });
test('b', () => { expect(2).toBe(2); });
JS
    git add -A && git commit -q -m "base with tests"
    git branch -M main
    git checkout -q -b feature/work
}

# ──────────────────────────────────────────────
describe "TestGuard — blocks weakening tests without human approval"

test_deleting_test_file_blocked() {
    seed_main_with_tests
    git rm -q tests/sample.test.js
    echo "x=1" > src_app.py 2>/dev/null || true
    git add -A && git commit -q -m "remove tests"
    create_state_with_issue "#80"
    create_qa_auto_checkpoint "#80"
    run_hook
    assert_equals "2" "$?" "deleting a test file must block gh pr create (qa:auto cannot bypass)"
}
run_test "deleting a test file is blocked" test_deleting_test_file_blocked

test_adding_skip_blocked() {
    seed_main_with_tests
    cat > tests/sample.test.js << 'JS'
test('a', () => { expect(1).toBe(1); });
test.skip('b', () => { expect(2).toBe(2); });
JS
    git add -A && git commit -q -m "skip b"
    create_state_with_issue "#81"
    create_qa_auto_checkpoint "#81"
    run_hook
    assert_equals "2" "$?" "adding .skip to an existing test must block"
}
run_test "adding a .skip is blocked" test_adding_skip_blocked

test_dropping_test_case_blocked() {
    seed_main_with_tests
    cat > tests/sample.test.js << 'JS'
test('a', () => { expect(1).toBe(1); });
JS
    git add -A && git commit -q -m "drop b"
    create_state_with_issue "#82"
    create_qa_auto_checkpoint "#82"
    run_hook
    assert_equals "2" "$?" "removing a test case (net count drop) must block"
}
run_test "dropping a test case is blocked" test_dropping_test_case_blocked

# ──────────────────────────────────────────────
describe "TestGuard — legitimate test changes pass"

test_adding_tests_passes() {
    seed_main_with_tests
    cat > tests/sample.test.js << 'JS'
test('a', () => { expect(1).toBe(1); });
test('b', () => { expect(2).toBe(2); });
test('c', () => { expect(3).toBe(3); });
JS
    git add -A && git commit -q -m "add c"
    create_state_with_issue "#83"
    create_qa_auto_checkpoint "#83"
    run_hook
    assert_equals "0" "$?" "adding a new test case must pass"
}
run_test "adding a test case passes" test_adding_tests_passes

test_new_test_file_passes() {
    seed_main_with_tests
    cat > tests/extra.test.js << 'JS'
test('x', () => { expect(1).toBe(1); });
JS
    git add -A && git commit -q -m "new test file"
    create_state_with_issue "#84"
    create_qa_auto_checkpoint "#84"
    run_hook
    assert_equals "0" "$?" "a brand-new test file must pass"
}
run_test "new test file passes" test_new_test_file_passes

test_human_approval_overrides() {
    seed_main_with_tests
    git rm -q tests/sample.test.js
    git commit -q -m "remove tests deliberately"
    create_state_with_issue "#85"
    create_human_checkpoint "#85"
    run_hook
    assert_equals "0" "$?" "a deliberate test removal with human approval must pass"
}
run_test "human approval overrides TestGuard" test_human_approval_overrides

# ──────────────────────────────────────────────
describe "TestGuard — qa_judge denies auto_pass on weakened tests"

test_qa_judge_blocks_weakened_tests() {
    local verdict
    verdict=$(python3 -c "
import os, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.qa_judge import judge
log = os.path.join('${TEST_DIR}', 'test.log'); open(log,'w').write('ok')
ex = os.path.join('${TEST_DIR}', 'test.exit'); open(ex,'w').write('0')
r = judge({
    'labels': ['type:fix','risk:low','qa:auto'],
    'tests_passed': True, 'review_verdict': 'pass',
    'files_changed': 1, 'lines_changed': 5,
    'evidence': {'test_log': log, 'test_exit': ex},
    'test_guard': {'tests_deleted': True, 'tests_skipped_added': False, 'test_count_delta': -2},
})
print(r['verdict'])
")
    assert_equals "needs_human" "$verdict" "qa_judge must not auto_pass when tests were weakened"
}
run_test "qa_judge routes weakened tests to needs_human" test_qa_judge_blocks_weakened_tests

# ──────────────────────────────────────────────
describe "TestGuard — rule is documented"

test_rule_documented() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/workflow-standard.md" \
        "テストの削除" "the no-weakening-tests rule must be written down"
}
run_test "no-weakening-tests rule is documented" test_rule_documented

print_summary
