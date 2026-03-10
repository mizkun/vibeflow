#!/bin/bash

# VibeFlow Test: vibeflow-execute-all Skill

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Execute All — skill exists"

test_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-all/SKILL.md" \
        "vibeflow-execute-all SKILL.md must exist"
}
run_test "SKILL.md exists" test_skill_exists

test_skill_registered() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-execute-all" \
        "Skill must be registered in create_skills.sh"
}
run_test "registered in create_skills.sh" test_skill_registered

# ──────────────────────────────────────────────
describe "Execute All — dependency ordering"

test_has_dependency_analysis() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-all/SKILL.md" \
        "dependency\|依存\|execution_order\|dependency_analyzer" \
        "Must reference dependency analysis"
}
run_test "dependency analysis" test_has_dependency_analysis

# ──────────────────────────────────────────────
describe "Execute All — issue loop"

test_has_issue_list() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-all/SKILL.md" \
        "gh issue list\|open.*Issue\|Issue.*一覧" \
        "Must get open issues"
}
run_test "fetches open issues" test_has_issue_list

test_has_execute_issue_ref() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-all/SKILL.md" \
        "execute-issue\|vibeflow-execute-issue\|11.*Step\|11.*ステップ" \
        "Must reference execute-issue skill"
}
run_test "references execute-issue" test_has_execute_issue_ref

# ──────────────────────────────────────────────
describe "Execute All — progress reporting"

test_has_progress_report() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-all/SKILL.md" \
        "進捗\|progress\|報告\|サマリ\|summary" \
        "Must include progress reporting"
}
run_test "progress reporting" test_has_progress_report

# ──────────────────────────────────────────────
print_summary
