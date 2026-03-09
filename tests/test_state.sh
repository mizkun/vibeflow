#!/bin/bash

# VibeFlow Test: Phase 2 — State Split (Issue 2-1)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "State schema — files exist"

test_project_state_schema_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/project_state.yaml" \
        "core/schema/project_state.yaml must exist"
}
run_test "project_state.yaml schema exists" test_project_state_schema_exists

test_session_state_schema_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/session_state.yaml" \
        "core/schema/session_state.yaml must exist"
}
run_test "session_state.yaml schema exists" test_session_state_schema_exists

# ──────────────────────────────────────────────
describe "State schema — project_state structure"

test_project_state_has_active_issue() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/project_state.yaml" \
        "active_issue" "project_state should have active_issue field"
}
run_test "project_state has active_issue" test_project_state_has_active_issue

test_project_state_has_current_phase() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/project_state.yaml" \
        "current_phase" "project_state should have current_phase field"
}
run_test "project_state has current_phase" test_project_state_has_current_phase

test_project_state_no_current_role() {
    assert_file_not_contains "${FRAMEWORK_DIR}/core/schema/project_state.yaml" \
        "current_role" "project_state should NOT have current_role (session concern)"
}
run_test "project_state has no current_role" test_project_state_no_current_role

# ──────────────────────────────────────────────
describe "State schema — session_state structure"

test_session_state_has_session_id() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/session_state.yaml" \
        "session_id" "session_state should have session_id"
}
run_test "session_state has session_id" test_session_state_has_session_id

test_session_state_has_current_role() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/session_state.yaml" \
        "current_role" "session_state should have current_role"
}
run_test "session_state has current_role" test_session_state_has_current_role

test_session_state_has_current_step() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/session_state.yaml" \
        "current_step" "session_state should have current_step"
}
run_test "session_state has current_step" test_session_state_has_current_step

test_session_state_has_attached_issue() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/session_state.yaml" \
        "attached_issue" "session_state should have attached_issue"
}
run_test "session_state has attached_issue" test_session_state_has_attached_issue

# ──────────────────────────────────────────────
describe "State examples — templates exist"

test_example_project_state_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.vibe/project_state.yaml" \
        "examples should have project_state.yaml"
}
run_test "examples/project_state.yaml exists" test_example_project_state_exists

test_example_iris_session_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.vibe/sessions/iris-main.yaml" \
        "examples should have sessions/iris-main.yaml"
}
run_test "examples/sessions/iris-main.yaml exists" test_example_iris_session_exists

test_example_iris_session_has_iris_role() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.vibe/sessions/iris-main.yaml" \
        "Iris" "iris-main.yaml should have Iris role"
}
run_test "iris-main.yaml has Iris role" test_example_iris_session_has_iris_role

# ──────────────────────────────────────────────
describe "State runtime — state.py API"

test_state_py_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/state.py" \
        "core/runtime/state.py must exist"
}
run_test "state.py exists" test_state_py_exists

test_state_read_project() {
    local tmpdir="${TEST_DIR}/state_test"
    mkdir -p "${tmpdir}/.vibe"

    cat > "${tmpdir}/.vibe/project_state.yaml" << 'YAML'
active_issue: 42
current_phase: development
YAML

    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import read_project_state
ps = read_project_state('${tmpdir}')
print(ps['active_issue'])
print(ps['current_phase'])
")

    local issue=$(echo "$result" | head -1)
    local phase=$(echo "$result" | tail -1)

    assert_equals "42" "$issue" "Should read active_issue=42"
    assert_equals "development" "$phase" "Should read current_phase=development"
}
run_test "state.py reads project_state" test_state_read_project

test_state_read_session() {
    local tmpdir="${TEST_DIR}/state_test"
    mkdir -p "${tmpdir}/.vibe/sessions"

    cat > "${tmpdir}/.vibe/sessions/dev-issue-42.yaml" << 'YAML'
session_id: dev-issue-42
current_role: "Engineer"
current_step: 4_test_writing
attached_issue: 42
YAML

    local result
    result=$(VIBEFLOW_SESSION=dev-issue-42 python3 -c "
import sys, os
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import read_session_state
ss = read_session_state('${tmpdir}')
print(ss['current_role'])
print(ss['current_step'])
print(ss['attached_issue'])
")

    local role=$(echo "$result" | sed -n '1p')
    local step=$(echo "$result" | sed -n '2p')
    local issue=$(echo "$result" | sed -n '3p')

    assert_equals "Engineer" "$role" "Should read current_role=Engineer"
    assert_equals "4_test_writing" "$step" "Should read current_step=4_test_writing"
    assert_equals "42" "$issue" "Should read attached_issue=42"
}
run_test "state.py reads session_state via VIBEFLOW_SESSION" test_state_read_session

test_state_write_project() {
    local tmpdir="${TEST_DIR}/state_test"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'active_issue': 99, 'current_phase': 'development'})
"

    assert_file_exists "${tmpdir}/.vibe/project_state.yaml" \
        "project_state.yaml should be written"
    assert_file_contains "${tmpdir}/.vibe/project_state.yaml" "99" \
        "project_state.yaml should contain issue 99"
}
run_test "state.py writes project_state" test_state_write_project

test_state_write_session() {
    local tmpdir="${TEST_DIR}/state_test"
    mkdir -p "${tmpdir}/.vibe/sessions"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_session_state
write_session_state('${tmpdir}', 'dev-issue-55', {
    'session_id': 'dev-issue-55',
    'current_role': 'QA Engineer',
    'current_step': '7_acceptance_test',
    'attached_issue': 55,
})
"

    assert_file_exists "${tmpdir}/.vibe/sessions/dev-issue-55.yaml" \
        "session file should be written"
    assert_file_contains "${tmpdir}/.vibe/sessions/dev-issue-55.yaml" "QA Engineer" \
        "session file should contain QA Engineer"
}
run_test "state.py writes session_state" test_state_write_session

# ──────────────────────────────────────────────
describe "validate_access.py — session state integration"

test_validate_access_reads_session() {
    local tmpdir="${TEST_DIR}/va_test"
    mkdir -p "${tmpdir}/.vibe/sessions" "${tmpdir}/.vibe/hooks"

    # Copy validate_access.py
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"

    # Create session state (Engineer role)
    cat > "${tmpdir}/.vibe/sessions/dev-issue-10.yaml" << 'YAML'
session_id: dev-issue-10
current_role: "Engineer"
current_step: 5_implementation
attached_issue: 10
YAML

    # Test: Engineer should be allowed to write src/
    local payload='{"tool_name":"Write","tool_input":{"file_path":"src/main.py"}}'

    set +e
    echo "$payload" | VIBEFLOW_SESSION=dev-issue-10 \
        CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" 2>/dev/null
    local code=$?
    set -e

    assert_equals "0" "$code" "Engineer should be allowed to write src/"
}
run_test "validate_access reads session state" test_validate_access_reads_session

test_validate_access_blocks_wrong_role() {
    local tmpdir="${TEST_DIR}/va_test2"
    mkdir -p "${tmpdir}/.vibe/sessions" "${tmpdir}/.vibe/hooks"

    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"

    # Create session state (QA role)
    cat > "${tmpdir}/.vibe/sessions/qa-session.yaml" << 'YAML'
session_id: qa-session
current_role: "QA Engineer"
current_step: 7_acceptance_test
attached_issue: 10
YAML

    # Test: QA should be blocked from writing src/
    local payload='{"tool_name":"Write","tool_input":{"file_path":"src/main.py"}}'

    set +e
    echo "$payload" | VIBEFLOW_SESSION=qa-session \
        CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" 2>/dev/null
    local code=$?
    set -e

    assert_equals "2" "$code" "QA Engineer should be blocked from writing src/"
}
run_test "validate_access blocks wrong role from session" test_validate_access_blocks_wrong_role

test_validate_access_fallback_to_state_yaml() {
    local tmpdir="${TEST_DIR}/va_fallback"
    mkdir -p "${tmpdir}/.vibe/hooks"

    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"

    # No session, but state.yaml exists (backward compat)
    cat > "${tmpdir}/.vibe/state.yaml" << 'YAML'
current_role: "Engineer"
YAML

    local payload='{"tool_name":"Write","tool_input":{"file_path":"src/main.py"}}'

    set +e
    echo "$payload" | CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" 2>/dev/null
    local code=$?
    set -e

    assert_equals "0" "$code" "Should fall back to state.yaml when no session"
}
run_test "validate_access falls back to state.yaml" test_validate_access_fallback_to_state_yaml

# ──────────────────────────────────────────────
describe "Permission model — new state files"

test_policy_has_project_state() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        "project_state.yaml" "policy should reference project_state.yaml"
}
run_test "policy.yaml includes project_state.yaml" test_policy_has_project_state

test_policy_has_sessions() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        "sessions/\*.yaml" "policy should reference sessions/*.yaml"
}
run_test "policy.yaml includes sessions/*.yaml" test_policy_has_sessions

test_always_allow_has_new_state_files() {
    local policy="${FRAMEWORK_DIR}/core/schema/policy.yaml"

    # Extract always_allow section and check both new files
    assert_file_contains "$policy" "project_state.yaml" \
        "always_allow should include project_state.yaml"
    assert_file_contains "$policy" "sessions/\*.yaml" \
        "always_allow should include sessions/*.yaml"
    assert_file_contains "$policy" "state.yaml" \
        "always_allow should keep legacy state.yaml"
}
run_test "always_allow includes new state files + legacy" test_always_allow_has_new_state_files

test_validate_access_allows_project_state() {
    local tmpdir="${TEST_DIR}/va_perm1"
    mkdir -p "${tmpdir}/.vibe/sessions" "${tmpdir}/.vibe/hooks"

    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"

    cat > "${tmpdir}/.vibe/sessions/dev-issue-1.yaml" << 'YAML'
session_id: dev-issue-1
current_role: "Engineer"
current_step: 5_implementation
YAML

    # Engineer writing to project_state.yaml should be allowed
    local payload='{"tool_name":"Write","tool_input":{"file_path":".vibe/project_state.yaml"}}'

    set +e
    echo "$payload" | VIBEFLOW_SESSION=dev-issue-1 \
        CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" 2>/dev/null
    local code=$?
    set -e

    assert_equals "0" "$code" "Engineer should be allowed to write project_state.yaml"
}
run_test "validate_access allows project_state.yaml write" test_validate_access_allows_project_state

test_validate_access_allows_session_file() {
    local tmpdir="${TEST_DIR}/va_perm2"
    mkdir -p "${tmpdir}/.vibe/sessions" "${tmpdir}/.vibe/hooks"

    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"

    cat > "${tmpdir}/.vibe/sessions/dev-issue-2.yaml" << 'YAML'
session_id: dev-issue-2
current_role: "Product Manager"
current_step: 1_issue_review
YAML

    # PM writing to session file should be allowed
    local payload='{"tool_name":"Write","tool_input":{"file_path":".vibe/sessions/dev-issue-2.yaml"}}'

    set +e
    echo "$payload" | VIBEFLOW_SESSION=dev-issue-2 \
        CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" 2>/dev/null
    local code=$?
    set -e

    assert_equals "0" "$code" "PM should be allowed to write session files"
}
run_test "validate_access allows session file write" test_validate_access_allows_session_file

test_validate_access_error_msg_no_legacy_reference() {
    local tmpdir="${TEST_DIR}/va_errmsg"
    mkdir -p "${tmpdir}/.vibe/sessions" "${tmpdir}/.vibe/hooks"

    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${tmpdir}/.vibe/hooks/validate_access.py"

    cat > "${tmpdir}/.vibe/sessions/qa-errmsg.yaml" << 'YAML'
session_id: qa-errmsg
current_role: "QA Engineer"
current_step: 7_acceptance_test
YAML

    # QA trying to write src/ → blocked, check error message
    local payload='{"tool_name":"Write","tool_input":{"file_path":"src/main.py"}}'

    set +e
    local stderr_output
    stderr_output=$(echo "$payload" | VIBEFLOW_SESSION=qa-errmsg \
        CLAUDE_PROJECT_DIR="$tmpdir" \
        python3 "${tmpdir}/.vibe/hooks/validate_access.py" 2>&1 >/dev/null)
    set -e

    echo "$stderr_output" > "${TEST_DIR}/errmsg_output.txt"

    # Error message should reference session files, not just state.yaml
    assert_file_contains "${TEST_DIR}/errmsg_output.txt" "セッション状態ファイル" \
        "Error message should reference session state files"
}
run_test "validate_access error message references sessions" test_validate_access_error_msg_no_legacy_reference

test_generated_hook_has_new_permissions() {
    # Verify the generated validate_access.py has project_state + sessions in ALWAYS_ALLOW
    assert_file_contains "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
        "project_state.yaml" "Generated hook should have project_state.yaml"
    assert_file_contains "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
        "sessions/" "Generated hook should have sessions/"
}
run_test "generated hook includes new state permissions" test_generated_hook_has_new_permissions

test_claude_md_roles_have_new_state() {
    # CLAUDE.md roles section should show new state files in Can Write
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "project_state.yaml" "CLAUDE.md roles should reference project_state.yaml"
    assert_file_contains "${FRAMEWORK_DIR}/examples/CLAUDE.md" \
        "sessions/" "CLAUDE.md roles should reference sessions/"
}
run_test "CLAUDE.md roles include new state files" test_claude_md_roles_have_new_state

# ──────────────────────────────────────────────
describe "dev.sh — session file creation"

test_dev_sh_has_session_creation() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.vibe/scripts/dev.sh" \
        "sessions" "dev.sh should reference sessions directory"
    assert_file_contains "${FRAMEWORK_DIR}/examples/.vibe/scripts/dev.sh" \
        "VIBEFLOW_SESSION" "dev.sh should set VIBEFLOW_SESSION"
}
run_test "dev.sh creates session and sets VIBEFLOW_SESSION" test_dev_sh_has_session_creation

# ──────────────────────────────────────────────
describe "Generate — state templates"

test_generate_produces_project_state() {
    local tmpdir="${TEST_DIR}/gen_test"
    mkdir -p "${tmpdir}/.vibe" "${tmpdir}/.claude"

    # Need a CLAUDE.md with VF markers for generate
    cat > "${tmpdir}/CLAUDE.md" << 'EOF'
# Project
<!-- VF:BEGIN roles -->
old
<!-- VF:END roles -->
<!-- VF:BEGIN workflow -->
old
<!-- VF:END workflow -->
<!-- VF:BEGIN hook_list -->
old
<!-- VF:END hook_list -->
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${tmpdir}/.vibe/project_state.yaml" \
        "generate should create project_state.yaml"
}
run_test "generate creates project_state.yaml" test_generate_produces_project_state

test_generate_produces_iris_session() {
    local tmpdir="${TEST_DIR}/gen_test2"
    mkdir -p "${tmpdir}/.vibe" "${tmpdir}/.claude"

    cat > "${tmpdir}/CLAUDE.md" << 'EOF'
# Project
<!-- VF:BEGIN roles -->
old
<!-- VF:END roles -->
<!-- VF:BEGIN workflow -->
old
<!-- VF:END workflow -->
<!-- VF:BEGIN hook_list -->
old
<!-- VF:END hook_list -->
EOF

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" 2>/dev/null

    assert_file_exists "${tmpdir}/.vibe/sessions/iris-main.yaml" \
        "generate should create sessions/iris-main.yaml"
    assert_file_contains "${tmpdir}/.vibe/sessions/iris-main.yaml" "Iris" \
        "iris-main.yaml should have Iris role"
}
run_test "generate creates iris-main.yaml" test_generate_produces_iris_session

# ──────────────────────────────────────────────
print_summary
