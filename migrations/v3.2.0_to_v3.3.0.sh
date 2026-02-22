#!/bin/bash
# VibeFlow Migration: v3.2.0 -> v3.3.0
# 11ステップワークフロー復活、current_step 追加

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v3.2.0 → v3.3.0 マイグレーション開始"

# ============================================================
# 1/4: state.yaml に current_step を追加
# ============================================================
log_info "1/4: state.yaml に current_step を追加"
if [ -f ".vibe/state.yaml" ]; then
    if grep -q "current_step" ".vibe/state.yaml"; then
        log_ok "  current_step は既に存在します（スキップ）"
    else
        # current_role の直後に current_step を追加
        if command -v python3 &>/dev/null; then
            python3 -c "
import re
with open('.vibe/state.yaml', 'r') as f:
    content = f.read()
# current_role の行の後に current_step を挿入
content = re.sub(
    r'(current_role:.*\n)',
    r'\1current_step: null  # 1-11 (null = not in dev cycle)\n',
    content,
    count=1
)
with open('.vibe/state.yaml', 'w') as f:
    f.write(content)
"
            log_ok "  current_step: null を追加"
        else
            # python3 がない場合は sed でフォールバック
            sed -i.bak '/^current_role:/a\
current_step: null  # 1-11 (null = not in dev cycle)' ".vibe/state.yaml"
            rm -f ".vibe/state.yaml.bak"
            log_ok "  current_step: null を追加（sed フォールバック）"
        fi
    fi
else
    log_warn "  .vibe/state.yaml が見つかりません"
fi

# ============================================================
# 2/4: CLAUDE.md 更新
# ============================================================
log_info "2/4: CLAUDE.md 更新"
if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v3.3 に更新（11ステップワークフロー復活）"
fi

# ============================================================
# 3/4: コマンドファイル更新
# ============================================================
log_info "3/4: コマンドファイル更新"
for cmd in discuss.md conclude.md progress.md healthcheck.md run-e2e.md; do
    if [ -f "${FRAMEWORK}/lib/commands/${cmd}" ]; then
        cp "${FRAMEWORK}/lib/commands/${cmd}" ".claude/commands/${cmd}"
    fi
done
log_ok "  コマンドを最新版に更新"

# ============================================================
# 4/4: バージョン更新
# ============================================================
log_info "4/4: バージョン更新"
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
