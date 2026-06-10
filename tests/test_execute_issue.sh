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
describe "Execute Issue — fail-closed QA chain (no fake pass)"

SKILL="${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md"

test_no_provisional_pass() {
    # The Step 7 judgment must not feed a fabricated review_verdict
    # 'pass' before the cross-review has run.
    assert_file_not_contains "$SKILL" "初回は仮 pass" \
        "Step 7 must not fabricate review_verdict='pass'" || return 1
    assert_file_contains "$SKILL" "'pending'" \
        "Step 7 should pass review_verdict='pending'" || return 1
}
run_test "Step 7 uses review_verdict=pending, not a fake pass" test_no_provisional_pass

test_has_step_9_5_final_judgment() {
    assert_file_contains "$SKILL" "Step 9.5" \
        "needs a Step 9.5 re-judgment with the real review verdict" || return 1
    assert_file_contains "$SKILL" "確定判定" \
        "Step 9.5 should be described as the final judgment" || return 1
}
run_test "Step 9.5 re-judges with the real review verdict" test_has_step_9_5_final_judgment

test_test_evidence_is_captured() {
    assert_file_contains "$SKILL" ".vibe/reports/" \
        "test output must be captured under .vibe/reports/" || return 1
    assert_file_contains "$SKILL" "test.exit" \
        "the test exit code must be saved as evidence" || return 1
    assert_file_contains "$SKILL" "'evidence'" \
        "qa_judge context must include the evidence dict" || return 1
}
run_test "Step 7 captures test log + exit code as evidence" test_test_evidence_is_captured

test_review_failure_handling() {
    assert_file_contains "$SKILL" "review.md" \
        "cross-review result must be persisted (review.md)" || return 1
    assert_file_contains "$SKILL" "verdict 抽出不能" \
        "reviewer crash / unparseable verdict handling must be specified" || return 1
}
run_test "Step 9 persists review + handles reviewer failure" test_review_failure_handling

test_completion_report_has_evidence() {
    # the completion report must carry evidence, not bare checkmarks
    assert_file_contains "$SKILL" "test.log" \
        "completion report must reference the captured test log" || return 1
}
run_test "Step 11 report is evidence-based" test_completion_report_has_evidence

test_workflow_standard_synced() {
    local wf="${FRAMEWORK_DIR}/examples/.claude/rules/workflow-standard.md"
    assert_file_contains "$wf" "Step 9.5" \
        "workflow-standard.md must document the Step 9.5 final judgment" || return 1
}
run_test "workflow-standard.md documents Step 9.5" test_workflow_standard_synced

# ──────────────────────────────────────────────
describe "Execute Issue — spec loop wiring (Issue = Spec 差分)"

test_has_tobe_spec_step() {
    assert_file_contains "$SKILL" "Step 3.5" \
        "needs Step 3.5: To-Be spec editing on the issue branch" || return 1
    assert_file_contains "$SKILL" "To-Be" \
        "Step 3.5 should describe the To-Be spec edit" || return 1
    assert_file_contains "$SKILL" "## Spec 変更" \
        "the issue's Spec 変更 section drives the To-Be edit" || return 1
}
run_test "Step 3.5: To-Be spec editing is wired" test_has_tobe_spec_step

test_has_spec_verify_gate() {
    assert_file_contains "$SKILL" "spec-verify" \
        "Step 7 must run spec-verify before judgment" || return 1
}
run_test "Step 7 runs spec-verify" test_has_spec_verify_gate

test_checkpoint_shows_spec_diff() {
    assert_file_contains "$SKILL" "diff.*\.vibe/spec/" \
        "Step 7a must present the As-Is→To-Be spec diff" || return 1
}
run_test "Step 7a presents the spec diff" test_checkpoint_shows_spec_diff

test_checkpoint_packet_generated() {
    assert_file_contains "$SKILL" "packet.md" \
        "Step 7a must produce a checkpoint packet file" || return 1
    assert_file_contains "$SKILL" "AC チェックリスト" \
        "packet carries the AC checklist with test names" || return 1
    assert_file_contains "$SKILL" "スコープ外" \
        "packet lists out-of-scope changes" || return 1
    assert_file_contains "$SKILL" "invariant 接触" \
        "packet lists touched invariants (best-effort)" || return 1
}
run_test "Step 7a builds a checkpoint packet (PO decides without reading code)" test_checkpoint_packet_generated

# ──────────────────────────────────────────────
print_summary
