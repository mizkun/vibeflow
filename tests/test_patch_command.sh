#!/bin/bash

# VibeFlow Test: Phase 2 — /patch command + /quickfix alias (Issue 2-4)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "/patch command — file exists"

test_patch_md_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/lib/commands/patch.md" \
        "lib/commands/patch.md must exist"
}
run_test "patch.md exists" test_patch_md_exists

# ──────────────────────────────────────────────
describe "/patch command — content"

test_patch_has_parent_issue_required() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/patch.md" \
        "親 Issue" "patch.md should mention parent Issue requirement"
}
run_test "patch.md states parent Issue is required" test_patch_has_parent_issue_required

test_patch_has_target_tests_required() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/patch.md" \
        "テスト" "patch.md should mention target tests requirement"
}
run_test "patch.md states target tests are required" test_patch_has_target_tests_required

test_patch_has_escalation_guidance() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/patch.md" \
        "Standard" "patch.md should mention escalation to Standard Issue"
}
run_test "patch.md mentions Standard Issue escalation" test_patch_has_escalation_guidance

test_patch_has_usage() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/patch.md" \
        "/patch" "patch.md should show usage"
}
run_test "patch.md has usage example" test_patch_has_usage

test_patch_has_scope_review() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/patch.md" \
        "Scope" "patch.md should include scope review step"
}
run_test "patch.md has scope review step" test_patch_has_scope_review

# ──────────────────────────────────────────────
describe "/quickfix alias — updated content"

test_quickfix_is_alias() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/quickfix.md" \
        "alias" "quickfix.md should indicate it's an alias"
}
run_test "quickfix.md is marked as alias" test_quickfix_is_alias

test_quickfix_points_to_patch() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/quickfix.md" \
        "/patch" "quickfix.md should reference /patch"
}
run_test "quickfix.md references /patch" test_quickfix_points_to_patch

test_quickfix_requires_parent_issue() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/quickfix.md" \
        "親 Issue" "quickfix.md should require parent Issue"
}
run_test "quickfix.md requires parent Issue" test_quickfix_requires_parent_issue

# ──────────────────────────────────────────────
describe "CLAUDE.md — /patch integration"

test_claude_md_has_patch_command() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "/patch" "CLAUDE.md should list /patch command"
}
run_test "CLAUDE.md lists /patch" test_claude_md_has_patch_command

test_claude_md_quickfix_is_alias() {
    # v5 removed /quickfix from CLAUDE.md; verify /patch is listed as the command
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "/patch" "CLAUDE.md should list /patch command"
}
run_test "CLAUDE.md lists /patch command (v5)" test_claude_md_quickfix_is_alias

test_claude_md_patch_loop_section() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "Patch Loop" "CLAUDE.md should have Patch Loop section"
}
run_test "CLAUDE.md has Patch Loop section" test_claude_md_patch_loop_section

test_claude_md_patch_parent_issue() {
    # v5 moved detailed patch rules to rules/workflow-patch.md
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/workflow-patch.md" \
        "親 Issue" "workflow-patch.md should mention parent Issue requirement"
}
run_test "Patch workflow rules mention parent Issue (v5)" test_claude_md_patch_parent_issue

# ──────────────────────────────────────────────
describe "Consistency — patch.md and CLAUDE.md alignment"

test_patch_workflow_steps_in_claude_md() {
    # CLAUDE.md Patch Loop section should have the 4 steps
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "scope_review" "CLAUDE.md should mention scope_review step"
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "fix_implementation" "CLAUDE.md should mention fix_implementation step"
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "targeted_test" "CLAUDE.md should mention targeted_test step"
}
run_test "CLAUDE.md has Patch Loop workflow steps" test_patch_workflow_steps_in_claude_md

test_no_standalone_quickfix_promotion() {
    # CLAUDE.md should NOT promote standalone quickfix (without parent Issue)
    assert_file_not_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "Issue 不要" "CLAUDE.md should not say Issue is not required for Patch Loop"
}
run_test "CLAUDE.md does not promote standalone quickfix" test_no_standalone_quickfix_promotion

# ──────────────────────────────────────────────
print_summary
