#!/bin/bash

# VibeFlow Test: Phase 2 — Worker Handoff Packet (Issue 2-7)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Handoff — files exist"

test_schema_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/handoff_packet.yaml" \
        "core/schema/handoff_packet.yaml must exist"
}
run_test "handoff_packet.yaml schema exists" test_schema_exists

test_runtime_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/handoff.py" \
        "core/runtime/handoff.py must exist"
}
run_test "handoff.py runtime exists" test_runtime_exists

# ──────────────────────────────────────────────
describe "Handoff — schema structure"

test_schema_has_required_fields() {
    local schema="${FRAMEWORK_DIR}/core/schema/handoff_packet.yaml"
    assert_file_contains "$schema" "task_id" "Should have task_id"
    assert_file_contains "$schema" "task_type" "Should have task_type"
    assert_file_contains "$schema" "source_of_truth" "Should have source_of_truth"
    assert_file_contains "$schema" "goal" "Should have goal"
    assert_file_contains "$schema" "acceptance_criteria" "Should have acceptance_criteria"
    assert_file_contains "$schema" "constraints" "Should have constraints"
    assert_file_contains "$schema" "must_read" "Should have must_read"
    assert_file_contains "$schema" "validation" "Should have validation"
    assert_file_contains "$schema" "worker_type" "Should have worker_type"
    assert_file_contains "$schema" "artifacts" "Should have artifacts"
}
run_test "schema has all required fields" test_schema_has_required_fields

test_schema_constraints_fields() {
    local schema="${FRAMEWORK_DIR}/core/schema/handoff_packet.yaml"
    assert_file_contains "$schema" "allowed_paths" "Should have allowed_paths"
    assert_file_contains "$schema" "forbidden_paths" "Should have forbidden_paths"
    assert_file_contains "$schema" "max_files_changed" "Should have max_files_changed"
}
run_test "schema constraints has sub-fields" test_schema_constraints_fields

# ──────────────────────────────────────────────
describe "Handoff — build packet (normal)"

test_build_packet_basic() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 42,
    'title': 'Add login feature',
    'body': '## Overview\nLogin form\n\n## Acceptance Criteria\n- Login works\n- Logout works',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue,
    repo='mizkun/vibeflow',
    role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
print(json.dumps(packet))
")

    # Verify basic fields
    echo "$result" | python3 -c "
import sys, json
p = json.load(sys.stdin)
assert p['source_of_truth']['issue_number'] == 42, f'issue_number: {p[\"source_of_truth\"]}'
assert p['source_of_truth']['repo'] == 'mizkun/vibeflow', f'repo: {p[\"source_of_truth\"]}'
assert p['goal'] == 'Add login feature', f'goal: {p[\"goal\"]}'
assert p['worker_type'] == 'claude', f'worker_type: {p[\"worker_type\"]}'
assert 'task_id' in p, 'Missing task_id'
assert 'task_type' in p, 'Missing task_type'
print('OK')
" || { fail "Basic fields should be populated"; return 1; }
}
run_test "builds packet with basic fields" test_build_packet_basic

test_build_packet_acceptance_criteria() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10,
    'title': 'Fix bug',
    'body': '## Acceptance Criteria\n- Bug is fixed\n- No regression',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='owner/repo', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
print(json.dumps(packet))
")

    local has_ac
    has_ac=$(echo "$result" | python3 -c "
import sys, json
p = json.load(sys.stdin)
ac = p.get('acceptance_criteria', [])
print(len(ac) > 0)
")
    assert_equals "True" "$has_ac" "Should extract acceptance criteria from body"
}
run_test "extracts acceptance criteria" test_build_packet_acceptance_criteria

# ──────────────────────────────────────────────
describe "Handoff — constraints from policy"

test_allowed_paths_from_policy() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10, 'title': 'Task', 'body': 'body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
print(json.dumps(packet['constraints']))
")

    echo "$result" | python3 -c "
import sys, json
c = json.load(sys.stdin)
assert 'src/*' in c['allowed_paths'], f'allowed_paths: {c[\"allowed_paths\"]}'
assert 'tests/*' in c['allowed_paths'], f'allowed_paths: {c[\"allowed_paths\"]}'
assert isinstance(c['forbidden_paths'], list), 'forbidden_paths should be list'
assert isinstance(c['max_files_changed'], int), 'max_files_changed should be int'
print('OK')
" || { fail "Constraints should reflect engineer role from policy"; return 1; }
}
run_test "allowed_paths comes from policy can_write" test_allowed_paths_from_policy

test_forbidden_paths_has_defaults() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10, 'title': 'Task', 'body': 'body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
forbidden = packet['constraints']['forbidden_paths']
print(json.dumps(forbidden))
")

    echo "$result" | python3 -c "
import sys, json
f = json.load(sys.stdin)
assert len(f) > 0, 'forbidden_paths should not be empty'
print('OK')
" || { fail "forbidden_paths should have default entries"; return 1; }
}
run_test "forbidden_paths has default entries" test_forbidden_paths_has_defaults

# ──────────────────────────────────────────────
describe "Handoff — must_read from policy can_read"

test_must_read_from_policy() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10, 'title': 'Task', 'body': 'body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
print(json.dumps(packet['must_read']))
")

    echo "$result" | python3 -c "
import sys, json
mr = json.load(sys.stdin)
assert isinstance(mr, list), 'must_read should be list'
assert 'spec.md' in mr, f'coding_agent must_read should include spec.md, got {mr}'
print('OK')
" || { fail "must_read should include policy can_read entries"; return 1; }
}
run_test "must_read reflects policy can_read" test_must_read_from_policy

# ──────────────────────────────────────────────
describe "Handoff — worker_type"

test_worker_type_explicit() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10, 'title': 'Task', 'body': 'body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

for wt in ['claude', 'codex', 'human']:
    packet = build_packet(
        issue=issue, repo='o/r', role='coding_agent',
        policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
        worker_type=wt,
    )
    assert packet['worker_type'] == wt, f'Expected {wt}, got {packet[\"worker_type\"]}'

print('OK')
")
    assert_equals "OK" "$result" "worker_type should be set to explicit value"
}
run_test "worker_type accepts claude/codex/human" test_worker_type_explicit

# ──────────────────────────────────────────────
describe "Handoff — task_type from labels"

test_task_type_from_labels() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

for label, expected in [('type:dev', 'dev'), ('type:patch', 'patch'), ('type:spike', 'spike'), ('type:ops', 'ops')]:
    issue = {
        'number': 1, 'title': 'T', 'body': 'b',
        'labels': [{'name': label}, {'name': 'workflow:standard'}],
    }
    packet = build_packet(
        issue=issue, repo='o/r', role='coding_agent',
        policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
        worker_type='claude',
    )
    assert packet['task_type'] == expected, f'Expected {expected}, got {packet[\"task_type\"]}'

print('OK')
")
    assert_equals "OK" "$result" "task_type should be derived from type: label"
}
run_test "task_type derived from type label" test_task_type_from_labels

# ──────────────────────────────────────────────
describe "Handoff — JSON save/load"

test_save_and_load_packet() {
    local tmpdir="${TEST_DIR}/handoff_io"
    mkdir -p "$tmpdir"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet, save_packet, load_packet

issue = {
    'number': 42, 'title': 'Test save', 'body': '## Acceptance Criteria\n- works',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)

path = save_packet('${tmpdir}', packet)
loaded = load_packet(path)

assert loaded['source_of_truth']['issue_number'] == 42
assert loaded['goal'] == 'Test save'
assert loaded['worker_type'] == 'claude'
print('OK')
")
    assert_equals "OK" "$result" "Packet should survive save/load cycle"
}
run_test "save and load packet as JSON" test_save_and_load_packet

test_save_creates_file() {
    local tmpdir="${TEST_DIR}/handoff_file"
    mkdir -p "$tmpdir"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet, save_packet

issue = {
    'number': 99, 'title': 'File test', 'body': 'b',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
save_packet('${tmpdir}', packet)
"

    # Check a JSON file was created
    local count
    count=$(find "${tmpdir}" -name "*.json" | wc -l | tr -d ' ')
    [ "$count" -ge 1 ] || { fail "Should create at least one JSON file"; return 1; }
}
run_test "save creates JSON file" test_save_creates_file

# ──────────────────────────────────────────────
describe "Handoff — validation field"

test_validation_field() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10, 'title': 'Task', 'body': 'body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
v = packet.get('validation', {})
assert 'required_commands' in v, f'Missing required_commands in validation: {v}'
assert isinstance(v['required_commands'], list), 'required_commands should be list'
print('OK')
")
    assert_equals "OK" "$result" "validation should have required_commands"
}
run_test "validation has required_commands" test_validation_field

# ──────────────────────────────────────────────
describe "Handoff — artifacts field"

test_artifacts_field() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.handoff import build_packet

issue = {
    'number': 10, 'title': 'Task', 'body': 'body',
    'labels': [{'name': 'type:dev'}, {'name': 'workflow:standard'}],
}

packet = build_packet(
    issue=issue, repo='o/r', role='coding_agent',
    policy_path='${FRAMEWORK_DIR}/core/schema/policy.yaml',
    worker_type='claude',
)
a = packet.get('artifacts', {})
assert isinstance(a, dict), f'artifacts should be dict, got {type(a)}'
print('OK')
")
    assert_equals "OK" "$result" "artifacts should be present as dict"
}
run_test "artifacts field present" test_artifacts_field

# ──────────────────────────────────────────────
print_summary
