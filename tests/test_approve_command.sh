#!/bin/bash

# Tests for `vibeflow approve <issue>` and the checkpoint self-approval lock.
#
# The Human Checkpoint is fail-closed only if the agent cannot create the
# approval itself. Previously the skill had the agent run
# `echo approved > .vibe/checkpoints/<n>-qa-approved`. Now:
#  - the approval is created by `vibeflow approve`, which requires a TTY
#    (the agent's Bash tool has no TTY → deterministically PO-only)
#  - BashGuard denies writes to .vibe/checkpoints/ via redirection/tee/etc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

VIBEFLOW="${FRAMEWORK_DIR}/bin/vibeflow"
BASH_HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_bash.py"

# ──────────────────────────────────────────────
describe "vibeflow approve — requires a TTY (agent cannot self-approve)"

test_approve_without_tty_fails() {
    cd "$TEST_DIR"
    mkdir -p .vibe/checkpoints
    echo "# packet" > .vibe/checkpoints/90-packet.md
    # No TTY on stdin (pipe) — must refuse
    local rc=0
    echo "" | "$VIBEFLOW" approve 90 >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 0 ] || { fail "approve without a TTY must fail (agents have no TTY)"; return 1; }
    if [ -f .vibe/checkpoints/90-qa-approved ]; then
        fail "no checkpoint may be created without a TTY"
        return 1
    fi
    return 0
}
run_test "approve without a TTY refuses and creates nothing" test_approve_without_tty_fails

test_approve_with_tty_creates_checkpoint() {
    command -v script >/dev/null 2>&1 || { return 0; }  # skip if `script` missing
    cd "$TEST_DIR"
    mkdir -p .vibe/checkpoints
    echo "# packet" > .vibe/checkpoints/91-packet.md
    # `script` allocates a pseudo-TTY; pipe 'y' to confirm
    if script -q /dev/null bash -c "cd '$TEST_DIR' && echo y | '$VIBEFLOW' approve 91" >/dev/null 2>&1; then
        :
    fi
    assert_file_exists ".vibe/checkpoints/91-qa-approved" \
        "approve over a TTY must create the approval checkpoint" || return 1
    assert_file_contains ".vibe/checkpoints/91-qa-approved" "approved" \
        "the checkpoint content must be 'approved'" || return 1
}
run_test "approve over a TTY creates the approval" test_approve_with_tty_creates_checkpoint

test_approve_requires_packet() {
    command -v script >/dev/null 2>&1 || { return 0; }
    cd "$TEST_DIR"
    mkdir -p .vibe/checkpoints
    # no packet for issue 92
    script -q /dev/null bash -c "cd '$TEST_DIR' && echo y | '$VIBEFLOW' approve 92" >/dev/null 2>&1 || true
    if [ -f .vibe/checkpoints/92-qa-approved ]; then
        fail "approve must refuse when the checkpoint packet is missing"
        return 1
    fi
    return 0
}
run_test "approve refuses without a checkpoint packet" test_approve_requires_packet

# ──────────────────────────────────────────────
describe "BashGuard — blocks self-approval via bash"

run_bash_guard() {
    local command="$1"
    local rc=0
    python3 -c "
import json
print(json.dumps({'tool_name': 'Bash', 'tool_input': {'command': '''$command'''}}))
" | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$BASH_HOOK" >/dev/null 2>&1 || rc=$?
    return $rc
}

test_echo_to_checkpoint_blocked() {
    local rc=0
    run_bash_guard "echo approved > .vibe/checkpoints/40-qa-approved" || rc=$?
    assert_equals "2" "$rc" "writing a checkpoint via bash redirection must be blocked"
}
run_test "echo > .vibe/checkpoints/ is blocked" test_echo_to_checkpoint_blocked

test_tee_to_checkpoint_blocked() {
    local rc=0
    run_bash_guard "echo approved | tee .vibe/checkpoints/40-qa-approved" || rc=$?
    assert_equals "2" "$rc" "writing a checkpoint via tee must be blocked"
}
run_test "tee into .vibe/checkpoints/ is blocked" test_tee_to_checkpoint_blocked

# ──────────────────────────────────────────────
describe "no bypass instructions remain"

test_skill_uses_approve_command() {
    local skill="${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md"
    assert_file_contains "$skill" "vibeflow approve" \
        "the skill must instruct the PO to run 'vibeflow approve', not echo a file" || return 1
    assert_file_not_contains "$skill" 'echo "approved" >' \
        "the agent-creates-checkpoint instruction must be removed" || return 1
}
run_test "skill instructs vibeflow approve, not echo bypass" test_skill_uses_approve_command

test_hook_message_points_to_approve() {
    local hook="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py"
    assert_file_contains "$hook" "vibeflow approve" \
        "block messages must direct to 'vibeflow approve', not 'create the checkpoint'"
}
run_test "hook block message points to vibeflow approve" test_hook_message_points_to_approve

print_summary
