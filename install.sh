#!/bin/bash
set -euo pipefail

# VibeFlow Installer
# Creates a symlink so `vibeflow` command is available from anywhere

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_SOURCE="${SCRIPT_DIR}/bin/vibeflow"
VERSION=$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo "unknown")

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}VibeFlow${NC} v${VERSION} Installer"
echo "─────────────────────────"

# Ensure executables have proper permissions
chmod +x "$BIN_SOURCE"
chmod +x "${SCRIPT_DIR}/setup_vibeflow.sh"
[ -f "${SCRIPT_DIR}/upgrade_vibeflow.sh" ] && chmod +x "${SCRIPT_DIR}/upgrade_vibeflow.sh"

# Install target candidates
INSTALL_TARGETS=(
  "$HOME/.local/bin"
  "/usr/local/bin"
)

# Detect existing installation
EXISTING=$(which vibeflow 2>/dev/null || true)
if [ -n "$EXISTING" ]; then
  echo -e "${YELLOW}既存のインストールを検出: ${EXISTING}${NC}"
  read -p "上書きしますか？ (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "キャンセルしました。"
    exit 0
  fi
  rm -f "$EXISTING"
fi

# Prefer ~/.local/bin (no sudo needed)
INSTALL_DIR=""
for target in "${INSTALL_TARGETS[@]}"; do
  if [ -d "$target" ] && echo "$PATH" | grep -q "$target"; then
    INSTALL_DIR="$target"
    break
  fi
done

# If ~/.local/bin not in PATH, create it and add to shell config
SHELL_RC=""
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  echo -e "${YELLOW}${INSTALL_DIR} を作成しました${NC}"

  if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
  elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
  fi

  PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

  if [ -n "$SHELL_RC" ]; then
    if ! grep -qF '.local/bin' "$SHELL_RC" 2>/dev/null; then
      echo "" >> "$SHELL_RC"
      echo "# VibeFlow" >> "$SHELL_RC"
      echo "$PATH_LINE" >> "$SHELL_RC"
      echo -e "${GREEN}PATH を ${SHELL_RC} に追加しました${NC}"
      echo -e "${YELLOW}反映するには: source ${SHELL_RC}${NC}"
    fi
  else
    echo -e "${YELLOW}以下を手動でシェル設定に追加してください:${NC}"
    echo "  $PATH_LINE"
  fi
fi

# Create symlink
ln -sf "$BIN_SOURCE" "${INSTALL_DIR}/vibeflow"

echo ""
echo -e "${GREEN}✓ インストール完了${NC}"
echo ""
echo "  コマンド: vibeflow"
echo "  リンク:   ${INSTALL_DIR}/vibeflow → ${BIN_SOURCE}"
echo "  フレームワーク: ${SCRIPT_DIR}"
echo ""
echo "使い方:"
echo "  vibeflow setup      新規プロジェクト作成"
echo "  vibeflow upgrade    既存プロジェクトのアップグレード"
echo "  vibeflow doctor     環境チェック"
echo "  vibeflow help       ヘルプ"
echo ""

# Warn if PATH not yet active
if ! command -v vibeflow &>/dev/null; then
  echo -e "${YELLOW}注意: 新しいターミナルを開くか、以下を実行してください:${NC}"
  echo "  source ${SHELL_RC:-~/.bashrc}"
fi
