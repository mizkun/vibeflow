#!/bin/bash

# VibeFlow Test: v5 — Claude Code CLI Wrapper (Issue #54)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — module exists"

test_wrapper_py_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "core/runtime/claude_code_wrapper.py must exist"
}
run_test "claude_code_wrapper.py exists" test_wrapper_py_exists

test_wrapper_sh_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" \
        "lib/wrappers/claude_code.sh must exist"
}
run_test "lib/wrappers/claude_code.sh exists" test_wrapper_sh_exists

test_wrapper_sh_executable() {
    [ -x "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" ]
    assert_equals "0" "$?" "claude_code.sh should be executable"
}
run_test "claude_code.sh is executable" test_wrapper_sh_executable

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — Python interface"

test_has_dispatch() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "def dispatch" "Should have dispatch function"
}
run_test "has dispatch function" test_has_dispatch

test_has_poll() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "def poll" "Should have poll function"
}
run_test "has poll function" test_has_poll

test_has_collect() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "def collect" "Should have collect function"
}
run_test "has collect function" test_has_collect

test_has_cancel() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "def cancel" "Should have cancel function"
}
run_test "has cancel function" test_has_cancel

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — CLI flags"

test_uses_dangerously_skip() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" \
        "dangerously-skip-permissions\|dangerously_skip" "Should use --dangerously-skip-permissions"
}
run_test "uses --dangerously-skip-permissions" test_uses_dangerously_skip

test_uses_print_flag() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" \
        "\-\-print\|print" "Should use --print flag"
}
run_test "uses --print flag" test_uses_print_flag

test_uses_json_output() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" \
        "output-format\|json" "Should use --output-format json"
}
run_test "uses JSON output format" test_uses_json_output

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — worktree support"

test_wrapper_has_worktree() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" \
        "worktree" "Should support worktree isolation"
}
run_test "supports worktree" test_wrapper_has_worktree

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — session recording"

test_records_session() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "sessions\|session" "Should record sessions"
}
run_test "records sessions" test_records_session

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — JSON parsing"

test_has_parse_output() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "parse_output\|parse_json" "Should have output parser"
}
run_test "has output parser" test_has_parse_output

test_parse_output_works() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.claude_code_wrapper import parse_output

# Simulate Claude Code JSON output
output = json.dumps({
    'type': 'result',
    'subtype': 'success',
    'result': 'Task completed successfully',
    'cost_usd': 0.05
})
parsed = parse_output(output)
assert parsed['status'] == 'success', f'Expected success, got {parsed}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse JSON output correctly"
}
run_test "JSON parsing works" test_parse_output_works

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — timeout handling"

test_has_timeout() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/claude_code_wrapper.py" \
        "timeout\|TIMEOUT" "Should handle timeouts"
}
run_test "has timeout handling" test_has_timeout

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — dispatch returns handle"

test_dispatch_returns_handle() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.claude_code_wrapper import ClaudeCodeWrapper

wrapper = ClaudeCodeWrapper(claude_cmd='echo')
handle = wrapper.dispatch(task_prompt='test task', work_dir='/tmp')
assert 'task_id' in handle, f'Handle should have task_id: {handle}'
assert 'status' in handle, f'Handle should have status: {handle}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "dispatch should return handle with task_id and status"
}
run_test "dispatch returns proper handle" test_dispatch_returns_handle

# ──────────────────────────────────────────────
describe "Claude Code Wrapper — shell script usage"

test_sh_shows_usage() {
    local output
    output=$(bash "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" 2>&1 || true)
    echo "$output" > "${TEST_DIR}/claude_code_wrapper_usage.txt"
    assert_file_contains "${TEST_DIR}/claude_code_wrapper_usage.txt" "Usage\|usage" \
        "Should show usage when called without args"
}
run_test "shows usage without args" test_sh_shows_usage

# ──────────────────────────────────────────────
print_summary
