#!/bin/bash

# VibeFlow Test: Phase 1.5 — Baseline hash DB (Issue 1.5-3)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Baseline — files exist"

test_baseline_json_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/baselines/v3.5.0.json" \
        "core/baselines/v3.5.0.json must exist"
}
run_test "v3.5.0.json exists" test_baseline_json_exists

test_baseline_loader_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/baselines/loader.py" \
        "core/baselines/loader.py must exist"
}
run_test "loader.py exists" test_baseline_loader_exists

# ──────────────────────────────────────────────
describe "Baseline — JSON structure"

test_baseline_has_version() {
    assert_file_contains "${FRAMEWORK_DIR}/core/baselines/v3.5.0.json" '"version"' \
        "Should have version field"
    assert_file_contains "${FRAMEWORK_DIR}/core/baselines/v3.5.0.json" '"3.5.0"' \
        "Should have version 3.5.0"
}
run_test "Baseline has version field" test_baseline_has_version

test_baseline_has_files() {
    assert_file_contains "${FRAMEWORK_DIR}/core/baselines/v3.5.0.json" '"files"' \
        "Should have files field"
}
run_test "Baseline has files field" test_baseline_has_files

test_baseline_has_key_files() {
    local baseline="${FRAMEWORK_DIR}/core/baselines/v3.5.0.json"

    assert_file_contains "$baseline" '".vibe/hooks/validate_access.py"' \
        "Should have validate_access.py"
    assert_file_contains "$baseline" '".vibe/hooks/validate_write.sh"' \
        "Should have validate_write.sh"
    assert_file_contains "$baseline" '".vibe/policy.yaml"' \
        "Should have policy.yaml"
    assert_file_contains "$baseline" '".claude/settings.json"' \
        "Should have settings.json"
    assert_file_contains "$baseline" '".vibe/roles/iris.md"' \
        "Should have iris.md role"
}
run_test "Baseline has key managed files" test_baseline_has_key_files

test_baseline_entries_have_sha256() {
    local has_sha
    has_sha=$(python3 -c "
import json
with open('${FRAMEWORK_DIR}/core/baselines/v3.5.0.json') as f:
    data = json.load(f)
files = data['files']
# Check all entries have sha256
for path, entry in files.items():
    if 'sha256' not in entry:
        print(f'MISSING: {path}')
        exit(1)
print('OK')
")
    assert_equals "OK" "$has_sha" "All entries should have sha256"
}
run_test "All baseline entries have sha256" test_baseline_entries_have_sha256

# ──────────────────────────────────────────────
describe "Baseline — classification logic"

test_classify_stock_managed() {
    # Create a project with a file matching baseline hash
    local project="${TEST_DIR}/project"
    mkdir -p "${project}/.vibe/hooks"

    # Copy a stock file whose hash still matches v3.5.0 baseline
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_write.sh" \
       "${project}/.vibe/hooks/validate_write.sh"

    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.baselines.loader import classify_file
result = classify_file('${project}', '.vibe/hooks/validate_write.sh', '3.5.0',
                       baselines_dir='${FRAMEWORK_DIR}/core/baselines')
print(result)
")
    assert_equals "stock-managed" "$result" "Unmodified stock file should be stock-managed"
}
run_test "Classifies unmodified stock file as stock-managed" test_classify_stock_managed

test_classify_customized() {
    local project="${TEST_DIR}/project"
    mkdir -p "${project}/.vibe/hooks"

    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" \
       "${project}/.vibe/hooks/validate_access.py"
    echo "# user customization" >> "${project}/.vibe/hooks/validate_access.py"

    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.baselines.loader import classify_file
result = classify_file('${project}', '.vibe/hooks/validate_access.py', '3.5.0',
                       baselines_dir='${FRAMEWORK_DIR}/core/baselines')
print(result)
")
    assert_equals "customized" "$result" "Modified stock file should be customized"
}
run_test "Classifies modified stock file as customized" test_classify_customized

test_classify_unknown() {
    local project="${TEST_DIR}/project"
    mkdir -p "${project}/.vibe"

    echo "# unknown file" > "${project}/.vibe/custom_script.py"

    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.baselines.loader import classify_file
result = classify_file('${project}', '.vibe/custom_script.py', '3.5.0',
                       baselines_dir='${FRAMEWORK_DIR}/core/baselines')
print(result)
")
    assert_equals "unknown" "$result" "Unknown file should be classified as unknown"
}
run_test "Classifies unknown file as unknown" test_classify_unknown

test_classify_all_project_files() {
    # Create a project simulating v3.5 setup output
    local project="${TEST_DIR}/project"
    mkdir -p "${project}/.vibe/hooks" "${project}/.vibe/roles" "${project}/.claude/commands"

    # Copy stock files (use files whose hashes still match v3.5.0 baseline)
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_write.sh" "${project}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py" "${project}/.vibe/hooks/"
    cp "${FRAMEWORK_DIR}/examples/.vibe/hooks/waiting_input.sh" "${project}/.vibe/hooks/"
    # Modify one
    echo "# custom" >> "${project}/.vibe/hooks/validate_write.sh"
    # Add unknown
    echo "# my notes" > "${project}/.vibe/notes.md"

    local output
    output=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.baselines.loader import classify_project
results = classify_project('${project}', '3.5.0',
                           baselines_dir='${FRAMEWORK_DIR}/core/baselines')
for path, status in sorted(results.items()):
    print(f'{status}: {path}')
")

    echo "$output" > "${TEST_DIR}/classify_output.txt"

    assert_file_contains "${TEST_DIR}/classify_output.txt" "stock-managed: .vibe/hooks/validate_step7a.py" \
        "validate_step7a.py should be stock-managed"
    assert_file_contains "${TEST_DIR}/classify_output.txt" "customized: .vibe/hooks/validate_write.sh" \
        "Modified validate_write.sh should be customized"
}
run_test "classify_project classifies multiple files" test_classify_all_project_files

# ──────────────────────────────────────────────
describe "Baseline — hash accuracy"

test_baseline_hashes_match_source() {
    # Verify baseline hashes match actual source files (using files unchanged since v3.5.0)
    local result
    result=$(python3 -c "
import hashlib, json
with open('${FRAMEWORK_DIR}/core/baselines/v3.5.0.json') as f:
    baseline = json.load(f)

# Check validate_write.sh (unchanged since v3.5.0)
with open('${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_write.sh', 'rb') as f:
    actual = hashlib.sha256(f.read()).hexdigest()
recorded = baseline['files']['.vibe/hooks/validate_write.sh']['sha256']
if actual != recorded:
    print(f'MISMATCH: validate_write.sh actual={actual[:16]} recorded={recorded[:16]}')
    exit(1)

# Check validate_step7a.py (unchanged since v3.5.0)
with open('${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py', 'rb') as f:
    actual = hashlib.sha256(f.read()).hexdigest()
recorded = baseline['files']['.vibe/hooks/validate_step7a.py']['sha256']
if actual != recorded:
    print(f'MISMATCH: validate_step7a.py actual={actual[:16]} recorded={recorded[:16]}')
    exit(1)

print('OK')
")
    assert_equals "OK" "$result" "Baseline hashes should match source files"
}
run_test "Baseline hashes match source files" test_baseline_hashes_match_source

# ──────────────────────────────────────────────
print_summary
