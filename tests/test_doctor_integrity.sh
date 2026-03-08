#!/bin/bash

# VibeFlow Test: Issue 0-5 — Doctor コマンド整合性チェック
# doctor が環境チェックだけでなく、真実源の整合性もチェックすること。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
# Helper: create a valid v3.5 project structure
# ──────────────────────────────────────────────

create_v35_project() {
    local dir="${1:-$TEST_DIR}"
    cd "$dir"

    # Run actual setup in a subshell to create valid structure
    mkdir -p .vibe/hooks .vibe/roles .vibe/context .vibe/references .vibe/archive
    mkdir -p .vibe/scripts .vibe/checkpoints .vibe/templates
    mkdir -p .claude/commands .claude/agents .claude/skills

    # Version
    echo "3.5.0" > .vibe/version

    # State
    cat > .vibe/state.yaml << 'YAML'
current_issue: null
current_role: "Iris"
current_step: null
phase: development
issues_recent: []
quickfix:
  active: false
  description: null
  started: null
discovery:
  active: false
  last_session: null
safety:
  ui_mode: atomic
  destructive_op: require_confirmation
  max_fix_attempts: 3
  failed_approach_log: []
infra_log:
  hook_changes: []
  rollback_pending: false
YAML

    # Policy
    cat > .vibe/policy.yaml << 'YAML'
roles:
  iris:
    can_read: ["vision.md"]
    can_write: [".vibe/state.yaml"]
  product_manager:
    can_read: ["vision.md"]
    can_write: ["plan.md"]
  engineer:
    can_read: ["spec.md"]
    can_write: ["src/**"]
  qa_engineer:
    can_read: ["spec.md"]
    can_write: [".vibe/qa-reports/**"]
  infra_manager:
    can_read: [".vibe/hooks/**"]
    can_write: [".vibe/hooks/**"]
YAML

    # Hook files
    echo '#!/usr/bin/env python3' > .vibe/hooks/validate_access.py
    echo '#!/bin/bash' > .vibe/hooks/validate_write.sh
    echo '#!/usr/bin/env python3' > .vibe/hooks/validate_step7a.py
    echo '#!/bin/bash' > .vibe/hooks/checkpoint_alert.sh
    echo '#!/bin/bash' > .vibe/hooks/task_complete.sh
    echo '#!/bin/bash' > .vibe/hooks/waiting_input.sh
    chmod +x .vibe/hooks/*

    # Settings
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_access.py"
          }
        ]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_write.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_step7a.py"
          }
        ]
      }
    ]
  }
}
JSON

    echo "# CLAUDE.md" > CLAUDE.md

    git add -A
    git commit -q -m "v3.5.0 project"
}

# ──────────────────────────────────────────────
# Tests: Valid project should pass
# ──────────────────────────────────────────────

describe "Doctor — valid project passes all checks"

test_doctor_clean_project() {
    create_v35_project
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    # Should not contain ✗ (failure markers) in project integrity section
    if echo "$output" | grep -q "INTEGRITY.*✗\|integrity.*✗"; then
        fail "Doctor should not report failures for valid project"
        return 1
    fi
}
run_test "Valid project passes doctor" test_doctor_clean_project

# ──────────────────────────────────────────────
# Tests: Version mismatch detection
# ──────────────────────────────────────────────

describe "Doctor — version mismatch detection"

test_doctor_detects_version_mismatch() {
    create_v35_project
    echo "2.0.0" > .vibe/version  # Introduce mismatch

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "version.*mismatch\|バージョン.*不一致\|outdated\|古い"; then
        return 0
    else
        fail "Doctor should detect version mismatch (project=2.0.0 vs framework=3.5.0)"
        return 1
    fi
}
run_test "Detects version mismatch" test_doctor_detects_version_mismatch

# ──────────────────────────────────────────────
# Tests: Missing hooks detection
# ──────────────────────────────────────────────

describe "Doctor — missing hooks detection"

test_doctor_detects_missing_hook() {
    create_v35_project
    rm .vibe/hooks/validate_access.py  # Remove a required hook

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "validate_access.py\|hook.*missing\|フック.*不足"; then
        return 0
    else
        fail "Doctor should detect missing validate_access.py"
        return 1
    fi
}
run_test "Detects missing hook file" test_doctor_detects_missing_hook

# ──────────────────────────────────────────────
# Tests: Missing policy.yaml detection
# ──────────────────────────────────────────────

describe "Doctor — missing policy.yaml detection"

test_doctor_detects_missing_policy() {
    create_v35_project
    rm .vibe/policy.yaml

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "policy.yaml\|ポリシー"; then
        return 0
    else
        fail "Doctor should detect missing policy.yaml"
        return 1
    fi
}
run_test "Detects missing policy.yaml" test_doctor_detects_missing_policy

# ──────────────────────────────────────────────
# Tests: Policy missing required roles
# ──────────────────────────────────────────────

describe "Doctor — policy role validation"

test_doctor_detects_missing_role_in_policy() {
    create_v35_project
    # Overwrite policy without engineer role
    cat > .vibe/policy.yaml << 'YAML'
roles:
  iris:
    can_read: ["vision.md"]
  product_manager:
    can_read: ["vision.md"]
YAML

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "engineer\|role.*missing\|ロール.*不足"; then
        return 0
    else
        fail "Doctor should detect missing required roles in policy.yaml"
        return 1
    fi
}
run_test "Detects missing required roles in policy.yaml" test_doctor_detects_missing_role_in_policy

# ──────────────────────────────────────────────
# Tests: state.yaml validation
# ──────────────────────────────────────────────

describe "Doctor — state.yaml validation"

test_doctor_detects_missing_state_fields() {
    create_v35_project
    echo "current_issue: null" > .vibe/state.yaml  # Missing required fields

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor 2>&1)

    if echo "$output" | grep -qi "state.yaml\|current_role\|field.*missing\|フィールド"; then
        return 0
    else
        fail "Doctor should detect missing required fields in state.yaml"
        return 1
    fi
}
run_test "Detects missing required fields in state.yaml" test_doctor_detects_missing_state_fields

# ──────────────────────────────────────────────
# Tests: --json output
# ──────────────────────────────────────────────

describe "Doctor — JSON output mode"

test_doctor_json_output() {
    create_v35_project
    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor --json 2>&1)

    # Should be valid JSON (python3 can parse it)
    if echo "$output" | python3 -m json.tool >/dev/null 2>&1; then
        return 0
    else
        fail "Doctor --json should output valid JSON, got: $(echo "$output" | head -5)"
        return 1
    fi
}
run_test "Doctor --json outputs valid JSON" test_doctor_json_output

test_doctor_json_contains_checks() {
    create_v35_project
    rm .vibe/hooks/validate_access.py  # Create an issue

    local output
    output=$("${FRAMEWORK_DIR}/bin/vibeflow" doctor --json 2>&1)

    # JSON should contain checks array with at least one failure
    if echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert any(c.get('status')!='ok' for c in d.get('checks',d.get('results',[])))" 2>/dev/null; then
        return 0
    else
        fail "Doctor --json should report check failures in structured format"
        return 1
    fi
}
run_test "Doctor --json reports failures in structured format" test_doctor_json_contains_checks

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

print_summary
