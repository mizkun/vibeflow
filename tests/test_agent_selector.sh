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
describe "Agent Selector — default is Claude Code"

test_default_claude_code() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({'title': 'Add API endpoint', 'labels': ['type:dev']})
assert result['agent'] == 'claude_code', f'Default should be claude_code, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Default agent should be claude_code"
}
run_test "default agent is claude_code" test_default_claude_code

# ──────────────────────────────────────────────
describe "Agent Selector — Codex for sandbox"

test_sandbox_uses_codex() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.agent_selector import select_agent

result = select_agent({
    'title': 'Run isolated task',
    'labels': ['type:dev'],
    'requires_sandbox': True
})
assert result['agent'] == 'codex', f'Sandbox tasks should use codex, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Sandbox tasks should use codex"
}
run_test "sandbox tasks use codex" test_sandbox_uses_codex

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
    user_preference='codex'
)
assert result['agent'] == 'codex', f'User override should work, got {result[\"agent\"]}'
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
    claude_code_failures=2
)
assert result['agent'] == 'codex', f'Should fallback after 2 failures, got {result[\"agent\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should fallback to codex after 2 claude_code failures"
}
run_test "fallback after 2 claude_code failures" test_fallback_on_failure

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
