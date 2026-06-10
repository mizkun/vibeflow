#!/bin/bash

# Tests the role-string contract: the value written into session/state by
# the wrappers and skills must resolve to the same role the hooks key on.
#
# Background: the hook keyed ROLE_EDIT_ALLOW on the policy display_name
# 'Coding Agent (Claude Code / Codex)', but lib/wrappers wrote the short
# 'Coding Agent' and never exported VIBEFLOW_SESSION — so a legitimate
# worker write resolved to allow=[] and got blocked, training agents to
# bypass the guard. A normalization layer + a contract test fix this.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

ACCESS_HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py"

# Resolve: write a session file with $1 as current_role, attempt to write
# $2, echo the exit code.
run_access() {
    local tmp="${TEST_DIR}/r"
    mkdir -p "${tmp}/.vibe/sessions"
    cp "$ACCESS_HOOK" "${tmp}/validate_access.py"
    cat > "${tmp}/.vibe/sessions/s.yaml" << YAML
current_role: "$1"
YAML
    local code=0
    echo "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$2\"}}" \
        | VIBEFLOW_SESSION=s CLAUDE_PROJECT_DIR="$tmp" python3 "${tmp}/validate_access.py" >/dev/null 2>&1 || code=$?
    echo "$code"
}

# ──────────────────────────────────────────────
describe "role normalization — any spelling of the coding role resolves"

test_display_name_resolves() {
    assert_equals "0" "$(run_access 'Coding Agent (Claude Code / Codex)' 'src/app.py')" \
        "the policy display_name must allow src writes"
}
run_test "display_name resolves to coding_agent" test_display_name_resolves

test_short_form_resolves() {
    assert_equals "0" "$(run_access 'Coding Agent' 'src/app.py')" \
        "the short form 'Coding Agent' must also resolve (no allow=[] time bomb)"
}
run_test "short form 'Coding Agent' resolves" test_short_form_resolves

test_role_id_resolves() {
    assert_equals "0" "$(run_access 'coding_agent' 'src/app.py')" \
        "the role id 'coding_agent' must resolve too"
}
run_test "role id 'coding_agent' resolves" test_role_id_resolves

test_iris_still_blocked_from_code() {
    assert_equals "2" "$(run_access 'Iris' 'src/app.py')" \
        "Iris must still be blocked from code regardless of normalization"
}
run_test "Iris still blocked from code" test_iris_still_blocked_from_code

test_unknown_role_defaults_restrictive() {
    assert_equals "2" "$(run_access 'Wizard' 'src/app.py')" \
        "an unknown role must default to the most restrictive (Iris)"
}
run_test "unknown role defaults to restrictive" test_unknown_role_defaults_restrictive

# ──────────────────────────────────────────────
describe "role contract — wrappers ⇄ hook key agree"

test_wrappers_role_resolves() {
    # Whatever the shell wrappers write must resolve to coding_agent.
    local role_line
    role_line=$(grep -h 'current_role:' "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" | head -1)
    local role
    role=$(echo "$role_line" | sed 's/.*current_role:[[:space:]]*//' | tr -d '"')
    assert_equals "0" "$(run_access "$role" 'src/app.py')" \
        "the role string the wrapper writes ('$role') must resolve to coding_agent"
}
run_test "wrapper-written role resolves to coding_agent" test_wrappers_role_resolves

test_python_wrappers_set_session_role() {
    # The Popen dispatch path must also record a session role + export
    # VIBEFLOW_SESSION, or worker writes resolve to the state.yaml default.
    for w in claude_code_wrapper codex_wrapper; do
        grep -q "current_role" "${FRAMEWORK_DIR}/core/runtime/${w}.py" || {
            fail "${w}.py must write a current_role into its session file"
            return 1
        }
        grep -q "VIBEFLOW_SESSION" "${FRAMEWORK_DIR}/core/runtime/${w}.py" || {
            fail "${w}.py must set VIBEFLOW_SESSION for the dispatched process"
            return 1
        }
    done
    return 0
}
run_test "python wrappers set session role + VIBEFLOW_SESSION" test_python_wrappers_set_session_role

test_role_transitions_audited() {
    # Role switches should be auditable (logged), per the transition rule.
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/safety.md" \
        "ロール" "safety rules must describe role transition auditing" || return 1
}
run_test "role transition auditing is documented" test_role_transitions_audited

print_summary
