#!/bin/bash

# VibeFlow Test: Phase 3 — AGENTS.md Generation (Issue 3-2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "AGENTS.md generator — files exist"

test_template_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/templates/AGENTS.md.j2" \
        "core/templates/AGENTS.md.j2 must exist"
}
run_test "AGENTS.md.j2 template exists" test_template_exists

test_generator_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        "core/generators/generate_agents_md.py must exist"
}
run_test "generate_agents_md.py exists" test_generator_exists

# ──────────────────────────────────────────────
describe "AGENTS.md generator — standalone generation"

test_generates_agents_md() {
    local outdir="${TEST_DIR}/agents_gen"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    assert_file_exists "${outdir}/AGENTS.md" "AGENTS.md should be generated"
}
run_test "generator produces AGENTS.md" test_generates_agents_md

# ──────────────────────────────────────────────
describe "AGENTS.md — policy-derived content"

test_has_file_access_rules() {
    local outdir="${TEST_DIR}/agents_policy"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    assert_file_contains "${outdir}/AGENTS.md" "allowed" \
        "AGENTS.md should mention allowed paths"
    assert_file_contains "${outdir}/AGENTS.md" "forbidden" \
        "AGENTS.md should mention forbidden paths"
}
run_test "AGENTS.md has file access rules" test_has_file_access_rules

test_has_role_permissions() {
    local outdir="${TEST_DIR}/agents_roles"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    assert_file_contains "${outdir}/AGENTS.md" "Engineer" \
        "AGENTS.md should mention Engineer role"
    assert_file_contains "${outdir}/AGENTS.md" "can_write" \
        "AGENTS.md should show can_write permissions"
}
run_test "AGENTS.md has role permissions" test_has_role_permissions

# ──────────────────────────────────────────────
describe "AGENTS.md — workflow-derived content"

test_has_workflow_rules() {
    local outdir="${TEST_DIR}/agents_workflow"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    assert_file_contains "${outdir}/AGENTS.md" "Standard" \
        "AGENTS.md should mention Standard workflow"
    assert_file_contains "${outdir}/AGENTS.md" "Patch" \
        "AGENTS.md should mention Patch workflow"
}
run_test "AGENTS.md has workflow rules" test_has_workflow_rules

test_has_validation_section() {
    local outdir="${TEST_DIR}/agents_validation"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    assert_file_contains "${outdir}/AGENTS.md" "validation" \
        "AGENTS.md should mention validation"
}
run_test "AGENTS.md has validation section" test_has_validation_section

# ──────────────────────────────────────────────
describe "AGENTS.md — Codex-specific content"

test_has_codex_instructions() {
    local outdir="${TEST_DIR}/agents_codex"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    assert_file_contains "${outdir}/AGENTS.md" "max_files_changed" \
        "AGENTS.md should mention max_files_changed constraint"
}
run_test "AGENTS.md has Codex constraints" test_has_codex_instructions

# ──────────────────────────────────────────────
describe "AGENTS.md — generate_all.py integration"

test_generate_all_agents_md_target() {
    local outdir="${TEST_DIR}/gen_all_agents"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.vibe/roles" "${outdir}/.claude"

    # Need a CLAUDE.md with markers for generate_all
    cp "${FRAMEWORK_DIR}/examples/CLAUDE.md" "${outdir}/CLAUDE.md"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --target agents_md 2>/dev/null

    assert_file_exists "${outdir}/AGENTS.md" "generate_all --target agents_md should produce AGENTS.md"
}
run_test "generate_all --target agents_md works" test_generate_all_agents_md_target

test_generate_all_includes_agents_md() {
    local outdir="${TEST_DIR}/gen_all_full"
    mkdir -p "${outdir}/.vibe/hooks" "${outdir}/.vibe/roles" "${outdir}/.claude"

    cp "${FRAMEWORK_DIR}/examples/CLAUDE.md" "${outdir}/CLAUDE.md"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$outdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${outdir}/AGENTS.md" "Full generate_all should produce AGENTS.md"
}
run_test "full generate_all produces AGENTS.md" test_generate_all_includes_agents_md

# ──────────────────────────────────────────────
describe "AGENTS.md — examples/ freshness"

test_examples_agents_md_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/AGENTS.md" \
        "examples/AGENTS.md should exist"
}
run_test "examples/AGENTS.md exists" test_examples_agents_md_exists

test_examples_agents_md_has_content() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/AGENTS.md" "Engineer" \
        "examples/AGENTS.md should have role content"
    assert_file_contains "${FRAMEWORK_DIR}/examples/AGENTS.md" "allowed" \
        "examples/AGENTS.md should have access rules"
}
run_test "examples/AGENTS.md has expected content" test_examples_agents_md_has_content

# ──────────────────────────────────────────────
describe "AGENTS.md — idempotent generation"

test_idempotent_generation() {
    local outdir="${TEST_DIR}/idem"
    mkdir -p "$outdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    local hash1
    hash1=$(shasum "${outdir}/AGENTS.md" | cut -d' ' -f1)

    python3 "${FRAMEWORK_DIR}/core/generators/generate_agents_md.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/AGENTS.md" 2>/dev/null

    local hash2
    hash2=$(shasum "${outdir}/AGENTS.md" | cut -d' ' -f1)

    assert_equals "$hash1" "$hash2" "Generating twice should produce identical output"
}
run_test "generation is idempotent" test_idempotent_generation

# ──────────────────────────────────────────────
print_summary
