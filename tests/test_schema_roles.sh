#!/bin/bash

# VibeFlow Test: Issue 1-3 — Roles Schema Validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Roles schema — file existence and structure"

test_roles_schema_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/roles.yaml" \
        "core/schema/roles.yaml must exist"
}
run_test "core/schema/roles.yaml exists" test_roles_schema_exists

test_roles_has_roles_key() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/roles.yaml" "^roles:" \
        "roles.yaml must have top-level 'roles:' key"
}
run_test "roles.yaml has roles: key" test_roles_has_roles_key

# ──────────────────────────────────────────────
describe "Roles schema — required fields"

test_roles_have_required_fields() {
    local result
    result=$(python3 -c "
import yaml, sys
with open('${FRAMEWORK_DIR}/core/schema/roles.yaml') as f:
    data = yaml.safe_load(f)
errors = []
for role_id, role in data.get('roles', {}).items():
    for field in ['name', 'description', 'responsibilities']:
        if field not in role:
            errors.append(f'{role_id} missing {field}')
    if 'responsibilities' in role and not isinstance(role['responsibilities'], list):
        errors.append(f'{role_id}: responsibilities must be a list')
if errors:
    print('\\n'.join(errors))
    sys.exit(1)
" 2>&1) || {
        fail "Required fields missing: ${result}"
        return 1
    }
}
run_test "Each role has name, description, responsibilities" test_roles_have_required_fields

# ──────────────────────────────────────────────
describe "Roles schema — cross-validation with policy.yaml"

test_roles_match_policy_roles() {
    local result
    result=$(python3 -c "
import yaml, sys
with open('${FRAMEWORK_DIR}/core/schema/roles.yaml') as f:
    rdata = yaml.safe_load(f)
with open('${FRAMEWORK_DIR}/core/schema/policy.yaml') as f:
    pdata = yaml.safe_load(f)
policy_roles = set(pdata.get('roles', {}).keys())
roles_roles = set(rdata.get('roles', {}).keys())
missing_in_roles = policy_roles - roles_roles
missing_in_policy = roles_roles - policy_roles
errors = []
if missing_in_roles:
    errors.append(f'In policy.yaml but not in roles.yaml: {missing_in_roles}')
if missing_in_policy:
    errors.append(f'In roles.yaml but not in policy.yaml: {missing_in_policy}')
if errors:
    print('\\n'.join(errors))
    sys.exit(1)
" 2>&1) || {
        fail "Role mismatch: ${result}"
        return 1
    }
}
run_test "roles.yaml and policy.yaml have same role set" test_roles_match_policy_roles

# ──────────────────────────────────────────────
describe "Roles schema — schema_validate.py"

test_schema_validate_passes_roles() {
    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${FRAMEWORK_DIR}/core/schema/roles.yaml" 2>&1 || {
        fail "schema_validate.py should pass for valid roles.yaml"
        return 1
    }
}
run_test "schema_validate.py passes valid roles.yaml" test_schema_validate_passes_roles

# ──────────────────────────────────────────────
print_summary
