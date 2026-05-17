#!/bin/bash

# VibeFlow Test: v6 — Spec Gate (validate_step7a.py)
# Keystone rule: a PR that changes the structured spec (.vibe/spec/ Story/Contract)
# must go through the Human Checkpoint. qa:auto auto-pass CANNOT bypass it.
# Only a human "approved" checkpoint lets a spec-changing PR through.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK_SCRIPT="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py"

PR_CMD='{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\""}}'

run_hook() {
    local rc=0
    echo "$PR_CMD" | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    return $rc
}

create_state_with_issue() {
    mkdir -p "${TEST_DIR}/.vibe"
    cat > "${TEST_DIR}/.vibe/state.yaml" << YAML
current_issue: "${1}"
current_step: 7
phase: development
YAML
}

# qa:auto checkpoint — the artifact the auto-pass path produces
create_qa_auto_checkpoint() {
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "auto-approved:qa:auto" > "${TEST_DIR}/.vibe/checkpoints/${1}-qa-approved"
}

# human checkpoint — explicit PO approval
create_human_checkpoint() {
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "approved" > "${TEST_DIR}/.vibe/checkpoints/${1}-qa-approved"
}

# Build a base 'main' + feature branch. arg1: "spec" changes .vibe/spec/, "code" does not.
make_feature_branch() {
    cd "$TEST_DIR"
    echo "readme" > README.md
    git add -A && git commit -q -m "base"
    git branch -M main
    git checkout -q -b feature/work
    if [ "$1" = "spec" ]; then
        mkdir -p .vibe/spec/stories
        cat > .vibe/spec/stories/memory.yaml << 'YAML'
id: memory
one_liner: 記憶レイヤー
invariants: []
source_files:
  - src/
YAML
    else
        mkdir -p src
        echo "x = 1" > src/app.py
    fi
    git add -A && git commit -q -m "feature work"
}

# ──────────────────────────────────────────────
describe "spec gate — qa:auto cannot bypass a spec-changing PR"

test_spec_pr_blocked_despite_qa_auto() {
    make_feature_branch spec
    create_state_with_issue "#40"
    create_qa_auto_checkpoint "#40"
    run_hook
    assert_equals "2" "$?" "spec-changing PR must be blocked even with a qa:auto checkpoint"
}
run_test "blocks a spec-changing PR even when a qa:auto checkpoint exists" test_spec_pr_blocked_despite_qa_auto

test_spec_pr_blocked_no_checkpoint() {
    make_feature_branch spec
    create_state_with_issue "#41"
    run_hook
    assert_equals "2" "$?" "spec-changing PR with no checkpoint must be blocked"
}
run_test "blocks a spec-changing PR with no checkpoint" test_spec_pr_blocked_no_checkpoint

# ──────────────────────────────────────────────
describe "spec gate — human approval lets a spec PR through"

test_spec_pr_allowed_with_human_checkpoint() {
    make_feature_branch spec
    create_state_with_issue "#42"
    create_human_checkpoint "#42"
    run_hook
    assert_equals "0" "$?" "spec-changing PR with a human 'approved' checkpoint must pass"
}
run_test "allows a spec-changing PR with a human approved checkpoint" test_spec_pr_allowed_with_human_checkpoint

# ──────────────────────────────────────────────
describe "spec gate — non-spec PRs keep qa:auto fast path"

test_code_pr_allowed_with_qa_auto() {
    make_feature_branch code
    create_state_with_issue "#43"
    create_qa_auto_checkpoint "#43"
    run_hook
    assert_equals "0" "$?" "non-spec PR with a qa:auto checkpoint must still pass"
}
run_test "allows a code-only PR with a qa:auto checkpoint" test_code_pr_allowed_with_qa_auto

test_code_pr_allowed_with_human_checkpoint() {
    make_feature_branch code
    create_state_with_issue "#44"
    create_human_checkpoint "#44"
    run_hook
    assert_equals "0" "$?" "non-spec PR with a human checkpoint must pass"
}
run_test "allows a code-only PR with a human checkpoint" test_code_pr_allowed_with_human_checkpoint

# ──────────────────────────────────────────────
describe "spec gate — rename / deletion of spec files is caught"

# base 'main' HAS a spec file; feature branch deletes it
make_branch_deleting_spec() {
    cd "$TEST_DIR"
    mkdir -p .vibe/spec/stories
    echo "id: memory" > .vibe/spec/stories/memory.yaml
    git add -A && git commit -q -m "base with spec"
    git branch -M main
    git checkout -q -b feature/work
    git rm -q .vibe/spec/stories/memory.yaml
    git commit -q -m "remove spec"
}

test_spec_deletion_blocked() {
    make_branch_deleting_spec
    create_state_with_issue "#45"
    create_qa_auto_checkpoint "#45"
    run_hook
    assert_equals "2" "$?" "deleting a spec file must still trip the gate"
}
run_test "blocks a PR that deletes a spec file (qa:auto present)" test_spec_deletion_blocked

# ──────────────────────────────────────────────
describe "spec gate — honors the PR --base branch"

# main: base / develop: holds the spec file / feature (from develop): code only
make_branch_base_distinguishes() {
    cd "$TEST_DIR"
    echo "readme" > README.md
    git add -A && git commit -q -m "base"
    git branch -M main
    git checkout -q -b develop
    mkdir -p .vibe/spec/stories
    echo "id: x" > .vibe/spec/stories/x.yaml
    git add -A && git commit -q -m "spec on develop"
    git checkout -q -b feature/work
    mkdir -p src
    echo "x = 1" > src/app.py
    git add -A && git commit -q -m "code on feature"
}

test_base_develop_excludes_spec() {
    make_branch_base_distinguishes
    create_state_with_issue "#46"
    create_qa_auto_checkpoint "#46"
    local rc=0
    echo '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title \"feat\" --base develop"}}' \
        | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    assert_equals "0" "$rc" "with --base develop, feature diff has no spec change → qa:auto passes"
}
run_test "honors --base: spec on develop is not counted for a develop-based PR" test_base_develop_excludes_spec

test_base_absent_falls_back_to_main() {
    make_branch_base_distinguishes
    create_state_with_issue "#47"
    create_qa_auto_checkpoint "#47"
    # no --base → falls back to main; diff main...HEAD includes develop's spec file
    run_hook
    assert_equals "2" "$?" "without --base, fallback base main sees the spec change → blocked"
}
run_test "without --base, fallback to main catches the spec change" test_base_absent_falls_back_to_main

# ──────────────────────────────────────────────
describe "spec gate — robust gh pr create matching (codex High 1)"

test_spec_pr_blocked_extra_whitespace() {
    make_feature_branch spec
    create_state_with_issue "#48"
    create_qa_auto_checkpoint "#48"
    local rc=0
    echo '{"tool_name":"Bash","tool_input":{"command":"gh  pr   create --title \"feat\""}}' \
        | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    assert_equals "2" "$rc" "spec PR via 'gh  pr   create' (extra spaces) must still be gated"
}
run_test "blocks a spec PR even with extra whitespace in gh pr create" test_spec_pr_blocked_extra_whitespace

test_spec_pr_blocked_tab_separated() {
    make_feature_branch spec
    create_state_with_issue "#49"
    create_qa_auto_checkpoint "#49"
    local rc=0
    printf '{"tool_name":"Bash","tool_input":{"command":"gh\\tpr\\tcreate --title x"}}' \
        | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK_SCRIPT" 2>/dev/null || rc=$?
    assert_equals "2" "$rc" "spec PR via tab-separated gh pr create must still be gated"
}
run_test "blocks a spec PR even with tab-separated gh pr create" test_spec_pr_blocked_tab_separated

# ──────────────────────────────────────────────
describe "spec gate — missing issue state fails closed for spec PRs (codex High 2)"

test_spec_pr_blocked_issue_null() {
    make_feature_branch spec
    create_state_with_issue "null"
    run_hook
    assert_equals "2" "$?" "spec PR with current_issue null must be blocked (fail-closed)"
}
run_test "blocks a spec PR when current_issue is null" test_spec_pr_blocked_issue_null

test_spec_pr_blocked_state_missing() {
    make_feature_branch spec
    mkdir -p "${TEST_DIR}/.vibe"   # no state.yaml at all
    run_hook
    assert_equals "2" "$?" "spec PR with no state.yaml must be blocked (fail-closed)"
}
run_test "blocks a spec PR when state.yaml is missing" test_spec_pr_blocked_state_missing

test_code_pr_still_passes_issue_null() {
    make_feature_branch code
    create_state_with_issue "null"
    run_hook
    assert_equals "0" "$?" "non-spec PR with null issue keeps passing (no regression)"
}
run_test "non-spec PR with null issue still passes" test_code_pr_still_passes_issue_null

# ──────────────────────────────────────────────
describe "spec gate — quote/escape obfuscation still matched (codex re-review)"

test_spec_pr_blocked_quoted_command() {
    make_feature_branch spec
    create_state_with_issue "#50"
    create_qa_auto_checkpoint "#50"
    local pf="$TEST_DIR/payload.json"
    cat > "$pf" << 'JSON'
{"tool_name":"Bash","tool_input":{"command":"g'h' pr cre'ate' --title x"}}
JSON
    local rc=0
    CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK_SCRIPT" < "$pf" 2>/dev/null || rc=$?
    assert_equals "2" "$rc" "spec PR via quote-obfuscated gh pr create must still be gated"
}
run_test "blocks a spec PR even with shell-quote obfuscation" test_spec_pr_blocked_quoted_command

# ──────────────────────────────────────────────
describe "spec gate — unresolvable base fails closed for spec projects (codex re-review)"

# commits exist on a non-standard branch; no main/master/origin to diff against
make_branch_no_resolvable_base() {
    cd "$TEST_DIR"
    git checkout -q -b trunk   # from unborn HEAD; main/master never created
    mkdir -p .vibe/spec/stories
    echo "id: x" > .vibe/spec/stories/x.yaml
    git add -A && git commit -q -m "spec on trunk"
}

test_spec_pr_blocked_unresolvable_base() {
    make_branch_no_resolvable_base
    create_state_with_issue "#51"
    create_qa_auto_checkpoint "#51"
    run_hook
    assert_equals "2" "$?" "unresolvable base + .vibe/spec present must fail closed"
}
run_test "blocks a spec PR when base is unresolvable and .vibe/spec exists" test_spec_pr_blocked_unresolvable_base

# ──────────────────────────────────────────────
print_summary
