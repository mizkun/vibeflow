#!/bin/bash

# VibeFlow Test: validate_step7a.py
# Tests the Step 7a guard hook that blocks gh pr create without QA checkpoint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK_SCRIPT="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py"

# ──────────────────────────────────────────────
# Helper: run hook with given JSON payload
# Returns exit code of the hook
# ──────────────────────────────────────────────
run_hook() {
    local json="$1"
    local project_dir="${2:-$TEST_DIR}"
    # Don't use set -e/+e here - run_test already disables errexit
    local rc=0
    echo "$json" | CLAUDE_PROJECT_DIR="$project_dir" python3 "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    return $rc
}

# ──────────────────────────────────────────────
# Helper: create state.yaml with current_issue
# ──────────────────────────────────────────────
create_state_with_issue() {
    local issue="${1:-null}"
    mkdir -p "${TEST_DIR}/.vibe"
    cat > "${TEST_DIR}/.vibe/state.yaml" << YAML
current_issue: ${issue}
current_role: "Engineer"
current_step: 7
phase: development
YAML
}

# ──────────────────────────────────────────────
# Helper: create checkpoint file with valid content
# ──────────────────────────────────────────────
create_checkpoint() {
    local issue="$1"
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "approved" > "${TEST_DIR}/.vibe/checkpoints/${issue}-qa-approved"
}

# ══════════════════════════════════════════════
# Tests: Core blocking logic
# ══════════════════════════════════════════════

describe "validate_step7a.py - gh pr create blocking"

# --- Test 1: Block gh pr create without checkpoint ---
test_block_pr_create_no_checkpoint() {
    create_state_with_issue '"#32"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat: add login\" --body \"...\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block (exit 2) when checkpoint missing"
}
run_test "blocks gh pr create when checkpoint is missing" test_block_pr_create_no_checkpoint

# --- Test 2: Allow gh pr create with checkpoint ---
test_allow_pr_create_with_checkpoint() {
    create_state_with_issue '"#32"'
    create_checkpoint "#32"

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat: add login\""}}'
    local rc=$?

    assert_equals "0" "$rc" "Should allow (exit 0) when checkpoint exists"
}
run_test "allows gh pr create when checkpoint exists" test_allow_pr_create_with_checkpoint

# --- Test 3: Non-pr-create commands pass through ---
test_allow_other_commands() {
    create_state_with_issue '"#32"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"npm test"}}'
    local rc=$?

    assert_equals "0" "$rc" "Should allow non-pr-create commands"
}
run_test "allows non-pr-create bash commands" test_allow_other_commands

# --- Test 4: Non-Bash tools pass through ---
test_allow_non_bash_tools() {
    create_state_with_issue '"#32"'

    run_hook '{"tool_name":"Edit","tool_input":{"file_path":"src/index.ts"}}'
    local rc=$?

    assert_equals "0" "$rc" "Should allow non-Bash tools"
}
run_test "allows non-Bash tools" test_allow_non_bash_tools

# --- Test 5: Invalid JSON passes through ---
test_allow_invalid_json() {
    run_hook 'not-valid-json'
    local rc=$?

    assert_equals "0" "$rc" "Should pass through on invalid JSON"
}
run_test "passes through on invalid JSON input" test_allow_invalid_json

# --- Test 6: current_issue is null → pass through ---
test_allow_null_issue() {
    create_state_with_issue "null"

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"test\""}}'
    local rc=$?

    assert_equals "0" "$rc" "Should pass through when current_issue is null"
}
run_test "passes through when current_issue is null" test_allow_null_issue

# --- Test 7: qa:auto checkpoint ---
test_qa_auto_label_bypass() {
    create_state_with_issue '"#32"'
    # Simulate: create checkpoint with qa:auto content (what qa:auto would do)
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "auto-approved:qa:auto" > "${TEST_DIR}/.vibe/checkpoints/#32-qa-approved"

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"refactor: cleanup\""}}'
    local rc=$?

    assert_equals "0" "$rc" "Should allow when qa:auto checkpoint exists"
}
run_test "allows gh pr create when qa:auto checkpoint exists" test_qa_auto_label_bypass

# --- Test 8: gh pr create embedded in piped command ---
test_block_piped_pr_create() {
    create_state_with_issue '"#32"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"echo test && gh pr create --title \"feat\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block gh pr create even in piped commands"
}
run_test "blocks gh pr create in piped/chained commands" test_block_piped_pr_create

# --- Test 9: state.yaml missing → pass through ---
test_allow_missing_state() {
    # Don't create state.yaml
    mkdir -p "${TEST_DIR}/.vibe"

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"test\""}}'
    local rc=$?

    assert_equals "0" "$rc" "Should pass through when state.yaml is missing"
}
run_test "passes through when state.yaml is missing" test_allow_missing_state

# --- Test 10: Issue number without # prefix ---
test_block_issue_without_hash() {
    create_state_with_issue '"32"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block even when issue number lacks # prefix"
}
run_test "blocks when issue number lacks # prefix" test_block_issue_without_hash

# --- Test 10b: Allow with checkpoint matching non-hash issue ---
test_allow_issue_without_hash_with_checkpoint() {
    create_state_with_issue '"32"'
    create_checkpoint "32"

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'
    local rc=$?

    assert_equals "0" "$rc" "Should allow with checkpoint matching non-hash issue"
}
run_test "allows with checkpoint for issue without # prefix" test_allow_issue_without_hash_with_checkpoint

# ══════════════════════════════════════════════
# Tests: Security hardening
# ══════════════════════════════════════════════

describe "validate_step7a.py - security: input validation"

# --- Test 11: Path traversal in issue number → block ---
test_block_path_traversal() {
    create_state_with_issue '"../../../tmp/evil"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"hack\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block path traversal in issue number"
}
run_test "blocks path traversal in issue number" test_block_path_traversal

# --- Test 12: Shell metacharacters in issue → block ---
test_block_shell_injection() {
    create_state_with_issue '"32; rm -rf /"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"hack\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block shell metacharacters in issue number"
}
run_test "blocks shell metacharacters in issue number" test_block_shell_injection

# --- Test 13: Empty checkpoint file → block ---
test_block_empty_checkpoint() {
    create_state_with_issue '"#32"'
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    touch "${TEST_DIR}/.vibe/checkpoints/#32-qa-approved"  # empty file

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block when checkpoint file is empty"
}
run_test "blocks when checkpoint file is empty" test_block_empty_checkpoint

# --- Test 14: Checkpoint with garbage content → block ---
test_block_garbage_checkpoint() {
    create_state_with_issue '"#32"'
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "hacked-bypass" > "${TEST_DIR}/.vibe/checkpoints/#32-qa-approved"

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block when checkpoint has invalid content"
}
run_test "blocks when checkpoint has invalid content" test_block_garbage_checkpoint

# --- Test 15: Issue with spaces → block ---
test_block_spaces_in_issue() {
    create_state_with_issue '"32 extra stuff"'

    run_hook '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'
    local rc=$?

    assert_equals "2" "$rc" "Should block issue number with spaces"
}
run_test "blocks issue number with spaces" test_block_spaces_in_issue

# ──────────────────────────────────────────────
print_summary
