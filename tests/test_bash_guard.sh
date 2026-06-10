#!/bin/bash

# Tests for validate_bash.py — the Bash-bypass guard.
#
# Background: AccessGuard / LintGuard / Iris no-code enforcement only
# matched Edit|Write|MultiEdit. `cat > src/x`, `sed -i`, `tee`, and
# destructive git (force push, main push, reset --hard) sailed past
# every guard. This hook closes the redirect/destructive-git routes.
# Like validate_step7a.py it is a guardrail for a cooperative agent —
# eval/alias obfuscation is deliberately out of scope.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_bash.py"

# Run the hook with a bash command payload inside $TEST_DIR
run_bash_guard() {
    local command="$1"
    local rc=0
    python3 -c "
import json
print(json.dumps({'tool_name': 'Bash', 'tool_input': {'command': '''$command'''}}))
" | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK" >/dev/null 2>&1 || rc=$?
    return $rc
}

test_hook_exists_and_valid() {
    assert_file_exists "$HOOK" "validate_bash.py must be generated into examples" || return 1
    python3 -c "import ast; ast.parse(open('$HOOK').read())" || {
        fail "validate_bash.py must be valid python"
        return 1
    }
}

# ──────────────────────────────────────────────
# Destructive git
# ──────────────────────────────────────────────

test_force_push_blocked() {
    local rc=0
    run_bash_guard "git push --force origin feature/x" || rc=$?
    assert_equals "2" "$rc" "git push --force must be blocked"
}

test_short_force_push_blocked() {
    local rc=0
    run_bash_guard "git push -f" || rc=$?
    assert_equals "2" "$rc" "git push -f must be blocked"
}

test_main_push_blocked() {
    local rc=0
    run_bash_guard "git push origin main" || rc=$?
    assert_equals "2" "$rc" "direct push to main must be blocked"
}

test_feature_push_allowed() {
    local rc=0
    run_bash_guard "git push origin feature/issue-42" || rc=$?
    assert_equals "0" "$rc" "normal feature-branch push must pass"
}

test_reset_hard_blocked_without_approval() {
    local rc=0
    run_bash_guard "git reset --hard HEAD~3" || rc=$?
    assert_equals "2" "$rc" "git reset --hard without human approval must be blocked"
}

test_reset_hard_allowed_with_approval() {
    mkdir -p "${TEST_DIR}/.vibe/checkpoints"
    echo "approved" > "${TEST_DIR}/.vibe/checkpoints/destructive-op-approved"
    local rc=0
    run_bash_guard "git reset --hard HEAD~1" || rc=$?
    assert_equals "0" "$rc" "an explicit human approval checkpoint allows the operation once" || return 1
    if [ -f "${TEST_DIR}/.vibe/checkpoints/destructive-op-approved" ]; then
        fail "the approval must be consumed (one-shot), not reusable forever"
        return 1
    fi
    return 0
}

test_clean_fd_blocked() {
    local rc=0
    run_bash_guard "git clean -fd" || rc=$?
    assert_equals "2" "$rc" "git clean -fd must be blocked without approval"
}

# ──────────────────────────────────────────────
# Bash write bypass to guarded paths
# ──────────────────────────────────────────────

test_redirect_to_test_file_blocked() {
    local rc=0
    run_bash_guard "cat > tests/foo.test.js" || rc=$?
    assert_equals "2" "$rc" "bash redirection into tests/ must be blocked (use Write/Edit)"
}

test_redirect_to_hooks_blocked() {
    local rc=0
    run_bash_guard "echo x > .vibe/hooks/validate_access.py" || rc=$?
    assert_equals "2" "$rc" "overwriting a guard via bash must be blocked"
}

test_sed_i_on_guard_blocked() {
    local rc=0
    run_bash_guard "sed -i .bak s/x/y/ .vibe/hooks/validate_step7a.py" || rc=$?
    assert_equals "2" "$rc" "sed -i on a guard file must be blocked"
}

test_rm_tests_blocked() {
    local rc=0
    run_bash_guard "rm -rf tests/" || rc=$?
    assert_equals "2" "$rc" "rm of the test directory must be blocked"
}

test_settings_local_creation_blocked() {
    local rc=0
    run_bash_guard "echo x > .claude/settings.local.json" || rc=$?
    assert_equals "2" "$rc" "creating settings.local.json via bash (kill switch) must be blocked"
}

test_tee_to_lint_config_blocked() {
    local rc=0
    run_bash_guard "echo x | tee .eslintrc.json" || rc=$?
    assert_equals "2" "$rc" "tee into a linter config must be blocked"
}

# ──────────────────────────────────────────────
# Legitimate commands keep working
# ──────────────────────────────────────────────

test_state_yaml_heredoc_allowed() {
    local rc=0
    run_bash_guard "cat > .vibe/state.yaml << YAML
current_role: Iris
YAML" || rc=$?
    assert_equals "0" "$rc" "the role-switch heredoc to state.yaml must keep working"
}

test_stderr_redirect_allowed() {
    local rc=0
    run_bash_guard "npm test 2>/dev/null" || rc=$?
    assert_equals "0" "$rc" "stderr redirect to /dev/null must pass"
}

test_report_tee_allowed() {
    local rc=0
    run_bash_guard "npm test 2>&1 | tee .vibe/reports/42/test.log" || rc=$?
    assert_equals "0" "$rc" "evidence capture into .vibe/reports/ must pass"
}

test_plain_commands_allowed() {
    local rc=0
    run_bash_guard "git status && npm test && ls -la" || rc=$?
    assert_equals "0" "$rc" "read-only commands must pass"
}

test_non_bash_tool_ignored() {
    local rc=0
    echo '{"tool_name":"Write","tool_input":{"file_path":"tests/x.test.js"}}' \
        | CLAUDE_PROJECT_DIR="$TEST_DIR" python3 "$HOOK" >/dev/null 2>&1 || rc=$?
    assert_equals "0" "$rc" "non-Bash tools are not this hook's business"
}

# ──────────────────────────────────────────────
# Wiring
# ──────────────────────────────────────────────

test_settings_wires_bash_guard() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/settings.json" \
        "validate_bash.py" "settings.json must wire validate_bash.py on the Bash matcher"
}

test_template_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/templates/validate_bash.py.j2" \
        "the guard must be schema-generated (template), not hand-deployed"
}

describe "BashGuard — destructive git"
run_test "hook exists and is valid python" test_hook_exists_and_valid
run_test "git push --force is blocked" test_force_push_blocked
run_test "git push -f is blocked" test_short_force_push_blocked
run_test "git push origin main is blocked" test_main_push_blocked
run_test "feature-branch push passes" test_feature_push_allowed
run_test "git reset --hard blocked without approval" test_reset_hard_blocked_without_approval
run_test "git reset --hard allowed once with human approval" test_reset_hard_allowed_with_approval
run_test "git clean -fd is blocked" test_clean_fd_blocked

describe "BashGuard — write bypass to guarded paths"
run_test "redirect into tests/ is blocked" test_redirect_to_test_file_blocked
run_test "redirect into .vibe/hooks/ is blocked" test_redirect_to_hooks_blocked
run_test "sed -i on a guard file is blocked" test_sed_i_on_guard_blocked
run_test "rm -rf tests/ is blocked" test_rm_tests_blocked
run_test "creating settings.local.json is blocked" test_settings_local_creation_blocked
run_test "tee into a linter config is blocked" test_tee_to_lint_config_blocked

describe "BashGuard — legitimate commands pass"
run_test "state.yaml role-switch heredoc passes" test_state_yaml_heredoc_allowed
run_test "stderr redirect passes" test_stderr_redirect_allowed
run_test "evidence tee into .vibe/reports/ passes" test_report_tee_allowed
run_test "plain read-only commands pass" test_plain_commands_allowed
run_test "non-Bash tools are ignored" test_non_bash_tool_ignored

describe "BashGuard — wiring"
run_test "settings.json wires validate_bash.py" test_settings_wires_bash_guard
run_test "guard is generated from a template" test_template_exists

print_summary
