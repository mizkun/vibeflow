#!/bin/bash

# VibeFlow Test: upgrade → generate integration (Issue #75)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "bin/vibeflow — set -u compatibility"

test_generate_no_args_succeeds() {
    # cmd_generate with no args should not fail with unbound variable
    local tmpdir="${TEST_DIR}/gen_project"
    mkdir -p "${tmpdir}/.vibe"

    set +e
    bash "${FRAMEWORK_DIR}/bin/vibeflow" generate 2>&1
    local code=$?
    set -e

    # Should succeed (exit 0) — the actual generate may warn but should not crash
    assert_equals "0" "$code" "vibeflow generate with no args should not crash"
}
run_test "vibeflow generate runs without unbound variable error" test_generate_no_args_succeeds

test_generate_with_target_succeeds() {
    set +e
    bash "${FRAMEWORK_DIR}/bin/vibeflow" generate --target hooks 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "vibeflow generate --target hooks should not crash"
}
run_test "vibeflow generate --target works" test_generate_with_target_succeeds

# ──────────────────────────────────────────────
describe "upgrade — dry-run does not call generate"

test_upgrade_dry_run_no_manifest() {
    local tmpdir="${TEST_DIR}/upgrade_project"
    mkdir -p "${tmpdir}/.vibe"
    echo "5.0.0" > "${tmpdir}/.vibe/version"
    cd "$tmpdir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    touch .gitkeep && git add . && git commit -q -m "init"

    set +e
    local output
    output=$(bash "${FRAMEWORK_DIR}/bin/vibeflow" upgrade --dry-run 2>&1)
    local code=$?
    set -e

    # dry-run should NOT output "Regenerating manifest..."
    if echo "$output" | grep -q "Regenerating manifest"; then
        fail "dry-run should not trigger generate"
        return 1
    fi
    return 0
}
run_test "upgrade --dry-run skips generate" test_upgrade_dry_run_no_manifest

# ──────────────────────────────────────────────
describe "upgrade — generates manifest after upgrade"

test_upgrade_creates_manifest() {
    local tmpdir="${TEST_DIR}/upgrade_manifest_project"
    mkdir -p "${tmpdir}/.vibe"
    echo "5.0.0" > "${tmpdir}/.vibe/version"
    cd "$tmpdir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    touch .gitkeep && git add . && git commit -q -m "init"

    set +e
    bash "${FRAMEWORK_DIR}/bin/vibeflow" upgrade --allow-dirty 2>&1
    set -e

    assert_file_exists "${tmpdir}/.vibe/generated-manifest.json" \
        "upgrade should create generated-manifest.json via generate"
}
run_test "upgrade creates manifest via auto-generate" test_upgrade_creates_manifest

# ──────────────────────────────────────────────
describe "upgrade + doctor — end-to-end"

test_upgrade_then_doctor_passes() {
    local tmpdir="${TEST_DIR}/e2e_project"
    mkdir -p "${tmpdir}/.vibe"
    echo "5.0.0" > "${tmpdir}/.vibe/version"
    cd "$tmpdir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    touch .gitkeep && git add . && git commit -q -m "init"

    # Run upgrade (creates files + manifest)
    set +e
    bash "${FRAMEWORK_DIR}/bin/vibeflow" upgrade --allow-dirty > /dev/null 2>&1
    set -e

    # Run doctor — should have no errors
    set +e
    local doctor_output
    doctor_output=$(python3 "${FRAMEWORK_DIR}/core/doctor.py" \
        --project-dir "$tmpdir" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --framework-dir "${FRAMEWORK_DIR}" 2>&1)
    local code=$?
    set -e

    assert_equals "0" "$code" "doctor should pass after upgrade (exit 0)"

    if echo "$doctor_output" | grep -q "✗"; then
        fail "doctor should have no errors after upgrade"
        return 1
    fi
    return 0
}
run_test "upgrade then doctor passes with no errors" test_upgrade_then_doctor_passes

# ──────────────────────────────────────────────
print_summary
