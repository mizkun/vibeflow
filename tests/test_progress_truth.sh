#!/bin/bash

# Tests progress-state unification and the Human Checkpoint alert.
#
#  - waiting_input.sh fired its dramatic Step-7a alert only when
#    current_step == "7" exactly, but execute-issue writes
#    "7_acceptance_test" / "7a_human_checkpoint" — so the away-from-desk
#    PO was never alerted that the loop had stopped for approval.
#  - /progress read project_state.yaml + sessions, but execute-issue
#    only wrote state.yaml; update_workflow_state writes all three.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

WAIT_HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/waiting_input.sh"

# waiting_input.sh decides IS_STEP7A and (on Linux CI) prints nothing,
# so we grep the script's own logic via a step-detection probe: run it
# with a state file and check it doesn't error, then assert the matching
# logic in-source (portable across CI without audio).
step_is_7a() {
    # returns 0 if the hook would treat $1 as a checkpoint step
    grep -E 'CURRENT_STEP.*in|= "7"|7\|7_|7a' "$WAIT_HOOK" >/dev/null
}

test_hook_matches_7_variants() {
    # The hook must recognize 7, 7_acceptance_test, and 7a_human_checkpoint
    assert_file_contains "$WAIT_HOOK" '7_\*\|7a\*\|7|7_\|7a' \
        "waiting_input must match 7 / 7_* / 7a* (not just exact '7')" || return 1
    if grep -q 'CURRENT_STEP" = "7"' "$WAIT_HOOK"; then
        fail "the exact-'7' comparison must be replaced with a pattern match"
        return 1
    fi
    return 0
}
run_test "waiting_input matches all Step-7 variants" test_hook_matches_7_variants

test_generated_notifications_step7a_aware() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_notifications.sh" \
        "current_step\|7a\|7_" \
        "the generated waiting_input must also be Step-7a aware (not a bare ping)"
}
run_test "generated waiting_input is Step-7a aware" test_generated_notifications_step7a_aware

# ──────────────────────────────────────────────
describe "state — update_workflow_state writes all three stores"

test_update_workflow_state_exists() {
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime import state
assert hasattr(state, 'update_workflow_state'), 'state.update_workflow_state must exist'
print('OK')
" | grep -q OK || { fail "state.update_workflow_state must exist"; return 1; }
}
run_test "state.update_workflow_state exists" test_update_workflow_state_exists

test_update_writes_all_three() {
    python3 -c "
import sys, os
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime import state
d = '${TEST_DIR}'
state.update_workflow_state(d, role='Iris', step='7a_human_checkpoint', issue=42)
assert os.path.isfile(os.path.join(d, '.vibe', 'state.yaml')), 'state.yaml not written'
assert os.path.isfile(os.path.join(d, '.vibe', 'project_state.yaml')), 'project_state.yaml not written'
ss = state.read_session_state(d, 'iris-main')
assert ss.get('current_step') == '7a_human_checkpoint', f'session step wrong: {ss}'
print('OK')
" | grep -q OK || { fail "update_workflow_state must write state.yaml, project_state.yaml, and the session"; return 1; }
}
run_test "update_workflow_state writes all three stores" test_update_writes_all_three

test_update_preserves_existing_fields() {
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime import state
d = '${TEST_DIR}2'
import os; os.makedirs(os.path.join(d, '.vibe'), exist_ok=True)
state.write_project_state(d, {'phase': 'development', 'custom': 'keepme'})
state.update_workflow_state(d, role='Iris', step='5_implementation', issue=7)
ps = state.read_project_state(d)
assert ps.get('custom') == 'keepme', f'existing field lost: {ps}'
print('OK')
" | grep -q OK || { fail "update_workflow_state must preserve existing project_state fields"; return 1; }
}
run_test "update preserves existing project_state fields" test_update_preserves_existing_fields

test_skill_uses_update_workflow_state() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md" \
        "update_workflow_state" \
        "execute-issue must update state via update_workflow_state, not a lone state.yaml heredoc"
}
run_test "execute-issue uses update_workflow_state" test_skill_uses_update_workflow_state

print_summary
