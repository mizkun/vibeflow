#!/bin/bash

# VibeFlow Migration Test: v2.0.0 -> v3.0.0
# TDD: These tests define the expected behavior of the v3 migration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

echo "╔════════════════════════════════════════╗"
echo "║  VibeFlow v2→v3 Migration Tests        ║"
echo "╚════════════════════════════════════════╝"

# ──────────────────────────────────────────────
# Test: Directory structure
# ──────────────────────────────────────────────

describe "Directory Structure"

test_creates_context_dir() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_dir_exists ".vibe/context" || return 1
}
run_test "creates .vibe/context/ directory" test_creates_context_dir

test_creates_references_dir() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_dir_exists ".vibe/references" || return 1
}
run_test "creates .vibe/references/ directory" test_creates_references_dir

test_creates_archive_dir() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_dir_exists ".vibe/archive" || return 1
}
run_test "creates .vibe/archive/ directory" test_creates_archive_dir

test_creates_github_issue_templates_dir() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_dir_exists ".github/ISSUE_TEMPLATE" || return 1
}
run_test "creates .github/ISSUE_TEMPLATE/ directory" test_creates_github_issue_templates_dir

# ──────────────────────────────────────────────
# Test: STATUS.md
# ──────────────────────────────────────────────

describe "STATUS.md Template"

test_creates_status_md() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".vibe/context/STATUS.md" || return 1
}
run_test "creates .vibe/context/STATUS.md" test_creates_status_md

test_status_md_has_sections() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains ".vibe/context/STATUS.md" "Current Focus" || return 1
    assert_file_contains ".vibe/context/STATUS.md" "Active Issues" || return 1
    assert_file_contains ".vibe/context/STATUS.md" "Recent Decisions" || return 1
}
run_test "STATUS.md has required sections" test_status_md_has_sections

# ──────────────────────────────────────────────
# Test: GitHub Issue Templates
# ──────────────────────────────────────────────

describe "GitHub Issue Templates"

test_creates_dev_template() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".github/ISSUE_TEMPLATE/dev.md" || return 1
}
run_test "creates dev.md issue template" test_creates_dev_template

test_creates_human_template() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".github/ISSUE_TEMPLATE/human.md" || return 1
}
run_test "creates human.md issue template" test_creates_human_template

test_creates_discussion_template() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".github/ISSUE_TEMPLATE/discussion.md" || return 1
}
run_test "creates discussion.md issue template" test_creates_discussion_template

# ──────────────────────────────────────────────
# Test: Role migration
# ──────────────────────────────────────────────

describe "Role Migration"

test_creates_project_partner_role() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".vibe/roles/project-partner.md" || return 1
}
run_test "creates project-partner.md role doc" test_creates_project_partner_role

test_removes_discussion_partner_role() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_exists ".vibe/roles/discussion-partner.md" || return 1
}
run_test "removes discussion-partner.md (archived)" test_removes_discussion_partner_role

test_archives_discussion_partner() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    local archived
    archived=$(ls .vibe/archive/*discussion-partner* 2>/dev/null | head -1)
    if [ -n "$archived" ]; then
        return 0
    else
        fail "discussion-partner.md should be archived"
        return 1
    fi
}
run_test "archives old discussion-partner.md" test_archives_discussion_partner

# ──────────────────────────────────────────────
# Test: Policy migration
# ──────────────────────────────────────────────

describe "Policy Migration"

test_policy_has_project_partner() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains ".vibe/policy.yaml" "project_partner" || return 1
}
run_test "policy.yaml has project_partner role" test_policy_has_project_partner

test_policy_no_discussion_partner() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_contains ".vibe/policy.yaml" "discussion_partner" || return 1
}
run_test "policy.yaml does NOT have discussion_partner" test_policy_no_discussion_partner

# ──────────────────────────────────────────────
# Test: State migration
# ──────────────────────────────────────────────

describe "State Migration"

test_state_no_current_step() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_contains ".vibe/state.yaml" "current_step" || return 1
}
run_test "state.yaml removes current_step" test_state_no_current_step

test_state_no_current_cycle() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_contains ".vibe/state.yaml" "current_cycle" || return 1
}
run_test "state.yaml removes current_cycle" test_state_no_current_cycle

test_state_no_checkpoint_status() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_contains ".vibe/state.yaml" "checkpoint_status" || return 1
}
run_test "state.yaml removes checkpoint_status" test_state_no_checkpoint_status

test_state_has_issues_recent() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains ".vibe/state.yaml" "issues_recent" || return 1
}
run_test "state.yaml has issues_recent" test_state_has_issues_recent

test_state_preserves_safety() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains ".vibe/state.yaml" "safety" || return 1
    assert_file_contains ".vibe/state.yaml" "ui_mode" || return 1
}
run_test "state.yaml preserves safety section" test_state_preserves_safety

test_state_simplified_discovery() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains ".vibe/state.yaml" "discovery" || return 1
    assert_file_not_contains ".vibe/state.yaml" "sessions:" || return 1
}
run_test "state.yaml has simplified discovery section" test_state_simplified_discovery

# ──────────────────────────────────────────────
# Test: Command migration
# ──────────────────────────────────────────────

describe "Command Migration"

test_removes_next_command() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_exists ".claude/commands/next.md" || return 1
}
run_test "removes /next command" test_removes_next_command

test_updates_discuss_command() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".claude/commands/discuss.md" || return 1
    assert_file_contains ".claude/commands/discuss.md" "Project Partner" || return 1
}
run_test "updates /discuss command with Project Partner" test_updates_discuss_command

test_updates_progress_command() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".claude/commands/progress.md" || return 1
    assert_file_contains ".claude/commands/progress.md" "gh issue" || return 1
}
run_test "updates /progress command with gh issue" test_updates_progress_command

# ──────────────────────────────────────────────
# Test: Discussions migration
# ──────────────────────────────────────────────

describe "Discussions Migration"

test_migrates_discussions_to_references() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".vibe/references/DISC-001-architecture.md" || return 1
}
run_test "copies discussions/ files to references/" test_migrates_discussions_to_references

# ──────────────────────────────────────────────
# Test: Version update
# ──────────────────────────────────────────────

describe "Version Update"

test_updates_version_file() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    local version
    version=$(cat .vibe/version 2>/dev/null)
    assert_equals "3.0.0" "$version" || return 1
}
run_test "updates .vibe/version to 3.0.0" test_updates_version_file

# ──────────────────────────────────────────────
# Test: CLAUDE.md update
# ──────────────────────────────────────────────

describe "CLAUDE.md Update"

test_claude_md_no_step_workflow() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_not_contains "CLAUDE.md" "step_1_plan_review" || return 1
}
run_test "CLAUDE.md does not contain step_1_plan_review" test_claude_md_no_step_workflow

test_claude_md_has_project_partner() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains "CLAUDE.md" "Project Partner" || return 1
}
run_test "CLAUDE.md mentions Project Partner" test_claude_md_has_project_partner

test_claude_md_has_github_issues() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_contains "CLAUDE.md" "GitHub Issues" || return 1
}
run_test "CLAUDE.md mentions GitHub Issues" test_claude_md_has_github_issues

# ──────────────────────────────────────────────
# Test: Migration tool
# ──────────────────────────────────────────────

describe "Issues Migration Tool"

test_migration_tool_exists() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    assert_file_exists ".vibe/tools/migrate-issues.sh" || return 1
}
run_test "places migrate-issues.sh tool" test_migration_tool_exists

# ──────────────────────────────────────────────
# Test: Idempotency
# ──────────────────────────────────────────────

describe "Idempotency"

test_migration_idempotent() {
    create_v2_project
    source "${FRAMEWORK_DIR}/lib/migration_helpers.sh"
    # Run migration twice
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    source "${FRAMEWORK_DIR}/migrations/v2.0.0_to_v3.0.0.sh" 2>/dev/null || true
    # Should still have valid structure
    assert_dir_exists ".vibe/context" || return 1
    assert_file_exists ".vibe/context/STATUS.md" || return 1
    assert_file_exists ".vibe/roles/project-partner.md" || return 1
    local version
    version=$(cat .vibe/version 2>/dev/null)
    assert_equals "3.0.0" "$version" || return 1
}
run_test "migration is idempotent (safe to run twice)" test_migration_idempotent

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

print_summary
