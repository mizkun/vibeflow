#!/bin/bash

# VibeFlow Test: Issue 0-4 — Subagent 記述の整理 + legacy ロール削除
# README.md must not contain contradictory subagent statements.
# Legacy discussion-partner role files must not exist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
# Tests
# ──────────────────────────────────────────────

describe "Subagent cleanup — README contradictions removed"

test_readme_no_no_agent_files() {
    assert_file_not_contains "${FRAMEWORK_DIR}/README.md" "No Agent Files" \
        "README.md should not contain 'No Agent Files'"
}
run_test "README.md does not contain 'No Agent Files'" test_readme_no_no_agent_files

test_readme_no_subagents_deprecated() {
    assert_file_not_contains "${FRAMEWORK_DIR}/README.md" "Subagents are deprecated" \
        "README.md should not contain 'Subagents are deprecated'"
}
run_test "README.md does not contain 'Subagents are deprecated'" test_readme_no_subagents_deprecated

describe "Subagent cleanup — legacy role files deleted"

test_lib_discussion_partner_not_exists() {
    assert_file_not_exists "${FRAMEWORK_DIR}/lib/roles/discussion-partner.md" \
        "lib/roles/discussion-partner.md should not exist"
}
run_test "lib/roles/discussion-partner.md does not exist" test_lib_discussion_partner_not_exists

test_examples_discussion_partner_not_exists() {
    assert_file_not_exists "${FRAMEWORK_DIR}/examples/.vibe/roles/discussion-partner.md" \
        "examples/.vibe/roles/discussion-partner.md should not exist"
}
run_test "examples/.vibe/roles/discussion-partner.md does not exist" test_examples_discussion_partner_not_exists

describe "Subagent cleanup — README consistency"

test_readme_no_no_separate_agent_files() {
    assert_file_not_contains "${FRAMEWORK_DIR}/README.md" "No Separate Agent Files" \
        "README.md should not contain 'No Separate Agent Files'"
}
run_test "README.md does not contain 'No Separate Agent Files'" test_readme_no_no_separate_agent_files

test_readme_key_principles_mentions_subagents() {
    # v5 uses agents/ directory for sub-agents (code-reviewer, qa-acceptance, test-runner)
    if grep -q "agents/\|サブエージェント\|Coding Agent\|Agent Selection" "${FRAMEWORK_DIR}/README.md"; then
        return 0
    else
        fail "README.md Architecture should mention agents positively"
        return 1
    fi
}
run_test "README.md acknowledges agents in Architecture (v5)" test_readme_key_principles_mentions_subagents

# ──────────────────────────────────────────────
print_summary
