#!/bin/bash

# VibeFlow Test: v5 — Result Collection & Reporting (Issue #57)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Result Collector — module exists"

test_collector_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/result_collector.py" \
        "core/runtime/result_collector.py must exist"
}
run_test "result_collector.py exists" test_collector_exists

# ──────────────────────────────────────────────
describe "Result Collector — interface"

test_has_collect_results() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/result_collector.py" \
        "def collect_results" "Should have collect_results function"
}
run_test "has collect_results function" test_has_collect_results

test_has_format_report() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/result_collector.py" \
        "def format_report" "Should have format_report function"
}
run_test "has format_report function" test_has_format_report

# ──────────────────────────────────────────────
describe "Result Collector — Codex JSONL parsing"

test_parse_codex_success() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import collect_results

codex_output = {
    'agent': 'codex',
    'raw_output': '{\"type\": \"result\", \"status\": \"success\", \"summary\": \"Done\"}',
    'exit_code': 0
}
result = collect_results(codex_output)
assert result['status'] == 'success', f'Expected success: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse successful Codex output"
}
run_test "parses Codex success output" test_parse_codex_success

test_parse_codex_failure() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import collect_results

codex_output = {
    'agent': 'codex',
    'raw_output': '{\"type\": \"error\", \"message\": \"Build failed\"}',
    'exit_code': 1
}
result = collect_results(codex_output)
assert result['status'] == 'failed', f'Expected failed: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should detect Codex failure"
}
run_test "detects Codex failure output" test_parse_codex_failure

# ──────────────────────────────────────────────
describe "Result Collector — Claude Code JSON parsing"

test_parse_claude_success() {
    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import collect_results

claude_output = {
    'agent': 'claude_code',
    'raw_output': json.dumps({
        'type': 'result',
        'subtype': 'success',
        'result': 'Task completed',
        'cost_usd': 0.03
    }),
    'exit_code': 0
}
result = collect_results(claude_output)
assert result['status'] == 'success', f'Expected success: {result}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse successful Claude Code output"
}
run_test "parses Claude Code success output" test_parse_claude_success

# ──────────────────────────────────────────────
describe "Result Collector — report formatting"

test_format_report_summary() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import format_report

report = format_report({
    'status': 'success',
    'agent': 'codex',
    'summary': 'Implemented feature',
    'files_changed': ['src/app.py', 'tests/test_app.py'],
    'tests_passed': True
})
assert 'success' in report.lower() or '✅' in report, f'Report should indicate success: {report}'
assert 'src/app.py' in report, f'Report should list files: {report}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Report should include status and files"
}
run_test "formats report with status and files" test_format_report_summary

# ──────────────────────────────────────────────
describe "Result Collector — PR detection"

test_has_detect_pr() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/result_collector.py" \
        "detect_pr\|pr_number\|pull_request" "Should support PR detection"
}
run_test "supports PR detection" test_has_detect_pr

# ──────────────────────────────────────────────
describe "Result Collector — test results"

test_has_test_results() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/result_collector.py" \
        "test_results\|tests_passed\|test_status" "Should collect test results"
}
run_test "collects test results" test_has_test_results

# ──────────────────────────────────────────────
describe "Result Collector — fail-closed parsing"

test_claude_non_json_is_not_success() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import collect_results

out = collect_results({
    'agent': 'claude_code',
    'raw_output': 'Error: something went wrong before any JSON was emitted',
    'exit_code': 0,
})
assert out['status'] == 'unparsed', f\"non-JSON must be 'unparsed', got: {out['status']}\"
print('OK')
")
    assert_equals "OK" "$result" "claude_code non-JSON output must be status='unparsed'"
}
run_test "claude_code non-JSON output is unparsed, not success" test_claude_non_json_is_not_success

test_codex_garbage_is_not_success() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import collect_results

out = collect_results({
    'agent': 'codex',
    'raw_output': 'total garbage\nnot a single json line',
    'exit_code': 0,
})
assert out['status'] == 'unparsed', f\"garbage JSONL must be 'unparsed', got: {out['status']}\"
print('OK')
")
    assert_equals "OK" "$result" "codex unparseable JSONL must be status='unparsed'"
}
run_test "codex unparseable JSONL is unparsed, not success" test_codex_garbage_is_not_success

test_codex_result_without_status_is_not_success() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.result_collector import collect_results

out = collect_results({
    'agent': 'codex',
    'raw_output': '{\"type\": \"result\", \"summary\": \"did something\"}',
    'exit_code': 0,
})
assert out['status'] == 'unparsed', f\"result entry without status must be 'unparsed', got: {out['status']}\"
print('OK')
")
    assert_equals "OK" "$result" "codex result entry without status must not default to success"
}
run_test "codex result entry without status is unparsed" test_codex_result_without_status_is_not_success

# ──────────────────────────────────────────────
print_summary
