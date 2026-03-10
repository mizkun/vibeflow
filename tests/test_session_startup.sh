#!/bin/bash

# VibeFlow Test: Session Startup Routine (Issue #73)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

RULES_DIR="${FRAMEWORK_DIR}/examples/.claude/rules"
STARTUP_FILE="${RULES_DIR}/session-startup.md"

# ──────────────────────────────────────────────
describe "Session Startup — file exists"

test_startup_file_exists() {
    assert_file_exists "$STARTUP_FILE" \
        "session-startup.md must exist in examples/.claude/rules/"
}
run_test "session-startup.md exists" test_startup_file_exists

# ──────────────────────────────────────────────
describe "Session Startup — required sections"

test_has_git_status_check() {
    assert_file_contains "$STARTUP_FILE" \
        "git status" "Should reference git status check"
}
run_test "contains git status check" test_has_git_status_check

test_has_git_log_check() {
    assert_file_contains "$STARTUP_FILE" \
        "git log" "Should reference git log check"
}
run_test "contains git log check" test_has_git_log_check

test_has_state_yaml_check() {
    assert_file_contains "$STARTUP_FILE" \
        "state.yaml" "Should reference state.yaml check"
}
run_test "contains state.yaml check" test_has_state_yaml_check

test_has_test_check() {
    assert_file_contains "$STARTUP_FILE" \
        "テスト疎通" "Should reference test execution"
}
run_test "contains test execution section" test_has_test_check

test_has_status_md_check() {
    assert_file_contains "$STARTUP_FILE" \
        "STATUS.md" "Should reference STATUS.md check"
}
run_test "contains STATUS.md check" test_has_status_md_check

# ──────────────────────────────────────────────
describe "Session Startup — recovery table"

test_has_recovery_table() {
    assert_file_contains "$STARTUP_FILE" \
        "リカバリ手順" "Should contain recovery table"
}
run_test "contains recovery table" test_has_recovery_table

test_has_branch_creation_recovery() {
    assert_file_contains "$STARTUP_FILE" \
        "3_branch_creation" "Should have branch_creation recovery entry"
}
run_test "recovery covers branch_creation state" test_has_branch_creation_recovery

test_has_acceptance_test_recovery() {
    assert_file_contains "$STARTUP_FILE" \
        "7_acceptance_test" "Should have acceptance_test recovery entry"
}
run_test "recovery covers acceptance_test state" test_has_acceptance_test_recovery

test_has_merge_recovery() {
    assert_file_contains "$STARTUP_FILE" \
        "10_merge" "Should have merge recovery entry"
}
run_test "recovery covers merge state" test_has_merge_recovery

# ──────────────────────────────────────────────
describe "Session Startup — CLAUDE.md reference"

test_claude_md_references_startup() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "session-startup" "CLAUDE.md should reference session-startup"
}
run_test "CLAUDE.md references startup routine" test_claude_md_references_startup

# ──────────────────────────────────────────────
describe "Session Startup — migration glob coverage"

test_migration_glob_picks_up_file() {
    # The migration uses: ${FRAMEWORK}/examples/.claude/rules/*.md
    # Verify our file matches this glob
    local found=0
    for f in "${RULES_DIR}/"*.md; do
        [ -f "$f" ] || continue
        if [ "$(basename "$f")" = "session-startup.md" ]; then
            found=1
            break
        fi
    done
    assert_equals "1" "$found" "session-startup.md should be matched by *.md glob"
}
run_test "migration glob covers session-startup.md" test_migration_glob_picks_up_file

# ──────────────────────────────────────────────
print_summary
