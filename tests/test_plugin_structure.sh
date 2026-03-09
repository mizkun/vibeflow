#!/bin/bash

# VibeFlow Test: Phase 4 — Plugin-compatible structure (Issue 4-3)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Plugin — directory structure"

test_plugin_dir_exists() {
    assert_dir_exists "${FRAMEWORK_DIR}/plugin" \
        "plugin/ directory must exist"
}
run_test "plugin/ exists" test_plugin_dir_exists

test_plugin_skills_dir() {
    assert_dir_exists "${FRAMEWORK_DIR}/plugin/skills" \
        "plugin/skills/ must exist"
}
run_test "plugin/skills/ exists" test_plugin_skills_dir

test_plugin_hooks_dir() {
    assert_dir_exists "${FRAMEWORK_DIR}/plugin/hooks" \
        "plugin/hooks/ must exist"
}
run_test "plugin/hooks/ exists" test_plugin_hooks_dir

test_plugin_agents_dir() {
    assert_dir_exists "${FRAMEWORK_DIR}/plugin/agents" \
        "plugin/agents/ must exist"
}
run_test "plugin/agents/ exists" test_plugin_agents_dir

test_plugin_commands_dir() {
    assert_dir_exists "${FRAMEWORK_DIR}/plugin/commands" \
        "plugin/commands/ must exist"
}
run_test "plugin/commands/ exists" test_plugin_commands_dir

# ──────────────────────────────────────────────
describe "Plugin — plugin.json"

test_plugin_json_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/.claude-plugin/plugin.json" \
        ".claude-plugin/plugin.json must exist"
}
run_test "plugin.json exists" test_plugin_json_exists

test_plugin_json_valid() {
    python3 -c "import json; json.load(open('${FRAMEWORK_DIR}/.claude-plugin/plugin.json'))" 2>/dev/null
    assert_equals "0" "$?" "plugin.json should be valid JSON"
}
run_test "plugin.json is valid JSON" test_plugin_json_valid

test_plugin_json_has_name() {
    assert_file_contains "${FRAMEWORK_DIR}/.claude-plugin/plugin.json" \
        '"name"' "plugin.json should have name field"
}
run_test "plugin.json has name" test_plugin_json_has_name

test_plugin_json_has_version() {
    assert_file_contains "${FRAMEWORK_DIR}/.claude-plugin/plugin.json" \
        '"version"' "plugin.json should have version field"
}
run_test "plugin.json has version" test_plugin_json_has_version

test_plugin_json_has_provides() {
    assert_file_contains "${FRAMEWORK_DIR}/.claude-plugin/plugin.json" \
        '"provides"' "plugin.json should have provides field"
}
run_test "plugin.json has provides" test_plugin_json_has_provides

# ──────────────────────────────────────────────
describe "Plugin — mapping consistency"

test_plugin_skills_map_to_examples() {
    # Each skill in examples/ should be referenced in plugin/skills/
    local plugin_readme="${FRAMEWORK_DIR}/plugin/skills/README.md"
    [ -f "$plugin_readme" ] || { echo "FAIL: plugin/skills/README.md missing"; return 1; }
    for skill_dir in "${FRAMEWORK_DIR}"/examples/.claude/skills/vibeflow-*/; do
        local skill_name
        skill_name=$(basename "$skill_dir")
        grep -q "$skill_name" "$plugin_readme"
        assert_equals "0" "$?" "plugin/skills/ should reference ${skill_name}"
    done
}
run_test "plugin skills map to all examples skills" test_plugin_skills_map_to_examples

test_plugin_hooks_map_to_examples() {
    local plugin_readme="${FRAMEWORK_DIR}/plugin/hooks/README.md"
    [ -f "$plugin_readme" ] || { echo "FAIL: plugin/hooks/README.md missing"; return 1; }
    for hook in validate_access.py validate_write.sh validate_step7a.py; do
        grep -q "$hook" "$plugin_readme"
        assert_equals "0" "$?" "plugin/hooks/ should reference ${hook}"
    done
}
run_test "plugin hooks map to all examples hooks" test_plugin_hooks_map_to_examples

test_plugin_agents_map_to_examples() {
    local plugin_readme="${FRAMEWORK_DIR}/plugin/agents/README.md"
    [ -f "$plugin_readme" ] || { echo "FAIL: plugin/agents/README.md missing"; return 1; }
    for agent in code-reviewer qa-acceptance test-runner; do
        grep -q "$agent" "$plugin_readme"
        assert_equals "0" "$?" "plugin/agents/ should reference ${agent}"
    done
}
run_test "plugin agents map to all examples agents" test_plugin_agents_map_to_examples

# ──────────────────────────────────────────────
describe "Plugin — docs"

test_architecture_doc_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/docs/architecture.md" \
        "docs/architecture.md must exist"
}
run_test "docs/architecture.md exists" test_architecture_doc_exists

test_architecture_covers_plugin() {
    assert_file_contains "${FRAMEWORK_DIR}/docs/architecture.md" \
        "plugin" "docs/architecture.md should cover plugin structure"
}
run_test "architecture doc covers plugin" test_architecture_covers_plugin

test_architecture_covers_standalone() {
    assert_file_contains "${FRAMEWORK_DIR}/docs/architecture.md" \
        "standalone\|setup_vibeflow\|Standalone" \
        "docs/architecture.md should cover standalone setup"
}
run_test "architecture doc covers standalone" test_architecture_covers_standalone

test_architecture_covers_coexistence() {
    assert_file_contains "${FRAMEWORK_DIR}/docs/architecture.md" \
        "examples/" "docs should explain examples/ as source of truth"
}
run_test "architecture doc explains examples/ role" test_architecture_covers_coexistence

# ──────────────────────────────────────────────
describe "Plugin — standalone non-regression"

test_setup_vibeflow_unchanged() {
    # setup_vibeflow.sh should NOT reference plugin/ directly
    # (plugin is optional layer, not part of standard setup)
    if grep -q "plugin/" "${FRAMEWORK_DIR}/setup_vibeflow.sh"; then
        echo "FAIL: setup_vibeflow.sh should not reference plugin/"
        return 1
    fi
    assert_equals "0" "$?" "setup_vibeflow.sh should not depend on plugin/"
}
run_test "setup_vibeflow.sh does not depend on plugin/" test_setup_vibeflow_unchanged

test_examples_still_source_of_truth() {
    # examples/ directory should still contain all skills
    local count
    count=$(ls -d "${FRAMEWORK_DIR}"/examples/.claude/skills/vibeflow-*/ 2>/dev/null | wc -l)
    [ "$count" -ge 8 ]
    assert_equals "0" "$?" "examples/ should still have >= 8 skills (current: ${count})"
}
run_test "examples/ still has all skills" test_examples_still_source_of_truth

test_existing_skills_tests_pass() {
    # Run the existing skills test suite to confirm non-regression
    bash "${FRAMEWORK_DIR}/tests/test_skills.sh" >/dev/null 2>&1
    assert_equals "0" "$?" "test_skills.sh should still pass"
}
run_test "existing skills tests still pass" test_existing_skills_tests_pass

test_existing_playwright_tests_pass() {
    bash "${FRAMEWORK_DIR}/tests/test_playwright.sh" >/dev/null 2>&1
    assert_equals "0" "$?" "test_playwright.sh should still pass"
}
run_test "existing playwright tests still pass" test_existing_playwright_tests_pass

# ──────────────────────────────────────────────
print_summary
