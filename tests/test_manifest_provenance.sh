#!/bin/bash

# Tests that each manifest entry records its REAL source, so the
# "which schema/file produced this?" audit actually works.
#
# Background: copied hooks (validate_write.sh, validate_step7a.py) and
# the state templates were all recorded with source core/schema/*.yaml
# even though they are copied verbatim from examples/, not derived from
# the schema — a lie that makes provenance useless.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

gen_project() {
    local proj="$1"
    mkdir -p "${proj}/.vibe"
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" --framework-dir "${FRAMEWORK_DIR}" >/dev/null 2>&1
}

source_of() {
    # $1 manifest, $2 rel path
    python3 -c "
import json
m = json.load(open('$1'))['files']
print(m.get('$2', {}).get('source', 'MISSING'))
"
}

test_copied_hooks_point_to_examples() {
    local proj="${TEST_DIR}/p"
    gen_project "$proj"
    local man="${proj}/.vibe/generated-manifest.json"

    local s
    s=$(source_of "$man" ".vibe/hooks/validate_write.sh")
    case "$s" in
        examples/.vibe/hooks/validate_write.sh) ;;
        *) fail "validate_write.sh source should be its examples/ copy origin, got: $s"; return 1 ;;
    esac
    s=$(source_of "$man" ".vibe/hooks/validate_step7a.py")
    case "$s" in
        examples/.vibe/hooks/validate_step7a.py) ;;
        *) fail "validate_step7a.py source should be its examples/ copy origin, got: $s"; return 1 ;;
    esac
    return 0
}
run_test "copied hooks record their examples/ origin" test_copied_hooks_point_to_examples

test_schema_generated_keep_schema_source() {
    local proj="${TEST_DIR}/p2"
    gen_project "$proj"
    local man="${proj}/.vibe/generated-manifest.json"
    # validate_access.py is genuinely template-generated from policy.yaml
    local s
    s=$(source_of "$man" ".vibe/hooks/validate_access.py")
    case "$s" in
        core/schema/policy.yaml) ;;
        *) fail "schema-generated validate_access.py should keep its schema source, got: $s"; return 1 ;;
    esac
    return 0
}
run_test "schema-generated files keep the schema source" test_schema_generated_keep_schema_source

test_state_templates_point_to_examples() {
    local proj="${TEST_DIR}/p3"
    gen_project "$proj"
    local man="${proj}/.vibe/generated-manifest.json"
    local s
    s=$(source_of "$man" ".vibe/project_state.yaml")
    case "$s" in
        examples/.vibe/project_state.yaml) ;;
        *) fail "project_state.yaml is copied from examples/, source should say so, got: $s"; return 1 ;;
    esac
    return 0
}
run_test "state templates record their examples/ origin" test_state_templates_point_to_examples

print_summary
