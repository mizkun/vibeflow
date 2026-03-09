#!/bin/bash

# VibeFlow Test: Phase 1.5 — CI freshness check (Issue 1.5-4)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "CI freshness — files exist"

test_freshness_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/check_freshness.sh" \
        "scripts/check_freshness.sh must exist"
}
run_test "check_freshness.sh exists" test_freshness_script_exists

test_workflow_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/.github/workflows/generate-check.yml" \
        ".github/workflows/generate-check.yml must exist"
}
run_test "generate-check.yml exists" test_workflow_exists

# ──────────────────────────────────────────────
describe "CI freshness — workflow structure"

test_workflow_triggers() {
    assert_file_contains "${FRAMEWORK_DIR}/.github/workflows/generate-check.yml" \
        "core/schema" \
        "Should trigger on schema changes"
    assert_file_contains "${FRAMEWORK_DIR}/.github/workflows/generate-check.yml" \
        "core/generators" \
        "Should trigger on generator changes"
}
run_test "Workflow triggers on schema/generator changes" test_workflow_triggers

test_workflow_runs_check() {
    assert_file_contains "${FRAMEWORK_DIR}/.github/workflows/generate-check.yml" \
        "check_freshness.sh" \
        "Should run freshness check script"
}
run_test "Workflow runs check_freshness.sh" test_workflow_runs_check

test_workflow_installs_deps() {
    assert_file_contains "${FRAMEWORK_DIR}/.github/workflows/generate-check.yml" \
        "pyyaml" \
        "Should install pyyaml"
}
run_test "Workflow installs Python dependencies" test_workflow_installs_deps

# ──────────────────────────────────────────────
describe "CI freshness — script behavior"

test_freshness_passes_when_fresh() {
    # Running against real examples/ should pass (they should be fresh)
    set +e
    bash "${FRAMEWORK_DIR}/scripts/check_freshness.sh" > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "Fresh examples/ should pass"
}
run_test "Passes when examples/ are fresh" test_freshness_passes_when_fresh

test_freshness_detects_stale() {
    # Create a temp project with stale files
    local tmpdir="${TEST_DIR}/stale_project"
    mkdir -p "${tmpdir}/.vibe/hooks" "${tmpdir}/.claude"

    cat > "${tmpdir}/CLAUDE.md" << 'EOF'
# Project
<!-- VF:BEGIN roles -->
old
<!-- VF:END roles -->
<!-- VF:BEGIN workflow -->
old
<!-- VF:END workflow -->
<!-- VF:BEGIN hook_list -->
old
<!-- VF:END hook_list -->
EOF

    # Generate to create files
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    # Now tamper with a generated file to make it "stale"
    echo "# stale" >> "${tmpdir}/.vibe/policy.yaml"

    # Run generate --diff and check for modifications
    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --diff 2>&1)

    echo "$output" > "${TEST_DIR}/diff_output.txt"

    assert_file_contains "${TEST_DIR}/diff_output.txt" "modified" \
        "Should detect modified file"
}
run_test "Detects stale generated files" test_freshness_detects_stale

# ──────────────────────────────────────────────
print_summary
