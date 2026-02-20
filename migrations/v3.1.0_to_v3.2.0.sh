#!/bin/bash
# VibeFlow Migration: v3.1.0 -> v3.2.0
# Setup/Examples/Upgrade の出力統一、ゴミコマンド削除

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v3.1.0 → v3.2.0 マイグレーション開始"

# ============================================================
# 1/4: 不要コマンド削除
# ============================================================
log_info "1/4: 不要コマンド削除"
for stale_cmd in quickfix.md exit-quickfix.md parallel-test.md next.md; do
    if [ -f ".claude/commands/${stale_cmd}" ]; then
        rm ".claude/commands/${stale_cmd}"
        log_ok "  ${stale_cmd} を削除"
    fi
done

# ============================================================
# 2/4: コマンドファイル更新
# ============================================================
log_info "2/4: コマンドファイル更新"
for cmd in discuss.md conclude.md progress.md healthcheck.md run-e2e.md; do
    if [ -f "${FRAMEWORK}/lib/commands/${cmd}" ]; then
        cp "${FRAMEWORK}/lib/commands/${cmd}" ".claude/commands/${cmd}"
    fi
done
log_ok "  コマンドを最新版に更新"

# ============================================================
# 3/4: CLAUDE.md 更新
# ============================================================
log_info "3/4: CLAUDE.md 更新"
if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v3.2 に更新（不要コマンド参照削除）"
fi

# ============================================================
# 4/4: バージョン更新
# ============================================================
log_info "4/4: バージョン更新"
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
