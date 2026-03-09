#!/bin/bash

# VibeFlow Test: Phase 2 — v3.5.0 → v4.0.0 Migration (Issue 2-8)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Helper: create a v3.5 stock project for migration testing
create_v35_project() {
    local dir="$1"
    mkdir -p "${dir}/.vibe/hooks" "${dir}/.vibe/roles" "${dir}/.vibe/context"
    mkdir -p "${dir}/.claude/commands"

    echo "3.5.0" > "${dir}/.vibe/version"

    # state.yaml (v3.5 format)
    cat > "${dir}/.vibe/state.yaml" << 'YAML'
current_issue: "#42"
current_role: "Engineer"
current_step: 5_implementation
phase: development
issues_recent: []
quickfix:
  active: false
  description: null
  started: null
discovery:
  active: false
  last_session: null
safety:
  ui_mode: atomic
  destructive_op: require_confirmation
  max_fix_attempts: 3
  failed_approach_log: []
infra_log:
  hook_changes: []
  rollback_pending: false
YAML

    # CLAUDE.md with managed sections
    cat > "${dir}/CLAUDE.md" << 'EOF'
# VibeFlow v3 Project
<!-- VF:BEGIN roles -->
### Engineer
old roles content
<!-- VF:END roles -->
<!-- VF:BEGIN workflow -->
old workflow
<!-- VF:END workflow -->
<!-- VF:BEGIN hook_list -->
old hooks
<!-- VF:END hook_list -->
EOF

    # Stock hooks (copy from examples for hash match)
    for f in validate_write.sh validate_step7a.py checkpoint_alert.sh task_complete.sh waiting_input.sh; do
        if [ -f "${FRAMEWORK_DIR}/examples/.vibe/hooks/${f}" ]; then
            cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/${f}" "${dir}/.vibe/hooks/${f}"
        fi
    done

    # Stock role docs
    for f in "${FRAMEWORK_DIR}"/examples/.vibe/roles/*.md; do
        [ -f "$f" ] && cp "$f" "${dir}/.vibe/roles/$(basename "$f")"
    done

    # policy.yaml
    cp "${FRAMEWORK_DIR}/examples/.vibe/policy.yaml" "${dir}/.vibe/policy.yaml" 2>/dev/null || true

    # settings.json
    mkdir -p "${dir}/.claude"
    cp "${FRAMEWORK_DIR}/examples/.claude/settings.json" "${dir}/.claude/settings.json" 2>/dev/null || true

    # Git init
    cd "$dir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git add -A
    git commit -q -m "v3.5.0 project"
    cd - > /dev/null
}

# Helper: create a v3.5 project with customized files
create_v35_customized_project() {
    local dir="$1"
    create_v35_project "$dir"

    # Customize validate_write.sh
    echo "# user customization" >> "${dir}/.vibe/hooks/validate_write.sh"

    # Customize a role doc
    echo "# my custom notes" >> "${dir}/.vibe/roles/engineer.md"

    cd "$dir"
    git add -A
    git commit -q -m "customized project"
    cd - > /dev/null
}

# ──────────────────────────────────────────────
describe "Migration script — exists"

test_migration_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" \
        "migrations/v3.5.0_to_v4.0.0.sh must exist"
}
run_test "migration script exists" test_migration_script_exists

# ──────────────────────────────────────────────
describe "Migration — standard v3.5 project"

test_migrate_standard_project() {
    local project="${TEST_DIR}/std_project"
    mkdir -p "$project"
    create_v35_project "$project"

    # Run migration
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Version should be updated
    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.0.0" "$version" "Version should be 4.0.0 after migration"
}
run_test "standard project upgrades to v4.0.0" test_migrate_standard_project

# ──────────────────────────────────────────────
describe "Migration — state split"

test_state_split_project_state() {
    local project="${TEST_DIR}/state_split"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    assert_file_exists "${project}/.vibe/project_state.yaml" \
        "project_state.yaml should be created"
    assert_file_contains "${project}/.vibe/project_state.yaml" "active_issue" \
        "project_state should have active_issue"
}
run_test "state split creates project_state.yaml" test_state_split_project_state

test_project_state_matches_schema() {
    local project="${TEST_DIR}/ps_schema"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Must have all schema-required fields
    assert_file_contains "${project}/.vibe/project_state.yaml" "active_issue" \
        "project_state should have active_issue"
    assert_file_contains "${project}/.vibe/project_state.yaml" "active_pr" \
        "project_state should have active_pr"
    assert_file_contains "${project}/.vibe/project_state.yaml" "current_phase" \
        "project_state should have current_phase"
    assert_file_contains "${project}/.vibe/project_state.yaml" "patch_runs" \
        "project_state should have patch_runs"
    assert_file_contains "${project}/.vibe/project_state.yaml" "backlog_summary" \
        "project_state should have backlog_summary"
    assert_file_contains "${project}/.vibe/project_state.yaml" "safety" \
        "project_state should have safety"

    # Must NOT have old v3 fields (use exact key to avoid matching current_phase)
    assert_file_not_contains "${project}/.vibe/project_state.yaml" "^phase:" \
        "project_state should not have old 'phase' field"
    assert_file_not_contains "${project}/.vibe/project_state.yaml" "issues_recent" \
        "project_state should not have issues_recent"
    assert_file_not_contains "${project}/.vibe/project_state.yaml" "infra_log" \
        "project_state should not have infra_log"
}
run_test "project_state.yaml matches schema" test_project_state_matches_schema

test_state_split_session() {
    local project="${TEST_DIR}/state_session"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    assert_file_exists "${project}/.vibe/sessions/iris-main.yaml" \
        "sessions/iris-main.yaml should be created"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "current_role" \
        "Session should have current_role"
}
run_test "state split creates session file" test_state_split_session

test_session_matches_schema() {
    local project="${TEST_DIR}/sess_schema"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Must have all schema-required fields
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "session_id" \
        "session should have session_id"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "kind" \
        "session should have kind"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "current_role" \
        "session should have current_role"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "current_step" \
        "session should have current_step"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "attached_issue" \
        "session should have attached_issue"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "worktree" \
        "session should have worktree"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "status" \
        "session should have status"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "safety" \
        "session should have safety"
    assert_file_contains "${project}/.vibe/sessions/iris-main.yaml" "infra_log" \
        "session should have infra_log"

    # Must NOT have old v3 fields
    assert_file_not_contains "${project}/.vibe/sessions/iris-main.yaml" "discovery" \
        "session should not have old 'discovery' field"
}
run_test "session iris-main.yaml matches schema" test_session_matches_schema

test_state_yaml_backed_up() {
    local project="${TEST_DIR}/state_backup"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    assert_file_exists "${project}/.vibe/state.yaml.v3-backup" \
        "state.yaml should be backed up"
}
run_test "state.yaml is backed up" test_state_yaml_backed_up

# ──────────────────────────────────────────────
describe "Migration — quickfix → patch_runs"

test_quickfix_to_patch_runs() {
    local project="${TEST_DIR}/qf_migrate"
    mkdir -p "$project"
    create_v35_project "$project"

    # Add active quickfix to state.yaml
    cat > "${project}/.vibe/state.yaml" << 'YAML'
current_issue: "#10"
current_role: "Engineer"
current_step: null
phase: quickfix
quickfix:
  active: true
  description: "Fix button color"
  started: "2026-03-01"
YAML
    cd "$project" && git add -A && git commit -q -m "active quickfix" && cd - > /dev/null

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    assert_file_contains "${project}/.vibe/project_state.yaml" "patch_runs" \
        "project_state should have patch_runs"
}
run_test "quickfix converted to patch_runs" test_quickfix_to_patch_runs

# ──────────────────────────────────────────────
describe "Migration — customized files"

test_customized_not_overwritten() {
    local project="${TEST_DIR}/custom_project"
    mkdir -p "$project"
    create_v35_customized_project "$project"

    # Save customized content
    local custom_content
    custom_content=$(cat "${project}/.vibe/hooks/validate_write.sh")

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Customized file should NOT be overwritten
    local after_content
    after_content=$(cat "${project}/.vibe/hooks/validate_write.sh")
    assert_equals "$custom_content" "$after_content" \
        "Customized validate_write.sh should not be overwritten"
}
run_test "customized files are not overwritten" test_customized_not_overwritten

test_migration_reports_customized() {
    local project="${TEST_DIR}/custom_report"
    mkdir -p "$project"
    create_v35_customized_project "$project"

    local output
    output=$(VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true)

    echo "$output" > "${TEST_DIR}/migration_output.txt"
    assert_file_contains "${TEST_DIR}/migration_output.txt" "customized" \
        "Migration should report customized files"
}
run_test "migration reports customized files" test_migration_reports_customized

# ──────────────────────────────────────────────
describe "Migration — new files placed"

test_patch_command_placed() {
    local project="${TEST_DIR}/patch_placed"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    assert_file_exists "${project}/.claude/commands/patch.md" \
        "/patch command should be placed"
}
run_test "/patch command placed" test_patch_command_placed

test_managed_sections_regenerated() {
    local project="${TEST_DIR}/managed_regen"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Managed sections should be regenerated with new content
    assert_file_contains "${project}/CLAUDE.md" "project_state.yaml" \
        "CLAUDE.md should have new state references after regen"
}
run_test "CLAUDE.md managed sections regenerated" test_managed_sections_regenerated

test_claude_md_hand_written_preserved() {
    local project="${TEST_DIR}/claude_handwritten"
    mkdir -p "$project"
    create_v35_project "$project"

    # Add hand-written custom section outside managed markers
    cat > "${project}/CLAUDE.md" << 'EOF'
# My Custom Project

## Custom Section
This is my hand-written documentation that must be preserved.

<!-- VF:BEGIN roles -->
### Engineer
old roles content
<!-- VF:END roles -->

## Another Custom Section
More custom content here.

<!-- VF:BEGIN workflow -->
old workflow
<!-- VF:END workflow -->

## My Special Notes
These notes are important to me.

<!-- VF:BEGIN hook_list -->
old hooks
<!-- VF:END hook_list -->

## Final Custom Section
Do not delete this.
EOF
    cd "$project" && git add -A && git commit -q -m "custom CLAUDE.md" && cd - > /dev/null

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Hand-written sections must be preserved
    assert_file_contains "${project}/CLAUDE.md" "Custom Section" \
        "Hand-written Custom Section should be preserved"
    assert_file_contains "${project}/CLAUDE.md" "hand-written documentation" \
        "Hand-written content should be preserved"
    assert_file_contains "${project}/CLAUDE.md" "Another Custom Section" \
        "Another Custom Section should be preserved"
    assert_file_contains "${project}/CLAUDE.md" "My Special Notes" \
        "My Special Notes should be preserved"
    assert_file_contains "${project}/CLAUDE.md" "Final Custom Section" \
        "Final Custom Section should be preserved"

    # Managed sections should be updated
    assert_file_not_contains "${project}/CLAUDE.md" "old roles content" \
        "Old roles content should be replaced"
    assert_file_not_contains "${project}/CLAUDE.md" "old workflow" \
        "Old workflow content should be replaced"
}
run_test "CLAUDE.md hand-written sections preserved" test_claude_md_hand_written_preserved

test_claude_md_only_managed_updated() {
    local project="${TEST_DIR}/claude_managed_only"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Markers must still exist
    assert_file_contains "${project}/CLAUDE.md" "VF:BEGIN roles" \
        "VF:BEGIN roles marker should exist"
    assert_file_contains "${project}/CLAUDE.md" "VF:END roles" \
        "VF:END roles marker should exist"
    assert_file_contains "${project}/CLAUDE.md" "VF:BEGIN workflow" \
        "VF:BEGIN workflow marker should exist"
    assert_file_contains "${project}/CLAUDE.md" "VF:END workflow" \
        "VF:END workflow marker should exist"

    # Title should be preserved (not overwritten with examples/CLAUDE.md title)
    assert_file_contains "${project}/CLAUDE.md" "VibeFlow v3 Project" \
        "Original title should be preserved"
}
run_test "CLAUDE.md only managed sections updated" test_claude_md_only_managed_updated

# ──────────────────────────────────────────────
describe "Migration — dirty tree"

test_dirty_tree_rejected() {
    local project="${TEST_DIR}/dirty_project"
    mkdir -p "$project"
    create_v35_project "$project"

    # Make tree dirty
    echo "dirty" > "${project}/dirty_file.txt"

    local output
    set +e
    output=$(VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1)
    local code=$?
    set -e

    # Should fail (non-zero exit) or warn about dirty tree
    echo "$output" > "${TEST_DIR}/dirty_output.txt"
    # Version should NOT be updated if dirty tree is rejected
    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "3.5.0" "$version" "Dirty tree should prevent migration"
}
run_test "dirty tree rejects migration" test_dirty_tree_rejected

test_allow_dirty_flag() {
    local project="${TEST_DIR}/allow_dirty"
    mkdir -p "$project"
    create_v35_project "$project"

    # Make tree dirty
    echo "dirty" > "${project}/dirty_file.txt"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    VIBEFLOW_ALLOW_DIRTY=1 \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.0.0" "$version" "--allow-dirty should allow migration"
}
run_test "--allow-dirty permits migration" test_allow_dirty_flag

# ──────────────────────────────────────────────
describe "Migration — dry-run"

test_dry_run_no_changes() {
    local project="${TEST_DIR}/dry_run"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    VIBEFLOW_DRY_RUN=1 \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Version should NOT be updated in dry-run
    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "3.5.0" "$version" "Dry-run should not update version"
}
run_test "dry-run does not modify files" test_dry_run_no_changes

# ──────────────────────────────────────────────
describe "Migration — upgrade report"

test_upgrade_report_created() {
    local project="${TEST_DIR}/report_project"
    mkdir -p "$project"
    create_v35_customized_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # Report file should exist in .vibe/upgrade-reports/
    local report
    report=$(ls "${project}/.vibe/upgrade-reports/"*.json 2>/dev/null | head -1)
    [ -n "$report" ]
    assert_equals "0" "$?" "Upgrade report JSON should be created"
}
run_test "upgrade report JSON created" test_upgrade_report_created

test_upgrade_report_has_customized() {
    local project="${TEST_DIR}/report_custom"
    mkdir -p "$project"
    create_v35_customized_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    local report
    report=$(ls "${project}/.vibe/upgrade-reports/"*.json 2>/dev/null | head -1)
    assert_file_contains "$report" "customized_files" \
        "Report should list customized files"
}
run_test "upgrade report lists customized files" test_upgrade_report_has_customized

# ──────────────────────────────────────────────
describe "Migration — doctor validation"

test_doctor_passes_after_migration() {
    local project="${TEST_DIR}/doctor_post"
    mkdir -p "$project"
    create_v35_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="3.5.0" \
    VIBEFLOW_TO_VERSION="4.0.0" \
    bash "${FRAMEWORK_DIR}/migrations/v3.5.0_to_v4.0.0.sh" 2>&1 || true

    # After migration, key v4 files should exist
    assert_file_exists "${project}/.vibe/project_state.yaml" \
        "project_state.yaml should exist post-migration"
    assert_file_exists "${project}/.vibe/sessions/iris-main.yaml" \
        "sessions/iris-main.yaml should exist post-migration"
    assert_file_exists "${project}/.claude/commands/patch.md" \
        "patch.md should exist post-migration"
    assert_file_exists "${project}/CLAUDE.md" \
        "CLAUDE.md should exist post-migration"

    # Version should be correct
    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.0.0" "$version" "Version should be 4.0.0"
}
run_test "doctor checks pass after migration" test_doctor_passes_after_migration

# ──────────────────────────────────────────────
describe "Migration — VERSION file"

test_framework_version_updated() {
    # VERSION file should be 4.0.0 for this migration to be discoverable
    assert_file_exists "${FRAMEWORK_DIR}/VERSION" "VERSION file must exist"
    local version
    version=$(cat "${FRAMEWORK_DIR}/VERSION")
    assert_equals "4.0.0" "$version" "Framework VERSION should be 4.0.0"
}
run_test "framework VERSION is 4.0.0" test_framework_version_updated

# ──────────────────────────────────────────────
print_summary
