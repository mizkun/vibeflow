#!/bin/bash

# Tests that sourcing lib/create_*.sh does not clobber the caller's
# SCRIPT_DIR.
#
# setup_vibeflow.sh sets SCRIPT_DIR to the framework root, then sources
# every lib/create_*.sh. Each lib file used to reassign the global
# SCRIPT_DIR to lib/, which silently broke every later use of
# ${SCRIPT_DIR}/examples and ${SCRIPT_DIR}/core in setup (rules/runtime
# deployment, GitHub label creation).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

LIB_DIR="${FRAMEWORK_DIR}/lib"

# Source one lib file in a clean subshell with SCRIPT_DIR pre-set to a
# sentinel, and echo what SCRIPT_DIR is afterwards.
script_dir_after_sourcing() {
    local lib_file="$1"
    bash -c '
        set -uo pipefail
        SCRIPT_DIR="/sentinel-root"
        source "$1" >/dev/null 2>&1 || true
        echo "$SCRIPT_DIR"
    ' _ "$lib_file"
}

test_each_lib_preserves_script_dir() {
    local broken=""
    local lib_file
    for lib_file in "$LIB_DIR"/create_*.sh; do
        local after
        after="$(script_dir_after_sourcing "$lib_file")"
        if [ "$after" != "/sentinel-root" ]; then
            broken="${broken} $(basename "$lib_file")"
        fi
    done
    if [ -n "$broken" ]; then
        fail "these lib files clobber the caller's SCRIPT_DIR:${broken}"
        return 1
    fi
    return 0
}

test_setup_source_sequence_preserves_script_dir() {
    # Reproduce setup_vibeflow.sh's source sequence and verify the
    # framework-root SCRIPT_DIR survives it.
    local after
    after=$(bash -c '
        set -uo pipefail
        SCRIPT_DIR="$1"
        source "${SCRIPT_DIR}/lib/common.sh" >/dev/null 2>&1 || true
        for f in "${SCRIPT_DIR}"/lib/create_*.sh; do
            source "$f" >/dev/null 2>&1 || true
        done
        echo "$SCRIPT_DIR"
    ' _ "$FRAMEWORK_DIR")
    assert_equals "$FRAMEWORK_DIR" "$after" \
        "SCRIPT_DIR must still be the framework root after sourcing all create_*.sh"
}

describe "lib/create_*.sh — SCRIPT_DIR pollution"
run_test "each lib file preserves the caller's SCRIPT_DIR" test_each_lib_preserves_script_dir
run_test "setup's full source sequence preserves SCRIPT_DIR" test_setup_source_sequence_preserves_script_dir

print_summary
