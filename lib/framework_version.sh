#!/bin/bash

# Vibe Coding Framework - Version Management
# This script handles framework versioning

# Current framework version
FRAMEWORK_VERSION="3.4.0"
FRAMEWORK_NAME="GitHub Issues, Iris, Multi-Terminal, 3-Tier Context, Quick Fix Mode"
FRAMEWORK_RELEASE_DATE="2026-02-22"

# Function to write version file
write_version_file() {
    local target_dir=$1
    cat > "${target_dir}/.vibe/framework_version.yaml" << EOF
# Vibe Coding Framework Version Information
framework:
  version: "${FRAMEWORK_VERSION}"
  name: "${FRAMEWORK_NAME}"
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
    # New in 3.0.0
    github_issues: true
    iris_role: true
    multi_terminal: true
    three_tier_context: true

  # Claude Code integration
  claude_code:
    settings_file: ".claude/settings.json"
    hooks:
      - PreToolUse (validate_access.py)
      - PreToolUse (validate_write.sh)
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
