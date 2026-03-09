#!/bin/bash

# VibeFlow Test: Phase 1.5 — vibeflow doctor (manifest-aware integrity check)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Helper: generate a full project with manifest
generate_project() {
    local outdir="$1"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    # Create a CLAUDE.md with VF markers
    cat > "${outdir}/CLAUDE.md" << 'EOF'
# My Project

<!-- VF:BEGIN roles -->
old roles
<!-- VF:END roles -->

<!-- VF:BEGIN workflow -->
old workflow
<!-- VF:END workflow -->

<!-- VF:BEGIN hook_list -->
old hooks
<!-- VF:END hook_list -->
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null
}

# ──────────────────────────────────────────────
describe "doctor.py — module exists"

test_doctor_module_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/doctor.py" \
        "core/doctor.py must exist"
}
run_test "core/doctor.py exists" test_doctor_module_exists

# ──────────────────────────────────────────────
describe "doctor — manifest integrity (all OK)"

test_doctor_all_ok() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    # Should be valid JSON
    python3 -c "import json; json.load(open('${TEST_DIR}/doctor_output.json'))" || {
        fail "doctor --json should produce valid JSON"
        return 1
    }

    # No errors
    local error_count
    error_count=$(python3 -c "
import json
with open('${TEST_DIR}/doctor_output.json') as f:
    data = json.load(f)
print(sum(1 for c in data['checks'] if c['level'] == 'error'))
")
    assert_equals "0" "$error_count" "Should have no errors on fresh project"
}
run_test "Fresh project passes doctor" test_doctor_all_ok

# ──────────────────────────────────────────────
describe "doctor — file hash mismatch"

test_doctor_detects_modified_file() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Tamper with a generated file
    echo "# tampered" >> "${outdir}/.vibe/policy.yaml"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    assert_file_contains "${TEST_DIR}/doctor_output.json" "hash_mismatch" \
        "Should detect hash mismatch for modified file"
}
run_test "Detects modified generated file" test_doctor_detects_modified_file

test_doctor_detects_missing_file() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Delete a generated file
    rm "${outdir}/.vibe/hooks/validate_access.py"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    assert_file_contains "${TEST_DIR}/doctor_output.json" "file_missing" \
        "Should detect missing generated file"
}
run_test "Detects missing generated file" test_doctor_detects_missing_file

# ──────────────────────────────────────────────
describe "doctor — CLAUDE.md managed section check"

test_doctor_detects_section_modification() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Tamper with a managed section in CLAUDE.md
    sed -i.bak 's/<!-- VF:BEGIN roles -->/<!-- VF:BEGIN roles -->\nTAMPERED/' \
        "${outdir}/CLAUDE.md"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    assert_file_contains "${TEST_DIR}/doctor_output.json" "section_modified" \
        "Should detect modified managed section"
}
run_test "Detects CLAUDE.md managed section modification" test_doctor_detects_section_modification

# ──────────────────────────────────────────────
describe "doctor — version drift"

test_doctor_detects_version_drift() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Change generator_version in manifest
    python3 -c "
import json
with open('${outdir}/.vibe/generated-manifest.json') as f:
    data = json.load(f)
data['generator_version'] = '0.0.1-old'
with open('${outdir}/.vibe/generated-manifest.json', 'w') as f:
    json.dump(data, f, indent=2)
"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    assert_file_contains "${TEST_DIR}/doctor_output.json" "version_drift" \
        "Should detect version drift"
}
run_test "Detects version drift" test_doctor_detects_version_drift

# ──────────────────────────────────────────────
describe "doctor — cross-schema validation"

test_doctor_cross_schema_ok() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    # cross_schema check should pass
    local cross_errors
    cross_errors=$(python3 -c "
import json
with open('${TEST_DIR}/doctor_output.json') as f:
    data = json.load(f)
print(sum(1 for c in data['checks'] if c['name'].startswith('cross_') and c['level'] == 'error'))
")
    assert_equals "0" "$cross_errors" "Cross-schema should pass with valid schemas"
}
run_test "Cross-schema passes with valid schemas" test_doctor_cross_schema_ok

test_doctor_labels_workflow_mismatch() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Create a bad issue_labels.yaml with unknown workflow
    local schema_dir="${TEST_DIR}/schemas"
    cp -r "${FRAMEWORK_DIR}/core/schema" "$schema_dir"

    cat > "${schema_dir}/issue_labels.yaml" << 'YAML'
categories:
  type:
    description: "Type labels"
    labels:
      - name: "type:dev"
        color: "0e8a16"
        description: "Dev"
  risk:
    description: "Risk labels"
    labels:
      - name: "risk:low"
        color: "c2e0c6"
        description: "Low"
  qa:
    description: "QA labels"
    labels:
      - name: "qa:auto"
        color: "0e8a16"
        description: "Auto"
  workflow:
    description: "Workflow labels"
    labels:
      - name: "workflow:standard"
        color: "0075ca"
        description: "Standard"
      - name: "workflow:nonexistent"
        color: "ff0000"
        description: "This workflow does not exist"
YAML

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "$schema_dir" \
        --json 2>&1)

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    assert_file_contains "${TEST_DIR}/doctor_output.json" "nonexistent" \
        "Should detect workflow label not matching workflow.yaml"
}
run_test "Detects labels/workflow mismatch" test_doctor_labels_workflow_mismatch

# ──────────────────────────────────────────────
describe "doctor — exit codes"

test_doctor_exit_0_on_ok() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    set +e
    python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "Should exit 0 on clean project"
}
run_test "Exit 0 on clean project" test_doctor_exit_0_on_ok

test_doctor_exit_1_on_error() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    rm "${outdir}/.vibe/hooks/validate_access.py"

    set +e
    python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "1" "$code" "Should exit 1 on error"
}
run_test "Exit 1 on error" test_doctor_exit_1_on_error

test_doctor_exit_0_on_warn_normal() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Create version drift (warn only)
    python3 -c "
import json
with open('${outdir}/.vibe/generated-manifest.json') as f:
    data = json.load(f)
data['generator_version'] = '0.0.1-old'
with open('${outdir}/.vibe/generated-manifest.json', 'w') as f:
    json.dump(data, f, indent=2)
"

    set +e
    python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "Should exit 0 on warn-only (normal mode)"
}
run_test "Exit 0 on warn-only (normal mode)" test_doctor_exit_0_on_warn_normal

test_doctor_exit_1_on_warn_strict() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    # Create version drift (warn only)
    python3 -c "
import json
with open('${outdir}/.vibe/generated-manifest.json') as f:
    data = json.load(f)
data['generator_version'] = '0.0.1-old'
with open('${outdir}/.vibe/generated-manifest.json', 'w') as f:
    json.dump(data, f, indent=2)
"

    set +e
    python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --strict > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "1" "$code" "Should exit 1 on warn with --strict"
}
run_test "Exit 1 on warn with --strict" test_doctor_exit_1_on_warn_strict

# ──────────────────────────────────────────────
describe "doctor — manifest missing"

test_doctor_no_manifest() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe"

    set +e
    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$outdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --json 2>&1)
    local code=$?
    set -e

    echo "$output" > "${TEST_DIR}/doctor_output.json"

    assert_file_contains "${TEST_DIR}/doctor_output.json" "manifest_missing" \
        "Should report manifest missing"
    assert_equals "1" "$code" "Missing manifest should be error"
}
run_test "Reports missing manifest as error" test_doctor_no_manifest

# ──────────────────────────────────────────────
describe "doctor — CLI integration"

test_vibeflow_doctor_subcommand() {
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" help 2>&1)
    echo "$output" | grep -q "doctor" || {
        fail "vibeflow help should list doctor command"
        return 1
    }
}
run_test "vibeflow help lists doctor command" test_vibeflow_doctor_subcommand

# ──────────────────────────────────────────────
print_summary
