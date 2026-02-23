#!/bin/bash
# VibeFlow Development Terminal Launcher
# Usage: .vibe/scripts/dev.sh <issue-number>
#
# Starts a Claude Code development session for the given GitHub Issue.
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
    echo "    - Role: Engineer"
    echo "    - 11-step workflow auto-progression"
    echo "    - VibeFlow hooks as guardrails"
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
# Launch Claude Code
# ──────────────────────────────────────────────
PROMPT="Issue #${ISSUE_NUM} の実装を開始してください。

まず以下を実行:
1. \`gh issue view ${ISSUE_NUM}\` で Issue の詳細を確認
2. state.yaml を更新: current_issue=\"#${ISSUE_NUM}\", current_role=\"Product Manager\", current_step=1, phase=development
3. Step 1 (Issue Review) から 11 ステップワークフローを順に実行

Step 7a では必ず停止してユーザーの手動確認を待ってください。"

echo -e "${CYAN}Claude Code を起動中...${NC}"
echo -e "${CYAN}  Role: Engineer → PM → Engineer → QA (auto-progression)${NC}"
echo -e "${CYAN}  Hooks: validate_access.py, validate_write.sh, validate_step7a.py${NC}"
echo ""

exec claude --dangerously-skip-permissions -p "$PROMPT"
