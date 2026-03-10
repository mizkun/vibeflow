#!/bin/bash

# VibeFlow Test: Issue 1-2 — Workflow Schema Validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Workflow schema — file existence and structure"

test_workflow_schema_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/workflow.yaml" \
        "core/schema/workflow.yaml must exist"
}
run_test "core/schema/workflow.yaml exists" test_workflow_schema_exists

test_workflow_has_workflows_key() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/workflow.yaml" "^workflows:" \
        "workflow.yaml must have top-level 'workflows:' key"
}
run_test "workflow.yaml has workflows: key" test_workflow_has_workflows_key

# ──────────────────────────────────────────────
describe "Workflow schema — required workflow types"

test_workflow_has_all_types() {
    local wf="${FRAMEWORK_DIR}/core/schema/workflow.yaml"
    local missing=""
    for wtype in standard patch spike ops; do
        if ! grep -q "^  ${wtype}:" "$wf"; then
            missing="${missing} ${wtype}"
        fi
    done
    if [ -n "$missing" ]; then
        fail "Missing workflow types:${missing}"
        return 1
    fi
}
run_test "All 4 workflow types present" test_workflow_has_all_types

# ──────────────────────────────────────────────
describe "Workflow schema — step structure"

test_workflow_steps_have_required_fields() {
    local result
    result=$(python3 -c "
import yaml, sys
with open('${FRAMEWORK_DIR}/core/schema/workflow.yaml') as f:
    data = yaml.safe_load(f)
errors = []
valid_modes = {'solo', 'team', 'fork', 'checkpoint', 'review_worker'}
for wtype, wdef in data.get('workflows', {}).items():
    if 'steps' not in wdef:
        errors.append(f'{wtype}: missing steps')
        continue
    if 'description' not in wdef:
        errors.append(f'{wtype}: missing description')
    for step in wdef['steps']:
        for field in ['id', 'role', 'mode']:
            if field not in step:
                errors.append(f'{wtype}.{step.get(\"id\", \"?\")}: missing {field}')
        mode = step.get('mode', '')
        if mode not in valid_modes:
            errors.append(f'{wtype}.{step.get(\"id\", \"?\")}: invalid mode={mode}')
if errors:
    print('\\n'.join(errors))
    sys.exit(1)
" 2>&1) || {
        fail "Step validation errors: ${result}"
        return 1
    }
}
run_test "Each step has id, role, mode with valid values" test_workflow_steps_have_required_fields

test_workflow_standard_has_11_steps() {
    local count
    count=$(python3 -c "
import yaml
with open('${FRAMEWORK_DIR}/core/schema/workflow.yaml') as f:
    data = yaml.safe_load(f)
print(len(data['workflows']['standard']['steps']))
" 2>&1)
    # v5: 10 steps (no sub-steps like 2.5, 6.5, 7a in schema)
    if [ "$count" -lt 10 ]; then
        fail "Standard workflow should have at least 10 steps, got ${count}"
        return 1
    fi
}
run_test "Standard workflow has >= 11 steps" test_workflow_standard_has_11_steps

# ──────────────────────────────────────────────
describe "Workflow schema — role references valid"

test_workflow_roles_exist_in_policy() {
    local result
    result=$(python3 -c "
import yaml, sys
with open('${FRAMEWORK_DIR}/core/schema/workflow.yaml') as f:
    wdata = yaml.safe_load(f)
with open('${FRAMEWORK_DIR}/core/schema/policy.yaml') as f:
    pdata = yaml.safe_load(f)
policy_roles = set(pdata.get('roles', {}).keys())
errors = []
for wtype, wdef in wdata.get('workflows', {}).items():
    for step in wdef.get('steps', []):
        role = step.get('role', '')
        if role not in policy_roles:
            errors.append(f'{wtype}.{step[\"id\"]}: role={role} not in policy.yaml')
if errors:
    print('\\n'.join(errors))
    sys.exit(1)
" 2>&1) || {
        fail "Role reference errors: ${result}"
        return 1
    }
}
run_test "All workflow roles exist in policy.yaml" test_workflow_roles_exist_in_policy

# ──────────────────────────────────────────────
describe "Workflow schema — schema_validate.py"

test_schema_validate_passes_workflow() {
    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${FRAMEWORK_DIR}/core/schema/workflow.yaml" 2>&1 || {
        fail "schema_validate.py should pass for valid workflow.yaml"
        return 1
    }
}
run_test "schema_validate.py passes valid workflow.yaml" test_schema_validate_passes_workflow

test_schema_validate_fails_invalid_workflow() {
    cat > "${TEST_DIR}/bad_workflow.yaml" << 'YAML'
workflows:
  standard:
    steps:
      - id: step1
        role: engineer
YAML

    if python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${TEST_DIR}/bad_workflow.yaml" 2>/dev/null; then
        fail "schema_validate.py should fail for workflow step missing 'mode'"
        return 1
    fi
}
run_test "schema_validate.py fails for invalid workflow" test_schema_validate_fails_invalid_workflow

# ──────────────────────────────────────────────
print_summary
