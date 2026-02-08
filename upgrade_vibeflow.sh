#!/bin/bash
set -euo pipefail

# VibeFlow Upgrade Script
# Usage: ~/vibeflow/upgrade_vibeflow.sh [options]
#
# Options:
#   --dry-run    Show what would be done without making changes
#   --force      Skip confirmation prompts
#   --no-backup  Skip backup (not recommended)
#   --help       Show help

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"
VERSION_FILE="${PROJECT_DIR}/.vibe/version"
FRAMEWORK_VERSION_FILE="${SCRIPT_DIR}/VERSION"
MIGRATIONS_DIR="${SCRIPT_DIR}/migrations"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
DRY_RUN=false
FORCE=false
NO_BACKUP=false

# --- Helper functions ---

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  echo "Usage: $(basename "$0") [options]"
  echo ""
  echo "VibeFlow フレームワークを既存プロジェクトでアップグレードします。"
  echo "プロジェクトディレクトリ内で実行してください。"
  echo ""
  echo "Options:"
  echo "  --dry-run    変更を実行せず、何が行われるかを表示"
  echo "  --force      確認プロンプトをスキップ"
  echo "  --no-backup  バックアップをスキップ（非推奨）"
  echo "  --help       このヘルプを表示"
  exit 0
}

# Version comparison
version_gt() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
}

version_eq() {
  [ "$1" = "$2" ]
}

# --- Argument parsing ---

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)    DRY_RUN=true;    shift ;;
    --force)      FORCE=true;      shift ;;
    --no-backup)  NO_BACKUP=true;  shift ;;
    --help|-h)    usage ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

# --- Pre-flight checks ---

echo ""
echo "========================================="
echo "  VibeFlow Upgrade"
echo "========================================="
echo ""

# Check if this is a VibeFlow project
if [ ! -d ".vibe" ]; then
  log_error "VibeFlow プロジェクトが見つかりません（.vibe/ ディレクトリが存在しない）"
  log_error "プロジェクトディレクトリ内で実行してください。"
  exit 1
fi

if [ ! -f "$FRAMEWORK_VERSION_FILE" ]; then
  log_error "フレームワークの VERSION ファイルが見つかりません: $FRAMEWORK_VERSION_FILE"
  exit 1
fi

# Get versions
FRAMEWORK_VERSION=$(cat "$FRAMEWORK_VERSION_FILE" | tr -d '[:space:]')

if [ -f "$VERSION_FILE" ]; then
  PROJECT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
  PROJECT_VERSION="1.0.0"
  log_warn "バージョンファイルが見つかりません。v1.0.0 として扱います。"
fi

log_info "プロジェクトバージョン: v${PROJECT_VERSION}"
log_info "フレームワークバージョン: v${FRAMEWORK_VERSION}"
echo ""

# Already up to date?
if version_eq "$PROJECT_VERSION" "$FRAMEWORK_VERSION"; then
  log_ok "すでに最新バージョンです (v${FRAMEWORK_VERSION})"
  exit 0
fi

if version_gt "$PROJECT_VERSION" "$FRAMEWORK_VERSION"; then
  log_error "プロジェクト (v${PROJECT_VERSION}) がフレームワーク (v${FRAMEWORK_VERSION}) より新しいです"
  exit 1
fi

# --- Find applicable migrations ---

MIGRATIONS=()
if [ -d "$MIGRATIONS_DIR" ]; then
  for migration_file in "$MIGRATIONS_DIR"/*.sh; do
    [ -f "$migration_file" ] || continue

    basename_noext=$(basename "$migration_file" .sh)
    from_version=$(echo "$basename_noext" | sed 's/^v//' | sed 's/_to_v.*//')
    to_version=$(echo "$basename_noext" | sed 's/.*_to_v//')

    # Include migration if from_version matches or is between project and framework versions
    if version_eq "$from_version" "$PROJECT_VERSION" || \
       { version_gt "$from_version" "$PROJECT_VERSION" && ! version_gt "$from_version" "$FRAMEWORK_VERSION"; }; then
      if version_gt "$to_version" "$PROJECT_VERSION"; then
        MIGRATIONS+=("$migration_file|$from_version|$to_version")
      fi
    fi
  done
fi

# Sort migrations by version
if [ ${#MIGRATIONS[@]} -gt 0 ]; then
  IFS=$'\n' MIGRATIONS=($(sort -t'|' -k2 -V <<< "${MIGRATIONS[*]}")); unset IFS
fi

if [ ${#MIGRATIONS[@]} -eq 0 ]; then
  log_error "v${PROJECT_VERSION} → v${FRAMEWORK_VERSION} のマイグレーションが見つかりません"
  log_error "migrations/ ディレクトリを確認してください"
  exit 1
fi

# --- Show migration plan ---

echo "適用するマイグレーション:"
echo "─────────────────────────"
for entry in "${MIGRATIONS[@]}"; do
  IFS='|' read -r file from to <<< "$entry"
  echo "  v${from} → v${to}  ($(basename "$file"))"
done
echo "─────────────────────────"
echo ""

if $DRY_RUN; then
  log_info "[DRY RUN] 上記のマイグレーションが適用されます。実際の変更は行いません。"
  exit 0
fi

# --- Confirmation ---

if ! $FORCE; then
  read -p "アップグレードを実行しますか？ (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log_info "キャンセルしました。"
    exit 0
  fi
fi

# --- Backup ---

if ! $NO_BACKUP; then
  BACKUP_NAME="vibeflow-backup-$(date +%Y%m%d-%H%M%S)"
  log_info "バックアップを作成中: ${BACKUP_NAME}"

  # Git checkpoint
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git add -A 2>/dev/null || true
    git commit -m "checkpoint: before VibeFlow upgrade v${PROJECT_VERSION} → v${FRAMEWORK_VERSION}" --allow-empty 2>/dev/null || true
    log_ok "Git checkpoint 作成済み"
  fi

  # File backup
  BACKUP_DIR=".vibe/backups/${BACKUP_NAME}"
  mkdir -p "$BACKUP_DIR"
  cp CLAUDE.md "${BACKUP_DIR}/" 2>/dev/null || true
  cp .vibe/state.yaml "${BACKUP_DIR}/" 2>/dev/null || true
  [ -d .claude/commands ] && cp -r .claude/commands/ "${BACKUP_DIR}/commands/" 2>/dev/null || true
  log_ok "ファイルバックアップ: ${BACKUP_DIR}/"
fi

# --- Execute migrations ---

echo ""
log_info "マイグレーションを実行中..."
echo ""

for entry in "${MIGRATIONS[@]}"; do
  IFS='|' read -r migration_file from_version to_version <<< "$entry"

  echo "─────────────────────────"
  log_info "実行中: v${from_version} → v${to_version}"
  echo "─────────────────────────"

  export VIBEFLOW_PROJECT_DIR="$PROJECT_DIR"
  export VIBEFLOW_FRAMEWORK_DIR="$SCRIPT_DIR"
  export VIBEFLOW_FROM_VERSION="$from_version"
  export VIBEFLOW_TO_VERSION="$to_version"

  if bash "$migration_file"; then
    echo "$to_version" > "$VERSION_FILE"
    log_ok "v${to_version} に更新完了"
  else
    log_error "マイグレーション失敗: $(basename "$migration_file")"
    log_error "プロジェクトは v${from_version} のままです。"
    if [ -n "${BACKUP_DIR:-}" ]; then
      log_error "バックアップから復旧してください: ${BACKUP_DIR}/"
    fi
    exit 1
  fi

  echo ""
done

# --- Done ---

echo "========================================="
log_ok "VibeFlow v${FRAMEWORK_VERSION} へのアップグレードが完了しました"
echo "========================================="
echo ""

if git rev-parse --is-inside-work-tree &>/dev/null; then
  git add -A && git commit -m "feat: VibeFlow upgrade to v${FRAMEWORK_VERSION}" 2>/dev/null || true
fi

echo "次のステップ:"
echo "  1. /healthcheck でプロジェクトの整合性を確認"
echo "  2. /discuss または /next で開発を再開"
echo ""
