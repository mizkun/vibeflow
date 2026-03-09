#!/bin/bash

# VibeFlow Test: Issue 1-9 — vibeflow generate コマンド

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "generate_all.py — module exists"

test_generate_all_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        "core/generators/generate_all.py must exist"
}
run_test "generate_all.py exists" test_generate_all_exists

# ──────────────────────────────────────────────
describe "generate_all.py — full generation"

test_generate_all_produces_hooks() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${outdir}/.vibe/hooks/validate_access.py" \
        "Should generate validate_access.py"
    assert_file_exists "${outdir}/.vibe/hooks/validate_write.sh" \
        "Should generate validate_write.sh"
    assert_file_exists "${outdir}/.vibe/hooks/validate_step7a.py" \
        "Should generate validate_step7a.py"
}
run_test "Full generation produces hook files" test_generate_all_produces_hooks

test_generate_all_produces_settings() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${outdir}/.claude/settings.json" \
        "Should generate settings.json"
    assert_file_contains "${outdir}/.claude/settings.json" "PreToolUse" \
        "settings.json should contain PreToolUse"
}
run_test "Full generation produces settings.json" test_generate_all_produces_settings

test_generate_all_produces_policy() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${outdir}/.vibe/policy.yaml" \
        "Should generate policy.yaml"
    assert_file_contains "${outdir}/.vibe/policy.yaml" "enforcement" \
        "policy.yaml should contain enforcement"
    assert_file_contains "${outdir}/.vibe/policy.yaml" "human" \
        "policy.yaml should contain human role"
}
run_test "Full generation produces policy.yaml" test_generate_all_produces_policy

test_generate_all_produces_role_docs() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${outdir}/.vibe/roles/iris.md" \
        "Should generate iris.md role doc"
    assert_file_exists "${outdir}/.vibe/roles/engineer.md" \
        "Should generate engineer.md role doc"
}
run_test "Full generation produces role docs" test_generate_all_produces_role_docs

test_generate_all_produces_manifest() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${outdir}/.vibe/generated-manifest.json" \
        "Should generate manifest"
    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "generator_version" \
        "Manifest should contain generator_version"
}
run_test "Full generation produces manifest" test_generate_all_produces_manifest

# ──────────────────────────────────────────────
describe "generate_all.py — CLAUDE.md handling"

test_generate_all_updates_claude_md_with_markers() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    cat > "${outdir}/CLAUDE.md" << 'EOF'
# My Project

Hand-written intro.

<!-- VF:BEGIN roles -->
old roles
<!-- VF:END roles -->

Hand-written outro.
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_contains "${outdir}/CLAUDE.md" "Hand-written intro" \
        "Hand-written content should be preserved"
    assert_file_contains "${outdir}/CLAUDE.md" "Hand-written outro" \
        "Hand-written outro should be preserved"
    assert_file_not_contains "${outdir}/CLAUDE.md" "old roles" \
        "Old managed content should be replaced"
    assert_file_contains "${outdir}/CLAUDE.md" "Iris" \
        "Generated roles should contain Iris"
}
run_test "CLAUDE.md with markers is updated" test_generate_all_updates_claude_md_with_markers

test_generate_all_warns_markerless_claude_md() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    echo "# Plain CLAUDE.md" > "${outdir}/CLAUDE.md"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>&1)

    assert_file_contains "${outdir}/CLAUDE.md" "Plain CLAUDE.md" \
        "Markerless CLAUDE.md should not be modified"
    assert_file_not_contains "${outdir}/CLAUDE.md" "VF:BEGIN" \
        "Markers should not be auto-inserted"
}
run_test "Markerless CLAUDE.md gets warning only" test_generate_all_warns_markerless_claude_md

# ──────────────────────────────────────────────
describe "generate_all.py — --target option"

test_target_hooks_only() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --target hooks 2>/dev/null

    assert_file_exists "${outdir}/.vibe/hooks/validate_access.py" \
        "hooks target should produce validate_access.py"
    assert_file_not_exists "${outdir}/.claude/settings.json" \
        "hooks target should not produce settings.json"
}
run_test "--target hooks generates only hooks" test_target_hooks_only

test_target_settings_only() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --target settings 2>/dev/null

    assert_file_exists "${outdir}/.claude/settings.json" \
        "settings target should produce settings.json"
    assert_file_not_exists "${outdir}/.vibe/hooks/validate_access.py" \
        "settings target should not produce hooks"
}
run_test "--target settings generates only settings" test_target_settings_only

# ──────────────────────────────────────────────
describe "generate_all.py — --diff option"

test_diff_shows_changes() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.claude"

    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --diff 2>&1)

    # --diff should NOT create files
    assert_file_not_exists "${outdir}/.vibe/hooks/validate_access.py" \
        "--diff should not create files"

    # Should show what would be generated
    echo "$output" > "${TEST_DIR}/diff_output.txt"
    assert_file_contains "${TEST_DIR}/diff_output.txt" "validate_access.py\|settings.json\|policy.yaml" \
        "--diff should list files that would be generated"
}
run_test "--diff shows changes without writing" test_diff_shows_changes

# ──────────────────────────────────────────────
describe "vibeflow generate CLI"

test_vibeflow_generate_subcommand() {
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" help 2>&1)
    echo "$output" | grep -q "generate" || {
        fail "vibeflow help should list generate command"
        return 1
    }
}
run_test "vibeflow help lists generate command" test_vibeflow_generate_subcommand

# ──────────────────────────────────────────────
print_summary
