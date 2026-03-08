#!/bin/bash

# Test: Issue 0-3 — ローカル issues/ 参照の除去
# Verifies that non-legacy code no longer references local issues/ directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Issue 0-3: ローカル issues/ 参照の除去"
# ──────────────────────────────────────────────

test_no_issues_reference_in_create_subagents() {
    # create_subagents.sh should not contain issues/* or issues/*.md references
    if grep -q 'issues/\*' "$FRAMEWORK_DIR/lib/create_subagents.sh" 2>/dev/null; then
        fail "lib/create_subagents.sh still contains 'issues/*' reference"
        return 1
    fi
    if grep -q 'issues/\*\.md' "$FRAMEWORK_DIR/lib/create_subagents.sh" 2>/dev/null; then
        fail "lib/create_subagents.sh still contains 'issues/*.md' reference"
        return 1
    fi
    return 0
}

test_no_issues_reference_in_readme() {
    # README.md should not contain "or issues/" phrasing
    if grep -q 'or issues/' "$FRAMEWORK_DIR/README.md" 2>/dev/null; then
        fail "README.md still contains 'or issues/' reference"
        return 1
    fi
    return 0
}

test_migrate_issues_moved_to_legacy() {
    # migrate-issues.sh should NOT exist in examples/.vibe/tools/
    if [ -f "$FRAMEWORK_DIR/examples/.vibe/tools/migrate-issues.sh" ]; then
        fail "examples/.vibe/tools/migrate-issues.sh still exists (should be moved to legacy/)"
        return 1
    fi
    # migrate-issues.sh SHOULD exist in legacy/
    if [ ! -f "$FRAMEWORK_DIR/legacy/migrate-issues.sh" ]; then
        fail "legacy/migrate-issues.sh does not exist"
        return 1
    fi
    return 0
}

# ──────────────────────────────────────────────
# Run tests
# ──────────────────────────────────────────────

run_test "lib/create_subagents.sh に issues/* 参照がないこと" test_no_issues_reference_in_create_subagents
run_test "README.md に 'or issues/' 参照がないこと" test_no_issues_reference_in_readme
run_test "migrate-issues.sh が legacy/ に移動されていること" test_migrate_issues_moved_to_legacy

print_summary
