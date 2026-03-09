#!/bin/bash

# VibeFlow Test: Phase 4 — v4.0.0 → v4.1.0 Migration (Issue 4-4)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Helper: create a v4.0 standard project for migration testing
create_v40_project() {
    local dir="$1"
    mkdir -p "${dir}/.vibe/hooks" "${dir}/.vibe/sessions" "${dir}/.vibe/context"
    mkdir -p "${dir}/.claude/commands" "${dir}/.claude/skills"

    echo "4.0.0" > "${dir}/.vibe/version"

    # project_state.yaml (v4.0 format)
    cat > "${dir}/.vibe/project_state.yaml" << 'YAML'
active_issue: null
active_pr: null
current_phase: development
patch_runs: []
backlog_summary:
  ready: 0
  in_progress: 0
  blocked: 0
safety:
  ui_mode: atomic
  destructive_op: require_confirmation
YAML

    # sessions/iris-main.yaml
    cat > "${dir}/.vibe/sessions/iris-main.yaml" << 'YAML'
session_id: iris-main
kind: iris
current_role: Iris
current_step: null
attached_issue: null
worktree: null
status: active
safety:
  max_fix_attempts: 3
  failed_approach_log: []
infra_log:
  hook_changes: []
  rollback_pending: false
YAML

    # CLAUDE.md with managed sections
    cat > "${dir}/CLAUDE.md" << 'EOF'
# VibeFlow v4 Project

My custom introduction.

<!-- VF:BEGIN roles -->
### Iris
old roles content
<!-- VF:END roles -->

## My Custom Section
Do not touch this.

<!-- VF:BEGIN workflow -->
old workflow
<!-- VF:END workflow -->

<!-- VF:BEGIN hook_list -->
old hooks
<!-- VF:END hook_list -->
EOF

    # Stock hooks
    for f in validate_access.py validate_write.sh validate_step7a.py task_complete.sh waiting_input.sh checkpoint_alert.sh; do
        if [ -f "${FRAMEWORK_DIR}/examples/.vibe/hooks/${f}" ]; then
            cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/${f}" "${dir}/.vibe/hooks/${f}"
        fi
    done

    # 4 existing skills (v4.0 — issue-template, tdd, discuss, conclude, progress, healthcheck)
    for skill in vibeflow-issue-template vibeflow-tdd vibeflow-discuss vibeflow-conclude vibeflow-progress vibeflow-healthcheck; do
        if [ -d "${FRAMEWORK_DIR}/examples/.claude/skills/${skill}" ]; then
            mkdir -p "${dir}/.claude/skills/${skill}"
            cp "${FRAMEWORK_DIR}/examples/.claude/skills/${skill}/SKILL.md" \
               "${dir}/.claude/skills/${skill}/SKILL.md" 2>/dev/null || true
        fi
    done

    # Commands
    for cmd in discuss.md conclude.md progress.md healthcheck.md quickfix.md patch.md run-e2e.md; do
        if [ -f "${FRAMEWORK_DIR}/lib/commands/${cmd}" ]; then
            cp "${FRAMEWORK_DIR}/lib/commands/${cmd}" "${dir}/.claude/commands/${cmd}"
        fi
    done

    # Git init
    cd "$dir"
    git init -q -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    git add -A
    git commit -q -m "v4.0.0 project"
    cd - > /dev/null
}

# Helper: create a v4.0 project with customized files
create_v40_customized_project() {
    local dir="$1"
    create_v40_project "$dir"

    # Customize a hook
    echo "# user customization" >> "${dir}/.vibe/hooks/validate_write.sh"

    # Customize a skill
    echo "# my custom notes" >> "${dir}/.claude/skills/vibeflow-discuss/SKILL.md"

    cd "$dir"
    git add -A
    git commit -q -m "customized project"
    cd - > /dev/null
}

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — script exists"

test_migration_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" \
        "migrations/v4.0.0_to_v4.1.0.sh must exist"
}
run_test "migration script exists" test_migration_script_exists

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — standard v4.0 project"

test_migrate_standard_project() {
    local project="${TEST_DIR}/std_project"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.1.0" "$version" "Version should be 4.1.0 after migration"
}
run_test "standard project upgrades to v4.1.0" test_migrate_standard_project

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — skills deployed"

test_ui_smoke_skill_deployed() {
    local project="${TEST_DIR}/skills_smoke"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    assert_file_exists "${project}/.claude/skills/vibeflow-ui-smoke/SKILL.md" \
        "vibeflow-ui-smoke should be deployed"
}
run_test "ui-smoke skill deployed" test_ui_smoke_skill_deployed

test_ui_explore_skill_deployed() {
    local project="${TEST_DIR}/skills_explore"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    assert_file_exists "${project}/.claude/skills/vibeflow-ui-explore/SKILL.md" \
        "vibeflow-ui-explore should be deployed"
}
run_test "ui-explore skill deployed" test_ui_explore_skill_deployed

test_existing_skills_updated() {
    local project="${TEST_DIR}/skills_existing"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    # All 8 skills should exist
    local count=0
    for skill in vibeflow-issue-template vibeflow-tdd vibeflow-discuss vibeflow-conclude \
                 vibeflow-progress vibeflow-healthcheck vibeflow-ui-smoke vibeflow-ui-explore; do
        [ -f "${project}/.claude/skills/${skill}/SKILL.md" ] && count=$((count + 1))
    done
    assert_equals "8" "$count" "All 8 skills should exist after migration"
}
run_test "all 8 skills present after migration" test_existing_skills_updated

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — Playwright files deployed"

test_mcp_template_deployed() {
    local project="${TEST_DIR}/pw_mcp"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    assert_file_exists "${project}/.mcp.json.example" \
        ".mcp.json.example should be deployed"
}
run_test ".mcp.json.example deployed" test_mcp_template_deployed

test_playwright_scripts_deployed() {
    local project="${TEST_DIR}/pw_scripts"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    assert_file_exists "${project}/scripts/playwright_smoke.sh" \
        "playwright_smoke.sh should be deployed"
    assert_file_exists "${project}/scripts/playwright_open_report.sh" \
        "playwright_open_report.sh should be deployed"
    assert_file_exists "${project}/scripts/playwright_trace_pack.sh" \
        "playwright_trace_pack.sh should be deployed"
}
run_test "playwright scripts deployed" test_playwright_scripts_deployed

test_playwright_scripts_executable() {
    local project="${TEST_DIR}/pw_exec"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    [ -x "${project}/scripts/playwright_smoke.sh" ] && \
    [ -x "${project}/scripts/playwright_open_report.sh" ] && \
    [ -x "${project}/scripts/playwright_trace_pack.sh" ]
    assert_equals "0" "$?" "Playwright scripts should be executable"
}
run_test "playwright scripts are executable" test_playwright_scripts_executable

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — plugin structure deployed"

test_plugin_json_deployed() {
    local project="${TEST_DIR}/plugin_json"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    assert_file_exists "${project}/.claude-plugin/plugin.json" \
        ".claude-plugin/plugin.json should be deployed"
}
run_test "plugin.json deployed" test_plugin_json_deployed

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — commands compatibility"

test_commands_maintained() {
    local project="${TEST_DIR}/cmds_compat"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    for cmd in discuss.md conclude.md progress.md healthcheck.md; do
        assert_file_exists "${project}/.claude/commands/${cmd}" \
            "Command ${cmd} should still exist"
    done
}
run_test "commands compatibility maintained" test_commands_maintained

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — CLAUDE.md managed sections"

test_claude_md_updated() {
    local project="${TEST_DIR}/claude_updated"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    # Should have updated content (ui skills in Available Skills)
    assert_file_contains "${project}/CLAUDE.md" "vibeflow-ui-smoke" \
        "CLAUDE.md should reference vibeflow-ui-smoke after migration"
}
run_test "CLAUDE.md updated with UI skills" test_claude_md_updated

test_claude_md_custom_preserved() {
    local project="${TEST_DIR}/claude_custom"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    assert_file_contains "${project}/CLAUDE.md" "My Custom Section" \
        "Custom sections should be preserved"
    assert_file_contains "${project}/CLAUDE.md" "My custom introduction" \
        "Custom intro should be preserved"
}
run_test "CLAUDE.md custom sections preserved" test_claude_md_custom_preserved

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — customized files protected"

test_customized_skill_not_overwritten() {
    local project="${TEST_DIR}/custom_skill"
    mkdir -p "$project"
    create_v40_customized_project "$project"

    local custom_content
    custom_content=$(cat "${project}/.claude/skills/vibeflow-discuss/SKILL.md")

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    local after_content
    after_content=$(cat "${project}/.claude/skills/vibeflow-discuss/SKILL.md")
    assert_equals "$custom_content" "$after_content" \
        "Customized vibeflow-discuss should not be overwritten"
}
run_test "customized skill not overwritten" test_customized_skill_not_overwritten

test_customized_hook_not_overwritten() {
    local project="${TEST_DIR}/custom_hook"
    mkdir -p "$project"
    create_v40_customized_project "$project"

    local custom_content
    custom_content=$(cat "${project}/.vibe/hooks/validate_write.sh")

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    local after_content
    after_content=$(cat "${project}/.vibe/hooks/validate_write.sh")
    assert_equals "$custom_content" "$after_content" \
        "Customized validate_write.sh should not be overwritten"
}
run_test "customized hook not overwritten" test_customized_hook_not_overwritten

test_migration_warns_about_customized() {
    local project="${TEST_DIR}/custom_warn"
    mkdir -p "$project"
    create_v40_customized_project "$project"

    local output
    output=$(VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true)

    echo "$output" > "${TEST_DIR}/custom_output.txt"
    assert_file_contains "${TEST_DIR}/custom_output.txt" "customized\|カスタマイズ" \
        "Migration should warn about customized files"
}
run_test "migration warns about customized files" test_migration_warns_about_customized

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — dirty tree"

test_dirty_tree_rejected() {
    local project="${TEST_DIR}/dirty_project"
    mkdir -p "$project"
    create_v40_project "$project"

    echo "dirty" > "${project}/dirty_file.txt"

    local exit_code=0
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" >/dev/null 2>&1 || exit_code=$?

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.0.0" "$version" "Dirty tree should prevent migration"
}
run_test "dirty tree rejects migration" test_dirty_tree_rejected

test_allow_dirty_flag() {
    local project="${TEST_DIR}/allow_dirty"
    mkdir -p "$project"
    create_v40_project "$project"

    echo "dirty" > "${project}/dirty_file.txt"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    VIBEFLOW_ALLOW_DIRTY=1 \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.1.0" "$version" "--allow-dirty should allow migration"
}
run_test "--allow-dirty permits migration" test_allow_dirty_flag

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — dry-run"

test_dry_run_no_changes() {
    local project="${TEST_DIR}/dry_run"
    mkdir -p "$project"
    create_v40_project "$project"

    local output
    output=$(VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    VIBEFLOW_DRY_RUN=1 \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true)

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "4.0.0" "$version" "Dry-run should not update version"

    echo "$output" > "${TEST_DIR}/dryrun_output.txt"
    assert_file_contains "${TEST_DIR}/dryrun_output.txt" "DRY RUN\|dry.run\|dry-run" \
        "Dry-run should output human-readable plan"
}
run_test "dry-run does not modify files" test_dry_run_no_changes

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — upgrade report"

test_upgrade_report_created() {
    local project="${TEST_DIR}/report_project"
    mkdir -p "$project"
    create_v40_project "$project"

    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    VIBEFLOW_FROM_VERSION="4.0.0" \
    VIBEFLOW_TO_VERSION="4.1.0" \
    bash "${FRAMEWORK_DIR}/migrations/v4.0.0_to_v4.1.0.sh" 2>&1 || true

    local report
    report=$(ls "${project}/.vibe/upgrade-reports/"*v4.0.0_to_v4.1.0*.json 2>/dev/null | head -1)
    [ -n "$report" ]
    assert_equals "0" "$?" "Upgrade report JSON should be created"
}
run_test "upgrade report created" test_upgrade_report_created

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — VERSION and CHANGELOG"

test_framework_version_updated() {
    local version
    version=$(cat "${FRAMEWORK_DIR}/VERSION")
    assert_equals "4.1.0" "$version" "Framework VERSION should be 4.1.0"
}
run_test "framework VERSION is 4.1.0" test_framework_version_updated

test_changelog_has_v410() {
    assert_file_contains "${FRAMEWORK_DIR}/CHANGELOG.md" "4.1.0" \
        "CHANGELOG should have v4.1.0 entry"
}
run_test "CHANGELOG has v4.1.0 entry" test_changelog_has_v410

# ──────────────────────────────────────────────
describe "Migration v4.1.0 — non-regression"

test_existing_v4_migration_tests_pass() {
    bash "${FRAMEWORK_DIR}/tests/test_skills.sh" >/dev/null 2>&1
    assert_equals "0" "$?" "test_skills.sh should still pass"
}
run_test "existing skills tests pass" test_existing_v4_migration_tests_pass

test_existing_playwright_tests_pass() {
    bash "${FRAMEWORK_DIR}/tests/test_playwright.sh" >/dev/null 2>&1
    assert_equals "0" "$?" "test_playwright.sh should still pass"
}
run_test "existing playwright tests pass" test_existing_playwright_tests_pass

test_existing_plugin_tests_pass() {
    bash "${FRAMEWORK_DIR}/tests/test_plugin_structure.sh" >/dev/null 2>&1
    assert_equals "0" "$?" "test_plugin_structure.sh should still pass"
}
run_test "existing plugin tests pass" test_existing_plugin_tests_pass

# ──────────────────────────────────────────────
print_summary
