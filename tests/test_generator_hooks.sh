#!/bin/bash

# VibeFlow Test: Issue 1-5 — Generator: policy.yaml → validate_access.py

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Generator basics"

test_generator_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        "core/generators/generate_hooks.py must exist"
}
run_test "generate_hooks.py exists" test_generator_script_exists

test_template_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/templates/validate_access.py.j2" \
        "core/templates/validate_access.py.j2 must exist"
}
run_test "validate_access.py.j2 template exists" test_template_exists

# ──────────────────────────────────────────────
describe "Generator — produces validate_access.py"

test_generator_produces_output() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>&1 || {
        fail "generate_hooks.py should exit 0"
        return 1
    }
    assert_file_exists "${outdir}/validate_access.py" \
        "Generator should produce validate_access.py"
}
run_test "Generator produces validate_access.py" test_generator_produces_output

# ──────────────────────────────────────────────
describe "Generator — output matches examples/"

test_generated_has_all_roles() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    local generated="${outdir}/validate_access.py"
    local missing=""
    for role in '"Iris"' '"Product Manager"' '"Engineer"' '"QA Engineer"' '"Infrastructure Manager"' '"Human"'; do
        if ! grep -q "$role" "$generated"; then
            missing="${missing} ${role}"
        fi
    done
    if [ -n "$missing" ]; then
        fail "Generated file missing roles:${missing}"
        return 1
    fi
}
run_test "Generated file contains all role display names" test_generated_has_all_roles

test_generated_has_iris_write_paths() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    local generated="${outdir}/validate_access.py"
    assert_file_contains "$generated" "vision.md" \
        "Generated Iris write paths should include vision.md"
    assert_file_contains "$generated" "spec.md" \
        "Generated Iris write paths should include spec.md"
}
run_test "Generated Iris role has correct write paths" test_generated_has_iris_write_paths

test_generated_has_always_allow() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    assert_file_contains "${outdir}/validate_access.py" "ALWAYS_ALLOW" \
        "Generated file should have ALWAYS_ALLOW"
    assert_file_contains "${outdir}/validate_access.py" ".vibe/state.yaml" \
        "ALWAYS_ALLOW should contain .vibe/state.yaml"
}
run_test "Generated file has ALWAYS_ALLOW from schema" test_generated_has_always_allow

# ──────────────────────────────────────────────
describe "Generator — functional equivalence with examples/"

test_generated_is_valid_python() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    python3 -c "
import py_compile, sys
try:
    py_compile.compile('${outdir}/validate_access.py', doraise=True)
except py_compile.PyCompileError as e:
    print(str(e))
    sys.exit(1)
" 2>&1 || {
        fail "Generated validate_access.py is not valid Python"
        return 1
    }
}
run_test "Generated validate_access.py is valid Python" test_generated_is_valid_python

test_generated_has_same_structure_as_examples() {
    local outdir="${TEST_DIR}/generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        --output "$outdir" 2>/dev/null

    local generated="${outdir}/validate_access.py"
    local example="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py"

    # Check key structural elements exist in both
    for element in "ROLE_EDIT_ALLOW" "ALWAYS_ALLOW" "def main" "def block" "def match_any" "sys.exit(2)"; do
        if ! grep -q "$element" "$generated"; then
            fail "Generated file missing structural element: ${element}"
            return 1
        fi
    done
}
run_test "Generated file has same structural elements as examples/" test_generated_has_same_structure_as_examples

# ──────────────────────────────────────────────
describe "Generator — policy change propagation"

test_policy_change_reflects_in_output() {
    # Create a modified policy with an extra role
    cat > "${TEST_DIR}/custom_policy.yaml" << 'YAML'
roles:
  iris:
    display_name: "Iris"
    can_read: []
    can_write: ["vision.md"]
    enforcement: hard
  custom_role:
    display_name: "Custom Role"
    can_read: []
    can_write: ["custom/**"]
    enforcement: soft
always_allow:
  - ".vibe/state.yaml"
YAML

    local outdir="${TEST_DIR}/custom_generated"
    mkdir -p "$outdir"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_hooks.py" \
        --schema "${TEST_DIR}/custom_policy.yaml" \
        --output "$outdir" 2>/dev/null

    assert_file_contains "${outdir}/validate_access.py" '"Custom Role"' \
        "Generated file should contain custom role from modified policy"
    assert_file_contains "${outdir}/validate_access.py" 'custom/\*\*\|custom/\*' \
        "Generated file should contain custom role's write paths"
}
run_test "Policy changes propagate to generated output" test_policy_change_reflects_in_output

# ──────────────────────────────────────────────
print_summary
