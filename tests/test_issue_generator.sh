#!/bin/bash

# VibeFlow Test: v5 — Issue Auto-Generation (Issue #59)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Issue Generator — module exists"

test_generator_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/issue_generator.py" \
        "core/runtime/issue_generator.py must exist"
}
run_test "issue_generator.py exists" test_generator_exists

# ──────────────────────────────────────────────
describe "Issue Generator — interface"

test_has_generate_issues() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/issue_generator.py" \
        "def generate_issues" "Should have generate_issues function"
}
run_test "has generate_issues function" test_has_generate_issues

test_has_format_issue() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/issue_generator.py" \
        "def format_issue" "Should have format_issue function"
}
run_test "has format_issue function" test_has_format_issue

# ──────────────────────────────────────────────
describe "Issue Generator — plan parsing"

test_parse_plan_items() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.issue_generator import generate_issues

plan = '''
## Milestone 1: Authentication
- [ ] Implement login page
- [ ] Add JWT token handling
- [ ] Password reset flow

## Milestone 2: Dashboard
- [ ] Create dashboard layout
- [ ] Add analytics chart
'''
issues = generate_issues(plan)
assert len(issues) >= 4, f'Should generate at least 4 issues, got {len(issues)}'
assert any('login' in i['title'].lower() for i in issues), 'Should have login issue'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should parse plan items into issues"
}
run_test "parses plan into issues" test_parse_plan_items

# ──────────────────────────────────────────────
describe "Issue Generator — label assignment"

test_auto_labels() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.issue_generator import generate_issues

plan = '- [ ] Implement login page'
issues = generate_issues(plan)
assert len(issues) > 0
issue = issues[0]
assert 'labels' in issue, f'Issue should have labels: {issue}'
assert any('type:' in l for l in issue['labels']), f'Should have type label: {issue[\"labels\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should auto-assign labels"
}
run_test "auto-assigns labels" test_auto_labels

# ──────────────────────────────────────────────
describe "Issue Generator — qa label"

test_qa_auto_label() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.issue_generator import generate_issues

plan = '- [ ] Add API endpoint for user stats'
issues = generate_issues(plan)
issue = issues[0]
assert any('qa:' in l for l in issue['labels']), f'Should have qa label: {issue[\"labels\"]}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should assign qa:auto or qa:manual label"
}
run_test "assigns qa label" test_qa_auto_label

# ──────────────────────────────────────────────
describe "Issue Generator — issue formatting"

test_format_issue() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.issue_generator import format_issue

issue = {
    'title': 'Implement login page',
    'body': 'Create login form with email/password',
    'labels': ['type:dev', 'qa:manual'],
    'milestone': 'Authentication'
}
formatted = format_issue(issue)
assert 'login' in formatted.lower(), f'Should contain title: {formatted}'
assert 'type:dev' in formatted or 'dev' in formatted, f'Should mention labels: {formatted}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should format issue properly"
}
run_test "formats issue for review" test_format_issue

# ──────────────────────────────────────────────
describe "Issue Generator — template integration"

test_has_template_reference() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/issue_generator.py" \
        "template\|acceptance_criteria\|acceptance" "Should reference issue template"
}
run_test "references issue template" test_has_template_reference

# ──────────────────────────────────────────────
print_summary
