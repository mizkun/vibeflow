#!/bin/bash

# VibeFlow Test: v5 — CLAUDE.md → rules/ Restructure (Issue #65)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Rules — directory exists"

test_rules_dir_exists() {
    assert_dir_exists "${FRAMEWORK_DIR}/examples/.claude/rules" \
        ".claude/rules directory must exist"
}
run_test "rules/ directory exists" test_rules_dir_exists

# ──────────────────────────────────────────────
describe "Rules — core rule files"

test_iris_core_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" \
        "iris-core.md must exist"
}
run_test "iris-core.md exists" test_iris_core_exists

test_workflow_standard_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/rules/workflow-standard.md" \
        "workflow-standard.md must exist"
}
run_test "workflow-standard.md exists" test_workflow_standard_exists

test_workflow_patch_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/rules/workflow-patch.md" \
        "workflow-patch.md must exist"
}
run_test "workflow-patch.md exists" test_workflow_patch_exists

test_safety_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/rules/safety.md" \
        "safety.md must exist"
}
run_test "safety.md exists" test_safety_exists

# ──────────────────────────────────────────────
describe "Rules — iris-core content"

test_iris_core_has_responsibilities() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" \
        "責務\|Responsibilities\|dispatch\|QA" "Should define Iris responsibilities"
}
run_test "iris-core defines responsibilities" test_iris_core_has_responsibilities

# ──────────────────────────────────────────────
describe "Rules — workflow content"

test_standard_has_steps() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/workflow-standard.md" \
        "Step\|step\|ステップ" "Should define workflow steps"
}
run_test "workflow-standard has steps" test_standard_has_steps

test_patch_has_steps() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/workflow-patch.md" \
        "Step\|step\|ステップ\|Scope\|Fix" "Should define patch steps"
}
run_test "workflow-patch has steps" test_patch_has_steps

# ──────────────────────────────────────────────
describe "Rules — safety content"

test_safety_has_rules() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/safety.md" \
        "safety\|Safety\|destructive\|破壊的\|guard" "Should define safety rules"
}
run_test "safety.md has rules" test_safety_has_rules

# ──────────────────────────────────────────────
describe "Rules — playwright rule exists"

test_playwright_rule_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/rules/playwright.md" \
        "playwright.md must exist"
}
run_test "playwright.md exists" test_playwright_rule_exists

# ──────────────────────────────────────────────
describe "Rules — CLAUDE.md is concise"

test_claude_md_concise() {
    local line_count
    line_count=$(wc -l < "${FRAMEWORK_DIR}/examples/CLAUDE.md")
    # Compressed to ~50 lines in Issue #69
    [ "$line_count" -le 60 ]
    assert_equals "0" "$?" "CLAUDE.md should be ≤60 lines (got $line_count)"
}
run_test "CLAUDE.md is concise (≤60 lines)" test_claude_md_concise

# ──────────────────────────────────────────────
print_summary
