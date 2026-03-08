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

test_no_markers_inserts_at_end() {
    cat > "${TEST_DIR}/CLAUDE.md" << 'EOF'
# Plain CLAUDE.md

No markers here.
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_claude_md.py" \
        --input "${TEST_DIR}/CLAUDE.md" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --output "${TEST_DIR}/CLAUDE.md" 2>/dev/null

    assert_file_contains "${TEST_DIR}/CLAUDE.md" "No markers here" \
        "Original content should be preserved"
    assert_file_contains "${TEST_DIR}/CLAUDE.md" "VF:BEGIN" \
        "Markers should be inserted"
}
run_test "No markers: sections appended with markers" test_no_markers_inserts_at_end

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
print_summary
