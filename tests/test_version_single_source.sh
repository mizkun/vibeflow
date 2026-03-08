#!/bin/bash

# VibeFlow Test: Issue 0-1 — Version Single Source of Truth
# VERSION file must be the only place where version is hardcoded.
# lib/framework_version.sh must read from VERSION dynamically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
# Tests
# ──────────────────────────────────────────────

describe "Version Single Source of Truth"

test_version_file_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/VERSION" "VERSION file must exist"
}
run_test "VERSION file exists" test_version_file_exists

test_framework_version_reads_from_version_file() {
    # Source framework_version.sh and check FRAMEWORK_VERSION matches VERSION
    local expected_version
    expected_version=$(cat "${FRAMEWORK_DIR}/VERSION" | tr -d '[:space:]')

    source "${FRAMEWORK_DIR}/lib/framework_version.sh"
    assert_equals "$expected_version" "$FRAMEWORK_VERSION" \
        "FRAMEWORK_VERSION ('$FRAMEWORK_VERSION') should match VERSION file ('$expected_version')"
}
run_test "framework_version.sh reads version from VERSION file" test_framework_version_reads_from_version_file

test_no_hardcoded_version_in_framework_version() {
    # framework_version.sh should not contain hardcoded version like FRAMEWORK_VERSION="3.x.x"
    if grep -qE 'FRAMEWORK_VERSION="[0-9]+\.[0-9]+\.[0-9]+"' "${FRAMEWORK_DIR}/lib/framework_version.sh"; then
        fail "framework_version.sh contains hardcoded version string"
        return 1
    fi
}
run_test "No hardcoded version in framework_version.sh" test_no_hardcoded_version_in_framework_version

test_no_hardcoded_version_in_setup_script_comment() {
    # setup_vibeflow.sh should not have version number in comments
    if grep -qE '^# Version: [0-9]+\.[0-9]+\.[0-9]+' "${FRAMEWORK_DIR}/setup_vibeflow.sh"; then
        fail "setup_vibeflow.sh has hardcoded version in comment"
        return 1
    fi
}
run_test "No hardcoded version in setup_vibeflow.sh comment" test_no_hardcoded_version_in_setup_script_comment

test_vibeflow_version_matches() {
    # vibeflow version output should contain the VERSION file content
    local expected_version
    expected_version=$(cat "${FRAMEWORK_DIR}/VERSION" | tr -d '[:space:]')

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" version 2>&1)

    if echo "$output" | grep -q "v${expected_version}"; then
        return 0
    else
        fail "vibeflow version output should contain v${expected_version}, got: $output"
        return 1
    fi
}
run_test "vibeflow version matches VERSION file" test_vibeflow_version_matches

test_changelog_has_current_version() {
    local expected_version
    expected_version=$(cat "${FRAMEWORK_DIR}/VERSION" | tr -d '[:space:]')

    assert_file_contains "${FRAMEWORK_DIR}/CHANGELOG.md" "## \\[${expected_version}\\]" \
        "CHANGELOG.md should have entry for version ${expected_version}"
}
run_test "CHANGELOG.md has entry for current version" test_changelog_has_current_version

test_write_version_file_uses_correct_version() {
    # write_version_file should produce YAML with the VERSION file version
    local expected_version
    expected_version=$(cat "${FRAMEWORK_DIR}/VERSION" | tr -d '[:space:]')

    source "${FRAMEWORK_DIR}/lib/framework_version.sh"
    mkdir -p "${TEST_DIR}/.vibe"
    write_version_file "${TEST_DIR}"

    assert_file_contains "${TEST_DIR}/.vibe/framework_version.yaml" "version: \"${expected_version}\"" \
        "Generated framework_version.yaml should contain version ${expected_version}"
}
run_test "write_version_file generates correct version" test_write_version_file_uses_correct_version

test_no_hardcoded_version_in_setup_global_var() {
    # setup_vibeflow.sh should not have VERSION="3.x.x" — it should use FRAMEWORK_VERSION
    if grep -qE '^VERSION="[0-9]+\.[0-9]+\.[0-9]+"' "${FRAMEWORK_DIR}/setup_vibeflow.sh"; then
        fail "setup_vibeflow.sh has hardcoded VERSION variable"
        return 1
    fi
}
run_test "No hardcoded VERSION in setup_vibeflow.sh global var" test_no_hardcoded_version_in_setup_global_var

test_setup_version_uses_framework_version() {
    # setup_vibeflow.sh should reference FRAMEWORK_VERSION
    assert_file_contains "${FRAMEWORK_DIR}/setup_vibeflow.sh" 'FRAMEWORK_VERSION' \
        "setup_vibeflow.sh should use FRAMEWORK_VERSION from framework_version.sh"
}
run_test "setup_vibeflow.sh uses FRAMEWORK_VERSION" test_setup_version_uses_framework_version

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

print_summary
