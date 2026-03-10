#!/bin/bash

# VibeFlow Claude Code CLI Wrapper
# Dispatches tasks to Claude Code with --dangerously-skip-permissions --print --output-format json
# Supports worktree isolation and session recording

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CMD="${VIBEFLOW_CLAUDE_CMD:-claude}"
PROJECT_DIR="${VIBEFLOW_PROJECT_DIR:-.}"
TIMEOUT="${VIBEFLOW_CLAUDE_TIMEOUT:-600}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <prompt>

Dispatch a task to Claude Code with --dangerously-skip-permissions --print --output-format json.

Options:
  --worktree <branch>    Execute in a git worktree on <branch>
  --session-dir <dir>    Directory for session recording (default: .vibe/sessions)
  --timeout <seconds>    Timeout in seconds (default: 600)
  --help                 Show this help

Environment:
  VIBEFLOW_CLAUDE_CMD      Claude command (default: claude)
  VIBEFLOW_PROJECT_DIR     Project directory (default: .)
  VIBEFLOW_CLAUDE_TIMEOUT  Timeout in seconds (default: 600)

Examples:
  $(basename "$0") "Implement login feature"
  $(basename "$0") --worktree vf/issue-42 "Review the PR diff"
EOF
}

# Parse arguments
WORKTREE_BRANCH=""
SESSION_DIR="${PROJECT_DIR}/.vibe/sessions"
PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --worktree)
            WORKTREE_BRANCH="$2"
            shift 2
            ;;
        --session-dir)
            SESSION_DIR="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            PROMPT="$1"
            shift
            ;;
    esac
done

if [ -z "$PROMPT" ]; then
    usage
    exit 1
fi

# Setup worktree if requested
WORK_DIR="$PROJECT_DIR"
if [ -n "$WORKTREE_BRANCH" ]; then
    WORKTREE_DIR="${PROJECT_DIR}/.vibe/worktrees/${WORKTREE_BRANCH//\//_}"
    if [ ! -d "$WORKTREE_DIR" ]; then
        git -C "$PROJECT_DIR" worktree add "$WORKTREE_DIR" -b "$WORKTREE_BRANCH" 2>/dev/null || \
        git -C "$PROJECT_DIR" worktree add "$WORKTREE_DIR" "$WORKTREE_BRANCH" 2>/dev/null || true
    fi
    WORK_DIR="$WORKTREE_DIR"
fi

# Record session
mkdir -p "$SESSION_DIR"
TASK_ID="claude-$(date +%s)-$$"
SESSION_FILE="${SESSION_DIR}/${TASK_ID}.json"
cat > "$SESSION_FILE" <<SESS
{
  "task_id": "${TASK_ID}",
  "agent": "claude_code",
  "status": "running",
  "prompt": $(echo "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))'),
  "work_dir": "${WORK_DIR}",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
SESS

# Write YAML state file for hooks (validate_access.py, stop_test_gate.sh)
YAML_STATE_FILE="${SESSION_DIR}/${TASK_ID}.yaml"
cat > "$YAML_STATE_FILE" <<YAMLSTATE
session_id: "${TASK_ID}"
current_role: "Coding Agent"
current_step: "5_implementation"
agent: "claude_code"
status: "running"
YAMLSTATE

# Execute Claude Code with --dangerously-skip-permissions --print --output-format json
echo "Dispatching to Claude Code (dangerously-skip-permissions, print, json)..."
set +e
timeout "$TIMEOUT" "$CLAUDE_CMD" \
    --dangerously-skip-permissions \
    --print \
    --output-format json \
    "$PROMPT" 2>&1
EXIT_CODE=$?
set -e

# Update session status
if [ $EXIT_CODE -eq 0 ]; then
    STATUS="completed"
elif [ $EXIT_CODE -eq 124 ]; then
    STATUS="timeout"
else
    STATUS="failed"
fi

python3 -c "
import json
with open('${SESSION_FILE}', 'r') as f:
    session = json.load(f)
session['status'] = '${STATUS}'
session['exit_code'] = ${EXIT_CODE}
with open('${SESSION_FILE}', 'w') as f:
    json.dump(session, f, indent=2)
" 2>/dev/null || true

# Update YAML state file
cat > "$YAML_STATE_FILE" <<YAMLSTATE
session_id: "${TASK_ID}"
current_role: "Coding Agent"
current_step: "5_implementation"
agent: "claude_code"
status: "${STATUS}"
YAMLSTATE

# Cleanup worktree if requested
if [ -n "$WORKTREE_BRANCH" ] && [ "$STATUS" = "completed" ]; then
    echo "Worktree available at: $WORK_DIR"
fi

exit $EXIT_CODE
