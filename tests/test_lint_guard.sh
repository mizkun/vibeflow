#!/bin/bash

# VibeFlow Test: Issue #70 — LintGuard: Block Coding Agent from editing linter configs
# validate_access.py must block Coding Agent from editing linter/formatter config files
# with a specific LintGuard message.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py"

# Helper: invoke validate_access.py with given role and file path
# Captures stderr and exit code
run_hook_capture() {
    local role="$1"
    local file_path="$2"
    local tool_name="${3:-Edit}"

    setup_test_env

    # Create state.yaml with the given role
    mkdir -p "${TEST_DIR}/.vibe"
    cat > "${TEST_DIR}/.vibe/state.yaml" <<YAML
current_role: "${role}"
YAML

    local payload
    payload=$(cat <<JSON
{"tool_name": "${tool_name}", "tool_input": {"file_path": "${file_path}"}}
JSON
)

    HOOK_STDERR=""
    HOOK_EXIT=0
    HOOK_STDERR=$(echo "$payload" | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK" 2>&1) || HOOK_EXIT=$?

    teardown_test_env
}

# ──────────────────────────────────────────────
describe "LintGuard — Coding Agent blocked from linter configs with LintGuard message"

test_coding_agent_blocked_eslintrc() {
    run_hook_capture "Coding Agent (Claude Code / Codex)" ".eslintrc.json"
    if [ "$HOOK_EXIT" -ne 2 ]; then
        fail "Expected exit code 2 (blocked) but got $HOOK_EXIT"
        return 1
    fi
    if ! echo "$HOOK_STDERR" | grep -q "LintGuard"; then
        fail "Expected LintGuard message in stderr, got: $HOOK_STDERR"
        return 1
    fi
}
run_test "Coding Agent blocked from .eslintrc.json with LintGuard" test_coding_agent_blocked_eslintrc

test_coding_agent_blocked_pyproject() {
    run_hook_capture "Coding Agent (Claude Code / Codex)" "pyproject.toml"
    if [ "$HOOK_EXIT" -ne 2 ]; then
        fail "Expected exit code 2 (blocked) but got $HOOK_EXIT"
        return 1
    fi
    if ! echo "$HOOK_STDERR" | grep -q "LintGuard"; then
        fail "Expected LintGuard message in stderr, got: $HOOK_STDERR"
        return 1
    fi
}
run_test "Coding Agent blocked from pyproject.toml with LintGuard" test_coding_agent_blocked_pyproject

test_coding_agent_blocked_tsconfig() {
    run_hook_capture "Coding Agent (Claude Code / Codex)" "tsconfig.json"
    if [ "$HOOK_EXIT" -ne 2 ]; then
        fail "Expected exit code 2 (blocked) but got $HOOK_EXIT"
        return 1
    fi
    if ! echo "$HOOK_STDERR" | grep -q "LintGuard"; then
        fail "Expected LintGuard message in stderr, got: $HOOK_STDERR"
        return 1
    fi
}
run_test "Coding Agent blocked from tsconfig.json with LintGuard" test_coding_agent_blocked_tsconfig

# ──────────────────────────────────────────────
describe "LintGuard — Iris is NOT blocked by LintGuard"

test_iris_no_lintguard_eslintrc() {
    run_hook_capture "Iris" ".eslintrc.json"
    # Iris may or may not be blocked by role-based check, but NOT by LintGuard
    if echo "$HOOK_STDERR" | grep -q "LintGuard"; then
        fail "Iris should NOT get LintGuard message for .eslintrc.json"
        return 1
    fi
}
run_test "Iris does NOT get LintGuard block for .eslintrc.json" test_iris_no_lintguard_eslintrc

test_iris_no_lintguard_pyproject() {
    run_hook_capture "Iris" "pyproject.toml"
    if echo "$HOOK_STDERR" | grep -q "LintGuard"; then
        fail "Iris should NOT get LintGuard message for pyproject.toml"
        return 1
    fi
}
run_test "Iris does NOT get LintGuard block for pyproject.toml" test_iris_no_lintguard_pyproject

test_iris_no_lintguard_tsconfig() {
    run_hook_capture "Iris" "tsconfig.json"
    if echo "$HOOK_STDERR" | grep -q "LintGuard"; then
        fail "Iris should NOT get LintGuard message for tsconfig.json"
        return 1
    fi
}
run_test "Iris does NOT get LintGuard block for tsconfig.json" test_iris_no_lintguard_tsconfig

# ──────────────────────────────────────────────
describe "LintGuard — Coding Agent can still edit src/ files (regression)"

test_coding_agent_allowed_src() {
    run_hook_capture "Coding Agent (Claude Code / Codex)" "src/index.ts"
    if [ "$HOOK_EXIT" -ne 0 ]; then
        fail "Coding Agent should be allowed to edit src/index.ts (exit=$HOOK_EXIT)"
        return 1
    fi
}
run_test "Coding Agent allowed to edit src/index.ts" test_coding_agent_allowed_src

# ──────────────────────────────────────────────
print_summary
