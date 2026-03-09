#!/bin/bash

# VibeFlow Test: Phase 2 — DoR Gate (Issue 2-5)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "DoR gate — module exists"

test_dor_gate_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/dor_gate.py" \
        "core/runtime/dor_gate.py must exist"
}
run_test "dor_gate.py exists" test_dor_gate_exists

# ──────────────────────────────────────────────
describe "DoR gate — pass (all fields present)"

test_dor_pass_full() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Add login feature',
    'body': '## Overview\nLogin\n\n## Acceptance Criteria\n- works\n\n## File Locations\nsrc/\n\n## Testing Requirements\nunit tests',
    'labels': [
        {'name': 'type:dev'},
        {'name': 'workflow:standard'},
        {'name': 'risk:medium'},
        {'name': 'qa:manual'},
    ],
}
result = check_dor(issue)
print(json.dumps(result))
")

    local passed
    passed=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['passed'])")
    assert_equals "True" "$passed" "Fully specified issue should pass DoR"

    local hard_blocks
    hard_blocks=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(len(r['hard_blocks']))")
    assert_equals "0" "$hard_blocks" "Should have 0 hard blocks"

    local warnings
    warnings=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(len(r['warnings']))")
    assert_equals "0" "$warnings" "Should have 0 warnings"
}
run_test "fully specified issue passes DoR" test_dor_pass_full

# ──────────────────────────────────────────────
describe "DoR gate — hard blocks"

test_dor_hard_block_no_title() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': '',
    'body': 'some body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}
print(json.dumps(check_dor(issue)))
")
    local passed
    passed=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['passed'])")
    assert_equals "False" "$passed" "Empty title should fail"

    echo "$result" | python3 -c "
import sys, json
r = json.load(sys.stdin)
blocks = [b['field'] for b in r['hard_blocks']]
assert 'title' in blocks, f'Expected title in hard_blocks, got {blocks}'
" || { fail "hard_blocks should include 'title'"; return 1; }
}
run_test "hard block: no title" test_dor_hard_block_no_title

test_dor_hard_block_no_body() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': '',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}
print(json.dumps(check_dor(issue)))
")
    local passed
    passed=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['passed'])")
    assert_equals "False" "$passed" "Empty body should fail"
}
run_test "hard block: no body" test_dor_hard_block_no_body

test_dor_hard_block_no_type_label() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': 'some body',
    'labels': [{'name': 'workflow:standard'}],
}
print(json.dumps(check_dor(issue)))
")
    local passed
    passed=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['passed'])")
    assert_equals "False" "$passed" "Missing type label should fail"
}
run_test "hard block: no type label" test_dor_hard_block_no_type_label

test_dor_hard_block_no_workflow_label() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': 'some body',
    'labels': [{'name': 'type:dev'}],
}
print(json.dumps(check_dor(issue)))
")
    local passed
    passed=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['passed'])")
    assert_equals "False" "$passed" "Missing workflow label should fail"
}
run_test "hard block: no workflow label" test_dor_hard_block_no_workflow_label

test_dor_hard_block_multiple() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {'title': '', 'body': '', 'labels': []}
result = check_dor(issue)
print(len(result['hard_blocks']))
")
    # Should have 4 hard blocks: title, body, type label, workflow label
    local count
    count=$(echo "$result" | tr -d '[:space:]')
    assert_equals "4" "$count" "Should have 4 hard blocks for completely empty issue"
}
run_test "hard block: multiple missing fields" test_dor_hard_block_multiple

# ──────────────────────────────────────────────
describe "DoR gate — warnings"

test_dor_warning_no_risk_label() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': '## Acceptance Criteria\n- works\n## File Locations\nsrc/\n## Testing Requirements\ntests',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}, {'name': 'qa:manual'}],
}
result = check_dor(issue)
print(json.dumps(result))
")
    local passed
    passed=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['passed'])")
    assert_equals "True" "$passed" "Missing risk label should still pass (warning only)"

    local has_risk_warning
    has_risk_warning=$(echo "$result" | python3 -c "
import sys, json
r = json.load(sys.stdin)
fields = [w['field'] for w in r['warnings']]
print('risk' in fields)
")
    assert_equals "True" "$has_risk_warning" "Should have risk label warning"
}
run_test "warning: no risk label" test_dor_warning_no_risk_label

test_dor_warning_no_qa_label() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': '## Acceptance Criteria\n- works\n## File Locations\nsrc/\n## Testing Requirements\ntests',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}, {'name': 'risk:low'}],
}
result = check_dor(issue)
warnings = [w['field'] for w in result['warnings']]
print('qa' in warnings)
")
    assert_equals "True" "$result" "Should have qa label warning"
}
run_test "warning: no qa label" test_dor_warning_no_qa_label

test_dor_warning_no_acceptance_criteria() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': 'just some text without sections',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}, {'name': 'risk:low'}, {'name': 'qa:manual'}],
}
result = check_dor(issue)
warnings = [w['field'] for w in result['warnings']]
print(json.dumps(warnings))
")
    echo "$result" | python3 -c "
import sys, json
warnings = json.load(sys.stdin)
assert 'acceptance_criteria' in warnings, f'Expected acceptance_criteria warning, got {warnings}'
assert 'file_locations' in warnings, f'Expected file_locations warning, got {warnings}'
assert 'testing_requirements' in warnings, f'Expected testing_requirements warning, got {warnings}'
" || { fail "Should warn about missing AC, File Locations, Testing Requirements"; return 1; }
}
run_test "warning: missing body sections" test_dor_warning_no_acceptance_criteria

# ──────────────────────────────────────────────
describe "DoR gate — result structure"

test_dor_result_structure() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {
    'title': 'Some title',
    'body': 'some body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}
result = check_dor(issue)
# Verify structure
assert 'passed' in result, 'Missing passed field'
assert 'hard_blocks' in result, 'Missing hard_blocks field'
assert 'warnings' in result, 'Missing warnings field'
assert isinstance(result['hard_blocks'], list), 'hard_blocks should be list'
assert isinstance(result['warnings'], list), 'warnings should be list'
print('OK')
")
    assert_equals "OK" "$result" "Result should have correct structure"
}
run_test "result has passed/hard_blocks/warnings" test_dor_result_structure

test_dor_block_entry_has_field_and_message() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {'title': '', 'body': 'x', 'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}]}
result = check_dor(issue)
block = result['hard_blocks'][0]
assert 'field' in block, 'block should have field'
assert 'message' in block, 'block should have message'
print('OK')
")
    assert_equals "OK" "$result" "Block entries should have field and message"
}
run_test "block/warning entries have field and message" test_dor_block_entry_has_field_and_message

# ──────────────────────────────────────────────
describe "DoR gate — null/None body handling"

test_dor_null_body() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dor_gate import check_dor

issue = {'title': 'Title', 'body': None, 'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}]}
result = check_dor(issue)
print(result['passed'])
")
    assert_equals "False" "$result" "None body should fail"
}
run_test "null body is treated as missing" test_dor_null_body

# ──────────────────────────────────────────────
print_summary
