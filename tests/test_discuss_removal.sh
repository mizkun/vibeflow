#!/bin/bash

# VibeFlow Test: v5 — /discuss Removal & Always-Iris (Issue #66)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Always-Iris — Iris always-on rule"

test_iris_always_on() {
    local found=0
    # Check rules or CLAUDE.md for always-active Iris
    if grep -q "always.*active\|always.*on\|常にアクティブ\|自動.*状態読み込み" \
       "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" 2>/dev/null; then
        found=1
    elif grep -q "always.*active\|always.*on\|常にアクティブ" \
       "${FRAMEWORK_DIR}/examples/CLAUDE.md" 2>/dev/null; then
        found=1
    fi
    assert_equals "1" "$found" "Iris should be always-active"
}
run_test "Iris is always-active" test_iris_always_on

# ──────────────────────────────────────────────
describe "Always-Iris — /discuss deprecation"

test_discuss_deprecated() {
    local found=0
    # Check if discuss is deprecated/removed
    if grep -q "deprecated\|廃止\|非推奨\|removed" \
       "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-discuss/SKILL.md" 2>/dev/null; then
        found=1
    fi
    # Or check if there's a note about always-iris replacing discuss
    if grep -q "discuss.*廃止\|discuss.*deprecated\|always-iris\|always.*Iris" \
       "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" 2>/dev/null; then
        found=1
    fi
    assert_equals "1" "$found" "/discuss should be deprecated or replaced"
}
run_test "/discuss is deprecated" test_discuss_deprecated

# ──────────────────────────────────────────────
describe "Always-Iris — auto state loading"

test_auto_state_loading() {
    local found=0
    if grep -q "STATUS.md\|status.*読み込み\|auto.*load\|自動.*読み込み\|起動時" \
       "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" 2>/dev/null; then
        found=1
    fi
    assert_equals "1" "$found" "Should auto-load state on startup"
}
run_test "auto-loads state on startup" test_auto_state_loading

# ──────────────────────────────────────────────
describe "Always-Iris — /conclude redefined"

test_conclude_redefined() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-conclude/SKILL.md" \
        "Plan\|Spec\|更新\|update\|まとめ" "conclude should be redefined for plan/spec updates"
}
run_test "/conclude is redefined" test_conclude_redefined

# ──────────────────────────────────────────────
print_summary
