#!/bin/bash
# VibeFlow Migration: v3.3.0 -> v3.4.0
# Quick Fix Mode 追加

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v3.3.0 → v3.4.0 マイグレーション開始"

# ============================================================
# 1/5: state.yaml の quick_fixes を quickfix オブジェクトに変換
# ============================================================
log_info "1/5: state.yaml の quickfix セクションを更新"
if [ -f ".vibe/state.yaml" ]; then
    if grep -q "^quickfix:" ".vibe/state.yaml"; then
        log_ok "  quickfix セクションは既に存在します（スキップ）"
    else
        if command -v python3 &>/dev/null; then
            python3 -c "
import re
with open('.vibe/state.yaml', 'r') as f:
    content = f.read()
# quick_fixes: [] を quickfix オブジェクトに置換
content = re.sub(
    r'# Quick fixes tracking\nquick_fixes: \[\]',
    '# Quick Fix mode tracking\nquickfix:\n  active: false\n  description: null\n  started: null',
    content
)
# phase コメントに quickfix を追加
content = content.replace(
    'phase: development',
    'phase: development  # development | discovery | quickfix',
    1
)
with open('.vibe/state.yaml', 'w') as f:
    f.write(content)
"
            log_ok "  quick_fixes → quickfix オブジェクトに変換"
        else
            # python3 がない場合は sed でフォールバック
            sed -i.bak 's/# Quick fixes tracking/# Quick Fix mode tracking/' ".vibe/state.yaml"
            sed -i.bak 's/^quick_fixes: \[\]/quickfix:\n  active: false\n  description: null\n  started: null/' ".vibe/state.yaml"
            rm -f ".vibe/state.yaml.bak"
            log_ok "  quick_fixes → quickfix オブジェクトに変換（sed フォールバック）"
        fi
    fi
else
    log_warn "  .vibe/state.yaml が見つかりません"
fi

# ============================================================
# 2/5: CLAUDE.md 更新
# ============================================================
log_info "2/5: CLAUDE.md 更新"
if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v3.4 に更新（Quick Fix Mode 追加）"
fi

# ============================================================
# 3/5: コマンドファイル更新
# ============================================================
log_info "3/5: コマンドファイル更新"
for cmd in discuss.md conclude.md quickfix.md progress.md healthcheck.md run-e2e.md; do
    if [ -f "${FRAMEWORK}/lib/commands/${cmd}" ]; then
        cp "${FRAMEWORK}/lib/commands/${cmd}" ".claude/commands/${cmd}"
    fi
done
log_ok "  コマンドを最新版に更新（quickfix.md 追加）"

# ============================================================
# 4/5: framework_version.yaml 更新
# ============================================================
log_info "4/5: framework_version.yaml 更新"
if [ -f ".vibe/framework_version.yaml" ]; then
    if command -v python3 &>/dev/null; then
        python3 -c "
import re
with open('.vibe/framework_version.yaml', 'r') as f:
    content = f.read()
content = re.sub(r'version: \"[^\"]+\"', 'version: \"${VIBEFLOW_TO_VERSION}\"', content, count=1)
content = re.sub(r'name: \"[^\"]+\"', 'name: \"GitHub Issues, Iris, Multi-Terminal, 3-Tier Context, Quick Fix Mode\"', content, count=1)
with open('.vibe/framework_version.yaml', 'w') as f:
    f.write(content)
"
        log_ok "  framework_version.yaml を v${VIBEFLOW_TO_VERSION} に更新"
    else
        log_warn "  python3 がないため framework_version.yaml の更新をスキップ"
    fi
else
    log_warn "  .vibe/framework_version.yaml が見つかりません（スキップ）"
fi

# ============================================================
# 5/5: バージョン更新
# ============================================================
log_info "5/5: バージョン更新"
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
