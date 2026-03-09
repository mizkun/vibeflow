#!/bin/bash

# VibeFlow Test: Phase 1.5 — Manifest-aware upgrade (Issue 1.5-2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Helper: create a v3.5 project with stock files
create_v35_stock_project() {
    local dir="$1"
    mkdir -p "${dir}/.vibe/hooks" "${dir}/.vibe/roles" "${dir}/.vibe/context"
    mkdir -p "${dir}/.claude/commands" "${dir}/.github/ISSUE_TEMPLATE"

    # Copy stock files from examples/lib (matching baseline hashes)
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" "${dir}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_write.sh" "${dir}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py" "${dir}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/checkpoint_alert.sh" "${dir}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/task_complete.sh" "${dir}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/waiting_input.sh" "${dir}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/policy.yaml" "${dir}/.vibe/"
    cp "${FRAMEWORK_DIR}/examples/CLAUDE.md" "${dir}/CLAUDE.md"
    cp "${FRAMEWORK_DIR}/examples/.vibe/context/STATUS.md" "${dir}/.vibe/context/"

    for f in "${FRAMEWORK_DIR}/lib/roles/"*.md; do
        cp "$f" "${dir}/.vibe/roles/"
    done
    for f in "${FRAMEWORK_DIR}/lib/commands/"*.md; do
        cp "$f" "${dir}/.claude/commands/"
    done

    echo "3.5.0" > "${dir}/.vibe/version"

    cd "$dir"
    git add -A && git commit -q -m "v3.5.0 project"
}

# Helper: generate a project with manifest
generate_project() {
    local outdir="$1"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    cat > "${outdir}/CLAUDE.md" << 'EOF'
# My Project
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

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null
}

# ──────────────────────────────────────────────
describe "upgrade.py — module exists"

test_upgrade_module_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/upgrade.py" \
        "core/upgrade.py must exist"
}
run_test "core/upgrade.py exists" test_upgrade_module_exists

# ──────────────────────────────────────────────
describe "upgrade — dry-run classification"

test_dry_run_stock_project() {
    create_v35_stock_project "${TEST_DIR}/project"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --dry-run 2>&1)

    echo "$output" > "${TEST_DIR}/upgrade_output.txt"

    assert_file_contains "${TEST_DIR}/upgrade_output.txt" "stock-managed" \
        "Should identify stock-managed files"
}
run_test "Dry-run identifies stock-managed files" test_dry_run_stock_project

test_dry_run_customized_detection() {
    create_v35_stock_project "${TEST_DIR}/project"

    # Customize a file
    echo "# user code" >> "${TEST_DIR}/project/.vibe/hooks/validate_access.py"
    cd "${TEST_DIR}/project" && git add -A && git commit -q -m "customize"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --dry-run 2>&1)

    echo "$output" > "${TEST_DIR}/upgrade_output.txt"

    assert_file_contains "${TEST_DIR}/upgrade_output.txt" "customized" \
        "Should identify customized files"
}
run_test "Dry-run identifies customized files" test_dry_run_customized_detection

# ──────────────────────────────────────────────
describe "upgrade — dirty tree rejection"

test_upgrade_rejects_dirty_tree() {
    create_v35_stock_project "${TEST_DIR}/project"
    echo "dirty" > "${TEST_DIR}/project/dirty_file.txt"

    set +e
    python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null
    local code=$?
    set -e

    assert_equals "1" "$code" "Should reject dirty working tree"
}
run_test "Rejects dirty working tree" test_upgrade_rejects_dirty_tree

test_upgrade_allows_dirty_with_flag() {
    create_v35_stock_project "${TEST_DIR}/project"
    echo "dirty" > "${TEST_DIR}/project/dirty_file.txt"

    set +e
    python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --allow-dirty \
        --dry-run 2>/dev/null
    local code=$?
    set -e

    assert_equals "0" "$code" "Should allow with --allow-dirty"
}
run_test "Allows dirty tree with --allow-dirty" test_upgrade_allows_dirty_with_flag

# ──────────────────────────────────────────────
describe "upgrade — customized file safety"

test_upgrade_preserves_customized() {
    create_v35_stock_project "${TEST_DIR}/project"

    # Customize validate_access.py
    echo "# MY CUSTOM CODE" >> "${TEST_DIR}/project/.vibe/hooks/validate_access.py"
    cd "${TEST_DIR}/project" && git add -A && git commit -q -m "customize"

    python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null || true

    # Customized file should NOT be overwritten
    assert_file_contains "${TEST_DIR}/project/.vibe/hooks/validate_access.py" \
        "MY CUSTOM CODE" \
        "Customized file should be preserved"
}
run_test "Preserves customized files" test_upgrade_preserves_customized

# ──────────────────────────────────────────────
describe "upgrade — manifest-aware"

test_upgrade_uses_manifest() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"
    generate_project "$outdir"

    cd "$outdir" && git add -A && git commit -q -m "generated project"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --dry-run 2>&1)

    echo "$output" > "${TEST_DIR}/upgrade_output.txt"

    # Should mention manifest-based classification
    assert_file_contains "${TEST_DIR}/upgrade_output.txt" "manifest" \
        "Should use manifest for classification"
}
run_test "Uses manifest when available" test_upgrade_uses_manifest

test_upgrade_uses_baseline_without_manifest() {
    create_v35_stock_project "${TEST_DIR}/project"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --dry-run 2>&1)

    echo "$output" > "${TEST_DIR}/upgrade_output.txt"

    assert_file_contains "${TEST_DIR}/upgrade_output.txt" "baseline" \
        "Should use baseline when no manifest"
}
run_test "Uses baseline when no manifest" test_upgrade_uses_baseline_without_manifest

# ──────────────────────────────────────────────
describe "upgrade — report output"

test_upgrade_produces_report() {
    create_v35_stock_project "${TEST_DIR}/project"

    python3 "${FRAMEWORK_DIR}/core/upgrade.py" \
        --project-dir "${TEST_DIR}/project" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null || true

    # Should create a report file
    local report_dir="${TEST_DIR}/project/.vibe/upgrade-reports"
    if [ -d "$report_dir" ] && [ "$(ls -1 "$report_dir" 2>/dev/null | wc -l)" -gt 0 ]; then
        return 0
    else
        fail "Should create upgrade report in .vibe/upgrade-reports/"
        return 1
    fi
}
run_test "Produces upgrade report" test_upgrade_produces_report

# ──────────────────────────────────────────────
describe "upgrade — CLI integration"

test_vibeflow_upgrade_help() {
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" help 2>&1)
    echo "$output" | grep -q "upgrade" || {
        fail "vibeflow help should list upgrade command"
        return 1
    }
}
run_test "vibeflow help lists upgrade command" test_vibeflow_upgrade_help

# ──────────────────────────────────────────────
print_summary
