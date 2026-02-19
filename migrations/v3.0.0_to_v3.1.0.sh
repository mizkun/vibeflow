#!/bin/bash
# VibeFlow Migration: v3.0.0 -> v3.1.0
# /discuss コマンド改善: トピックなしでも Iris セッションが起動するように

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v3.0.0 → v3.1.0 マイグレーション開始"

# ============================================================
# 1/2: /discuss コマンド更新
# ============================================================
log_info "1/2: /discuss コマンド更新"
if [ -f "${FRAMEWORK}/lib/commands/discuss.md" ]; then
    cp "${FRAMEWORK}/lib/commands/discuss.md" ".claude/commands/discuss.md"
    log_ok "  discuss.md を更新（トピックなしでも Iris セッション起動）"
else
    log_warn "  discuss.md のソースが見つかりません"
fi

# ============================================================
# 2/2: STATUS.md の P2 → Iris 修正
# ============================================================
log_info "2/2: STATUS.md 更新"
if [ -f ".vibe/context/STATUS.md" ]; then
    if grep -q "P2" ".vibe/context/STATUS.md" 2>/dev/null; then
        sed -i.bak 's/P2/Iris/g' ".vibe/context/STATUS.md"
        rm -f ".vibe/context/STATUS.md.bak"
        log_ok "  STATUS.md: P2 → Iris に修正"
    else
        log_warn "  STATUS.md: P2 の参照なし（スキップ）"
    fi
else
    copy_if_absent "${FRAMEWORK}/examples/.vibe/context/STATUS.md" ".vibe/context/STATUS.md"
fi

# Version
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
