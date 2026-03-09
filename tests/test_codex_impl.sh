#!/bin/bash

# VibeFlow Test: Phase 3 — Codex Implementation Script (Issue 3-4)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# Helper: create a git repo with a handoff packet
create_impl_project() {
    local dir="$1"
    mkdir -p "${dir}/.vibe/worktrees" "${dir}/src" "${dir}/tests"

    cd "$dir"
    git init -q -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > README.md
    echo "app code" > src/app.py
    echo "test code" > tests/test_app.py
    git add -A
    git commit -q -m "initial commit"
    cd - > /dev/null
}

# Helper: create a valid handoff packet JSON
create_packet() {
    local dir="$1"
    local task_id="${2:-task-42-dev}"
    cat > "${dir}/packet.json" << EOF
{
    "task_id": "${task_id}",
    "task_type": "dev",
    "source_of_truth": { "issue_number": 42, "repo": "test/repo" },
    "goal": "Implement feature X",
    "acceptance_criteria": ["Tests pass", "Lint clean"],
    "constraints": {
        "allowed_paths": ["src/**", "tests/**"],
        "forbidden_paths": ["plans/*", ".vibe/hooks/*"],
        "max_files_changed": 5
    },
    "must_read": ["README.md"],
    "validation": {
        "required_commands": ["echo ok"]
    },
    "worker_type": "codex",
    "artifacts": { "qa_report": null, "pr_number": null, "branch": null }
}
EOF
}

# ──────────────────────────────────────────────
describe "Codex impl — script exists"

test_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        "scripts/codex_impl.sh must exist"
}
run_test "codex_impl.sh exists" test_script_exists

test_script_executable() {
    [ -x "${FRAMEWORK_DIR}/scripts/codex_impl.sh" ]
    assert_equals "0" "$?" "codex_impl.sh should be executable"
}
run_test "codex_impl.sh is executable" test_script_executable

# ──────────────────────────────────────────────
describe "Codex impl — runtime module"

test_runtime_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/runtime/codex_impl.py" \
        "core/runtime/codex_impl.py must exist"
}
run_test "codex_impl.py runtime exists" test_runtime_exists

test_runtime_has_validate_diff() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_impl.py" \
        "def validate_diff" "Should have validate_diff function"
}
run_test "runtime has validate_diff" test_runtime_has_validate_diff

test_runtime_has_run_validation() {
    assert_file_contains "${FRAMEWORK_DIR}/core/runtime/codex_impl.py" \
        "def run_validation" "Should have run_validation function"
}
run_test "runtime has run_validation" test_runtime_has_run_validation

# ──────────────────────────────────────────────
describe "Codex impl — usage"

test_shows_usage_without_args() {
    local output
    output=$(bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" 2>&1 || true)
    echo "$output" > "${TEST_DIR}/usage_output.txt"
    assert_file_contains "${TEST_DIR}/usage_output.txt" "Usage" \
        "Should show usage when called without args"
}
run_test "shows usage without args" test_shows_usage_without_args

test_references_agents_md() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        "AGENTS.md" "Should reference AGENTS.md"
}
run_test "references AGENTS.md" test_references_agents_md

test_supports_codex_cmd() {
    assert_file_contains "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        "VIBEFLOW_CODEX_CMD" "Should support VIBEFLOW_CODEX_CMD"
}
run_test "supports VIBEFLOW_CODEX_CMD" test_supports_codex_cmd

# ──────────────────────────────────────────────
describe "Codex impl — packet reading"

test_reads_handoff_packet() {
    local project="${TEST_DIR}/packet_read"
    create_impl_project "$project"
    create_packet "$project"

    local result
    result=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import load_and_validate_packet

packet = load_and_validate_packet('${project}/packet.json')
assert packet['task_id'] == 'task-42-dev'
assert packet['worker_type'] == 'codex'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Should load and validate handoff packet"
}
run_test "reads handoff packet" test_reads_handoff_packet

test_rejects_non_codex_packet() {
    local project="${TEST_DIR}/non_codex"
    create_impl_project "$project"

    cat > "${project}/packet.json" << 'EOF'
{
    "task_id": "task-1-dev",
    "task_type": "dev",
    "goal": "Test",
    "worker_type": "claude",
    "constraints": { "allowed_paths": [], "forbidden_paths": [], "max_files_changed": 5 },
    "validation": { "required_commands": [] }
}
EOF

    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import load_and_validate_packet
try:
    load_and_validate_packet('${project}/packet.json')
    print('NO_ERROR')
except ValueError:
    print('VALUE_ERROR')
" 2>/dev/null)
    assert_equals "VALUE_ERROR" "$result" "Should reject non-codex worker_type"
}
run_test "rejects non-codex packet" test_rejects_non_codex_packet

# ──────────────────────────────────────────────
describe "Codex impl — branch name"

test_branch_name_generation() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import make_branch_name

name = make_branch_name('task-42-dev')
assert name.startswith('vf/'), f'branch should start with vf/: {name}'
assert '42' in name, 'branch should contain task id'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Branch name should follow vf/<task_id> pattern"
}
run_test "branch name follows pattern" test_branch_name_generation

# ──────────────────────────────────────────────
describe "Codex impl — diff validation"

test_allowed_paths_pass() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import validate_diff

changed = ['src/app.py', 'tests/test_app.py']
constraints = {
    'allowed_paths': ['src/**', 'tests/**'],
    'forbidden_paths': ['plans/*'],
    'max_files_changed': 10,
}
errors = validate_diff(changed, constraints)
assert len(errors) == 0, f'Should pass: {errors}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Files within allowed_paths should pass"
}
run_test "allowed_paths changes pass" test_allowed_paths_pass

test_forbidden_paths_rejected() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import validate_diff

changed = ['src/app.py', 'plans/roadmap.md']
constraints = {
    'allowed_paths': ['src/**', 'tests/**'],
    'forbidden_paths': ['plans/*'],
    'max_files_changed': 10,
}
errors = validate_diff(changed, constraints)
assert len(errors) > 0, 'Should have errors for forbidden path'
assert any('plans/roadmap.md' in e for e in errors), 'Should mention forbidden file'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Files in forbidden_paths should be rejected"
}
run_test "forbidden_paths changes rejected" test_forbidden_paths_rejected

test_max_files_exceeded() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import validate_diff

changed = ['src/a.py', 'src/b.py', 'src/c.py']
constraints = {
    'allowed_paths': ['src/**'],
    'forbidden_paths': [],
    'max_files_changed': 2,
}
errors = validate_diff(changed, constraints)
assert len(errors) > 0, 'Should have errors for max_files exceeded'
assert any('max_files' in e.lower() or '3' in e for e in errors), 'Should mention count'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Exceeding max_files_changed should be detected"
}
run_test "max_files_changed exceeded detected" test_max_files_exceeded

test_not_in_allowed_paths() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import validate_diff

changed = ['src/app.py', 'docs/readme.md']
constraints = {
    'allowed_paths': ['src/**'],
    'forbidden_paths': [],
    'max_files_changed': 10,
}
errors = validate_diff(changed, constraints)
assert len(errors) > 0, 'Should reject file outside allowed_paths'
assert any('docs/readme.md' in e for e in errors), 'Should mention disallowed file'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Files outside allowed_paths should be rejected"
}
run_test "files outside allowed_paths rejected" test_not_in_allowed_paths

# ──────────────────────────────────────────────
describe "Codex impl — validation commands"

test_validation_passes() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import run_validation

commands = ['echo ok', 'true']
errors = run_validation(commands, cwd='.')
assert len(errors) == 0, f'Should pass: {errors}'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Passing commands should return no errors"
}
run_test "validation commands pass" test_validation_passes

test_validation_fails() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import run_validation

commands = ['echo ok', 'false']
errors = run_validation(commands, cwd='.')
assert len(errors) > 0, 'Should have errors for failing command'
print('OK')
" 2>/dev/null)
    assert_equals "OK" "$result" "Failing command should be detected"
}
run_test "validation command failure detected" test_validation_fails

# ──────────────────────────────────────────────
describe "Codex impl — mock execution"

test_mock_codex_impl() {
    local project="${TEST_DIR}/mock_impl"
    create_impl_project "$project"
    create_packet "$project"

    # Create mock codex that modifies a file
    local mock_dir="${TEST_DIR}/mock_impl_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
# Simulate codex implementation by modifying a file in cwd
echo "modified" > src/app.py
git add -A
git commit -q -m "codex: implement feature" 2>/dev/null || true
MOCK
    chmod +x "${mock_dir}/mock_codex"

    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" 2>&1 || true

    # Branch should have been created (even if impl failed partially)
    local branches
    branches=$(cd "$project" && git branch --list "vf/*" 2>/dev/null)
    [ -n "$branches" ]
    assert_equals "0" "$?" "Should create a vf/ branch"
}
run_test "mock codex creates branch" test_mock_codex_impl

test_no_auto_merge() {
    # Self-contained: create project, run mock codex, verify main untouched
    local project="${TEST_DIR}/no_merge_impl"
    create_impl_project "$project"
    create_packet "$project"

    local mock_dir="${TEST_DIR}/mock_nomerge_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "modified" > src/app.py
git add -A
git commit -q -m "codex: implement feature" 2>/dev/null || true
MOCK
    chmod +x "${mock_dir}/mock_codex"

    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" 2>&1 || true

    local main_content
    main_content=$(cd "$project" && git show main:src/app.py 2>/dev/null || echo "")
    assert_equals "app code" "$main_content" "Main branch should not be modified (no auto-merge)"
}
run_test "no auto-merge to main" test_no_auto_merge

# ──────────────────────────────────────────────
describe "Codex impl — AGENTS.md"

test_agents_md_used() {
    local project="${TEST_DIR}/agents_impl"
    create_impl_project "$project"
    create_packet "$project"
    echo "AGENTS_MARKER" > "${project}/AGENTS.md"

    local mock_dir="${TEST_DIR}/mock_agents_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "no-op"
MOCK
    chmod +x "${mock_dir}/mock_codex"

    local output
    output=$(VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" 2>&1 || true)

    echo "$output" > "${TEST_DIR}/agents_impl_output.txt"
    assert_file_contains "${TEST_DIR}/agents_impl_output.txt" "instruction layer" \
        "Should use AGENTS.md as instruction layer"
}
run_test "AGENTS.md used as instruction layer" test_agents_md_used

test_no_agents_md_fallback() {
    local project="${TEST_DIR}/no_agents_impl"
    create_impl_project "$project"
    create_packet "$project"
    # No AGENTS.md

    local mock_dir="${TEST_DIR}/mock_noagents_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "no-op"
MOCK
    chmod +x "${mock_dir}/mock_codex"

    local fake_fw="${TEST_DIR}/fake_fw_impl"
    mkdir -p "${fake_fw}/examples"
    ln -sf "${FRAMEWORK_DIR}/core" "${fake_fw}/core"

    local output
    output=$(VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$fake_fw" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" 2>&1 || true)

    echo "$output" > "${TEST_DIR}/noagents_impl_output.txt"
    assert_file_contains "${TEST_DIR}/noagents_impl_output.txt" "no instruction layer" \
        "Should fallback when no AGENTS.md"
}
run_test "fallback when no AGENTS.md" test_no_agents_md_fallback

# ──────────────────────────────────────────────
describe "Codex impl — failure exits"

test_codex_failure_exits_nonzero() {
    local project="${TEST_DIR}/fail_codex"
    create_impl_project "$project"
    create_packet "$project"

    local mock_dir="${TEST_DIR}/mock_fail_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
exit 1
MOCK
    chmod +x "${mock_dir}/mock_codex"

    local exit_code=0
    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" >/dev/null 2>&1 || exit_code=$?

    [ "$exit_code" -ne 0 ]
    assert_equals "0" "$?" "Codex failure should cause non-zero exit"
}
run_test "codex failure exits non-zero" test_codex_failure_exits_nonzero

test_diff_validation_failure_exits_nonzero() {
    local project="${TEST_DIR}/fail_diff"
    create_impl_project "$project"

    # Packet with restrictive allowed_paths
    cat > "${project}/packet.json" << 'EOF'
{
    "task_id": "task-diff-fail",
    "task_type": "dev",
    "goal": "Test",
    "worker_type": "codex",
    "constraints": {
        "allowed_paths": ["src/**"],
        "forbidden_paths": [],
        "max_files_changed": 5
    },
    "validation": { "required_commands": [] }
}
EOF

    local mock_dir="${TEST_DIR}/mock_difffail_bin"
    mkdir -p "$mock_dir"
    # Mock codex that modifies a file OUTSIDE allowed_paths
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "bad change" > docs_forbidden.txt
git add -A
git commit -q -m "bad change" 2>/dev/null || true
MOCK
    chmod +x "${mock_dir}/mock_codex"

    local exit_code=0
    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" >/dev/null 2>&1 || exit_code=$?

    [ "$exit_code" -ne 0 ]
    assert_equals "0" "$?" "Diff validation failure should cause non-zero exit"
}
run_test "diff validation failure exits non-zero" test_diff_validation_failure_exits_nonzero

test_validation_cmd_failure_exits_nonzero() {
    local project="${TEST_DIR}/fail_valcmd"
    create_impl_project "$project"

    cat > "${project}/packet.json" << 'EOF'
{
    "task_id": "task-valcmd-fail",
    "task_type": "dev",
    "goal": "Test",
    "worker_type": "codex",
    "constraints": {
        "allowed_paths": ["src/**"],
        "forbidden_paths": [],
        "max_files_changed": 5
    },
    "validation": { "required_commands": ["false"] }
}
EOF

    local mock_dir="${TEST_DIR}/mock_valcmdfail_bin"
    mkdir -p "$mock_dir"
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "modified" > src/app.py
git add -A
git commit -q -m "change" 2>/dev/null || true
MOCK
    chmod +x "${mock_dir}/mock_codex"

    local exit_code=0
    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" >/dev/null 2>&1 || exit_code=$?

    [ "$exit_code" -ne 0 ]
    assert_equals "0" "$?" "Validation command failure should cause non-zero exit"
}
run_test "validation command failure exits non-zero" test_validation_cmd_failure_exits_nonzero

# ──────────────────────────────────────────────
describe "Codex impl — uncommitted changes detection"

test_uncommitted_changes_detected() {
    local project="${TEST_DIR}/uncommit_detect"
    create_impl_project "$project"

    cat > "${project}/packet.json" << 'EOF'
{
    "task_id": "task-uncommit",
    "task_type": "dev",
    "goal": "Test",
    "worker_type": "codex",
    "constraints": {
        "allowed_paths": ["src/**"],
        "forbidden_paths": ["plans/*"],
        "max_files_changed": 5
    },
    "validation": { "required_commands": ["echo ok"] }
}
EOF

    local mock_dir="${TEST_DIR}/mock_uncommit_bin"
    mkdir -p "$mock_dir"
    # Mock codex that modifies files but does NOT commit
    cat > "${mock_dir}/mock_codex" << 'MOCK'
#!/bin/bash
echo "modified but not committed" > src/app.py
mkdir -p plans
echo "forbidden" > plans/roadmap.md
MOCK
    chmod +x "${mock_dir}/mock_codex"

    local exit_code=0
    VIBEFLOW_CODEX_CMD="${mock_dir}/mock_codex" \
    VIBEFLOW_PROJECT_DIR="$project" \
    VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR" \
    bash "${FRAMEWORK_DIR}/scripts/codex_impl.sh" \
        --packet "${project}/packet.json" >/dev/null 2>&1 || exit_code=$?

    [ "$exit_code" -ne 0 ]
    assert_equals "0" "$?" "Uncommitted forbidden changes should be detected and fail"
}
run_test "uncommitted changes detected in validation" test_uncommitted_changes_detected

# ──────────────────────────────────────────────
print_summary
