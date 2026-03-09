#!/bin/bash

# VibeFlow Test: v5 — Playwright Default (Issue #55)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Playwright Default — setup defaults"

test_with_e2e_default_true() {
    assert_file_contains "${FRAMEWORK_DIR}/setup_vibeflow.sh" \
        'WITH_E2E=.*true\|WITH_E2E:-true\|WITH_E2E:=true' \
        "WITH_E2E should default to true"
}
run_test "WITH_E2E defaults to true" test_with_e2e_default_true

test_without_e2e_flag() {
    assert_file_contains "${FRAMEWORK_DIR}/setup_vibeflow.sh" \
        "without-e2e\|without_e2e\|no-e2e" \
        "Should support --without-e2e opt-out flag"
}
run_test "supports --without-e2e flag" test_without_e2e_flag

# ──────────────────────────────────────────────
describe "Playwright Default — rules for UI issues"

test_playwright_rules_exist() {
    local found=0
    # Check in examples rules or CLAUDE.md for Playwright requirement on UI issues
    if [ -f "${FRAMEWORK_DIR}/examples/.claude/rules/playwright.md" ]; then
        found=1
    elif grep -q "playwright.*UI\|UI.*playwright\|Playwright.*必須\|ui.*playwright" \
         "${FRAMEWORK_DIR}/examples/CLAUDE.md" 2>/dev/null; then
        found=1
    elif ls "${FRAMEWORK_DIR}/examples/.claude/rules/"*playwright* 2>/dev/null | grep -q .; then
        found=1
    fi
    assert_equals "1" "$found" "Playwright rules for UI issues should exist"
}
run_test "Playwright rules for UI issues exist" test_playwright_rules_exist

# ──────────────────────────────────────────────
describe "Playwright Default — migration support"

test_migration_script_exists() {
    local found=0
    # Check for migration support (either in migrations/ or in setup)
    if ls "${FRAMEWORK_DIR}/migrations/"*playwright* 2>/dev/null | grep -q .; then
        found=1
    elif [ -f "${FRAMEWORK_DIR}/migrations/v5_playwright_default.sh" ]; then
        found=1
    elif assert_file_contains "${FRAMEWORK_DIR}/setup_vibeflow.sh" \
         "playwright" 2>/dev/null; then
        found=1
    fi
    assert_equals "1" "$found" "Playwright migration support should exist"
}
run_test "migration support exists" test_migration_script_exists

# ──────────────────────────────────────────────
describe "Playwright Default — setup integration"

test_setup_calls_playwright_by_default() {
    # The setup should call create_playwright_mcp without requiring --with-e2e
    local output
    output=$(bash "${FRAMEWORK_DIR}/setup_vibeflow.sh" --help 2>&1 || true)
    echo "$output" > "${TEST_DIR}/setup_help.txt"
    # Verify the help mentions e2e is default or --without-e2e is the opt-out
    assert_file_contains "${TEST_DIR}/setup_help.txt" \
        "without-e2e\|e2e.*default\|Playwright" \
        "Help should mention e2e default or --without-e2e"
}
run_test "setup mentions Playwright in help" test_setup_calls_playwright_by_default

# ──────────────────────────────────────────────
print_summary
