#!/bin/bash

# VibeFlow Test: Issue #71 — PostToolUse lint hook template
# Tests for examples/.vibe/hooks/postwrite_lint.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/postwrite_lint.sh"
SETTINGS="${FRAMEWORK_DIR}/examples/.claude/settings.json"

# ──────────────────────────────────────────────
describe "PostWrite Lint Hook — file existence and validity"

test_hook_exists() {
    assert_file_exists "$HOOK" "postwrite_lint.sh should exist"
}
run_test "postwrite_lint.sh exists" test_hook_exists

test_hook_is_valid_bash() {
    if ! bash -n "$HOOK" 2>/dev/null; then
        fail "postwrite_lint.sh has bash syntax errors"
        return 1
    fi
}
run_test "postwrite_lint.sh is valid bash" test_hook_is_valid_bash

test_hook_is_executable() {
    if [ ! -x "$HOOK" ]; then
        fail "postwrite_lint.sh should be executable"
        return 1
    fi
}
run_test "postwrite_lint.sh is executable" test_hook_is_executable

# ──────────────────────────────────────────────
describe "PostWrite Lint Hook — settings.json integration"

test_settings_has_postwrite_lint_entry() {
    assert_file_contains "$SETTINGS" "postwrite_lint.sh" \
        "settings.json should reference postwrite_lint.sh"
}
run_test "settings.json has postwrite_lint.sh entry" test_settings_has_postwrite_lint_entry

test_settings_has_write_edit_matcher() {
    # The new entry should match Write|Edit|MultiEdit
    if ! python3 -c "
import json, sys
with open('$SETTINGS') as f:
    data = json.load(f)
entries = data.get('hooks', {}).get('PostToolUse', [])
found = False
for entry in entries:
    if 'postwrite_lint' in json.dumps(entry):
        matcher = entry.get('matcher', '')
        if 'Write' in matcher and 'Edit' in matcher and 'MultiEdit' in matcher:
            found = True
            break
sys.exit(0 if found else 1)
" 2>/dev/null; then
        fail "PostToolUse entry for postwrite_lint should match Write|Edit|MultiEdit"
        return 1
    fi
}
run_test "PostToolUse entry has correct matcher" test_settings_has_write_edit_matcher

test_settings_still_has_task_complete() {
    assert_file_contains "$SETTINGS" "task_complete.sh" \
        "settings.json should still reference task_complete.sh"
}
run_test "settings.json still has task_complete.sh" test_settings_still_has_task_complete

test_settings_valid_json() {
    if ! python3 -c "import json; json.load(open('$SETTINGS'))" 2>/dev/null; then
        fail "settings.json is not valid JSON"
        return 1
    fi
}
run_test "settings.json is valid JSON" test_settings_valid_json

# ──────────────────────────────────────────────
describe "PostWrite Lint Hook — exits 0 when no linter available"

test_exit0_unknown_extension() {
    local payload='{"tool_name": "Write", "tool_input": {"file_path": "README.md"}}'
    setup_test_env
    # Create the file so it exists
    echo "# Hello" > "${TEST_DIR}/README.md"
    local exit_code=0
    echo "$payload" | CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
    teardown_test_env
    if [ "$exit_code" -ne 0 ]; then
        fail "Expected exit 0 for unknown extension (.md), got $exit_code"
        return 1
    fi
}
run_test "Exits 0 for unknown extension (.md)" test_exit0_unknown_extension

test_exit0_ts_no_linter() {
    local payload='{"tool_name": "Edit", "tool_input": {"file_path": "src/index.ts"}}'
    setup_test_env
    mkdir -p "${TEST_DIR}/src"
    echo "const x = 1;" > "${TEST_DIR}/src/index.ts"
    # Ensure npx is not in PATH for this test
    local exit_code=0
    echo "$payload" | CLAUDE_PROJECT_DIR="$TEST_DIR" PATH="/usr/bin:/bin" bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
    teardown_test_env
    if [ "$exit_code" -ne 0 ]; then
        fail "Expected exit 0 for .ts with no linter, got $exit_code"
        return 1
    fi
}
run_test "Exits 0 for .ts when no linter is available" test_exit0_ts_no_linter

# ──────────────────────────────────────────────
describe "PostWrite Lint Hook — handles missing/invalid input gracefully"

test_exit0_empty_stdin() {
    local exit_code=0
    echo "" | CLAUDE_PROJECT_DIR="/tmp" bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        fail "Expected exit 0 for empty stdin, got $exit_code"
        return 1
    fi
}
run_test "Exits 0 for empty stdin" test_exit0_empty_stdin

test_exit0_invalid_json() {
    local exit_code=0
    echo "not json" | CLAUDE_PROJECT_DIR="/tmp" bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        fail "Expected exit 0 for invalid JSON, got $exit_code"
        return 1
    fi
}
run_test "Exits 0 for invalid JSON input" test_exit0_invalid_json

test_exit0_missing_file_path() {
    local payload='{"tool_name": "Write", "tool_input": {}}'
    local exit_code=0
    echo "$payload" | CLAUDE_PROJECT_DIR="/tmp" bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        fail "Expected exit 0 for missing file_path, got $exit_code"
        return 1
    fi
}
run_test "Exits 0 when file_path is missing from JSON" test_exit0_missing_file_path

test_exit0_nonexistent_file() {
    local payload='{"tool_name": "Write", "tool_input": {"file_path": "nonexistent/file.ts"}}'
    local exit_code=0
    echo "$payload" | CLAUDE_PROJECT_DIR="/tmp" bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        fail "Expected exit 0 for nonexistent file, got $exit_code"
        return 1
    fi
}
run_test "Exits 0 when file does not exist" test_exit0_nonexistent_file

# ──────────────────────────────────────────────
describe "PostWrite Lint Hook — migration includes postwrite_lint.sh"

test_migration_includes_hook() {
    local migration="${FRAMEWORK_DIR}/migrations/v4.1.0_to_v5.0.0.sh"
    assert_file_contains "$migration" "postwrite_lint.sh" \
        "Migration script should include postwrite_lint.sh in hooks list"
}
run_test "Migration v4.1.0→v5.0.0 includes postwrite_lint.sh" test_migration_includes_hook

# ──────────────────────────────────────────────
print_summary
