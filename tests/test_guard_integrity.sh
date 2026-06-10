#!/bin/bash

# Tests that the guards cannot be tampered with by the guarded agent, and
# that the all-hooks kill switch is no longer shipped.
#
# - validate_access.py (Edit/Write) blocks edits to the guards, policy,
#   manifest, and settings for every role
# - the disableAllHooks template is gone (it silently disabled every
#   guard with one copy, invisible to the PO via gitignore)
# - doctor reports an existing disableAllHooks settings.local.json as an
#   error, and reports missing guard wiring in settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

ACCESS_HOOK="${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py"

run_access() {
    # $1 = role, $2 = file path
    local tmp="${TEST_DIR}/g"
    mkdir -p "${tmp}/.vibe/sessions"
    cp "$ACCESS_HOOK" "${tmp}/validate_access.py"
    cat > "${tmp}/.vibe/sessions/s.yaml" << YAML
current_role: "$1"
YAML
    local code=0
    echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$2\"}}" \
        | VIBEFLOW_SESSION=s CLAUDE_PROJECT_DIR="$tmp" python3 "${tmp}/validate_access.py" >/dev/null 2>&1 || code=$?
    echo "$code"
}

# ──────────────────────────────────────────────
describe "AccessGuard — guards are not editable by any role"

test_iris_blocked_from_hooks() {
    assert_equals "2" "$(run_access 'Iris' '.vibe/hooks/validate_access.py')" \
        "Iris must not edit the guards"
}
run_test "Iris blocked from .vibe/hooks/" test_iris_blocked_from_hooks

test_coding_agent_blocked_from_hooks() {
    assert_equals "2" "$(run_access 'Coding Agent (Claude Code / Codex)' '.vibe/hooks/validate_step7a.py')" \
        "Coding Agent must not edit the guards"
}
run_test "Coding Agent blocked from .vibe/hooks/" test_coding_agent_blocked_from_hooks

test_iris_blocked_from_policy() {
    assert_equals "2" "$(run_access 'Iris' '.vibe/policy.yaml')" \
        "policy.yaml must not be editable"
}
run_test "blocked from .vibe/policy.yaml" test_iris_blocked_from_policy

test_blocked_from_manifest() {
    assert_equals "2" "$(run_access 'Iris' '.vibe/generated-manifest.json')" \
        "the integrity record must not be editable"
}
run_test "blocked from generated-manifest.json" test_blocked_from_manifest

test_blocked_from_settings() {
    assert_equals "2" "$(run_access 'Iris' '.claude/settings.json')" \
        "settings.json must not be editable"
}
run_test "blocked from .claude/settings.json" test_blocked_from_settings

# ──────────────────────────────────────────────
describe "Kill switch — disableAllHooks template is gone"

test_template_removed() {
    assert_file_not_exists "${FRAMEWORK_DIR}/examples/.vibe/templates/settings.local.json" \
        "the disableAllHooks template must not be shipped" || return 1
    if grep -rq "disableAllHooks" "${FRAMEWORK_DIR}/lib/create_claude_settings.sh"; then
        fail "create_claude_settings.sh must not generate a disableAllHooks template"
        return 1
    fi
    return 0
}
run_test "disableAllHooks template is not shipped or generated" test_template_removed

# ──────────────────────────────────────────────
describe "doctor — detects a kill switch and missing guard wiring"

test_doctor_flags_disable_all_hooks() {
    local proj="${TEST_DIR}/proj"
    mkdir -p "${proj}/.claude"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" --framework-dir "${FRAMEWORK_DIR}" >/dev/null 2>&1
    echo '{"disableAllHooks": true}' > "${proj}/.claude/settings.local.json"
    cd "$proj"
    local out rc=0
    out=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1) || rc=$?
    [ "$rc" -ne 0 ] || { fail "doctor must exit non-zero when all hooks are disabled"; return 1; }
    echo "$out" | grep -qi "disableAllHooks\|hook" || { fail "doctor must mention the disabled hooks: $out"; return 1; }
    return 0
}
run_test "doctor errors on disableAllHooks settings.local.json" test_doctor_flags_disable_all_hooks

print_summary
