#!/bin/bash

# Dogfooding: VibeFlow's own .vibe/spec/ must pass spec-verify. The
# framework applies the v6 structured-spec engine to itself — if the
# repo's As-Is spec drifts from its code, this fails like any project's.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

test_own_spec_exists() {
    assert_dir_exists "${FRAMEWORK_DIR}/.vibe/spec/stories" \
        "VibeFlow must dogfood its own structured spec" || return 1
    local n
    n=$(ls "${FRAMEWORK_DIR}/.vibe/spec/stories/"*.yaml 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -ge 4 ] || { fail "expected several Story files, got ${n}"; return 1; }
}
run_test "VibeFlow ships its own .vibe/spec/" test_own_spec_exists

test_own_spec_verifies() {
    local out rc=0
    out=$(cd "${FRAMEWORK_DIR}" && python3 core/runtime/spec_verify.py .vibe/spec . 2>&1) || rc=$?
    if [ "$rc" -ne 0 ]; then
        fail "VibeFlow's own spec must pass spec-verify (drift detected):"
        echo "$out" | tail -10
        return 1
    fi
    echo "$out" | grep -q "RESULT: PASS" || { fail "expected PASS, got: $out"; return 1; }
}
run_test "VibeFlow's own spec passes spec-verify" test_own_spec_verifies

test_own_spec_invariants_have_tests() {
    # Every invariant in the framework's spec points at a real test file.
    local out
    out=$(cd "${FRAMEWORK_DIR}" && python3 core/runtime/spec_verify.py .vibe/spec . --json 2>/dev/null)
    local pending
    pending=$(echo "$out" | python3 -c "import json,sys; print(json.load(sys.stdin)['stats']['invariants_pending'])")
    assert_equals "0" "$pending" "the framework's own invariants should all be test-backed"
}
run_test "framework invariants are test-backed (0 pending)" test_own_spec_invariants_have_tests

print_summary
