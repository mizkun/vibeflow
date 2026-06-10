#!/bin/bash

# Tests that core/schema/spec.yaml (the canonical spec schema) and
# core/runtime/spec_verify.py (the verification engine) agree on which
# fields are required — and that the schema validator can check
# spec.yaml at all.
#
# Background: the required-field sets were declared twice with no
# consistency test, so a schema change could silently leave the
# verification engine behind.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Compare required-field sets between a spec schema YAML and
# spec_verify.py's constants. Prints MATCH or MISMATCH details.
check_consistency() {
    local schema_yaml="$1"
    python3 -c "
import re, sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
import yaml
from core.runtime import spec_verify

data = yaml.safe_load(open('$schema_yaml'))

def required_fields(section):
    fields = data.get(section, {}).get('fields', {})
    return {name for name, spec in fields.items()
            if isinstance(spec, dict) and spec.get('required') is True}

story_req = required_fields('story')
contract_req = required_fields('contract')

# invariant fields are documented as prose in story.fields.invariants.notes
# in the form: 'id (required, string) ...'
notes = data.get('story', {}).get('fields', {}).get('invariants', {}).get('notes', '')
inv_req = set()
for line in notes.splitlines():
    m = re.match(r'\s*(\w+)\s+\((required|optional)', line)
    if m and m.group(2) == 'required':
        inv_req.add(m.group(1))

problems = []
if story_req != set(spec_verify.STORY_REQUIRED):
    problems.append(f'story: schema={sorted(story_req)} verifier={sorted(spec_verify.STORY_REQUIRED)}')
if contract_req != set(spec_verify.CONTRACT_REQUIRED):
    problems.append(f'contract: schema={sorted(contract_req)} verifier={sorted(spec_verify.CONTRACT_REQUIRED)}')
if inv_req != set(spec_verify.INVARIANT_REQUIRED):
    problems.append(f'invariant: schema={sorted(inv_req)} verifier={sorted(spec_verify.INVARIANT_REQUIRED)}')

if problems:
    print('MISMATCH: ' + '; '.join(problems))
else:
    print('MATCH')
"
}

test_required_sets_match() {
    local result
    result=$(check_consistency "${FRAMEWORK_DIR}/core/schema/spec.yaml")
    assert_equals "MATCH" "$result" \
        "spec.yaml and spec_verify.py must agree on required fields: $result"
}

test_checker_detects_drift() {
    # Self-test: mutate a copy of the schema and confirm the checker
    # actually notices (guards against a vacuously-green consistency test).
    local mutated="${TEST_DIR}/spec_mutated.yaml"
    python3 -c "
import yaml
data = yaml.safe_load(open('${FRAMEWORK_DIR}/core/schema/spec.yaml'))
data['story']['fields']['out_of_scope'] = {'required': True, 'type': 'string'}
yaml.safe_dump(data, open('$mutated', 'w'), allow_unicode=True)
"
    local result
    result=$(check_consistency "$mutated")
    if [ "$result" = "MATCH" ]; then
        fail "checker must detect a schema field the verifier doesn't know"
        return 1
    fi
    return 0
}

test_schema_validate_handles_spec() {
    local out rc=0
    out=$(python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${FRAMEWORK_DIR}/core/schema/spec.yaml" 2>&1) || rc=$?
    assert_equals "0" "$rc" \
        "schema_validate.py must validate spec.yaml (got rc=$rc: $out)"
}

describe "spec schema ⇄ verification engine consistency"
run_test "required-field sets match between spec.yaml and spec_verify.py" test_required_sets_match
run_test "the consistency checker detects schema drift (self-test)" test_checker_detects_drift
run_test "schema_validate.py can validate spec.yaml" test_schema_validate_handles_spec

print_summary
