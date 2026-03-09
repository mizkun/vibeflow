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
# 0/8: Pre-flight — dirty tree check
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
# 0b/8: Dry-run guard
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
# 1/8: ファイル分類（baseline hash 照合）
# ============================================================
log_info "1/8: ファイル分類"

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

# Helper: check if a file is customized
is_customized() {
    local path="$1"
    for cf in "${CUSTOMIZED_FILES[@]:-}"; do
        [ "$cf" = "$path" ] && return 0
    done
    return 1
}

# ============================================================
# 2/8: state.yaml 分割 → project_state.yaml + sessions/
# ============================================================
log_info "2/8: state.yaml 分割"

if [ -f ".vibe/state.yaml" ]; then
    # Backup
    cp ".vibe/state.yaml" ".vibe/state.yaml.v3-backup"
    log_ok "  バックアップ: .vibe/state.yaml.v3-backup"

    # Create sessions directory
    ensure_dir ".vibe/sessions"

    # Split using Python for YAML parsing — schema-compliant output
    if command -v python3 &>/dev/null; then
        python3 -c "
import yaml, sys, os

with open('.vibe/state.yaml', 'r') as f:
    state = yaml.safe_load(f) or {}

# Extract safety sub-fields for split
old_safety = state.get('safety', {})

# --- project_state.yaml (matches core/schema/project_state.yaml) ---
project_state = {
    'active_issue': state.get('current_issue', None),
    'active_pr': None,
    'current_phase': state.get('phase', 'development'),
    'patch_runs': [],
    'backlog_summary': {
        'ready': 0,
        'in_progress': 0,
        'blocked': 0,
    },
    'safety': {
        'ui_mode': old_safety.get('ui_mode', 'atomic'),
        'destructive_op': old_safety.get('destructive_op', 'require_confirmation'),
    },
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

# --- sessions/iris-main.yaml (matches core/schema/session_state.yaml) ---
session = {
    'session_id': 'iris-main',
    'kind': 'iris',
    'current_role': state.get('current_role', 'Iris'),
    'current_step': state.get('current_step', None),
    'attached_issue': None,
    'worktree': None,
    'status': 'active',
    'safety': {
        'max_fix_attempts': old_safety.get('max_fix_attempts', 3),
        'failed_approach_log': old_safety.get('failed_approach_log', []),
    },
    'infra_log': state.get('infra_log', {
        'hook_changes': [],
        'rollback_pending': False,
    }),
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
# 3/8: /patch コマンド配置
# ============================================================
log_info "3/8: /patch コマンド配置"
ensure_dir ".claude/commands"

if [ -f "${FRAMEWORK}/lib/commands/patch.md" ]; then
    copy_if_absent "${FRAMEWORK}/lib/commands/patch.md" ".claude/commands/patch.md"
else
    log_warn "  patch.md のソースが見つかりません"
fi

# /quickfix alias も更新（カスタマイズされていなければ）
if [ -f "${FRAMEWORK}/lib/commands/quickfix.md" ]; then
    if ! is_customized ".claude/commands/quickfix.md"; then
        cp "${FRAMEWORK}/lib/commands/quickfix.md" ".claude/commands/quickfix.md"
        log_ok "  quickfix.md を /patch alias 版に更新"
    else
        log_warn "  quickfix.md はカスタマイズ済み（スキップ）"
    fi
fi

# ============================================================
# 4/8: ストックファイル更新（カスタマイズ済みは保護）
# ============================================================
log_info "4/8: ストックファイル更新"

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
# 5/8: CLAUDE.md マネージドセクション再生成（partial update）
# ============================================================
log_info "5/8: CLAUDE.md マネージドセクション再生成"

if [ -f "CLAUDE.md" ]; then
    if grep -q "VF:BEGIN" "CLAUDE.md"; then
        # Has markers — use generate_claude_md.py for partial update
        if command -v python3 &>/dev/null; then
            # Backup first
            cp "CLAUDE.md" "CLAUDE.md.v3-backup"
            log_ok "  バックアップ: CLAUDE.md.v3-backup"

            python3 "${FRAMEWORK}/core/generators/generate_claude_md.py" \
                --input "CLAUDE.md" \
                --schema-dir "${FRAMEWORK}/core/schema" \
                --output "CLAUDE.md" 2>/dev/null
            log_ok "  マネージドセクションを再生成（手書き部分は保持）"
        else
            log_warn "  python3 がないため CLAUDE.md の更新をスキップ"
        fi
    else
        log_warn "  CLAUDE.md に VF:BEGIN/VF:END マーカーがありません"
        log_warn "  マネージドセクションの自動更新をスキップします"
        log_warn "  手動で examples/CLAUDE.md のマーカーを追加してください"
    fi
else
    # No CLAUDE.md — copy from examples as initial
    if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
        cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
        log_ok "  CLAUDE.md を新規作成"
    fi
fi

# ============================================================
# 6/8: settings.json 更新
# ============================================================
log_info "6/8: settings.json 更新"
if [ -f "${FRAMEWORK}/examples/.claude/settings.json" ]; then
    if ! is_customized ".claude/settings.json"; then
        cp "${FRAMEWORK}/examples/.claude/settings.json" ".claude/settings.json"
        log_ok "  settings.json を v4.0.0 版に更新"
    else
        log_warn "  スキップ（カスタマイズ済み）: .claude/settings.json"
    fi
fi

# ============================================================
# 7/8: アップグレードレポート出力
# ============================================================
log_info "7/8: アップグレードレポート出力"

REPORT_DIR=".vibe/upgrade-reports"
ensure_dir "$REPORT_DIR"

REPORT_FILE="${REPORT_DIR}/v3.5.0_to_v4.0.0_$(date +%Y%m%d-%H%M%S).json"

if command -v python3 &>/dev/null; then
    python3 -c "
import json, datetime

customized = '''$(printf '%s\n' "${CUSTOMIZED_FILES[@]:-}")'''.strip().split('\n')
customized = [f for f in customized if f]

report = {
    'migration': 'v3.5.0 -> v4.0.0',
    'timestamp': datetime.datetime.now().isoformat(),
    'customized_files': customized,
    'actions': [
        'state.yaml split -> project_state.yaml + sessions/iris-main.yaml',
        'state.yaml backed up as .v3-backup',
        '/patch command placed',
        'CLAUDE.md managed sections regenerated',
        'stock files updated (customized files preserved)',
    ],
    'customized_count': len(customized),
}

with open('${REPORT_FILE}', 'w') as f:
    json.dump(report, f, indent=2, ensure_ascii=False)
    f.write('\n')
" 2>/dev/null
    log_ok "  レポート: ${REPORT_FILE}"
else
    log_warn "  python3 がないためレポート出力をスキップ"
fi

# ============================================================
# 8/8: バージョン更新
# ============================================================
log_info "8/8: バージョン更新"
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
