#!/bin/bash

# VibeFlow Test: vibeflow-execute-issue Skill

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Execute Issue — skill exists"

test_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "vibeflow-execute-issue SKILL.md must exist"
}
run_test "SKILL.md exists" test_skill_exists

test_skill_registered() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-execute-issue" \
        "Skill must be registered in create_skills.sh"
}
run_test "registered in create_skills.sh" test_skill_registered

# ──────────────────────────────────────────────
describe "Execute Issue — 11-Step workflow coverage"

test_has_issue_review() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "Issue Review\|issue.*review\|Issue 確認" \
        "Must include Issue Review step"
}
run_test "Step 1: Issue Review" test_has_issue_review

test_has_tdd() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "TDD\|Red.*Green\|テスト.*先" \
        "Must include TDD instructions"
}
run_test "Step 4-6: TDD cycle" test_has_tdd

test_has_qa_judgment() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "qa_judge\|QA.*判定\|QA.*judgment" \
        "Must include QA judgment step"
}
run_test "Step 7: QA judgment" test_has_qa_judgment

test_has_human_checkpoint() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "needs_human\|ユーザー.*確認\|Human.*Checkpoint" \
        "Must include human checkpoint"
}
run_test "Step 7a: Human checkpoint" test_has_human_checkpoint

test_has_pr_creation() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "gh pr create\|PR.*作成\|Pull Request" \
        "Must include PR creation step"
}
run_test "Step 8: PR creation" test_has_pr_creation

test_has_cross_review() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "cross.*review\|クロスレビュー\|レビュー.*dispatch" \
        "Must include cross-review step"
}
run_test "Step 9: Cross-review" test_has_cross_review

test_has_merge_and_close() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "merge\|close\|マージ\|クローズ" \
        "Must include merge and close steps"
}
run_test "Step 10-11: Merge and close" test_has_merge_and_close

# ──────────────────────────────────────────────
describe "Execute Issue — role switching"

test_has_role_switch() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "current_role\|role.*switch\|ロール.*切替" \
        "Must include role switching mechanism"
}
run_test "role switching documented" test_has_role_switch

# ──────────────────────────────────────────────
describe "Execute Issue — Playwright for UI tasks"

test_has_playwright_ui() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "playwright\|Playwright" \
        "Must include Playwright for UI tasks"
}
run_test "Playwright for UI tasks" test_has_playwright_ui

# ──────────────────────────────────────────────
describe "Execute Issue — retry and error handling"

test_has_retry() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "リトライ\|retry\|最大.*3\|3.*回" \
        "Must include retry mechanism"
}
run_test "retry on failure" test_has_retry

# ──────────────────────────────────────────────
print_summary
