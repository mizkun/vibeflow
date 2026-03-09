#!/bin/bash

# VibeFlow Test: Phase 2 — Iris-first + Issue Templates (Issue 2-2 + 2-6)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

CLAUDE_MD="${FRAMEWORK_DIR}/examples/CLAUDE.md"
ROLES_YAML="${FRAMEWORK_DIR}/core/schema/roles.yaml"
IRIS_MD="${FRAMEWORK_DIR}/examples/.vibe/roles/iris.md"
TEMPLATES_DIR="${FRAMEWORK_DIR}/examples/.github/ISSUE_TEMPLATE"

# ──────────────────────────────────────────────
describe "Iris-first — CLAUDE.md wording"

test_no_discussion_mode() {
    assert_file_not_contains "$CLAUDE_MD" "Discussion mode" \
        "CLAUDE.md should not contain 'Discussion mode'"
    assert_file_not_contains "$CLAUDE_MD" "Discussion Mode" \
        "CLAUDE.md should not contain 'Discussion Mode'"
}
run_test "No 'Discussion mode' in CLAUDE.md" test_no_discussion_mode

test_main_terminal_iris() {
    assert_file_contains "$CLAUDE_MD" "Iris-Only" \
        "CLAUDE.md should mention Iris-Only architecture"
    assert_file_contains "$CLAUDE_MD" "Iris" \
        "CLAUDE.md should mention Iris"
}
run_test "Iris-Only architecture mentioned" test_main_terminal_iris

test_worker_terminal() {
    assert_file_contains "$CLAUDE_MD" "Coding Agent" \
        "CLAUDE.md should mention Coding Agent (replaces Worker Terminal in v5)"
}
run_test "Coding Agent mentioned (v5)" test_worker_terminal

test_no_quick_fix_section() {
    assert_file_not_contains "$CLAUDE_MD" "## Quick Fix Mode" \
        "CLAUDE.md should not have Quick Fix Mode section header"
}
run_test "No Quick Fix Mode section" test_no_quick_fix_section

test_patch_loop_reference() {
    assert_file_contains "$CLAUDE_MD" "Patch Loop" \
        "CLAUDE.md should reference Patch Loop"
}
run_test "Patch Loop referenced in CLAUDE.md" test_patch_loop_reference

test_terminal_architecture_section() {
    assert_file_contains "$CLAUDE_MD" "## Architecture" \
        "CLAUDE.md should have Architecture section"
}
run_test "Architecture section exists (v5)" test_terminal_architecture_section

test_no_old_labels_in_operations() {
    assert_file_not_contains "$CLAUDE_MD" "priority:" \
        "CLAUDE.md should not reference priority: labels"
    assert_file_not_contains "$CLAUDE_MD" "status:" \
        "CLAUDE.md should not reference status: labels"
}
run_test "No priority:/status: labels in CLAUDE.md" test_no_old_labels_in_operations

test_operations_use_rev4_labels() {
    assert_file_contains "$CLAUDE_MD" "type:dev" \
        "CLAUDE.md should use type:dev label (v5 label taxonomy)"
    assert_file_contains "$CLAUDE_MD" "risk:medium" \
        "CLAUDE.md should use risk:medium label"
}
run_test "Operations use v5 label taxonomy" test_operations_use_rev4_labels

# ──────────────────────────────────────────────
describe "Iris-first — roles.yaml"

test_iris_dispatch_triage() {
    assert_file_contains "$ROLES_YAML" "dispatch" \
        "roles.yaml Iris should mention dispatch"
    assert_file_contains "$ROLES_YAML" "triage" \
        "roles.yaml Iris should mention triage"
}
run_test "Iris has dispatch/triage in roles.yaml" test_iris_dispatch_triage

test_iris_default_entry() {
    if grep -qi "default" "$ROLES_YAML" 2>/dev/null; then
        return 0
    else
        fail "roles.yaml Iris should indicate default entry point"
        return 1
    fi
}
run_test "Iris described as default entry" test_iris_default_entry

# ──────────────────────────────────────────────
describe "Iris-first — iris.md"

test_iris_md_default_role() {
    if grep -qi "default" "$IRIS_MD" 2>/dev/null; then
        return 0
    else
        fail "iris.md should describe Iris as default role"
        return 1
    fi
}
run_test "iris.md mentions default role" test_iris_md_default_role

test_iris_md_dispatch() {
    assert_file_contains "$IRIS_MD" "dispatch" \
        "iris.md should mention dispatch responsibility"
}
run_test "iris.md mentions dispatch" test_iris_md_dispatch

# ──────────────────────────────────────────────
describe "Issue Templates — new templates exist"

test_standard_template_exists() {
    assert_file_exists "${TEMPLATES_DIR}/standard.md" \
        "standard.md template must exist"
}
run_test "standard.md exists" test_standard_template_exists

test_patch_template_exists() {
    assert_file_exists "${TEMPLATES_DIR}/patch.md" \
        "patch.md template must exist"
}
run_test "patch.md exists" test_patch_template_exists

test_spike_template_exists() {
    assert_file_exists "${TEMPLATES_DIR}/spike.md" \
        "spike.md template must exist"
}
run_test "spike.md exists" test_spike_template_exists

test_ops_template_exists() {
    assert_file_exists "${TEMPLATES_DIR}/ops.md" \
        "ops.md template must exist"
}
run_test "ops.md exists" test_ops_template_exists

test_config_yml_exists() {
    assert_file_exists "${TEMPLATES_DIR}/config.yml" \
        "config.yml must exist"
}
run_test "config.yml exists" test_config_yml_exists

# ──────────────────────────────────────────────
describe "Issue Templates — old templates deprecated"

test_dev_template_deprecated() {
    assert_file_exists "${TEMPLATES_DIR}/dev.md" \
        "dev.md should still exist (deprecated)"
    assert_file_contains "${TEMPLATES_DIR}/dev.md" "DEPRECATED" \
        "dev.md should have DEPRECATED marker"
}
run_test "dev.md is deprecated" test_dev_template_deprecated

test_human_template_deprecated() {
    assert_file_exists "${TEMPLATES_DIR}/human.md" \
        "human.md should still exist (deprecated)"
    assert_file_contains "${TEMPLATES_DIR}/human.md" "DEPRECATED" \
        "human.md should have DEPRECATED marker"
}
run_test "human.md is deprecated" test_human_template_deprecated

test_discussion_template_deprecated() {
    assert_file_exists "${TEMPLATES_DIR}/discussion.md" \
        "discussion.md should still exist (deprecated)"
    assert_file_contains "${TEMPLATES_DIR}/discussion.md" "DEPRECATED" \
        "discussion.md should have DEPRECATED marker"
}
run_test "discussion.md is deprecated" test_discussion_template_deprecated

# ──────────────────────────────────────────────
describe "Issue Templates — DoR gate alignment"

test_standard_has_acceptance_criteria() {
    assert_file_contains "${TEMPLATES_DIR}/standard.md" "Acceptance Criteria" \
        "standard.md should have Acceptance Criteria section"
}
run_test "standard.md has Acceptance Criteria" test_standard_has_acceptance_criteria

test_standard_has_testing() {
    assert_file_contains "${TEMPLATES_DIR}/standard.md" "Testing" \
        "standard.md should have Testing section"
}
run_test "standard.md has Testing section" test_standard_has_testing

test_standard_has_file_locations() {
    assert_file_contains "${TEMPLATES_DIR}/standard.md" "File Locations" \
        "standard.md should have File Locations section"
}
run_test "standard.md has File Locations" test_standard_has_file_locations

test_standard_has_risk_label() {
    assert_file_contains "${TEMPLATES_DIR}/standard.md" "risk:" \
        "standard.md should reference risk label"
}
run_test "standard.md references risk label" test_standard_has_risk_label

test_patch_has_parent_issue() {
    assert_file_contains "${TEMPLATES_DIR}/patch.md" "parent" \
        "patch.md should reference parent issue"
}
run_test "patch.md references parent issue" test_patch_has_parent_issue

test_patch_has_scope() {
    if grep -qi "scope" "${TEMPLATES_DIR}/patch.md" 2>/dev/null; then
        return 0
    else
        fail "patch.md should have scope section"
        return 1
    fi
}
run_test "patch.md has scope" test_patch_has_scope

test_spike_has_decision_criteria() {
    assert_file_contains "${TEMPLATES_DIR}/spike.md" "Decision" \
        "spike.md should have Decision section"
}
run_test "spike.md has Decision section" test_spike_has_decision_criteria

test_ops_has_completion_criteria() {
    assert_file_contains "${TEMPLATES_DIR}/ops.md" "Completion" \
        "ops.md should have Completion section"
}
run_test "ops.md has Completion section" test_ops_has_completion_criteria

# ──────────────────────────────────────────────
describe "Issue Templates — workflow labels"

test_standard_workflow_label() {
    assert_file_contains "${TEMPLATES_DIR}/standard.md" "workflow:standard" \
        "standard.md should have workflow:standard label"
}
run_test "standard.md has workflow:standard" test_standard_workflow_label

test_patch_workflow_label() {
    assert_file_contains "${TEMPLATES_DIR}/patch.md" "workflow:patch" \
        "patch.md should have workflow:patch label"
}
run_test "patch.md has workflow:patch" test_patch_workflow_label

test_spike_workflow_label() {
    assert_file_contains "${TEMPLATES_DIR}/spike.md" "workflow:spike" \
        "spike.md should have workflow:spike label"
}
run_test "spike.md has workflow:spike" test_spike_workflow_label

test_ops_workflow_label() {
    assert_file_contains "${TEMPLATES_DIR}/ops.md" "workflow:ops" \
        "ops.md should have workflow:ops label"
}
run_test "ops.md has workflow:ops" test_ops_workflow_label

# ──────────────────────────────────────────────
print_summary
