#!/bin/bash

# VibeFlow Test: stop_test_gate.sh
# Tests the Stop hook that gates completion on test success

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK_SCRIPT="${FRAMEWORK_DIR}/examples/.vibe/hooks/stop_test_gate.sh"

# ──────────────────────────────────────────────
# Helper: create state.yaml with given role and step
# ──────────────────────────────────────────────
create_state() {
    local role="${1:-Iris}"
    local step="${2:-1_issue_review}"
    mkdir -p "${TEST_DIR}/.vibe"
    cat > "${TEST_DIR}/.vibe/state.yaml" << YAML
current_role: "${role}"
current_step: ${step}
current_issue: "#42"
phase: development
YAML
}

# ──────────────────────────────────────────────
# Helper: run the stop gate hook
# ──────────────────────────────────────────────
flag_file_for() {
    local project_dir="${1:-$TEST_DIR}"
    local hash
    hash=$(echo "$project_dir" | (md5sum 2>/dev/null || md5 2>/dev/null) | cut -c1-8)
    echo "/tmp/vibeflow_stop_gate_${hash}"
}

run_gate() {
    local project_dir="${1:-$TEST_DIR}"
    local rc=0
    # Clean up any leftover flag file
    rm -f "$(flag_file_for "$project_dir")"
    CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    return $rc
}

# ══════════════════════════════════════════════
# Tests: Script validity
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - script validity"

test_script_exists() {
    assert_file_exists "$HOOK_SCRIPT" "stop_test_gate.sh should exist in examples"
}
run_test "script exists" test_script_exists

test_valid_bash() {
    bash -n "$HOOK_SCRIPT"
    local rc=$?
    assert_equals "0" "$rc" "Script should pass bash -n syntax check"
}
run_test "script is valid bash" test_valid_bash

# ══════════════════════════════════════════════
# Tests: settings.json integration
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - settings.json integration"

test_settings_has_stop_gate() {
    local settings="${FRAMEWORK_DIR}/examples/.claude/settings.json"
    assert_file_contains "$settings" "stop_test_gate.sh" "settings.json should reference stop_test_gate.sh"
}
run_test "settings.json has Stop entry for stop_test_gate.sh" test_settings_has_stop_gate

test_stop_gate_before_waiting_input() {
    local settings="${FRAMEWORK_DIR}/examples/.claude/settings.json"
    # stop_test_gate should appear before waiting_input in the file
    local gate_line=$(grep -n "stop_test_gate" "$settings" | head -1 | cut -d: -f1)
    local notify_line=$(grep -n "waiting_input" "$settings" | head -1 | cut -d: -f1)
    if [ "$gate_line" -lt "$notify_line" ]; then
        return 0
    else
        fail "stop_test_gate.sh should appear before waiting_input.sh in settings.json"
        return 1
    fi
}
run_test "stop_test_gate appears before waiting_input in Stop hooks" test_stop_gate_before_waiting_input

# ══════════════════════════════════════════════
# Tests: Graceful degradation
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - graceful degradation"

test_no_state_yaml() {
    # Don't create state.yaml - should exit 0
    mkdir -p "${TEST_DIR}/.vibe"
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 when state.yaml missing"
}
run_test "exits 0 when no state.yaml exists" test_no_state_yaml

test_empty_state_yaml() {
    mkdir -p "${TEST_DIR}/.vibe"
    touch "${TEST_DIR}/.vibe/state.yaml"
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 when state.yaml is empty"
}
run_test "exits 0 when state.yaml is empty" test_empty_state_yaml

# ══════════════════════════════════════════════
# Tests: Role/step filtering
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - role/step filtering"

test_iris_role_passes() {
    create_state "Iris" "1_issue_review"
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 when role is Iris (not coding)"
}
run_test "exits 0 when role is Iris" test_iris_role_passes

test_coding_agent_non_coding_step() {
    create_state "Coding Agent" "8_pr_creation"
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 for Coding Agent on non-coding step"
}
run_test "exits 0 for Coding Agent on non-coding step" test_coding_agent_non_coding_step

test_coding_agent_coding_step_no_runner() {
    create_state "Coding Agent" "5_implementation"
    # No package.json, pytest.ini, Makefile, or tests/run_tests.sh → no test runner
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 when no test runner detected"
}
run_test "exits 0 when no test runner is detected" test_coding_agent_coding_step_no_runner

# ══════════════════════════════════════════════
# Tests: Infinite loop prevention
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - infinite loop prevention"

test_flag_file_prevents_reentry() {
    create_state "Coding Agent" "5_implementation"
    # Create a package.json with test script (would normally trigger tests)
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo fail && exit 1" } }
JSON
    # Pre-create the flag file to simulate reentry
    local flag
    flag="$(flag_file_for "$TEST_DIR")"
    touch "$flag"
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK_SCRIPT" 2>/dev/null
    local rc=$?
    rm -f "$flag"
    assert_equals "0" "$rc" "Should exit 0 when flag file exists (reentry prevention)"
}
run_test "exits 0 when reentry flag exists" test_flag_file_prevents_reentry

test_flag_file_cleaned_up() {
    create_state "Iris" "1_issue_review"
    local flag
    flag="$(flag_file_for "$TEST_DIR")"
    rm -f "$flag"
    run_gate "$TEST_DIR"
    # After the hook exits, the flag should be cleaned up
    if [ -f "$flag" ]; then
        fail "Flag file should be cleaned up after hook exits"
        rm -f "$flag"
        return 1
    fi
    return 0
}
run_test "flag file is cleaned up after exit" test_flag_file_cleaned_up

# ══════════════════════════════════════════════
# Tests: Test execution
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - test execution"

test_npm_test_pass() {
    create_state "Coding Agent" "5_implementation"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo all tests passed" } }
JSON
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 when npm test passes"
}
run_test "exits 0 when npm test passes" test_npm_test_pass

test_npm_test_fail() {
    create_state "Coding Agent" "4_test_writing"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo FAIL && exit 1" } }
JSON
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "2" "$rc" "Should exit 2 when npm test fails"
}
run_test "exits 2 when npm test fails" test_npm_test_fail

test_step_6_refactoring() {
    create_state "Coding Agent" "6_refactoring"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo ok" } }
JSON
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "0" "$rc" "Should gate on 6_refactoring step too"
}
run_test "gates on 6_refactoring step" test_step_6_refactoring

test_case_insensitive_role() {
    create_state "coding agent" "5_implementation"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo FAIL && exit 1" } }
JSON
    run_gate "$TEST_DIR"
    local rc=$?
    assert_equals "2" "$rc" "Should match Coding Agent case-insensitively"
}
run_test "matches Coding Agent case-insensitively" test_case_insensitive_role

# ──────────────────────────────────────────────
print_summary
