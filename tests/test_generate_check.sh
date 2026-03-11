#!/bin/bash

# VibeFlow Test: generate --check mode (Issue #76)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "generate --check — exit codes"

test_check_passes_when_fresh() {
    # Generate fresh, then --check should pass
    local tmpdir="${TEST_DIR}/check_fresh"
    mkdir -p "${tmpdir}/.vibe"
    cd "$tmpdir"

    # Generate first
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    # Check should pass
    set +e
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --check > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "--check should exit 0 when files are fresh"
}
run_test "generate --check passes when fresh" test_check_passes_when_fresh

test_check_fails_when_stale() {
    local tmpdir="${TEST_DIR}/check_stale"
    mkdir -p "${tmpdir}/.vibe"
    cd "$tmpdir"

    # Generate first
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    # Tamper with a generated file
    echo "# stale" >> "${tmpdir}/.vibe/policy.yaml"

    # Check should fail
    set +e
    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --check 2>&1)
    local code=$?
    set -e

    assert_equals "1" "$code" "--check should exit 1 when files are stale"
}
run_test "generate --check fails when stale" test_check_fails_when_stale

test_check_shows_stale_files() {
    local tmpdir="${TEST_DIR}/check_show"
    mkdir -p "${tmpdir}/.vibe"
    cd "$tmpdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    echo "# stale" >> "${tmpdir}/.vibe/policy.yaml"

    set +e
    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --check 2>&1)
    set -e

    if ! echo "$output" | grep -q "policy.yaml"; then
        fail "--check should show which file is stale"
        return 1
    fi
    return 0
}
run_test "generate --check shows stale file names" test_check_shows_stale_files

test_check_does_not_modify_files() {
    local tmpdir="${TEST_DIR}/check_readonly"
    mkdir -p "${tmpdir}/.vibe"
    cd "$tmpdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    echo "# stale" >> "${tmpdir}/.vibe/policy.yaml"

    # Record current content
    local before
    before=$(cat "${tmpdir}/.vibe/policy.yaml")

    set +e
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --check > /dev/null 2>&1
    set -e

    local after
    after=$(cat "${tmpdir}/.vibe/policy.yaml")

    assert_equals "$before" "$after" "--check should not modify files"
}
run_test "generate --check does not modify files" test_check_does_not_modify_files

# ──────────────────────────────────────────────
describe "generate --check — CLI integration"

test_vibeflow_generate_check() {
    local tmpdir="${TEST_DIR}/cli_check"
    mkdir -p "${tmpdir}/.vibe"
    cd "$tmpdir"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$tmpdir" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    set +e
    bash "${FRAMEWORK_DIR}/bin/vibeflow" generate --check 2>&1
    local code=$?
    set -e

    assert_equals "0" "$code" "vibeflow generate --check should work via CLI"
}
run_test "vibeflow generate --check works via CLI" test_vibeflow_generate_check

# ──────────────────────────────────────────────
describe "session-startup — doctor step"

test_session_startup_has_doctor() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/session-startup.md" \
        "vibeflow doctor" \
        "session-startup.md should include vibeflow doctor step"
}
run_test "session-startup.md includes vibeflow doctor" test_session_startup_has_doctor

test_session_startup_doctor_is_first() {
    # Doctor should be step 1
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/rules/session-startup.md" \
        "1\. \*\*VibeFlow 整合性チェック\*\*" \
        "vibeflow doctor should be step 1 in startup checklist"
}
run_test "vibeflow doctor is step 1 in startup checklist" test_session_startup_doctor_is_first

# ──────────────────────────────────────────────
print_summary
