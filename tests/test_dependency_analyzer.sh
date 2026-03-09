#!/bin/bash

# VibeFlow Test: v5 — Dependency Analysis (Issue #61)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Dependency Analyzer — module exists"

test_analyzer_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/dependency_analyzer.py" \
        "core/runtime/dependency_analyzer.py must exist"
}
run_test "dependency_analyzer.py exists" test_analyzer_exists

# ──────────────────────────────────────────────
describe "Dependency Analyzer — interface"

test_has_analyze() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dependency_analyzer.py" \
        "def analyze" "Should have analyze function"
}
run_test "has analyze function" test_has_analyze

test_has_execution_order() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/dependency_analyzer.py" \
        "def execution_order" "Should have execution_order function"
}
run_test "has execution_order function" test_has_execution_order

# ──────────────────────────────────────────────
describe "Dependency Analyzer — independent issues"

test_independent_parallel() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dependency_analyzer import analyze

issues = [
    {'number': 1, 'title': 'Add login', 'body': ''},
    {'number': 2, 'title': 'Add signup', 'body': ''},
]
result = analyze(issues)
# Both should be in the first batch (parallelizable)
assert len(result['batches']) >= 1, f'Should have batches: {result}'
assert len(result['batches'][0]) == 2, f'Independent issues should be in same batch: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Independent issues should be parallelizable"
}
run_test "independent issues are parallel" test_independent_parallel

# ──────────────────────────────────────────────
describe "Dependency Analyzer — dependency detection"

test_detects_dependency() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dependency_analyzer import analyze

issues = [
    {'number': 1, 'title': 'Create user model', 'body': ''},
    {'number': 2, 'title': 'Add login using user model', 'body': 'Depends on #1'},
]
result = analyze(issues)
assert len(result['batches']) >= 2, f'Dependent issues should be in separate batches: {result}'
assert 1 in result['batches'][0], f'Issue 1 should be first: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should detect dependencies from body"
}
run_test "detects dependency from body" test_detects_dependency

# ──────────────────────────────────────────────
describe "Dependency Analyzer — execution order"

test_execution_order() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dependency_analyzer import execution_order

issues = [
    {'number': 3, 'title': 'Deploy', 'body': 'Depends on #1 and #2'},
    {'number': 1, 'title': 'Backend', 'body': ''},
    {'number': 2, 'title': 'Frontend', 'body': ''},
]
order = execution_order(issues)
assert len(order) == 3, f'Should include all issues: {order}'
# Issues 1 and 2 should come before 3
idx1 = next(i for i, o in enumerate(order) if o['number'] == 1)
idx2 = next(i for i, o in enumerate(order) if o['number'] == 2)
idx3 = next(i for i, o in enumerate(order) if o['number'] == 3)
assert idx3 > idx1 and idx3 > idx2, f'Issue 3 should come after 1 and 2: {order}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Execution order should respect dependencies"
}
run_test "execution order respects dependencies" test_execution_order

# ──────────────────────────────────────────────
describe "Dependency Analyzer — cycle detection"

test_cycle_detection() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.dependency_analyzer import analyze

issues = [
    {'number': 1, 'title': 'A', 'body': 'Depends on #2'},
    {'number': 2, 'title': 'B', 'body': 'Depends on #1'},
]
result = analyze(issues)
assert 'warnings' in result or 'cycles' in result, f'Should detect cycle: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should detect circular dependencies"
}
run_test "detects circular dependencies" test_cycle_detection

# ──────────────────────────────────────────────
print_summary
