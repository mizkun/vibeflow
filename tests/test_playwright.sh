#!/bin/bash

# VibeFlow Test: Phase 4 — Playwright MCP + UI skills (Issue 4-1)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Playwright — MCP template"

test_mcp_example_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.mcp.json.example" \
        ".mcp.json.example must exist"
}
run_test ".mcp.json.example exists" test_mcp_example_exists

test_mcp_has_playwright() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.mcp.json.example" \
        "playwright" ".mcp.json.example should reference playwright"
}
run_test ".mcp.json.example references playwright" test_mcp_has_playwright

test_mcp_is_valid_json() {
    python3 -c "import json; json.load(open('${FRAMEWORK_DIR}/examples/.mcp.json.example'))" 2>/dev/null
    assert_equals "0" "$?" ".mcp.json.example should be valid JSON"
}
run_test ".mcp.json.example is valid JSON" test_mcp_is_valid_json

# ──────────────────────────────────────────────
describe "Playwright — scripts exist"

test_smoke_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/playwright_smoke.sh" \
        "playwright_smoke.sh must exist"
}
run_test "playwright_smoke.sh exists" test_smoke_exists

test_smoke_executable() {
    [ -x "${FRAMEWORK_DIR}/scripts/playwright_smoke.sh" ]
    assert_equals "0" "$?" "playwright_smoke.sh should be executable"
}
run_test "playwright_smoke.sh is executable" test_smoke_executable

test_open_report_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/playwright_open_report.sh" \
        "playwright_open_report.sh must exist"
}
run_test "playwright_open_report.sh exists" test_open_report_exists

test_open_report_executable() {
    [ -x "${FRAMEWORK_DIR}/scripts/playwright_open_report.sh" ]
    assert_equals "0" "$?" "playwright_open_report.sh should be executable"
}
run_test "playwright_open_report.sh is executable" test_open_report_executable

test_trace_pack_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/playwright_trace_pack.sh" \
        "playwright_trace_pack.sh must exist"
}
run_test "playwright_trace_pack.sh exists" test_trace_pack_exists

test_trace_pack_executable() {
    [ -x "${FRAMEWORK_DIR}/scripts/playwright_trace_pack.sh" ]
    assert_equals "0" "$?" "playwright_trace_pack.sh should be executable"
}
run_test "playwright_trace_pack.sh is executable" test_trace_pack_executable

# ──────────────────────────────────────────────
describe "Playwright — script content"

test_smoke_has_playwright_test() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/playwright_smoke.sh" \
        "playwright" "smoke should reference playwright"
}
run_test "smoke references playwright" test_smoke_has_playwright_test

test_trace_pack_has_artifacts() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/playwright_trace_pack.sh" \
        "trace\|screenshot\|report" "trace_pack should mention artifacts"
}
run_test "trace_pack mentions artifacts" test_trace_pack_has_artifacts

test_smoke_shows_usage() {
    local output
    output=$(bash "${FRAMEWORK_DIR}/scripts/playwright_smoke.sh" --help 2>&1 || true)
    echo "$output" > "${TEST_DIR}/smoke_usage.txt"
    assert_file_contains "${TEST_DIR}/smoke_usage.txt" "Usage\|usage\|smoke" \
        "smoke --help should show usage"
}
run_test "smoke shows usage" test_smoke_shows_usage

# ──────────────────────────────────────────────
describe "Playwright — UI skills exist"

test_ui_smoke_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-smoke/SKILL.md" \
        "vibeflow-ui-smoke SKILL.md must exist"
}
run_test "vibeflow-ui-smoke exists" test_ui_smoke_skill_exists

test_ui_explore_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-explore/SKILL.md" \
        "vibeflow-ui-explore SKILL.md must exist"
}
run_test "vibeflow-ui-explore exists" test_ui_explore_skill_exists

# ──────────────────────────────────────────────
describe "Playwright — UI skills structure"

test_ui_smoke_has_name() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-smoke/SKILL.md" \
        "name: vibeflow-ui-smoke" "Should have name in frontmatter"
}
run_test "ui-smoke has frontmatter name" test_ui_smoke_has_name

test_ui_explore_has_name() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-explore/SKILL.md" \
        "name: vibeflow-ui-explore" "Should have name in frontmatter"
}
run_test "ui-explore has frontmatter name" test_ui_explore_has_name

test_ui_smoke_has_when_to_use() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-smoke/SKILL.md" \
        "When to Use" "Should have When to Use section"
}
run_test "ui-smoke has When to Use" test_ui_smoke_has_when_to_use

test_ui_explore_has_when_to_use() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-explore/SKILL.md" \
        "When to Use" "Should have When to Use section"
}
run_test "ui-explore has When to Use" test_ui_explore_has_when_to_use

# ──────────────────────────────────────────────
describe "Playwright — quality gate"

test_ui_smoke_has_quality_gate() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-smoke/SKILL.md" \
        "quality gate\|品質ゲート\|artifact" "ui-smoke should mention quality gate or artifacts"
}
run_test "ui-smoke mentions quality gate" test_ui_smoke_has_quality_gate

test_ui_explore_has_quality_gate() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-ui-explore/SKILL.md" \
        "quality gate\|品質ゲート\|artifact" "ui-explore should mention quality gate or artifacts"
}
run_test "ui-explore mentions quality gate" test_ui_explore_has_quality_gate

# ──────────────────────────────────────────────
describe "Playwright — docs"

test_playwright_docs_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/docs/playwright.md" \
        "docs/playwright.md must exist"
}
run_test "docs/playwright.md exists" test_playwright_docs_exists

test_docs_has_setup() {
    assert_file_contains "${FRAMEWORK_DIR}/docs/playwright.md" \
        "setup\|セットアップ\|Setup" "docs should cover setup"
}
run_test "docs covers setup" test_docs_has_setup

test_docs_has_mcp() {
    assert_file_contains "${FRAMEWORK_DIR}/docs/playwright.md" \
        "mcp.json" "docs should reference .mcp.json"
}
run_test "docs references mcp.json" test_docs_has_mcp

test_docs_has_quality_gate() {
    assert_file_contains "${FRAMEWORK_DIR}/docs/playwright.md" \
        "quality gate\|品質ゲート" "docs should define quality gate"
}
run_test "docs defines quality gate" test_docs_has_quality_gate

# ──────────────────────────────────────────────
describe "Playwright — create_skills.sh updated"

test_create_skills_has_ui_smoke() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-ui-smoke" "create_skills.sh should include vibeflow-ui-smoke"
}
run_test "create_skills.sh includes ui-smoke" test_create_skills_has_ui_smoke

test_create_skills_has_ui_explore() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-ui-explore" "create_skills.sh should include vibeflow-ui-explore"
}
run_test "create_skills.sh includes ui-explore" test_create_skills_has_ui_explore

# ──────────────────────────────────────────────
print_summary
