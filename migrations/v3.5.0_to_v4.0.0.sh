#!/bin/bash
# VibeFlow Migration: v3.5.0 -> v4.0.0
# State split, Patch Loop, Handoff packet, /patch command

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${VIBEFLOW_DRY_RUN:-0}"
ALLOW_DIRTY="${VIBEFLOW_ALLOW_DIRTY:-0}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v3.5.0 → v4.0.0 マイグレーション開始"

# ============================================================
# 0/7: Pre-flight — dirty tree check
# ============================================================
if git rev-parse --is-inside-work-tree &>/dev/null; then
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        if [ "$ALLOW_DIRTY" != "1" ]; then
            log_error "作業ツリーに未コミットの変更があります"
            log_error "先にコミットするか、VIBEFLOW_ALLOW_DIRTY=1 で実行してください"
            exit 1
        else
            log_warn "作業ツリーが dirty ですが、ALLOW_DIRTY=1 のため続行します"
        fi
    fi
fi

# ============================================================
# 0b/7: Dry-run guard
# ============================================================
if [ "$DRY_RUN" = "1" ]; then
    log_info "[DRY RUN] 以下の変更が適用されます:"
    log_info "  - state.yaml → project_state.yaml + sessions/iris-main.yaml に分割"
    log_info "  - quickfix → patch_runs に変換"
    log_info "  - /patch コマンド配置"
    log_info "  - CLAUDE.md マネージドセクション再生成"
    log_info "  - カスタマイズ済みファイルの検出と保護"
    log_info "  - バージョン → 4.0.0"
    log_info "[DRY RUN] 実際の変更は行いません。"
    exit 0
fi

# ============================================================
# 1/7: ファイル分類（baseline hash 照合）
# ============================================================
log_info "1/7: ファイル分類"

CUSTOMIZED_FILES=()

if command -v python3 &>/dev/null; then
    while IFS='|' read -r rel_path classification; do
        [ -z "$rel_path" ] && continue
        if [ "$classification" = "customized" ]; then
            CUSTOMIZED_FILES+=("$rel_path")
            log_warn "  customized: $rel_path"
        fi
    done < <(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK}')
from core.baselines.loader import classify_project
results = classify_project('${PROJECT}', '3.5.0', '${FRAMEWORK}/core/baselines')
for path, cls in sorted(results.items()):
    print(f'{path}|{cls}')
" 2>/dev/null || true)
fi

if [ ${#CUSTOMIZED_FILES[@]} -gt 0 ]; then
    log_warn "${#CUSTOMIZED_FILES[@]} 個のカスタマイズ済みファイルを検出（上書きしません）"
else
    log_ok "  カスタマイズ済みファイルなし（全ファイルがストック）"
fi

# ============================================================
# 2/7: state.yaml 分割 → project_state.yaml + sessions/
# ============================================================
log_info "2/7: state.yaml 分割"

if [ -f ".vibe/state.yaml" ]; then
    # Backup
    cp ".vibe/state.yaml" ".vibe/state.yaml.v3-backup"
    log_ok "  バックアップ: .vibe/state.yaml.v3-backup"

    # Create sessions directory
    ensure_dir ".vibe/sessions"

    # Split using Python for YAML parsing
    if command -v python3 &>/dev/null; then
        python3 -c "
import yaml, sys, os

with open('.vibe/state.yaml', 'r') as f:
    state = yaml.safe_load(f) or {}

# --- project_state.yaml ---
project_state = {
    'active_issue': state.get('current_issue', None),
    'phase': state.get('phase', 'development'),
    'issues_recent': state.get('issues_recent', []),
    'patch_runs': [],
    'safety': state.get('safety', {}),
    'infra_log': state.get('infra_log', {}),
}

# Convert quickfix to patch_runs if active
qf = state.get('quickfix', {})
if qf and qf.get('active', False):
    patch_run = {
        'description': qf.get('description', ''),
        'started': str(qf.get('started', '')),
        'status': 'in_progress',
        'parent_issue': state.get('current_issue', None),
    }
    project_state['patch_runs'] = [patch_run]

with open('.vibe/project_state.yaml', 'w') as f:
    yaml.dump(project_state, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

# --- sessions/iris-main.yaml ---
session = {
    'current_role': state.get('current_role', 'Iris'),
    'current_step': state.get('current_step', None),
    'discovery': state.get('discovery', {}),
}

os.makedirs('.vibe/sessions', exist_ok=True)
with open('.vibe/sessions/iris-main.yaml', 'w') as f:
    yaml.dump(session, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print('OK')
" 2>/dev/null
        log_ok "  project_state.yaml + sessions/iris-main.yaml を作成"
    else
        log_warn "  python3 がないため state 分割をスキップ"
    fi
else
    log_warn "  state.yaml が見つかりません（スキップ）"
fi

# ============================================================
# 3/7: /patch コマンド配置
# ============================================================
log_info "3/7: /patch コマンド配置"
ensure_dir ".claude/commands"

if [ -f "${FRAMEWORK}/lib/commands/patch.md" ]; then
    copy_if_absent "${FRAMEWORK}/lib/commands/patch.md" ".claude/commands/patch.md"
else
    log_warn "  patch.md のソースが見つかりません"
fi

# /quickfix alias も更新（カスタマイズされていなければ）
is_customized() {
    local path="$1"
    for cf in "${CUSTOMIZED_FILES[@]:-}"; do
        [ "$cf" = "$path" ] && return 0
    done
    return 1
}

if [ -f "${FRAMEWORK}/lib/commands/quickfix.md" ]; then
    if ! is_customized ".claude/commands/quickfix.md"; then
        cp "${FRAMEWORK}/lib/commands/quickfix.md" ".claude/commands/quickfix.md"
        log_ok "  quickfix.md を /patch alias 版に更新"
    else
        log_warn "  quickfix.md はカスタマイズ済み（スキップ）"
    fi
fi

# ============================================================
# 4/7: ストックファイル更新（カスタマイズ済みは保護）
# ============================================================
log_info "4/7: ストックファイル更新"

# Hooks
for hook in validate_write.sh validate_step7a.py checkpoint_alert.sh task_complete.sh waiting_input.sh; do
    src="${FRAMEWORK}/examples/.vibe/hooks/${hook}"
    dst=".vibe/hooks/${hook}"
    if [ -f "$src" ]; then
        if ! is_customized ".vibe/hooks/${hook}"; then
            cp "$src" "$dst"
            chmod +x "$dst" 2>/dev/null || true
            log_ok "  更新: $dst"
        else
            log_warn "  スキップ（カスタマイズ済み）: $dst"
        fi
    fi
done

# Role docs
for role_file in "${FRAMEWORK}"/lib/roles/*.md; do
    [ -f "$role_file" ] || continue
    local_name=$(basename "$role_file")
    dst=".vibe/roles/${local_name}"
    if ! is_customized ".vibe/roles/${local_name}"; then
        cp "$role_file" "$dst"
        log_ok "  更新: $dst"
    else
        log_warn "  スキップ（カスタマイズ済み）: $dst"
    fi
done

# Validate access hook (v4 version)
if [ -f "${FRAMEWORK}/examples/.vibe/hooks/validate_access.py" ]; then
    if ! is_customized ".vibe/hooks/validate_access.py"; then
        cp "${FRAMEWORK}/examples/.vibe/hooks/validate_access.py" ".vibe/hooks/validate_access.py"
        chmod +x ".vibe/hooks/validate_access.py"
        log_ok "  更新: .vibe/hooks/validate_access.py"
    else
        log_warn "  スキップ（カスタマイズ済み）: .vibe/hooks/validate_access.py"
    fi
fi

# Policy
if [ -f "${FRAMEWORK}/examples/.vibe/policy.yaml" ]; then
    if ! is_customized ".vibe/policy.yaml"; then
        cp "${FRAMEWORK}/examples/.vibe/policy.yaml" ".vibe/policy.yaml"
        log_ok "  更新: .vibe/policy.yaml"
    else
        log_warn "  スキップ（カスタマイズ済み）: .vibe/policy.yaml"
    fi
fi

# ============================================================
# 5/7: CLAUDE.md マネージドセクション再生成
# ============================================================
log_info "5/7: CLAUDE.md 更新"
if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v4.0.0 版に更新"
fi

# ============================================================
# 6/7: settings.json 更新
# ============================================================
log_info "6/7: settings.json 更新"
if [ -f "${FRAMEWORK}/examples/.claude/settings.json" ]; then
    if ! is_customized ".claude/settings.json"; then
        cp "${FRAMEWORK}/examples/.claude/settings.json" ".claude/settings.json"
        log_ok "  settings.json を v4.0.0 版に更新"
    else
        log_warn "  スキップ（カスタマイズ済み）: .claude/settings.json"
    fi
fi

# ============================================================
# 7/7: バージョン更新
# ============================================================
log_info "7/7: バージョン更新"
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
echo ""
log_info "v4.0.0 の主な変更:"
log_info "  - state.yaml → project_state.yaml + sessions/ に分割"
log_info "  - /patch コマンド（旧 /quickfix の後継）"
log_info "  - Handoff パケット（Iris → Worker 連携）"
log_info "  - DoR ゲート（Issue 品質チェック）"

if [ ${#CUSTOMIZED_FILES[@]} -gt 0 ]; then
    echo ""
    log_warn "以下のファイルはカスタマイズ済みのため更新されませんでした:"
    for cf in "${CUSTOMIZED_FILES[@]}"; do
        log_warn "  - $cf"
    done
    log_warn "最新版は ${FRAMEWORK}/examples/ を参照してください"
fi
