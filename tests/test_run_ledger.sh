#!/bin/bash

# Tests for core/runtime/run_ledger.py — the append-only audit log a PO
# needs to verify an overnight/long-running loop after the fact. runtime
# had no logging at all; the conversation summary vanishes on compaction.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

RL="${FRAMEWORK_DIR}/core/runtime/run_ledger.py"

py() {
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime import run_ledger as rl
$1
"
}

test_module_exists() {
    assert_file_exists "$RL" "core/runtime/run_ledger.py must exist"
}
run_test "run_ledger.py exists" test_module_exists

test_append_creates_jsonl() {
    py "rl.append_event('${TEST_DIR}', issue=42, step='5_implementation', attempt=1, verdict='pass', evidence_paths=['.vibe/reports/42/test.log'], duration=12.3)"
    local f
    f=$(ls "${TEST_DIR}"/.vibe/runs/*.jsonl 2>/dev/null | head -1)
    [ -n "$f" ] || { fail "append_event must create .vibe/runs/<date>.jsonl"; return 1; }
    grep -q '"issue": 42' "$f" || { fail "the event must record the issue"; return 1; }
    grep -q '"verdict": "pass"' "$f" || { fail "the event must record the verdict"; return 1; }
    return 0
}
run_test "append_event writes a jsonl event" test_append_creates_jsonl

test_append_is_one_line_per_event() {
    py "
rl.append_event('${TEST_DIR}', issue=7, step='4_test_writing', attempt=1, verdict='fail')
rl.append_event('${TEST_DIR}', issue=7, step='5_implementation', attempt=2, verdict='pass')
"
    local f
    f=$(ls "${TEST_DIR}"/.vibe/runs/*.jsonl | head -1)
    local n
    n=$(wc -l < "$f" | tr -d ' ')
    assert_equals "2" "$n" "each event must be exactly one JSON line"
}
run_test "events are one JSON line each" test_append_is_one_line_per_event

test_persists_across_processes() {
    py "rl.append_event('${TEST_DIR}', issue=8, step='4', attempt=1, verdict='fail')"
    py "rl.append_event('${TEST_DIR}', issue=8, step='5', attempt=2, verdict='pass')"
    local out
    out=$(py "print(len(rl.read_events('${TEST_DIR}')))")
    assert_equals "2" "$out" "events appended by separate processes must accumulate"
}
run_test "events persist across processes" test_persists_across_processes

test_summarize_issue() {
    py "
rl.append_event('${TEST_DIR}', issue=9, step='5', attempt=1, verdict='fail')
rl.append_event('${TEST_DIR}', issue=9, step='5', attempt=2, verdict='fail')
rl.append_event('${TEST_DIR}', issue=9, step='7', attempt=3, verdict='pass')
"
    local out
    out=$(py "s = rl.summarize('${TEST_DIR}', issue=9); print(s['attempts'], s['final_verdict'])")
    assert_equals "3 pass" "$out" "summarize must report attempts and the final verdict for an issue"
}
run_test "summarize reports attempts and final verdict" test_summarize_issue

test_policy_allows_runs() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/policy.yaml" \
        ".vibe/runs" "coding_agent must be allowed to write the run ledger"
}
run_test "policy allows .vibe/runs/ writes" test_policy_allows_runs

test_healthcheck_checks_ledger() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-healthcheck/SKILL.md" \
        "ledger\|台帳\|runs/" "healthcheck must warn when a closed issue has no ledger entry"
}
run_test "healthcheck checks the run ledger" test_healthcheck_checks_ledger

print_summary
