#!/bin/bash
set -euo pipefail

# VibeFlow Uninstaller

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "VibeFlow Uninstaller"
echo "─────────────────────────"

# Find vibeflow command
VIBEFLOW_BIN=$(which vibeflow 2>/dev/null || true)

if [ -z "$VIBEFLOW_BIN" ]; then
  echo "vibeflow コマンドが見つかりません。"
  exit 0
fi

echo "削除対象: ${VIBEFLOW_BIN}"
read -p "vibeflow コマンドを削除しますか？ (y/N): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
  rm -f "$VIBEFLOW_BIN"
  echo -e "${GREEN}✓ vibeflow コマンドを削除しました${NC}"
  echo ""
  echo -e "${YELLOW}注意:${NC}"
  echo "  - フレームワーク本体（このディレクトリ）は削除されていません"
  echo "  - 再インストール: ./install.sh"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  echo "  - 完全削除: rm -rf ${SCRIPT_DIR}"
else
  echo "キャンセルしました。"
fi
