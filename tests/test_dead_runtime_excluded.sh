#!/bin/bash

# The v4 packet-handoff modules (handoff, worker_adapter stub, codex_impl)
# are unused by the v6 execution path but were being deployed into every
# project's .vibe/runtime/ by the runtime generate glob. Stop shipping
# them — they only confuse 'which module actually runs?'.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

DEAD=(handoff worker_adapter codex_impl)

test_dead_modules_not_deployed() {
    local proj="${TEST_DIR}/p"
    mkdir -p "${proj}/.vibe"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" --framework-dir "${FRAMEWORK_DIR}" >/dev/null 2>&1
    local m
    for m in "${DEAD[@]}"; do
        assert_file_not_exists "${proj}/.vibe/runtime/${m}.py" \
            "${m}.py is unused by v6 and must not be deployed" || return 1
    done
    return 0
}
run_test "v4 packet modules are not deployed to .vibe/runtime/" test_dead_modules_not_deployed

test_live_modules_still_deployed() {
    local proj="${TEST_DIR}/p2"
    mkdir -p "${proj}/.vibe"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" --framework-dir "${FRAMEWORK_DIR}" >/dev/null 2>&1
    for m in qa_judge spec_verify state loop_control run_ledger ui_task; do
        assert_file_exists "${proj}/.vibe/runtime/${m}.py" \
            "${m}.py is live and must still deploy" || return 1
    done
    return 0
}
run_test "live runtime modules still deploy" test_live_modules_still_deployed

test_examples_runtime_excludes_dead() {
    local m
    for m in "${DEAD[@]}"; do
        assert_file_not_exists "${FRAMEWORK_DIR}/examples/.vibe/runtime/${m}.py" \
            "examples/.vibe/runtime/${m}.py must not be a shipped artifact" || return 1
    done
    return 0
}
run_test "examples/ does not ship the dead modules" test_examples_runtime_excludes_dead

print_summary
