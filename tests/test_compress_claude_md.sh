#!/bin/bash

# VibeFlow Test: v5 — Compress CLAUDE.md to ~50 lines (Issue #69)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

CLAUDE_MD="${FRAMEWORK_DIR}/examples/CLAUDE.md"
RULES_DIR="${FRAMEWORK_DIR}/examples/.claude/rules"

# ──────────────────────────────────────────────
describe "Compressed CLAUDE.md — line count"

test_claude_md_around_50_lines() {
    local line_count
    line_count=$(wc -l < "$CLAUDE_MD")
    [ "$line_count" -le 60 ]
    assert_equals "0" "$?" "CLAUDE.md should be ≤60 lines (got $line_count)"
}
run_test "CLAUDE.md is ~50 lines (≤60)" test_claude_md_around_50_lines

test_claude_md_at_least_40_lines() {
    local line_count
    line_count=$(wc -l < "$CLAUDE_MD")
    [ "$line_count" -ge 40 ]
    assert_equals "0" "$?" "CLAUDE.md should be ≥40 lines (got $line_count)"
}
run_test "CLAUDE.md is ≥40 lines" test_claude_md_at_least_40_lines

# ──────────────────────────────────────────────
describe "Compressed CLAUDE.md — required sections kept"

test_has_roles_markers() {
    assert_file_contains "$CLAUDE_MD" "VF:BEGIN roles" \
        "CLAUDE.md must keep VF:BEGIN roles marker"
    assert_file_contains "$CLAUDE_MD" "VF:END roles" \
        "CLAUDE.md must keep VF:END roles marker"
}
run_test "VF:BEGIN/END roles markers preserved" test_has_roles_markers

test_has_architecture() {
    assert_file_contains "$CLAUDE_MD" "## Architecture" \
        "CLAUDE.md should have Architecture section"
}
run_test "Architecture section exists" test_has_architecture

test_has_commands() {
    assert_file_contains "$CLAUDE_MD" "/execute-issue" \
        "CLAUDE.md should list /execute-issue command"
    assert_file_contains "$CLAUDE_MD" "/patch" \
        "CLAUDE.md should list /patch command"
}
run_test "Commands listed" test_has_commands

test_has_critical_rules() {
    assert_file_contains "$CLAUDE_MD" "Critical Rules" \
        "CLAUDE.md should have Critical Rules section"
    assert_file_contains "$CLAUDE_MD" "TDD" \
        "CLAUDE.md should mention TDD"
}
run_test "Critical Rules section exists" test_has_critical_rules

test_has_language_directive() {
    assert_file_contains "$CLAUDE_MD" "Japanese\|日本語" \
        "CLAUDE.md should have language directive"
}
run_test "Language directive present" test_has_language_directive

test_has_rules_pointer() {
    assert_file_contains "$CLAUDE_MD" "rules/" \
        "CLAUDE.md should point to rules/ directory"
}
run_test "Points to rules/ for details" test_has_rules_pointer

test_has_build_test_commands() {
    assert_file_contains "$CLAUDE_MD" "npm test\|playwright" \
        "CLAUDE.md should have build/test commands"
}
run_test "Build/test commands present" test_has_build_test_commands

# ──────────────────────────────────────────────
describe "Compressed CLAUDE.md — removed sections"

test_no_workflow_markers() {
    assert_file_not_contains "$CLAUDE_MD" "VF:BEGIN workflow" \
        "CLAUDE.md should NOT have VF:BEGIN workflow (moved to rules/)"
    assert_file_not_contains "$CLAUDE_MD" "VF:END workflow" \
        "CLAUDE.md should NOT have VF:END workflow"
}
run_test "No VF:BEGIN/END workflow markers" test_no_workflow_markers

test_no_hook_list_markers() {
    assert_file_not_contains "$CLAUDE_MD" "VF:BEGIN hook_list" \
        "CLAUDE.md should NOT have VF:BEGIN hook_list (moved to settings.json)"
    assert_file_not_contains "$CLAUDE_MD" "VF:END hook_list" \
        "CLAUDE.md should NOT have VF:END hook_list"
}
run_test "No VF:BEGIN/END hook_list markers" test_no_hook_list_markers

test_no_issue_labels_detail() {
    assert_file_not_contains "$CLAUDE_MD" "### Type Labels" \
        "Detailed Type Labels should be in rules/project-structure.md"
    assert_file_not_contains "$CLAUDE_MD" "### Risk Labels" \
        "Detailed Risk Labels should be in rules/project-structure.md"
    assert_file_not_contains "$CLAUDE_MD" "### QA Labels" \
        "Detailed QA Labels should be in rules/project-structure.md"
}
run_test "No detailed Issue Labels (moved to rules/)" test_no_issue_labels_detail

test_no_3tier_context() {
    assert_file_not_contains "$CLAUDE_MD" "3-Tier Context" \
        "3-Tier Context should be in rules/project-structure.md"
    assert_file_not_contains "$CLAUDE_MD" "Tier 1:" \
        "Tier details should be in rules/project-structure.md"
}
run_test "No 3-Tier Context (moved to rules/)" test_no_3tier_context

test_no_subagents_detail() {
    assert_file_not_contains "$CLAUDE_MD" "## Subagents" \
        "Subagents section header should be in rules/project-structure.md"
}
run_test "No Subagents section (moved to rules/)" test_no_subagents_detail

# ──────────────────────────────────────────────
describe "New rules files — project-structure.md"

test_project_structure_exists() {
    assert_file_exists "${RULES_DIR}/project-structure.md" \
        "project-structure.md must exist"
}
run_test "project-structure.md exists" test_project_structure_exists

test_project_structure_has_labels() {
    assert_file_contains "${RULES_DIR}/project-structure.md" "type:dev" \
        "project-structure.md should have type:dev label"
    assert_file_contains "${RULES_DIR}/project-structure.md" "risk:medium" \
        "project-structure.md should have risk:medium label"
    assert_file_contains "${RULES_DIR}/project-structure.md" "qa:auto" \
        "project-structure.md should have qa:auto label"
}
run_test "project-structure.md has issue labels" test_project_structure_has_labels

test_project_structure_has_3tier() {
    assert_file_contains "${RULES_DIR}/project-structure.md" "3-Tier\|context\|STATUS.md" \
        "project-structure.md should have 3-Tier Context info"
}
run_test "project-structure.md has 3-Tier Context" test_project_structure_has_3tier

test_project_structure_has_subagents() {
    assert_file_contains "${RULES_DIR}/project-structure.md" "qa-acceptance" \
        "project-structure.md should list qa-acceptance subagent"
    assert_file_contains "${RULES_DIR}/project-structure.md" "code-reviewer" \
        "project-structure.md should list code-reviewer subagent"
    assert_file_contains "${RULES_DIR}/project-structure.md" "test-runner" \
        "project-structure.md should list test-runner subagent"
}
run_test "project-structure.md has subagents" test_project_structure_has_subagents

# ──────────────────────────────────────────────
describe "New rules files — workflows.md"

test_workflows_exists() {
    assert_file_exists "${RULES_DIR}/workflows.md" \
        "workflows.md must exist"
}
run_test "workflows.md exists" test_workflows_exists

test_workflows_points_to_standard() {
    assert_file_contains "${RULES_DIR}/workflows.md" "workflow-standard.md" \
        "workflows.md should point to workflow-standard.md"
}
run_test "workflows.md points to workflow-standard.md" test_workflows_points_to_standard

test_workflows_points_to_patch() {
    assert_file_contains "${RULES_DIR}/workflows.md" "workflow-patch.md" \
        "workflows.md should point to workflow-patch.md"
}
run_test "workflows.md points to workflow-patch.md" test_workflows_points_to_patch

test_workflows_has_spike() {
    assert_file_contains "${RULES_DIR}/workflows.md" "Spike" \
        "workflows.md should contain Spike workflow"
    assert_file_contains "${RULES_DIR}/workflows.md" "question_framing\|exploration\|decision_summary" \
        "workflows.md should have Spike steps"
}
run_test "workflows.md has Spike workflow" test_workflows_has_spike

test_workflows_has_ops() {
    assert_file_contains "${RULES_DIR}/workflows.md" "Ops" \
        "workflows.md should contain Ops workflow"
    assert_file_contains "${RULES_DIR}/workflows.md" "task_review\|execution\|completion" \
        "workflows.md should have Ops steps"
}
run_test "workflows.md has Ops workflow" test_workflows_has_ops

# ──────────────────────────────────────────────
print_summary
