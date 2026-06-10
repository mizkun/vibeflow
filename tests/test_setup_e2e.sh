#!/bin/bash

# End-to-end test of `setup_vibeflow.sh`: actually run it in a tmp git
# repo (with gh shimmed) and assert the v6 project is correctly laid out.
# Previously nothing executed setup — its core bugs (rules/runtime not
# deployed, manifest missing) lived entirely outside the test net.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

run_setup() {
    local proj="$1"
    mkdir -p "${proj}/bin"
    # gh shim: succeed silently (label creation etc.)
    printf '#!/bin/bash\nexit 0\n' > "${proj}/bin/gh"
    chmod +x "${proj}/bin/gh"
    ( cd "$proj" && git init -q && git config user.email t@t && git config user.name t \
        && PATH="${proj}/bin:$PATH" bash "${FRAMEWORK_DIR}/setup_vibeflow.sh" --force >/dev/null 2>&1 )
}

# ──────────────────────────────────────────────
describe "setup E2E — v6 project layout"

SETUP_PROJ="$(mktemp -d)/proj"
setup_ran=false
ensure_setup() {
    if [ "$setup_ran" = false ]; then
        run_setup "$SETUP_PROJ"
        setup_ran=true
    fi
}
trap 'rm -rf "$(dirname "$SETUP_PROJ")"' EXIT

test_rules_deployed() {
    ensure_setup
    local n
    n=$(ls "${SETUP_PROJ}/.claude/rules/"*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -ge 9 ] || { fail "setup must deploy the .claude/rules/ (got ${n} files)"; return 1; }
}
run_test "deploys .claude/rules/" test_rules_deployed

test_runtime_deployed() {
    ensure_setup
    assert_file_exists "${SETUP_PROJ}/.vibe/runtime/qa_judge.py" \
        "setup must deploy .vibe/runtime/ judgment modules" || return 1
    assert_file_exists "${SETUP_PROJ}/.vibe/runtime/spec_verify.py" \
        "setup must deploy spec_verify.py" || return 1
}
run_test "deploys .vibe/runtime/" test_runtime_deployed

test_guards_deployed() {
    ensure_setup
    assert_file_exists "${SETUP_PROJ}/.vibe/hooks/validate_access.py" || return 1
    assert_file_exists "${SETUP_PROJ}/.vibe/hooks/validate_bash.py" \
        "setup must deploy the BashGuard" || return 1
    assert_file_exists "${SETUP_PROJ}/.claude/settings.json" || return 1
}
run_test "deploys guards + settings" test_guards_deployed

test_no_loose_spec_md() {
    ensure_setup
    assert_file_not_exists "${SETUP_PROJ}/spec.md" \
        "v6 must not generate the loose spec.md" || return 1
}
run_test "does not create the loose spec.md" test_no_loose_spec_md

test_spec_skeleton() {
    ensure_setup
    assert_dir_exists "${SETUP_PROJ}/.vibe/spec/stories" \
        "setup must create the .vibe/spec/ skeleton" || return 1
}
run_test "creates the .vibe/spec/ skeleton" test_spec_skeleton

test_doctor_passes() {
    ensure_setup
    ( cd "$SETUP_PROJ" && "${FRAMEWORK_DIR}/bin/vibeflow" doctor >/dev/null 2>&1 )
    assert_equals "0" "$?" "vibeflow doctor must exit 0 on a fresh setup project"
}
run_test "doctor passes on a fresh setup" test_doctor_passes

test_advertised_commands_present() {
    ensure_setup
    assert_file_exists "${SETUP_PROJ}/.claude/commands/execute-issue.md" \
        "README-advertised /execute-issue must be deployed" || return 1
    assert_file_exists "${SETUP_PROJ}/.claude/commands/patch.md" || return 1
}
run_test "deploys the advertised commands" test_advertised_commands_present

# Migration source-rot is handled structurally by copy_if_absent's
# vanished-source guard (P0-4) and exercised by test_migration_*.sh, so
# this E2E file stays focused on the setup output.

print_summary
