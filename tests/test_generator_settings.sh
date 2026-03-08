#!/bin/bash

# VibeFlow Test: Issue 1-6 — Generator: settings.json + role docs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Generator — settings.json generation"

test_generate_settings_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_settings.py" \
        "core/generators/generate_settings.py must exist"
}
run_test "generate_settings.py exists" test_generate_settings_script_exists

test_generate_settings_produces_valid_json() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_settings.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "$outdir" 2>/dev/null

    assert_file_exists "${outdir}/settings.json" \
        "Generator should produce settings.json"

    python3 -c "import json; json.load(open('${outdir}/settings.json'))" 2>&1 || {
        fail "Generated settings.json is not valid JSON"
        return 1
    }
}
run_test "Generated settings.json is valid JSON" test_generate_settings_produces_valid_json

test_settings_has_pretooluse_hooks() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_settings.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "$outdir" 2>/dev/null

    assert_file_contains "${outdir}/settings.json" "PreToolUse" \
        "settings.json should have PreToolUse section"
    assert_file_contains "${outdir}/settings.json" "validate_access.py" \
        "settings.json should reference validate_access.py"
    assert_file_contains "${outdir}/settings.json" "validate_write.sh" \
        "settings.json should reference validate_write.sh"
    assert_file_contains "${outdir}/settings.json" "validate_step7a.py" \
        "settings.json should reference validate_step7a.py"
}
run_test "settings.json has all hook references" test_settings_has_pretooluse_hooks

test_settings_has_posttooluse_and_stop() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_settings.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "$outdir" 2>/dev/null

    assert_file_contains "${outdir}/settings.json" "PostToolUse" \
        "settings.json should have PostToolUse section"
    assert_file_contains "${outdir}/settings.json" "Stop" \
        "settings.json should have Stop section"
}
run_test "settings.json has PostToolUse and Stop" test_settings_has_posttooluse_and_stop

test_settings_no_pretooluse_when_all_soft() {
    # Create a schema dir with all-soft enforcement
    local schema_dir="${TEST_DIR}/soft-schema"
    mkdir -p "$schema_dir"
    cat > "${schema_dir}/policy.yaml" << 'YAML'
roles:
  engineer:
    display_name: "Engineer"
    can_read: ["src/**"]
    can_write: ["src/**"]
    enforcement: soft
always_allow: []
YAML

    local outdir="${TEST_DIR}/soft-generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_settings.py" \
        --schema-dir "$schema_dir" \
        --output "$outdir" 2>/dev/null

    assert_file_not_contains "${outdir}/settings.json" "validate_access.py" \
        "All-soft policy should not include validate_access.py hook"
}
run_test "All-soft enforcement: no PreToolUse hooks" test_settings_no_pretooluse_when_all_soft

# ──────────────────────────────────────────────
describe "Generator — policy.yaml generation"

test_generate_policy_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_policy.py" \
        "core/generators/generate_policy.py must exist"
}
run_test "generate_policy.py exists" test_generate_policy_script_exists

test_generate_policy_produces_full_fidelity() {
    local outdir="${TEST_DIR}/generated-policy"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_policy.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    assert_file_exists "${outdir}/policy.yaml" \
        "Generator should produce policy.yaml"
    assert_file_contains "${outdir}/policy.yaml" "enforcement" \
        "Generated policy should include enforcement field"
    assert_file_contains "${outdir}/policy.yaml" "display_name" \
        "Generated policy should include display_name field"
    assert_file_contains "${outdir}/policy.yaml" "human" \
        "Generated policy should include human role"
    assert_file_contains "${outdir}/policy.yaml" "always_allow" \
        "Generated policy should include always_allow section"
}
run_test "generate_policy.py produces full-fidelity output" test_generate_policy_produces_full_fidelity

# ──────────────────────────────────────────────
describe "Generator — role docs generation"

test_generate_docs_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_docs.py" \
        "core/generators/generate_docs.py must exist"
}
run_test "generate_docs.py exists" test_generate_docs_script_exists

test_generate_docs_produces_role_files() {
    local outdir="${TEST_DIR}/generated/roles"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_docs.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "$outdir" 2>/dev/null

    for role in iris product-manager engineer qa-engineer infra-manager human; do
        assert_file_exists "${outdir}/${role}.md" \
            "Generator should produce ${role}.md"
    done
}
run_test "Generator produces role doc files" test_generate_docs_produces_role_files

test_role_docs_contain_permissions() {
    local outdir="${TEST_DIR}/generated/roles"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_docs.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "$outdir" 2>/dev/null

    assert_file_contains "${outdir}/iris.md" "can_write\|Can Edit\|Can Write" \
        "Iris role doc should contain write permissions"
    assert_file_contains "${outdir}/engineer.md" "src/" \
        "Engineer role doc should reference src/"
}
run_test "Role docs contain permission info from policy" test_role_docs_contain_permissions

# ──────────────────────────────────────────────
describe "Generator — additional hooks"

test_generate_hooks_produces_write_guard() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    assert_file_exists "${outdir}/validate_write.sh" \
        "Generator should produce validate_write.sh"
    assert_file_contains "${outdir}/validate_write.sh" "plans/" \
        "validate_write.sh should block plans/ directory"
}
run_test "generate_hooks.py produces validate_write.sh" test_generate_hooks_produces_write_guard

test_generate_hooks_produces_step7a() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    assert_file_exists "${outdir}/validate_step7a.py" \
        "Generator should produce validate_step7a.py"
    assert_file_contains "${outdir}/validate_step7a.py" "qa-approved" \
        "validate_step7a.py should reference qa-approved checkpoint"
}
run_test "generate_hooks.py produces validate_step7a.py" test_generate_hooks_produces_step7a

# ──────────────────────────────────────────────
describe "Cross-file schema validation"

test_workflow_roles_validated_against_policy() {
    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        --cross "${FRAMEWORK_DIR}/core/schema" 2>&1 || {
        fail "Cross-file validation should pass for valid schemas"
        return 1
    }
}
run_test "Cross-file validation passes for valid schemas" test_workflow_roles_validated_against_policy

# ──────────────────────────────────────────────
print_summary
