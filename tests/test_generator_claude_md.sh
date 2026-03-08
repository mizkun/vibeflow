#!/bin/bash

# VibeFlow Test: Issue 1-7 — CLAUDE.md partial generation (VF:BEGIN/VF:END)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Generator — CLAUDE.md partial generation"

test_generate_claude_md_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        "core/generators/generate_claude_md.py must exist"
}
run_test "generate_claude_md.py exists" test_generate_claude_md_script_exists

# ──────────────────────────────────────────────
describe "VF:BEGIN/VF:END marker handling"

test_markers_replace_managed_section() {
    # Create a CLAUDE.md with markers
    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
# My Project

Hand-written intro.

<!-- VF:BEGIN roles -->
OLD CONTENT THAT SHOULD BE REPLACED
<!-- VF:END roles -->

More hand-written content.
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${TEST_DIR}/CLAUDE.md" 2>/dev/null

    assert_file_contains "${TEST_DIR}/CLAUDE.md" "Hand-written intro" \
        "Hand-written content before markers should be preserved"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "More hand-written content" \
        "Hand-written content after markers should be preserved"
    assert_file_not_contains "${TEST_DIR}/CLAUDE.md" "OLD CONTENT THAT SHOULD BE REPLACED" \
        "Old managed content should be replaced"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "VF:BEGIN roles" \
        "Markers should be preserved"
}
run_test "Managed section is replaced, hand-written preserved" test_markers_replace_managed_section

test_multiple_markers_handled() {
    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
# Project

<!-- VF:BEGIN roles -->
old roles
<!-- VF:END roles -->

middle text

<!-- VF:BEGIN workflow -->
old workflow
<!-- VF:END workflow -->

end text
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${TEST_DIR}/CLAUDE.md" 2>/dev/null

    assert_file_not_contains "${TEST_DIR}/CLAUDE.md" "old roles" \
        "Old roles section should be replaced"
    assert_file_not_contains "${TEST_DIR}/CLAUDE.md" "old workflow" \
        "Old workflow section should be replaced"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "middle text" \
        "Text between markers should be preserved"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "end text" \
        "Text after markers should be preserved"
}
run_test "Multiple VF:BEGIN/VF:END sections handled" test_multiple_markers_handled

test_no_markers_warns_and_skips() {
    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
# Plain CLAUDE.md

No markers here.
EOF

    local stderr_output
    stderr_output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${TEST_DIR}/CLAUDE.md" 2>&1 >/dev/null)

    assert_file_contains "${TEST_DIR}/CLAUDE.md" "No markers here" \
        "Original content should be preserved"
    assert_file_not_contains "${TEST_DIR}/CLAUDE.md" "VF:BEGIN" \
        "Markers should NOT be auto-inserted into markerless files"

    echo "$stderr_output" > "${TEST_DIR}/stderr.txt"
    assert_file_contains "${TEST_DIR}/stderr.txt" "WARNING" \
        "Should emit WARNING for markerless file"
}
run_test "No markers: WARNING only, no auto-insertion" test_no_markers_warns_and_skips

test_generated_roles_section_has_content() {
    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
<!-- VF:BEGIN roles -->
<!-- VF:END roles -->
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${TEST_DIR}/CLAUDE.md" 2>/dev/null

    assert_file_contains "${TEST_DIR}/CLAUDE.md" "Iris" \
        "Generated roles section should contain Iris"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "Engineer" \
        "Generated roles section should contain Engineer"
}
run_test "Generated roles section has schema-derived content" test_generated_roles_section_has_content

# ──────────────────────────────────────────────
describe "hook_list managed section"

test_hook_list_section_generated() {
    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
# Project

## Hooks

<!-- VF:BEGIN hook_list -->
old hook list
<!-- VF:END hook_list -->
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${TEST_DIR}/CLAUDE.md" 2>/dev/null

    assert_file_not_contains "${TEST_DIR}/CLAUDE.md" "old hook list" \
        "Old hook_list content should be replaced"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "validate_access.py" \
        "Generated hook_list should contain validate_access.py"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "validate_write.sh" \
        "Generated hook_list should contain validate_write.sh"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "validate_step7a.py" \
        "Generated hook_list should contain validate_step7a.py"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "PreToolUse" \
        "Generated hook_list should contain hook event type"
}
run_test "hook_list section is generated from schema" test_hook_list_section_generated

test_hook_list_excludes_when_soft() {
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
    cat > "${schema_dir}/roles.yaml" << 'YAML'
roles:
  engineer:
    name: "Engineer"
    description: "Implementation"
    responsibilities: []
YAML
    cat > "${schema_dir}/workflow.yaml" << 'YAML'
workflows: {}
YAML

    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
<!-- VF:BEGIN hook_list -->
placeholder
<!-- VF:END hook_list -->
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "$schema_dir" \
        --output "${TEST_DIR}/CLAUDE.md" 2>/dev/null

    assert_file_not_contains "${TEST_DIR}/CLAUDE.md" "validate_access.py" \
        "All-soft policy should not list validate_access.py"
}
run_test "hook_list omits guard hooks when all-soft enforcement" test_hook_list_excludes_when_soft

# ──────────────────────────────────────────────
describe "examples/CLAUDE.md regeneration"

test_examples_claude_md_has_markers() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" "VF:BEGIN roles" \
        "examples/CLAUDE.md should have VF:BEGIN roles marker"
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" "VF:BEGIN workflow" \
        "examples/CLAUDE.md should have VF:BEGIN workflow marker"
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" "VF:BEGIN hook_list" \
        "examples/CLAUDE.md should have VF:BEGIN hook_list marker"
}
run_test "examples/CLAUDE.md has VF markers" test_examples_claude_md_has_markers

test_examples_claude_md_regeneratable() {
    local outdir="${TEST_DIR}/regen"
    mkdir -p "$outdir"
    cp "${FRAMEWORK_DIR}/examples/CLAUDE.md" "${outdir}/CLAUDE.md"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${outdir}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/CLAUDE.md" 2>/dev/null

    # After regeneration, content should be identical (idempotent)
    diff "${FRAMEWORK_DIR}/examples/CLAUDE.md" "${outdir}/CLAUDE.md" > /dev/null 2>&1 || {
        fail "Regenerating examples/CLAUDE.md should produce identical output (idempotent)"
        return 1
    }
}
run_test "examples/CLAUDE.md is idempotent after regeneration" test_examples_claude_md_regeneratable

test_examples_claude_md_preserves_handwritten() {
    local outdir="${TEST_DIR}/regen"
    mkdir -p "$outdir"
    cp "${FRAMEWORK_DIR}/examples/CLAUDE.md" "${outdir}/CLAUDE.md"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${outdir}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${outdir}/CLAUDE.md" 2>/dev/null

    # Hand-written sections must be preserved
    assert_file_contains "${outdir}/CLAUDE.md" "Multi-Terminal Operation" \
        "Hand-written Multi-Terminal section should be preserved"
    assert_file_contains "${outdir}/CLAUDE.md" "Safety Rules" \
        "Hand-written Safety Rules section should be preserved"
}
run_test "Regeneration preserves hand-written sections" test_examples_claude_md_preserves_handwritten

# ──────────────────────────────────────────────
print_summary
