#!/bin/bash

# VibeFlow Test: v5.0.0 → v6.0.0 Migration — Structured Spec (Story/Contract)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

MIGRATION="${FRAMEWORK_DIR}/migrations/v5.0.0_to_v6.0.0.sh"

# Helper: create a v5.0.0 Iris-Only project (pre-structured-spec)
create_v50_project() {
    local dir="$1"
    mkdir -p "${dir}/.vibe/hooks" "${dir}/.vibe/sessions" "${dir}/.vibe/context" "${dir}/.vibe/runtime"
    mkdir -p "${dir}/.claude/rules" "${dir}/.claude/skills"

    echo "5.0.0" > "${dir}/.vibe/version"

    # v5 hooks
    for f in validate_access.py validate_write.sh validate_step7a.py task_complete.sh \
             waiting_input.sh checkpoint_alert.sh postwrite_lint.sh stop_test_gate.sh; do
        if [ -f "${FRAMEWORK_DIR}/examples/.vibe/hooks/${f}" ]; then
            cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/${f}" "${dir}/.vibe/hooks/${f}"
        fi
    done

    # v5 rules — NO spec-loop.md (that is the v6 addition)
    for r in iris-core workflow-standard workflow-patch workflows safety \
             playwright project-structure session-startup; do
        if [ -f "${FRAMEWORK_DIR}/examples/.claude/rules/${r}.md" ]; then
            cp "${FRAMEWORK_DIR}/examples/.claude/rules/${r}.md" "${dir}/.claude/rules/${r}.md"
        fi
    done

    # v5 skills
    for skill in vibeflow-issue-template vibeflow-tdd vibeflow-conclude vibeflow-progress \
                 vibeflow-healthcheck vibeflow-kickoff vibeflow-execute-issue \
                 vibeflow-execute-all vibeflow-ui-smoke vibeflow-ui-explore; do
        if [ -d "${FRAMEWORK_DIR}/examples/.claude/skills/${skill}" ]; then
            mkdir -p "${dir}/.claude/skills/${skill}"
            cp "${FRAMEWORK_DIR}/examples/.claude/skills/${skill}/SKILL.md" \
               "${dir}/.claude/skills/${skill}/SKILL.md" 2>/dev/null || true
        fi
    done

    # v5 runtime modules — NO spec_verify.py (that is the v6 addition)
    for m in agent_selector qa_judge dispatcher cross_review auto_close; do
        if [ -f "${FRAMEWORK_DIR}/core/runtime/${m}.py" ]; then
            cp "${FRAMEWORK_DIR}/core/runtime/${m}.py" "${dir}/.vibe/runtime/${m}.py"
        fi
    done

    # CLAUDE.md with managed section + custom content
    cat > "${dir}/CLAUDE.md" << 'EOF'
# VibeFlow v5 Project

My custom introduction.

<!-- VF:BEGIN roles -->
old roles content
<!-- VF:END roles -->

## My Custom Section
Do not lose this.
EOF

    cd "$dir"
    git init -q -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    git add -A
    git commit -q -m "v5.0.0 project"
    cd - > /dev/null
}

run_migration() {
    local project="$1"
    shift
    # env (not a bare assignment prefix) so extra "$@" KEY=VALUE args from
    # expansion are honored as environment variables, not treated as a command.
    env VIBEFLOW_PROJECT_DIR="$project" \
        VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
        VIBEFLOW_FROM_VERSION="5.0.0" \
        VIBEFLOW_TO_VERSION="6.0.0" \
        "$@" \
        bash "$MIGRATION" 2>&1 || true
}

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — script exists"

test_migration_script_exists() {
    assert_file_exists "$MIGRATION" "migrations/v5.0.0_to_v6.0.0.sh must exist"
}
run_test "migration script exists" test_migration_script_exists

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — standard v5 project"

test_migrate_version_bumped() {
    local project="${TEST_DIR}/std_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "6.0.0" "$version" "Version should be 6.0.0 after migration"
}
run_test "standard project upgrades to v6.0.0" test_migrate_version_bumped

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — structured spec rule deployed"

test_spec_loop_rule_deployed() {
    local project="${TEST_DIR}/rule_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    assert_file_exists "${project}/.claude/rules/spec-loop.md" \
        "spec-loop.md rule should be deployed"
}
run_test "spec-loop.md rule deployed" test_spec_loop_rule_deployed

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — .vibe/spec/ structure created"

test_spec_dirs_created() {
    local project="${TEST_DIR}/spec_dir_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    assert_dir_exists "${project}/.vibe/spec/stories" \
        ".vibe/spec/stories/ should be created"
    assert_dir_exists "${project}/.vibe/spec/contracts" \
        ".vibe/spec/contracts/ should be created"
}
run_test ".vibe/spec/ structure created" test_spec_dirs_created

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — spec verification runtime deployed"

test_spec_verify_runtime_deployed() {
    local project="${TEST_DIR}/runtime_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    assert_file_exists "${project}/.vibe/runtime/spec_verify.py" \
        "spec_verify.py runtime module should be deployed"
}
run_test "spec_verify.py runtime deployed" test_spec_verify_runtime_deployed

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — Spec Gate hook deployed"

test_spec_gate_hook_deployed() {
    local project="${TEST_DIR}/hook_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    assert_file_exists "${project}/.vibe/hooks/validate_step7a.py" \
        "validate_step7a.py (Spec Gate) should be deployed"
}
run_test "Spec Gate hook deployed" test_spec_gate_hook_deployed

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — CLAUDE.md backup"

test_claude_md_backup_created() {
    local project="${TEST_DIR}/claude_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    assert_file_exists "${project}/CLAUDE.md.v5-backup" \
        "CLAUDE.md should be backed up before update"
    assert_file_contains "${project}/CLAUDE.md.v5-backup" "My Custom Section" \
        "Backup should retain the user's custom content"
}
run_test "CLAUDE.md backed up before update" test_claude_md_backup_created

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — dirty tree"

test_dirty_tree_rejected() {
    local project="${TEST_DIR}/dirty_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    echo "dirty" > "${project}/dirty_file.txt"

    run_migration "$project" >/dev/null

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "5.0.0" "$version" "Dirty tree should prevent migration"
}
run_test "dirty tree rejects migration" test_dirty_tree_rejected

test_allow_dirty_flag() {
    local project="${TEST_DIR}/allow_dirty_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    echo "dirty" > "${project}/dirty_file.txt"

    run_migration "$project" VIBEFLOW_ALLOW_DIRTY=1 >/dev/null

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "6.0.0" "$version" "--allow-dirty should permit migration"
}
run_test "--allow-dirty permits migration" test_allow_dirty_flag

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — dry-run"

test_dry_run_no_changes() {
    local project="${TEST_DIR}/dry_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    local output
    output=$(run_migration "$project" VIBEFLOW_DRY_RUN=1)

    local version
    version=$(cat "${project}/.vibe/version")
    assert_equals "5.0.0" "$version" "Dry-run should not update version"

    echo "$output" > "${TEST_DIR}/dryrun_v6.txt"
    assert_file_contains "${TEST_DIR}/dryrun_v6.txt" "DRY RUN\|dry.run" \
        "Dry-run should output a human-readable plan"

    [ ! -f "${project}/.claude/rules/spec-loop.md" ]
    assert_equals "0" "$?" "Dry-run should not deploy files"
}
run_test "dry-run does not modify files" test_dry_run_no_changes

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — upgrade report"

test_upgrade_report_created() {
    local project="${TEST_DIR}/report_v6"
    mkdir -p "$project"
    create_v50_project "$project"

    run_migration "$project" >/dev/null

    local report
    report=$(ls "${project}/.vibe/upgrade-reports/"*v5.0.0_to_v6.0.0*.json 2>/dev/null | head -1)
    [ -n "$report" ]
    assert_equals "0" "$?" "Upgrade report JSON should be created"
}
run_test "upgrade report created" test_upgrade_report_created

# ──────────────────────────────────────────────
describe "Migration v6.0.0 — CHANGELOG"

test_changelog_has_v6() {
    assert_file_contains "${FRAMEWORK_DIR}/CHANGELOG.md" "6.0.0" \
        "CHANGELOG should have a v6.0.0 entry"
}
run_test "CHANGELOG has v6.0.0 entry" test_changelog_has_v6

# ──────────────────────────────────────────────
print_summary
