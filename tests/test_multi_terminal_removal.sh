#!/bin/bash

# VibeFlow Test: v5 — Multi-Terminal Removal (Issue #67)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Multi-Terminal Removal — no multi-terminal references"

test_claude_md_no_multi_terminal() {
    # CLAUDE.md should not reference multi-terminal operation
    assert_file_not_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "Terminal 1.*Terminal 2\|マルチターミナル\|multi-terminal\|Multi-Terminal" \
        "CLAUDE.md should not reference multi-terminal"
}
run_test "CLAUDE.md has no multi-terminal" test_claude_md_no_multi_terminal

# ──────────────────────────────────────────────
describe "Multi-Terminal Removal — rules updated"

test_rules_no_multi_terminal() {
    local found=0
    for rule in "${FRAMEWORK_DIR}/examples/.claude/rules/"*.md; do
        if grep -q "Terminal 1.*Terminal 2\|マルチターミナル\|multi-terminal" "$rule" 2>/dev/null; then
            found=1
        fi
    done
    assert_equals "0" "$found" "Rules should not reference multi-terminal"
}
run_test "rules have no multi-terminal" test_rules_no_multi_terminal

# ──────────────────────────────────────────────
describe "Multi-Terminal Removal — Iris manages sessions"

test_iris_manages_sessions() {
    local found=0
    if grep -q "session.*管理\|manages.*session\|Iris.*session\|session.*Iris" \
       "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" 2>/dev/null; then
        found=1
    fi
    assert_equals "1" "$found" "Iris should manage all sessions"
}
run_test "Iris manages all sessions" test_iris_manages_sessions

# ──────────────────────────────────────────────
describe "Multi-Terminal Removal — single terminal model"

test_single_terminal() {
    local found=0
    if grep -q "単一ターミナル\|single.*terminal\|Iris.*only\|Iris のみ" \
       "${FRAMEWORK_DIR}/examples/.claude/rules/iris-core.md" 2>/dev/null; then
        found=1
    elif grep -q "単一ターミナル\|single.*terminal\|Iris.*only\|Iris のみ" \
       "${FRAMEWORK_DIR}/examples/CLAUDE.md" 2>/dev/null; then
        found=1
    fi
    assert_equals "1" "$found" "Should describe single-terminal model"
}
run_test "describes single-terminal model" test_single_terminal

# ──────────────────────────────────────────────
print_summary
