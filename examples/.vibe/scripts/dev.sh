#!/bin/bash
# VibeFlow Development Terminal Launcher
# Usage: .vibe/scripts/dev.sh <issue-number>
#
# Starts a Claude Code development session for the given GitHub Issue.
# Creates a session file at .vibe/sessions/dev-issue-<N>.yaml and
# sets VIBEFLOW_SESSION so validate_access.py reads the correct role.
#
# Uses --dangerously-skip-permissions because VibeFlow hooks provide
# role-based access control (validate_access.py, validate_write.sh,
# validate_step7a.py).

set -euo pipefail

# ──────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# ──────────────────────────────────────────────
# Argument check
# ──────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <issue-number>${NC}"
    echo ""
    echo "  Example: $0 32    # Start dev session for Issue #32"
    echo ""
    echo "  This launches a Claude Code session with:"
    echo "    - Role: Product Manager → Engineer → QA (auto-progression)"
    echo "    - Standard workflow (11 steps)"
    echo "    - VibeFlow hooks as guardrails"
    echo "    - Session state in .vibe/sessions/dev-issue-<N>.yaml"
    exit 1
fi

ISSUE_NUM="$1"

# Strip # prefix if provided
ISSUE_NUM="${ISSUE_NUM#\#}"

# ──────────────────────────────────────────────
# Verify issue exists
# ──────────────────────────────────────────────
echo -e "${CYAN}Issue #${ISSUE_NUM} を確認中...${NC}"

if ! command -v gh &>/dev/null; then
    echo -e "${RED}gh CLI が見つかりません。インストールしてください: https://cli.github.com/${NC}"
    exit 1
fi

ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --json title --jq '.title' 2>/dev/null) || {
    echo -e "${RED}Issue #${ISSUE_NUM} が見つかりません。番号を確認してください。${NC}"
    exit 1
}

echo -e "${GREEN}Issue #${ISSUE_NUM}: ${ISSUE_TITLE}${NC}"
echo ""

# ──────────────────────────────────────────────
# Create session state
# ──────────────────────────────────────────────
SESSION_ID="dev-issue-${ISSUE_NUM}"
SESSION_DIR=".vibe/sessions"
SESSION_FILE="${SESSION_DIR}/${SESSION_ID}.yaml"

mkdir -p "$SESSION_DIR"

cat > "$SESSION_FILE" << YAML
# VibeFlow Dev Session — Issue #${ISSUE_NUM}
session_id: ${SESSION_ID}
kind: worker
current_role: "Product Manager"
current_step: 1_issue_review
attached_issue: ${ISSUE_NUM}
worktree: null
status: active

safety:
  max_fix_attempts: 3
  failed_approach_log: []

infra_log:
  hook_changes: []
  rollback_pending: false
YAML

echo -e "${CYAN}Session: ${SESSION_FILE}${NC}"

# ──────────────────────────────────────────────
# Launch Claude Code
# ──────────────────────────────────────────────
PROMPT="Issue #${ISSUE_NUM} の実装を開始してください。

まず以下を実行:
1. \`gh issue view ${ISSUE_NUM}\` で Issue の詳細を確認
2. Step 1 (Issue Review) から Standard workflow を順に実行

Step 7a では必ず停止してユーザーの手動確認を待ってください。"

echo -e "${CYAN}Claude Code を起動中...${NC}"
echo -e "${CYAN}  Session: ${SESSION_ID}${NC}"
echo -e "${CYAN}  Hooks: validate_access.py, validate_write.sh, validate_step7a.py${NC}"
echo ""

export VIBEFLOW_SESSION="$SESSION_ID"
exec claude --dangerously-skip-permissions -p "$PROMPT"
