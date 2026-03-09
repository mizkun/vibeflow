#!/bin/bash

# VibeFlow Test: v5 — Codex CLI Wrapper (Issue #53)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Codex Wrapper — module exists"

test_wrapper_py_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "core/runtime/codex_wrapper.py must exist"
}
run_test "codex_wrapper.py exists" test_wrapper_py_exists

test_wrapper_sh_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/lib/wrappers/codex.sh" \
        "lib/wrappers/codex.sh must exist"
}
run_test "lib/wrappers/codex.sh exists" test_wrapper_sh_exists

test_wrapper_sh_executable() {
    [ -x "${FRAMEWORK_DIR}/lib/wrappers/codex.sh" ]
    assert_equals "0" "$?" "codex.sh should be executable"
}
run_test "codex.sh is executable" test_wrapper_sh_executable

# ──────────────────────────────────────────────
describe "Codex Wrapper — Python interface"

test_has_dispatch() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "def dispatch" "Should have dispatch function"
}
run_test "has dispatch function" test_has_dispatch

test_has_poll() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "def poll" "Should have poll function"
}
run_test "has poll function" test_has_poll

test_has_collect() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "def collect" "Should have collect function"
}
run_test "has collect function" test_has_collect

test_has_cancel() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "def cancel" "Should have cancel function"
}
run_test "has cancel function" test_has_cancel

# ──────────────────────────────────────────────
describe "Codex Wrapper — full-auto and json flags"

test_uses_full_auto() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/codex.sh" \
        "full-auto\|full_auto\|FULL_AUTO" "Should use --full-auto mode"
}
run_test "uses --full-auto mode" test_uses_full_auto

test_uses_json_output() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/codex.sh" \
        "\-\-json\|json" "Should use --json output"
}
run_test "uses JSON output" test_uses_json_output

# ──────────────────────────────────────────────
describe "Codex Wrapper — worktree support"

test_wrapper_has_worktree() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/wrappers/codex.sh" \
        "worktree" "Should support worktree isolation"
}
run_test "supports worktree" test_wrapper_has_worktree

# ──────────────────────────────────────────────
describe "Codex Wrapper — session recording"

test_records_session() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "sessions\|session" "Should record sessions"
}
run_test "records sessions" test_records_session

# ──────────────────────────────────────────────
describe "Codex Wrapper — JSONL parsing"

test_has_parse_jsonl() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "parse_jsonl\|parse_output" "Should have JSONL parser"
}
run_test "has JSONL parser" test_has_parse_jsonl

test_parse_jsonl_works() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_wrapper import parse_output

# Simulate JSONL output
lines = [
    '{\"type\": \"message\", \"content\": \"Working on task...\"}',
    '{\"type\": \"result\", \"status\": \"success\", \"summary\": \"Done\"}'
]
parsed = parse_output('\n'.join(lines))
assert parsed['status'] == 'success', f'Expected success, got {parsed}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse JSONL output correctly"
}
run_test "JSONL parsing works" test_parse_jsonl_works

# ──────────────────────────────────────────────
describe "Codex Wrapper — timeout handling"

test_has_timeout() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_wrapper.py" \
        "timeout\|TIMEOUT" "Should handle timeouts"
}
run_test "has timeout handling" test_has_timeout

# ──────────────────────────────────────────────
describe "Codex Wrapper — error handling"

test_dispatch_returns_handle() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_wrapper import CodexWrapper

wrapper = CodexWrapper(codex_cmd='echo')
handle = wrapper.dispatch(task_prompt='test task', work_dir='/tmp')
assert 'task_id' in handle, f'Handle should have task_id: {handle}'
assert 'status' in handle, f'Handle should have status: {handle}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "dispatch should return handle with task_id and status"
}
run_test "dispatch returns proper handle" test_dispatch_returns_handle

# ──────────────────────────────────────────────
describe "Codex Wrapper — shell script usage"

test_sh_shows_usage() {
    local output
    output=$(bash "${FRAMEWORK_DIR}/lib/wrappers/codex.sh" 2>&1 || true)
    echo "$output" > "${TEST_DIR}/codex_wrapper_usage.txt"
    assert_file_contains "${TEST_DIR}/codex_wrapper_usage.txt" "Usage\|usage" \
        "Should show usage when called without args"
}
run_test "shows usage without args" test_sh_shows_usage

# ──────────────────────────────────────────────
print_summary
