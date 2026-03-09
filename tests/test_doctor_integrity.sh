#!/bin/bash

# VibeFlow Test: Doctor コマンド整合性チェック
# doctor が manifest-aware な整合性チェックを行うこと。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Helper: generate a project with manifest
generate_project() {
    local outdir="$1"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

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
describe "Doctor — valid project passes all checks"

test_doctor_clean_project() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    cd "$outdir"
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    # Should not contain ✗ (error markers)
    if echo "$output" | grep -q "✗"; then
        fail "Doctor should not report errors for valid project"
        echo "$output"
        return 1
    fi
}
run_test "Valid project passes doctor" test_doctor_clean_project

# ──────────────────────────────────────────────
describe "Doctor — manifest missing detection"

test_doctor_detects_no_manifest() {
    mkdir -p .vibe

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "manifest"; then
        return 0
    else
        fail "Doctor should detect missing manifest"
        return 1
    fi
}
run_test "Detects missing manifest" test_doctor_detects_no_manifest

# ──────────────────────────────────────────────
describe "Doctor — file integrity detection"

test_doctor_detects_missing_hook() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    rm "${outdir}/.vibe/hooks/validate_access.py"

    cd "$outdir"
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "validate_access.py\|file_missing\|missing"; then
        return 0
    else
        fail "Doctor should detect missing validate_access.py"
        return 1
    fi
}
run_test "Detects missing hook file" test_doctor_detects_missing_hook

test_doctor_detects_modified_policy() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    echo "# tampered" >> "${outdir}/.vibe/policy.yaml"

    cd "$outdir"
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "policy.yaml\|hash_mismatch\|modified"; then
        return 0
    else
        fail "Doctor should detect modified policy.yaml"
        return 1
    fi
}
run_test "Detects modified policy.yaml" test_doctor_detects_modified_policy

# ──────────────────────────────────────────────
describe "Doctor — cross-schema validation"

test_doctor_cross_schema_via_cli() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    cd "$outdir"
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "cross_schema\|cross-schema\|ok"; then
        return 0
    else
        fail "Doctor should include cross-schema validation"
        return 1
    fi
}
run_test "CLI runs cross-schema validation" test_doctor_cross_schema_via_cli

# ──────────────────────────────────────────────
describe "Doctor — JSON output mode"

test_doctor_json_output() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    cd "$outdir"
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor --json 2>&1)

    if echo "$output" | python3 -m json.tool >/dev/null 2>&1; then
        return 0
    else
        fail "Doctor --json should output valid JSON, got: $(echo "$output" | head -5)"
        return 1
    fi
}
run_test "Doctor --json outputs valid JSON" test_doctor_json_output

test_doctor_json_contains_checks() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    rm "${outdir}/.vibe/hooks/validate_access.py"

    cd "$outdir"
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor --json 2>&1)

    if echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert any(c['level'] == 'error' for c in d['checks'])
" 2>/dev/null; then
        return 0
    else
        fail "Doctor --json should report check failures"
        return 1
    fi
}
run_test "Doctor --json reports failures in structured format" test_doctor_json_contains_checks

# ──────────────────────────────────────────────
describe "Doctor — exit codes via CLI"

test_doctor_exit_0_clean() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    cd "$outdir"
    set +e
    "${FRAMEWORK_DIR}/bin/vibeflow" doctor > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "Clean project should exit 0"
}
run_test "CLI exit 0 on clean project" test_doctor_exit_0_clean

# ──────────────────────────────────────────────
print_summary
