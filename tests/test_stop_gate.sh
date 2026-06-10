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
    local stdin_json="${2:-}"
    [ -z "$stdin_json" ] && stdin_json='{}'
    local rc=0
    # Clean up any leftover block-counter file
    rm -f "$(flag_file_for "$project_dir")"
    printf '%s' "$stdin_json" | CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    return $rc
}

# Same as run_gate but keeps the block counter between calls
# (for consecutive-block escalation tests).
run_gate_keep_counter() {
    local project_dir="${1:-$TEST_DIR}"
    local rc=0
    printf '%s' '{}' | CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK_SCRIPT" 2>/dev/null || rc=$?
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
# Tests: Loop prevention & escalation
# ══════════════════════════════════════════════

describe "stop_test_gate.sh - loop prevention & escalation"

test_stop_hook_active_passes_through() {
    create_state "Coding Agent" "5_implementation"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo fail && exit 1" } }
JSON
    # Claude Code sets stop_hook_active=true when the stop was already
    # blocked once this turn — the hook must not block again (official
    # re-entry prevention).
    run_gate "$TEST_DIR" '{"stop_hook_active": true}'
    local rc=$?
    assert_equals "0" "$rc" "Should exit 0 when stop_hook_active is true"
}
run_test "exits 0 when stop_hook_active is true" test_stop_hook_active_passes_through

test_three_blocks_then_escalates() {
    create_state "Coding Agent" "5_implementation"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo fail && exit 1" } }
JSON
    local flag
    flag="$(flag_file_for "$TEST_DIR")"
    rm -f "$flag"

    local rc1=0 rc2=0 rc3=0 rc4=0
    run_gate_keep_counter "$TEST_DIR" || rc1=$?
    run_gate_keep_counter "$TEST_DIR" || rc2=$?
    run_gate_keep_counter "$TEST_DIR" || rc3=$?
    run_gate_keep_counter "$TEST_DIR" || rc4=$?
    rm -f "$flag"

    assert_equals "2" "$rc1" "1st consecutive failure should block (exit 2)"
    assert_equals "2" "$rc2" "2nd consecutive failure should block (exit 2)"
    assert_equals "2" "$rc3" "3rd consecutive failure should block (exit 2)"
    assert_equals "0" "$rc4" "4th attempt should pass through (escalate to human)"
}
run_test "blocks 3 consecutive failures then escalates" test_three_blocks_then_escalates

test_success_resets_counter() {
    create_state "Coding Agent" "5_implementation"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo fail && exit 1" } }
JSON
    local flag
    flag="$(flag_file_for "$TEST_DIR")"
    rm -f "$flag"

    local rc1=0 rc2=0
    run_gate_keep_counter "$TEST_DIR" || rc1=$?
    assert_equals "2" "$rc1" "failing test should block"

    # Tests now pass — counter must reset
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo ok" } }
JSON
    run_gate_keep_counter "$TEST_DIR" || rc2=$?
    assert_equals "0" "$rc2" "passing test should allow stop"
    if [ -f "$flag" ]; then
        fail "block counter should be removed after a successful test run"
        rm -f "$flag"
        return 1
    fi
    return 0
}
run_test "successful test run resets the block counter" test_success_resets_counter

test_failure_message_on_stderr() {
    create_state "Coding Agent" "5_implementation"
    cat > "${TEST_DIR}/package.json" << 'JSON'
{ "scripts": { "test": "echo fail && exit 1" } }
JSON
    local flag
    flag="$(flag_file_for "$TEST_DIR")"
    rm -f "$flag"
    # exit 2 feeds stderr (not stdout) back to Claude — the failure
    # message must be on stderr or the agent never sees it.
    local rc=0 err=""
    err=$(printf '%s' '{}' | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK_SCRIPT" 2>&1 >/dev/null) || rc=$?
    rm -f "$flag"
    assert_equals "2" "$rc" "failing test should block"
    echo "$err" | grep -q "テストが通っていません" || {
        fail "failure message should be on stderr, got: '$err'"
        return 1
    }
}
run_test "failure message is sent to stderr" test_failure_message_on_stderr

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
