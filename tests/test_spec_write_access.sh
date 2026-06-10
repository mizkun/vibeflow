#!/bin/bash

# Tests for the To-Be spec write contract.
#
# The v6 loop requires the Coding Agent to edit .vibe/spec/ on the
# issue branch (To-Be = spec files edited on the branch), but the hard
# ACL only allowed Iris to write there — the loop's core operation was
# blocked by the framework's own guard. And the shell wrappers wrote a
# role string that doesn't match the hook's ROLE_EDIT_ALLOW key, plus
# never exported VIBEFLOW_SESSION, so role resolution fell back to
# state.yaml regardless.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

run_access_hook() {
    # $1 = role for the session file, $2 = file_path payload
    local tmpdir="$TEST_DIR/hook"
    mkdir -p "${tmpdir}/.vibe/sessions" "${tmpdir}/.vibe/hooks"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"
    cat > "${tmpdir}/.vibe/sessions/test-session.yaml" << YAML
session_id: test-session
current_role: "$1"
current_step: 4_test_writing
YAML
    local payload="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$2\"}}"
    local code=0
    echo "$payload" | VIBEFLOW_SESSION=test-session \
        CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" >/dev/null 2>&1 || code=$?
    echo "$code"
}

test_coding_agent_can_write_spec() {
    local code
    code=$(run_access_hook "Coding Agent (Claude Code / Codex)" ".vibe/spec/stories/memory.yaml")
    assert_equals "0" "$code" \
        "Coding Agent must be able to edit To-Be spec on the issue branch"
}

test_coding_agent_can_write_contracts() {
    local code
    code=$(run_access_hook "Coding Agent (Claude Code / Codex)" ".vibe/spec/contracts/character.yaml")
    assert_equals "0" "$code" \
        "Coding Agent must be able to edit Contract files"
}

test_coding_agent_still_blocked_from_policy() {
    local code
    code=$(run_access_hook "Coding Agent (Claude Code / Codex)" ".vibe/policy.yaml")
    assert_equals "2" "$code" \
        "spec access must not open the rest of .vibe/ (policy.yaml stays blocked)"
}

test_iris_can_still_write_spec() {
    local code
    code=$(run_access_hook "Iris" ".vibe/spec/stories/memory.yaml")
    assert_equals "0" "$code" \
        "Iris keeps spec write access (kickoff / Bootstrap)"
}

test_wrappers_write_display_name_role() {
    local bad=""
    local w
    for w in claude_code codex; do
        if grep -q 'current_role: "Coding Agent"$' "${FRAMEWORK_DIR}/lib/wrappers/${w}.sh"; then
            bad="${bad} ${w}.sh"
        fi
    done
    if [ -n "$bad" ]; then
        fail "wrappers must write the policy display_name, not a short form (hook key mismatch):${bad}"
        return 1
    fi
    grep -q 'Coding Agent (Claude Code / Codex)' "${FRAMEWORK_DIR}/lib/wrappers/claude_code.sh" || {
        fail "claude_code.sh should write the full display_name"
        return 1
    }
    return 0
}

test_wrappers_export_session() {
    local w
    for w in claude_code codex; do
        grep -q 'export VIBEFLOW_SESSION' "${FRAMEWORK_DIR}/lib/wrappers/${w}.sh" || {
            fail "${w}.sh must export VIBEFLOW_SESSION so hooks resolve the session role"
            return 1
        }
    done
    return 0
}

describe "To-Be spec write access — policy"
run_test "Coding Agent can write .vibe/spec/stories/" test_coding_agent_can_write_spec
run_test "Coding Agent can write .vibe/spec/contracts/" test_coding_agent_can_write_contracts
run_test "Coding Agent still blocked from .vibe/policy.yaml" test_coding_agent_still_blocked_from_policy
run_test "Iris keeps spec write access" test_iris_can_still_write_spec

describe "Wrapper role contract"
run_test "wrappers write the full display_name role" test_wrappers_write_display_name_role
run_test "wrappers export VIBEFLOW_SESSION" test_wrappers_export_session

print_summary
