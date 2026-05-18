#!/bin/bash

# VibeFlow Test: .claude/worktrees/ must be git-ignored
# Session-scoped worktrees must not show up as untracked / dirty-tree noise.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "worktrees gitignore — framework repo"

test_root_gitignore_ignores_worktrees() {
    assert_file_contains "${FRAMEWORK_DIR}/.gitignore" ".claude/worktrees/" \
        "root .gitignore should ignore .claude/worktrees/"
}
run_test "root .gitignore ignores .claude/worktrees/" test_root_gitignore_ignores_worktrees

# ──────────────────────────────────────────────
describe "worktrees gitignore — generated project .gitignore"

test_create_structure_ignores_worktrees() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_structure.sh" ".claude/worktrees/" \
        "lib/create_structure.sh should add .claude/worktrees/ to the generated .gitignore"
}
run_test "create_structure.sh adds .claude/worktrees/ to project .gitignore" \
    test_create_structure_ignores_worktrees

# ──────────────────────────────────────────────
print_summary
