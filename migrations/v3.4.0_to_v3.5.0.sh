#!/bin/bash
# VibeFlow Migration: v3.4.0 -> v3.5.0
# Dev Launcher, Step 7a Guard, qa:auto/qa:manual labels, Batch Execution

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v3.4.0 → v3.5.0 マイグレーション開始"

# ============================================================
# 1/8: ディレクトリ作成
# ============================================================
log_info "1/8: 新規ディレクトリ作成"
ensure_dir ".vibe/scripts"
ensure_dir ".vibe/checkpoints"
log_ok "  .vibe/scripts/ と .vibe/checkpoints/ を作成"

# ============================================================
# 2/8: dev.sh ランチャー配置
# ============================================================
log_info "2/8: dev.sh ランチャー配置"
if [ -f "${FRAMEWORK}/examples/.vibe/scripts/dev.sh" ]; then
    copy_if_absent ".vibe/scripts/dev.sh" "${FRAMEWORK}/examples/.vibe/scripts/dev.sh"
    chmod +x ".vibe/scripts/dev.sh" 2>/dev/null || true
    log_ok "  dev.sh ランチャーを配置"
else
    log_warn "  dev.sh のソースが見つかりません"
fi

# ============================================================
# 3/8: validate_step7a.py フック配置
# ============================================================
log_info "3/8: validate_step7a.py フック配置"
if [ -f "${FRAMEWORK}/examples/.vibe/hooks/validate_step7a.py" ]; then
    cp "${FRAMEWORK}/examples/.vibe/hooks/validate_step7a.py" ".vibe/hooks/validate_step7a.py"
    chmod +x ".vibe/hooks/validate_step7a.py"
    log_ok "  validate_step7a.py を配置"
else
    log_warn "  validate_step7a.py のソースが見つかりません"
fi

# ============================================================
# 4/8: checkpoint_alert.sh 配置
# ============================================================
log_info "4/8: checkpoint_alert.sh 配置"
if [ -f "${FRAMEWORK}/examples/.vibe/hooks/checkpoint_alert.sh" ]; then
    copy_if_absent ".vibe/hooks/checkpoint_alert.sh" "${FRAMEWORK}/examples/.vibe/hooks/checkpoint_alert.sh"
    chmod +x ".vibe/hooks/checkpoint_alert.sh" 2>/dev/null || true
    log_ok "  checkpoint_alert.sh を配置"
else
    log_warn "  checkpoint_alert.sh のソースが見つかりません"
fi

# ============================================================
# 4b/8: waiting_input.sh 更新（Step 7a 通知音対応）
# ============================================================
log_info "4b/8: waiting_input.sh 更新"
if [ -f "${FRAMEWORK}/examples/.vibe/hooks/waiting_input.sh" ]; then
    cp "${FRAMEWORK}/examples/.vibe/hooks/waiting_input.sh" ".vibe/hooks/waiting_input.sh"
    chmod +x ".vibe/hooks/waiting_input.sh"
    log_ok "  waiting_input.sh を更新（Step 7a 派手通知対応）"
else
    log_warn "  waiting_input.sh のソースが見つかりません"
fi

# ============================================================
# 5/8: settings.json に validate_step7a.py フック追加
# ============================================================
log_info "5/8: settings.json 更新"
if [ -f ".claude/settings.json" ]; then
    if grep -q "validate_step7a" ".claude/settings.json"; then
        log_ok "  validate_step7a は既に登録済み（スキップ）"
    else
        if command -v python3 &>/dev/null; then
            python3 -c "
import json

with open('.claude/settings.json', 'r') as f:
    settings = json.load(f)

# Add validate_step7a.py hook to PreToolUse
pre_hooks = settings.get('hooks', {}).get('PreToolUse', [])
step7a_entry = {
    'matcher': 'Bash',
    'hooks': [
        {
            'type': 'command',
            'command': 'python3 \"\$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_step7a.py',
            'timeout': 10
        }
    ]
}
pre_hooks.append(step7a_entry)
settings['hooks']['PreToolUse'] = pre_hooks

with open('.claude/settings.json', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
            log_ok "  validate_step7a.py フックを settings.json に追加"
        else
            log_warn "  python3 がないため settings.json の更新をスキップ"
        fi
    fi
else
    log_warn "  .claude/settings.json が見つかりません"
fi

# ============================================================
# 6/8: CLAUDE.md 更新
# ============================================================
log_info "6/8: CLAUDE.md 更新"
if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v3.5 に更新"
fi

# ============================================================
# 7/8: ロールファイル更新
# ============================================================
log_info "7/8: ロールファイル更新"
for role in iris.md engineer.md product-manager.md qa-engineer.md infra.md; do
    if [ -f "${FRAMEWORK}/lib/roles/${role}" ]; then
        cp "${FRAMEWORK}/lib/roles/${role}" ".vibe/roles/${role}"
    fi
done
log_ok "  ロールファイルを最新版に更新"

# ============================================================
# 8/8: バージョン更新
# ============================================================
log_info "8/8: バージョン更新"
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
echo ""
log_info "新機能:"
log_info "  - .vibe/scripts/dev.sh: 開発ターミナルランチャー"
log_info "  - validate_step7a.py: Step 7a 強制停止フック"
log_info "  - qa:auto / qa:manual ラベル: Step 7a の自動承認/手動確認分類"
log_info "  - Batch Execution: Iris から qa:auto Issue を並列実行"
