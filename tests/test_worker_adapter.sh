#!/bin/bash

# VibeFlow Test: Phase 3 — Worker Adapter (Issue 3-1)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Worker adapter — module exists"

test_module_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "core/runtime/worker_adapter.py must exist"
}
run_test "worker_adapter.py exists" test_module_exists

# ──────────────────────────────────────────────
describe "Worker adapter — class structure"

test_has_base_class() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "class WorkerAdapter" "WorkerAdapter base class should exist"
}
run_test "WorkerAdapter base class exists" test_has_base_class

test_has_claude_worker() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "class ClaudeWorker" "ClaudeWorker class should exist"
}
run_test "ClaudeWorker exists" test_has_claude_worker

test_has_codex_worker() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "class CodexWorker" "CodexWorker class should exist"
}
run_test "CodexWorker exists" test_has_codex_worker

test_has_human_worker() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "class HumanWorker" "HumanWorker class should exist"
}
run_test "HumanWorker exists" test_has_human_worker

test_has_execute_method() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "def execute" "execute method should exist"
}
run_test "execute method exists" test_has_execute_method

test_has_factory() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/worker_adapter.py" \
        "def get_worker" "get_worker factory function should exist"
}
run_test "get_worker factory exists" test_has_factory

# ──────────────────────────────────────────────
describe "Worker adapter — Python import and factory"

test_import_and_factory() {
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.worker_adapter import get_worker, ClaudeWorker, CodexWorker, HumanWorker

# Factory returns correct types
assert isinstance(get_worker('claude'), ClaudeWorker), 'claude should return ClaudeWorker'
assert isinstance(get_worker('codex'), CodexWorker), 'codex should return CodexWorker'
assert isinstance(get_worker('human'), HumanWorker), 'human should return HumanWorker'
print('OK')
"
    assert_equals "0" "$?" "Import and factory should work"
}
run_test "import and factory work" test_import_and_factory

test_factory_rejects_unknown() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.worker_adapter import get_worker
try:
    get_worker('unknown_type')
    print('NO_ERROR')
except ValueError:
    print('VALUE_ERROR')
" 2>/dev/null)
    assert_equals "VALUE_ERROR" "$result" "Unknown worker_type should raise ValueError"
}
run_test "factory rejects unknown worker_type" test_factory_rejects_unknown

test_execute_returns_result() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.worker_adapter import get_worker

worker = get_worker('claude')
packet = {
    'task_id': 'test-1-dev',
    'task_type': 'dev',
    'worker_type': 'claude',
    'goal': 'Test task',
}
result = worker.execute(packet)
assert isinstance(result, dict), 'result should be dict'
assert 'status' in result, 'result should have status'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "execute should return result dict with status"
}
run_test "execute returns result dict" test_execute_returns_result

test_validate_packet() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.worker_adapter import get_worker

worker = get_worker('codex')

# Valid packet
packet = {'task_id': 'test-1', 'task_type': 'dev', 'worker_type': 'codex', 'goal': 'Test'}
assert worker.validate_packet(packet) is True, 'valid packet should pass'

# Invalid packet (missing required fields)
try:
    worker.validate_packet({})
    print('NO_ERROR')
except ValueError:
    print('VALUE_ERROR')
" 2>/dev/null)
    assert_equals "VALUE_ERROR" "$result" "validate_packet should reject incomplete packets"
}
run_test "validate_packet checks required fields" test_validate_packet

# ──────────────────────────────────────────────
describe "Worker adapter — worker_type matching"

test_worker_type_mismatch() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.worker_adapter import get_worker

worker = get_worker('claude')
packet = {'task_id': 'test-1', 'task_type': 'dev', 'worker_type': 'codex', 'goal': 'Test'}
try:
    worker.execute(packet)
    print('NO_ERROR')
except ValueError:
    print('VALUE_ERROR')
" 2>/dev/null)
    assert_equals "VALUE_ERROR" "$result" \
        "execute should reject packet with mismatched worker_type"
}
run_test "worker_type mismatch rejected" test_worker_type_mismatch

# ──────────────────────────────────────────────
print_summary
