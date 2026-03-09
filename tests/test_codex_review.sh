#!/bin/bash

# VibeFlow Test: Phase 3 — Codex Review Script (Issue 3-3)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Codex review — script exists"

test_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/codex_review.sh" \
        "scripts/codex_review.sh must exist"
}
run_test "codex_review.sh exists" test_script_exists

test_script_executable() {
    [ -x "${FRAMEWORK_DIR}/scripts/codex_review.sh" ]
    assert_equals "0" "$?" "codex_review.sh should be executable"
}
run_test "codex_review.sh is executable" test_script_executable

# ──────────────────────────────────────────────
describe "Codex review — runtime module"

test_runtime_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/codex_review.py" \
        "core/runtime/codex_review.py must exist"
}
run_test "codex_review.py runtime exists" test_runtime_exists

test_runtime_has_parse() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_review.py" \
        "def parse_review" "Should have parse_review function"
}
run_test "runtime has parse_review" test_runtime_has_parse

test_runtime_has_save() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_review.py" \
        "def save_review" "Should have save_review function"
}
run_test "runtime has save_review" test_runtime_has_save

# ──────────────────────────────────────────────
describe "Codex review — usage and help"

test_shows_usage_without_args() {
    local output
    output=$(bash "${FRAMEWORK_DIR}/scripts/codex_review.sh" 2>&1 || true)
    echo "$output" > "${TEST_DIR}/usage_output.txt"
    assert_file_contains "${TEST_DIR}/usage_output.txt" "Usage" \
        "Should show usage when called without args"
}
run_test "shows usage without args" test_shows_usage_without_args

test_help_flag() {
    local output
    output=$(bash "${FRAMEWORK_DIR}/scripts/codex_review.sh" --help 2>&1 || true)
    echo "$output" > "${TEST_DIR}/help_output.txt"
    assert_file_contains "${TEST_DIR}/help_output.txt" "Usage" \
        "Should show usage with --help"
}
run_test "--help shows usage" test_help_flag

# ──────────────────────────────────────────────
describe "Codex review — VIBEFLOW_CODEX_CMD"

test_custom_codex_cmd() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/codex_review.sh" \
        "VIBEFLOW_CODEX_CMD" "Should support VIBEFLOW_CODEX_CMD env var"
}
run_test "supports VIBEFLOW_CODEX_CMD" test_custom_codex_cmd

# ──────────────────────────────────────────────
describe "Codex review — AGENTS.md integration"

test_references_agents_md() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/codex_review.sh" \
        "AGENTS.md" "Should reference AGENTS.md as instruction source"
}
run_test "references AGENTS.md" test_references_agents_md

# ──────────────────────────────────────────────
describe "Codex review — input modes"

test_accepts_pr_number() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/codex_review.sh" \
        "pr" "Should accept PR number as input"
}
run_test "accepts PR number input" test_accepts_pr_number

test_accepts_diff_file() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/codex_review.sh" \
        "diff" "Should accept diff file as input"
}
run_test "accepts diff file input" test_accepts_diff_file

# ──────────────────────────────────────────────
describe "Codex review — structured JSON output"

test_review_json_schema() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_review import parse_review, save_review
import json, tempfile, os

# Simulate raw codex output with findings
raw_output = '''
## Review Summary
Found 2 issues.

### Finding 1
- File: src/app.py
- Line: 42
- Severity: warning
- Issue: Unused import
- Suggestion: Remove the unused import

### Finding 2
- File: src/utils.py
- Line: 10
- Severity: error
- Issue: SQL injection vulnerability
- Suggestion: Use parameterized queries
'''

review = parse_review(raw_output, identifier='pr-123')
assert isinstance(review, dict), 'review should be dict'
assert 'findings' in review, 'should have findings'
assert 'summary' in review, 'should have summary'
assert 'passed' in review, 'should have passed'
assert isinstance(review['findings'], list), 'findings should be list'

# Test save
tmpdir = tempfile.mkdtemp()
path = save_review(tmpdir, review)
assert os.path.exists(path), 'saved file should exist'
with open(path) as f:
    saved = json.load(f)
assert 'findings' in saved, 'saved should have findings'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Review JSON schema should be correct"
}
run_test "review JSON has correct schema" test_review_json_schema

test_empty_review_passes() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_review import parse_review

review = parse_review('No issues found.', identifier='pr-clean')
assert review['passed'] is True, 'clean review should pass'
assert len(review['findings']) == 0, 'should have no findings'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Empty review should pass"
}
run_test "empty review passes" test_empty_review_passes

# ──────────────────────────────────────────────
describe "Codex review — mock execution"

test_mock_codex_review() {
    # Create a mock codex command that returns structured output
    local mock_dir="${TEST_DIR}/mock_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "## Review Summary"
echo "Found 1 issue."
echo ""
echo "### Finding 1"
echo "- File: src/main.py"
echo "- Line: 5"
echo "- Severity: warning"
echo "- Issue: Missing docstring"
echo "- Suggestion: Add a module docstring"
MOCK
    chmod +x "${mock_dir}/mock_codex"

    # Create a test project with diff
    local project="${TEST_DIR}/mock_project"
    mkdir -p "${project}/.vibe/reviews"
    echo "test diff content" > "${project}/test.diff"

    # Run with mock codex
    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_review.sh" \
        --diff "${project}/test.diff" \
        --output-dir "${project}/.vibe/reviews" 2>&1 || true

    # Check that review JSON was created
    local review_file
    review_file=$(ls "${project}/.vibe/reviews/"*.json 2>/dev/null | head -1)
    [ -n "$review_file" ]
    assert_equals "0" "$?" "Mock codex review should produce JSON output"
}
run_test "mock codex produces review JSON" test_mock_codex_review

test_mock_review_has_findings() {
    local review_file
    review_file=$(ls "${TEST_DIR}/mock_project/.vibe/reviews/"*.json 2>/dev/null | head -1)
    if [ -n "$review_file" ]; then
        assert_file_contains "$review_file" "findings" \
            "Review JSON should contain findings"
    else
        fail "No review JSON file found"
    fi
}
run_test "mock review JSON has findings" test_mock_review_has_findings

# ──────────────────────────────────────────────
print_summary
