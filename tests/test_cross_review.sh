#!/bin/bash

# VibeFlow Test: v5 — Cross-Review Model (Issue #63)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Cross Review — module exists"

test_module_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/cross_review.py" \
        "core/runtime/cross_review.py must exist"
}
run_test "cross_review.py exists" test_module_exists

# ──────────────────────────────────────────────
describe "Cross Review — interface"

test_has_select_reviewer() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/cross_review.py" \
        "def select_reviewer" "Should have select_reviewer function"
}
run_test "has select_reviewer function" test_has_select_reviewer

test_has_format_review_prompt() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/cross_review.py" \
        "def format_review_prompt" "Should have format_review_prompt function"
}
run_test "has format_review_prompt function" test_has_format_review_prompt

test_has_parse_review() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/cross_review.py" \
        "def parse_review" "Should have parse_review function"
}
run_test "has parse_review function" test_has_parse_review

# ──────────────────────────────────────────────
describe "Cross Review — reviewer selection"

test_codex_coded_claude_reviews() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.cross_review import select_reviewer

reviewer = select_reviewer('codex')
assert reviewer == 'claude_code', f'Codex coded → Claude Code reviews, got {reviewer}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Codex codes → Claude Code reviews"
}
run_test "codex coded → claude_code reviews" test_codex_coded_claude_reviews

test_claude_coded_codex_reviews() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.cross_review import select_reviewer

reviewer = select_reviewer('claude_code')
assert reviewer == 'codex', f'Claude Code coded → Codex reviews, got {reviewer}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Claude Code codes → Codex reviews"
}
run_test "claude_code coded → codex reviews" test_claude_coded_codex_reviews

# ──────────────────────────────────────────────
describe "Cross Review — review prompt"

test_review_prompt_has_diff() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.cross_review import format_review_prompt

prompt = format_review_prompt(
    diff='+ added line\n- removed line',
    issue_title='Add login',
    acceptance_criteria=['Login works']
)
assert 'added line' in prompt, f'Should include diff: {prompt[:200]}'
assert 'login' in prompt.lower(), f'Should include issue title: {prompt[:200]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Review prompt should include diff and issue"
}
run_test "review prompt includes diff" test_review_prompt_has_diff

# ──────────────────────────────────────────────
describe "Cross Review — review parsing"

test_parse_pass() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.cross_review import parse_review

review = '''
verdict: pass

All code looks correct. Tests are comprehensive.
'''
parsed = parse_review(review)
assert parsed['verdict'] == 'pass', f'Should parse pass: {parsed}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse pass verdict"
}
run_test "parses pass verdict" test_parse_pass

test_parse_fail() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.cross_review import parse_review

review = '''
verdict: fail

Security vulnerability found in auth handler.
'''
parsed = parse_review(review)
assert parsed['verdict'] == 'fail', f'Should parse fail: {parsed}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse fail verdict"
}
run_test "parses fail verdict" test_parse_fail

# ──────────────────────────────────────────────
describe "Cross Review — review items"

test_parse_review_items() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.cross_review import parse_review

review = '''
verdict: warn

- severity: warning
  file: src/auth.py
  message: Missing input validation
- severity: info
  file: src/utils.py
  message: Consider using constants
'''
parsed = parse_review(review)
assert parsed['verdict'] == 'warn', f'Should parse warn: {parsed}'
assert 'items' in parsed, f'Should have items: {parsed}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse review items"
}
run_test "parses review items" test_parse_review_items

# ──────────────────────────────────────────────
print_summary
