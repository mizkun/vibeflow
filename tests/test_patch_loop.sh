#!/bin/bash

# VibeFlow Test: Phase 2 — Patch Loop Runtime (Issue 2-3)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Patch Loop — module exists"

test_patch_loop_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/patch_loop.py" \
        "core/runtime/patch_loop.py must exist"
}
run_test "patch_loop.py exists" test_patch_loop_exists

# ──────────────────────────────────────────────
describe "Patch Loop — create (normal)"

test_create_patch_with_parent_issue() {
    local tmpdir="${TEST_DIR}/pl_test"
    mkdir -p "${tmpdir}/.vibe"

    # Initialize project state
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {
    'active_issue': 42,
    'current_phase': 'development',
    'patch_runs': [],
})
"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=42,
    description='Fix button color',
    target_files=['src/button.css'],
    target_tests=['tests/test_button.py'],
)
print(json.dumps(patch))
")

    # Verify patch_id is generated
    local patch_id
    patch_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['patch_id'])")
    [ -n "$patch_id" ] || { fail "patch_id should not be empty"; return 1; }

    # Verify status
    local status
    status=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
    assert_equals "in_progress" "$status" "Initial status should be in_progress"

    # Verify parent_issue
    local parent
    parent=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['parent_issue'])")
    assert_equals "42" "$parent" "parent_issue should be 42"
}
run_test "creates patch with parent issue" test_create_patch_with_parent_issue

test_create_patch_without_parent_pr() {
    local tmpdir="${TEST_DIR}/pl_test2"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=10,
    description='Fix typo',
    target_files=['README.md'],
)
print(json.dumps(patch))
")

    # parent_pr should be None/null
    local parent_pr
    parent_pr=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('parent_pr'))")
    assert_equals "None" "$parent_pr" "parent_pr should be None when not specified"
}
run_test "creates patch without parent PR" test_create_patch_without_parent_pr

test_patch_recorded_in_project_state() {
    local tmpdir="${TEST_DIR}/pl_record"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

create_patch(
    project_dir='${tmpdir}',
    parent_issue=42,
    description='Fix button color',
    target_files=['src/button.css'],
)
"

    # Read project_state and check patch_runs
    local count
    count=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import read_project_state
ps = read_project_state('${tmpdir}')
print(len(ps.get('patch_runs', [])))
")
    assert_equals "1" "$count" "patch_runs should have 1 entry"
}
run_test "patch recorded in project_state.yaml" test_patch_recorded_in_project_state

# ──────────────────────────────────────────────
describe "Patch Loop — reject (no parent issue)"

test_reject_no_parent_issue() {
    local tmpdir="${TEST_DIR}/pl_reject"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    set +e
    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

try:
    create_patch(
        project_dir='${tmpdir}',
        parent_issue=None,
        description='standalone fix',
        target_files=['src/foo.py'],
    )
    print('ERROR: should have raised')
    sys.exit(1)
except ValueError as e:
    if 'parent' in str(e).lower():
        print('OK')
    else:
        print(f'Wrong error: {e}')
        sys.exit(1)
" 2>&1
    local code=$?
    set -e

    local output
    output=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch
try:
    create_patch(project_dir='${tmpdir}', parent_issue=None, description='x', target_files=['y'])
    print('ERROR')
except ValueError:
    print('OK')
")
    assert_equals "OK" "$output" "Should raise ValueError when parent_issue is None"
}
run_test "rejects patch without parent issue" test_reject_no_parent_issue

# ──────────────────────────────────────────────
describe "Patch Loop — escalation"

test_escalate_file_limit() {
    local tmpdir="${TEST_DIR}/pl_escalate"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch, DEFAULT_FILE_LIMIT

# Create a patch exceeding file limit
many_files = [f'src/file{i}.py' for i in range(DEFAULT_FILE_LIMIT + 5)]
patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=10,
    description='big fix',
    target_files=many_files,
)
print(json.dumps(patch))
")

    local status
    status=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
    assert_equals "escalated" "$status" "Should be escalated when exceeding file limit"

    local escalation
    escalation=$(echo "$result" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r.get('escalation_reason', ''))")
    [ -n "$escalation" ] || { fail "Should have escalation_reason"; return 1; }
}
run_test "escalates when file count exceeds limit" test_escalate_file_limit

# ──────────────────────────────────────────────
describe "Patch Loop — complete / status update"

test_complete_patch() {
    local tmpdir="${TEST_DIR}/pl_complete"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch, complete_patch

patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=42,
    description='Fix CSS',
    target_files=['src/style.css'],
)
patch_id = patch['patch_id']

updated = complete_patch('${tmpdir}', patch_id)
print(json.dumps(updated))
")

    local status
    status=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
    assert_equals "completed" "$status" "Completed patch should have status=completed"
}
run_test "completes a patch" test_complete_patch

# ──────────────────────────────────────────────
describe "Patch Loop — patch_id format"

test_patch_id_contains_parent() {
    local tmpdir="${TEST_DIR}/pl_id"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    local patch_id
    patch_id=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=77,
    description='Fix bug',
    target_files=['src/foo.py'],
)
print(patch['patch_id'])
")

    echo "$patch_id" | grep -q "77" || { fail "patch_id should contain parent issue number"; return 1; }
}
run_test "patch_id contains parent issue number" test_patch_id_contains_parent

# ──────────────────────────────────────────────
describe "Patch Loop — target files and tests"

test_patch_stores_targets() {
    local tmpdir="${TEST_DIR}/pl_targets"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=10,
    description='Fix test',
    target_files=['src/a.py', 'src/b.py'],
    target_tests=['tests/test_a.py'],
)
print(json.dumps(patch))
")

    local file_count
    file_count=$(echo "$result" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['target_files']))")
    assert_equals "2" "$file_count" "Should have 2 target files"

    local test_count
    test_count=$(echo "$result" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['target_tests']))")
    assert_equals "1" "$test_count" "Should have 1 target test"
}
run_test "patch stores target files and tests" test_patch_stores_targets

# ──────────────────────────────────────────────
describe "Patch Loop — parent PR (optional)"

test_patch_with_parent_pr() {
    local tmpdir="${TEST_DIR}/pl_pr"
    mkdir -p "${tmpdir}/.vibe"

    python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.state import write_project_state
write_project_state('${tmpdir}', {'patch_runs': []})
"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.patch_loop import create_patch

patch = create_patch(
    project_dir='${tmpdir}',
    parent_issue=42,
    parent_pr=30,
    description='Fix review feedback',
    target_files=['src/foo.py'],
)
print(json.dumps(patch))
")

    local parent_pr
    parent_pr=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['parent_pr'])")
    assert_equals "30" "$parent_pr" "parent_pr should be 30"
}
run_test "patch with parent PR" test_patch_with_parent_pr

# ──────────────────────────────────────────────
print_summary
