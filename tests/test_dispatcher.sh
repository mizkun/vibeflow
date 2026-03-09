#!/bin/bash

# VibeFlow Test: v5 — Session Auto-Dispatch (Issue #62)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Dispatcher — module exists"

test_dispatcher_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "core/runtime/dispatcher.py must exist"
}
run_test "dispatcher.py exists" test_dispatcher_exists

# ──────────────────────────────────────────────
describe "Dispatcher — interface"

test_has_dispatch_issue() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "def dispatch_issue" "Should have dispatch_issue function"
}
run_test "has dispatch_issue function" test_has_dispatch_issue

test_has_generate_prompt() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "def generate_prompt" "Should have generate_prompt function"
}
run_test "has generate_prompt function" test_has_generate_prompt

# ──────────────────────────────────────────────
describe "Dispatcher — prompt generation"

test_prompt_includes_issue() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dispatcher import generate_prompt

issue = {
    'number': 42,
    'title': 'Add user login',
    'body': 'Implement login with email/password',
    'labels': ['type:dev'],
}
prompt = generate_prompt(issue, context={})
assert 'login' in prompt.lower(), f'Prompt should contain issue content: {prompt[:200]}'
assert '42' in prompt, f'Prompt should reference issue number: {prompt[:200]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Prompt should include issue content"
}
run_test "prompt includes issue content" test_prompt_includes_issue

# ──────────────────────────────────────────────
describe "Dispatcher — session tracking"

test_has_session_tracking() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "sessions\|session" "Should track sessions"
}
run_test "tracks sessions" test_has_session_tracking

# ──────────────────────────────────────────────
describe "Dispatcher — worktree isolation"

test_has_worktree() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "worktree" "Should support worktree isolation"
}
run_test "supports worktree isolation" test_has_worktree

# ──────────────────────────────────────────────
describe "Dispatcher — agent selection integration"

test_uses_agent_selector() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "select_agent\|agent_selector" "Should use agent selector"
}
run_test "uses agent selector" test_uses_agent_selector

# ──────────────────────────────────────────────
describe "Dispatcher — status reporting"

test_has_status() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dispatcher.py" \
        "status\|STATUS" "Should report status"
}
run_test "has status reporting" test_has_status

# ──────────────────────────────────────────────
describe "Dispatcher — dispatch returns handle"

test_dispatch_returns_handle() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dispatcher import dispatch_issue

issue = {
    'number': 42,
    'title': 'Add feature',
    'body': 'Description',
    'labels': ['type:dev'],
}
handle = dispatch_issue(issue, project_dir='/tmp', dry_run=True)
assert 'task_id' in handle, f'Should have task_id: {handle}'
assert 'agent' in handle, f'Should have agent: {handle}'
assert 'status' in handle, f'Should have status: {handle}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "dispatch_issue should return handle"
}
run_test "dispatch_issue returns handle" test_dispatch_returns_handle

# ──────────────────────────────────────────────
print_summary
