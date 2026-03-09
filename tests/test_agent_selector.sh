#!/bin/bash

# VibeFlow Test: v5 — Agent Selection Logic (Issue #56)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Agent Selector — module exists"

test_selector_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/agent_selector.py" \
        "core/runtime/agent_selector.py must exist"
}
run_test "agent_selector.py exists" test_selector_exists

# ──────────────────────────────────────────────
describe "Agent Selector — interface"

test_has_select_agent() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/agent_selector.py" \
        "def select_agent" "Should have select_agent function"
}
run_test "has select_agent function" test_has_select_agent

# ──────────────────────────────────────────────
describe "Agent Selector — default is Codex"

test_default_codex() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({'title': 'Add API endpoint', 'labels': ['type:dev']})
assert result['agent'] == 'codex', f'Default should be codex, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Default agent should be codex"
}
run_test "default agent is codex" test_default_codex

# ──────────────────────────────────────────────
describe "Agent Selector — Claude Code for MCP"

test_mcp_uses_claude() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({
    'title': 'Fix UI component',
    'labels': ['type:dev'],
    'requires_mcp': True
})
assert result['agent'] == 'claude_code', f'MCP tasks should use claude_code, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "MCP tasks should use claude_code"
}
run_test "MCP tasks use claude_code" test_mcp_uses_claude

# ──────────────────────────────────────────────
describe "Agent Selector — Claude Code for Playwright"

test_playwright_uses_claude() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({
    'title': 'E2E test for dashboard',
    'labels': ['type:dev'],
    'requires_playwright': True
})
assert result['agent'] == 'claude_code', f'Playwright tasks should use claude_code, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Playwright tasks should use claude_code"
}
run_test "Playwright tasks use claude_code" test_playwright_uses_claude

# ──────────────────────────────────────────────
describe "Agent Selector — Claude Code for local FS"

test_local_fs_uses_claude() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({
    'title': 'Read local config',
    'labels': ['type:dev'],
    'requires_local_fs': True
})
assert result['agent'] == 'claude_code', f'Local FS tasks should use claude_code, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Local FS tasks should use claude_code"
}
run_test "local FS tasks use claude_code" test_local_fs_uses_claude

# ──────────────────────────────────────────────
describe "Agent Selector — user override"

test_user_override() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent(
    {'title': 'Normal task', 'labels': ['type:dev']},
    user_preference='claude_code'
)
assert result['agent'] == 'claude_code', f'User override should work, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "User preference should override default"
}
run_test "user preference overrides default" test_user_override

# ──────────────────────────────────────────────
describe "Agent Selector — fallback on failure"

test_fallback_on_failure() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent(
    {'title': 'Task', 'labels': ['type:dev']},
    codex_failures=2
)
assert result['agent'] == 'claude_code', f'Should fallback after 2 failures, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should fallback to claude_code after 2 codex failures"
}
run_test "fallback after 2 codex failures" test_fallback_on_failure

# ──────────────────────────────────────────────
describe "Agent Selector — reason provided"

test_provides_reason() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({'title': 'Task', 'labels': ['type:dev']})
assert 'reason' in result, f'Should provide reason: {result}'
assert len(result['reason']) > 0, 'Reason should not be empty'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Selection should include a reason"
}
run_test "provides selection reason" test_provides_reason

# ──────────────────────────────────────────────
print_summary
