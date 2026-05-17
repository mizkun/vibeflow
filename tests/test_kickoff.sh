#!/bin/bash

# VibeFlow Test: v6 — Structured-Spec Kickoff (Bootstrap + scratch)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Kickoff — skill exists"

test_kickoff_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "vibeflow-kickoff/SKILL.md must exist"
}
run_test "vibeflow-kickoff skill exists" test_kickoff_skill_exists

# ──────────────────────────────────────────────
describe "Kickoff — skill structure"

test_has_name() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "name: vibeflow-kickoff" "Should have name in frontmatter"
}
run_test "has frontmatter name" test_has_name

test_has_description() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "description:" "Should have description"
}
run_test "has description" test_has_description

test_has_when_to_use() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "When to Use" "Should have When to Use section"
}
run_test "has When to Use section" test_has_when_to_use

# ──────────────────────────────────────────────
describe "Kickoff — content covers Vision/Plan/Spec"

test_mentions_vision() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "vision\|Vision" "Should reference Vision"
}
run_test "mentions Vision" test_mentions_vision

test_mentions_plan() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "plan\|Plan" "Should reference Plan"
}
run_test "mentions Plan" test_mentions_plan

test_mentions_spec() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "spec\|Spec" "Should reference Spec"
}
run_test "mentions Spec" test_mentions_spec

# ──────────────────────────────────────────────
describe "Kickoff — project state detection"

test_detects_new_project() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "新規\|new.*project\|scratch\|初回" "Should detect new project"
}
run_test "handles new project detection" test_detects_new_project

test_detects_existing_project() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "既存\|existing\|読み込み\|load" "Should handle existing project"
}
run_test "handles existing project" test_detects_existing_project

# ──────────────────────────────────────────────
describe "Kickoff — v6 structured-spec modes"

test_has_bootstrap() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "Bootstrap" \
        "v6 kickoff should describe Bootstrap (existing code → As-Is structured spec)"
}
run_test "describes Bootstrap mode" test_has_bootstrap

test_references_structured_spec() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-kickoff/SKILL.md" \
        "Story\|Contract" \
        "v6 kickoff should reference Story/Contract structured spec"
}
run_test "references Story/Contract structured spec" test_references_structured_spec

# ──────────────────────────────────────────────
print_summary
