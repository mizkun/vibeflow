#!/bin/bash

# VibeFlow Test: Issue 1-1 — Policy Schema Validation
# core/schema/policy.yaml must be valid and contain all required roles/fields.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Policy schema — file existence and structure"

test_policy_schema_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        "core/schema/policy.yaml must exist"
}
run_test "core/schema/policy.yaml exists" test_policy_schema_exists

test_policy_has_roles_key() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/policy.yaml" "^roles:" \
        "policy.yaml must have top-level 'roles:' key"
}
run_test "policy.yaml has roles: key" test_policy_has_roles_key

test_policy_has_always_allow() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/policy.yaml" "^always_allow:" \
        "policy.yaml must have top-level 'always_allow:' key"
}
run_test "policy.yaml has always_allow: key" test_policy_has_always_allow

# ──────────────────────────────────────────────
describe "Policy schema — required roles"

test_policy_has_all_required_roles() {
    local policy="${FRAMEWORK_DIR}/core/schema/policy.yaml"
    local missing=""
    for role in iris coding_agent; do
        if ! grep -q "^  ${role}:" "$policy"; then
            missing="${missing} ${role}"
        fi
    done
    if [ -n "$missing" ]; then
        fail "Missing roles:${missing}"
        return 1
    fi
}
run_test "All required roles present" test_policy_has_all_required_roles

# ──────────────────────────────────────────────
describe "Policy schema — required fields per role"

test_policy_roles_have_required_fields() {
    local result
    result=$(python3 -c "
import yaml, sys
with open('${FRAMEWORK_DIR}/core/schema/policy.yaml') as f:
    data = yaml.safe_load(f)
errors = []
for role_id, role in data.get('roles', {}).items():
    for field in ['display_name', 'can_read', 'can_write', 'enforcement']:
        if field not in role:
            errors.append(f'{role_id} missing {field}')
if errors:
    print('\\n'.join(errors))
    sys.exit(1)
" 2>&1) || {
        fail "Required fields missing: ${result}"
        return 1
    }
}
run_test "Each role has display_name, can_read, can_write, enforcement" test_policy_roles_have_required_fields

test_policy_enforcement_values_valid() {
    local result
    result=$(python3 -c "
import yaml, sys
with open('${FRAMEWORK_DIR}/core/schema/policy.yaml') as f:
    data = yaml.safe_load(f)
errors = []
for role_id, role in data.get('roles', {}).items():
    e = role.get('enforcement', '')
    if e not in ('hard', 'soft'):
        errors.append(f'{role_id}: enforcement={e} (must be hard or soft)')
if errors:
    print('\\n'.join(errors))
    sys.exit(1)
" 2>&1) || {
        fail "Invalid enforcement values: ${result}"
        return 1
    }
}
run_test "enforcement values are 'hard' or 'soft'" test_policy_enforcement_values_valid

# ──────────────────────────────────────────────
describe "Policy schema — schema_validate.py"

test_schema_validate_passes_valid_policy() {
    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${FRAMEWORK_DIR}/core/schema/policy.yaml" 2>&1 || {
        fail "schema_validate.py should pass for valid policy.yaml"
        return 1
    }
}
run_test "schema_validate.py passes valid policy.yaml" test_schema_validate_passes_valid_policy

test_schema_validate_fails_invalid_policy() {
    # Create invalid policy (missing required role)
    cat > "${TEST_DIR}/bad_policy.yaml" << 'YAML'
roles:
  iris:
    display_name: "Iris"
    can_read: []
    can_write: []
YAML

    if python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${TEST_DIR}/bad_policy.yaml" 2>/dev/null; then
        fail "schema_validate.py should fail for policy missing enforcement field"
        return 1
    fi
}
run_test "schema_validate.py fails for invalid policy" test_schema_validate_fails_invalid_policy

test_schema_validate_fails_missing_roles() {
    # Create policy without required roles
    cat > "${TEST_DIR}/incomplete_policy.yaml" << 'YAML'
roles:
  iris:
    display_name: "Iris"
    can_read: []
    can_write: []
    enforcement: hard
always_allow: []
YAML

    if python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${TEST_DIR}/incomplete_policy.yaml" 2>/dev/null; then
        fail "schema_validate.py should fail when required roles are missing"
        return 1
    fi
}
run_test "schema_validate.py fails when required roles missing" test_schema_validate_fails_missing_roles

test_schema_validate_fails_missing_coding_agent_role() {
    # Create policy with iris but missing coding_agent
    cat > "${TEST_DIR}/no_coding_agent_policy.yaml" << 'YAML'
roles:
  iris:
    display_name: "Iris"
    can_read: []
    can_write: []
    enforcement: hard
always_allow: []
YAML

    if python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${TEST_DIR}/no_coding_agent_policy.yaml" 2>/dev/null; then
        fail "schema_validate.py should fail when coding_agent role is missing"
        return 1
    fi
}
run_test "schema_validate.py fails when coding_agent role missing" test_schema_validate_fails_missing_coding_agent_role

# ──────────────────────────────────────────────
print_summary
