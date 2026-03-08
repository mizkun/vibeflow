#!/bin/bash

# Vibe Coding Framework - Version Management
# This script handles framework versioning
# VERSION file is the single source of truth for version number.

# Read version from VERSION file (single source of truth)
_VIBEFLOW_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "${_VIBEFLOW_SCRIPT_DIR}/VERSION" ]; then
    FRAMEWORK_VERSION=$(cat "${_VIBEFLOW_SCRIPT_DIR}/VERSION" | tr -d '[:space:]')
else
    echo "WARNING: VERSION file not found at ${_VIBEFLOW_SCRIPT_DIR}/VERSION" >&2
    FRAMEWORK_VERSION="unknown"
fi
unset _VIBEFLOW_SCRIPT_DIR

# Function to write version file
write_version_file() {
    local target_dir=$1
    cat > "${target_dir}/.vibe/framework_version.yaml" << EOF
# Vibe Coding Framework Version Information
framework:
  version: "${FRAMEWORK_VERSION}"
  installed_at: "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')"

  # Version compatibility
  minimum_compatible: "1.0.0"

  # Features enabled
  features:
    simplified_state: true
    verification_system: true
    quick_fix_mode: true
    e2e_testing: true
    notifications: true
    hooks: true
    subagents: true
    skills: true
    access_guard: true
    discovery_phase: true
    agent_team_mode: true
    context_fork_mode: true
    safety_rules: true
    write_guard: true
    infra_manager_role: true
    github_issues: true
    iris_role: true
    multi_terminal: true
    three_tier_context: true
    # New in 3.5.0
    dev_launcher: true
    step7a_guard: true
    qa_labels: true
    batch_execution: true

  # Claude Code integration
  claude_code:
    settings_file: ".claude/settings.json"
    hooks:
      - PreToolUse (validate_access.py)
      - PreToolUse (validate_write.sh)
      - PreToolUse (validate_step7a.py)
      - PostToolUse (task_complete.sh)
      - Stop (waiting_input.sh)
    skills:
      - vibeflow-issue-template
      - vibeflow-tdd
    subagents:
      - qa-acceptance
      - code-reviewer
      - test-runner

  # Project repository
  repository_url: "https://github.com/mizkun/vibeflow"
EOF
}

# Export function
export -f write_version_file
