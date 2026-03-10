#!/bin/bash
# VibeFlow Migration: v4.1.0 -> v5.0.0
# Iris-Only Architecture: single terminal, auto-dispatch, cross-review, auto-close

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${VIBEFLOW_DRY_RUN:-0}"
ALLOW_DIRTY="${VIBEFLOW_ALLOW_DIRTY:-0}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v4.1.0 → v5.0.0 マイグレーション開始"

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
    log_info "  - .claude/rules/ ディレクトリを新規配置 (iris-core, workflow-standard, workflow-patch, safety, playwright)"
    log_info "  - Skills 更新: vibeflow-kickoff, execute-issue, execute-all 追加、vibeflow-discuss を deprecated に更新"
    log_info "  - CLAUDE.md を v5 Iris-Only Architecture に更新"
    log_info "  - /discuss コマンドを deprecated に更新"
    log_info "  - dev.sh (Dev Launcher) を削除"
    log_info "  - Runtime モジュール (.vibe/runtime/) を配置"
    log_info "  - マルチターミナル参照を削除"
    log_info "  - バージョン → 5.0.0"
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
results = classify_project('${PROJECT}', '4.1.0', '${FRAMEWORK}/core/baselines')
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
# 2/8: .claude/rules/ 配置 (v5 新規)
# ============================================================
log_info "2/8: .claude/rules/ 配置"

ensure_dir ".claude/rules"

for rule_file in "${FRAMEWORK}/examples/.claude/rules/"*.md; do
    [ -f "$rule_file" ] || continue
    local_name=$(basename "$rule_file")
    dst=".claude/rules/${local_name}"

    if [ ! -f "$dst" ]; then
        cp "$rule_file" "$dst"
        log_ok "  新規配置: ${dst}"
    elif ! is_customized ".claude/rules/${local_name}"; then
        cp "$rule_file" "$dst"
        log_ok "  更新: ${dst}"
    else
        log_warn "  スキップ（カスタマイズ済み）: ${dst}"
    fi
done

# ============================================================
# 3/8: Skills 配置（vibeflow-kickoff 追加 + 既存更新）
# ============================================================
log_info "3/8: Skills 配置"

ALL_SKILLS=(
    "vibeflow-issue-template"
    "vibeflow-tdd"
    "vibeflow-discuss"
    "vibeflow-conclude"
    "vibeflow-progress"
    "vibeflow-healthcheck"
    "vibeflow-ui-smoke"
    "vibeflow-ui-explore"
    "vibeflow-kickoff"
    "vibeflow-execute-issue"
    "vibeflow-execute-all"
)

for skill_name in "${ALL_SKILLS[@]}"; do
    local_path=".claude/skills/${skill_name}/SKILL.md"
    src="${FRAMEWORK}/examples/.claude/skills/${skill_name}/SKILL.md"

    if [ ! -f "$src" ]; then
        log_warn "  ソースなし: ${src}"
        continue
    fi

    if [ ! -f "$local_path" ]; then
        mkdir -p ".claude/skills/${skill_name}"
        cp "$src" "$local_path"
        log_ok "  新規配置: ${local_path}"
    elif ! is_customized "$local_path"; then
        cp "$src" "$local_path"
        log_ok "  更新: ${local_path}"
    else
        log_warn "  スキップ（カスタマイズ済み）: ${local_path}"
    fi
done

# ============================================================
# 4/8: CLAUDE.md v5 更新
# ============================================================
log_info "4/8: CLAUDE.md v5 更新"

if [ -f "CLAUDE.md" ]; then
    cp "CLAUDE.md" "CLAUDE.md.v4.1-backup"
    log_ok "  バックアップ: CLAUDE.md.v4.1-backup"
fi

if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v5 に更新"
fi

# ============================================================
# 5/8: マルチターミナル廃止 — dev.sh 削除
# ============================================================
log_info "5/8: マルチターミナル廃止"

if [ -f "dev.sh" ]; then
    rm "dev.sh"
    log_ok "  削除: dev.sh"
fi

# Remove patch.sh if it exists (v5 uses /patch skill instead)
if [ -f "patch.sh" ]; then
    rm "patch.sh"
    log_ok "  削除: patch.sh"
fi

# ============================================================
# 6/8: Hooks + settings.json 更新
# ============================================================
log_info "6/8: Hooks + settings.json 更新"

# Update hooks
for hook in validate_access.py validate_write.sh validate_step7a.py task_complete.sh waiting_input.sh; do
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

# Update settings.json
if [ -f "${FRAMEWORK}/examples/.claude/settings.json" ]; then
    if ! is_customized ".claude/settings.json"; then
        cp "${FRAMEWORK}/examples/.claude/settings.json" ".claude/settings.json"
        log_ok "  更新: .claude/settings.json"
    else
        log_warn "  スキップ（カスタマイズ済み）: .claude/settings.json"
    fi
fi

# ============================================================
# 6b/8: Runtime モジュール配置 (v5 新規)
# ============================================================
log_info "6b/8: Runtime モジュール配置"

RUNTIME_SRC="${FRAMEWORK}/core/runtime"
RUNTIME_DST=".vibe/runtime"

if [ -d "$RUNTIME_SRC" ]; then
    ensure_dir "$RUNTIME_DST"
    for py_file in "${RUNTIME_SRC}/"*.py; do
        [ -f "$py_file" ] || continue
        cp "$py_file" "${RUNTIME_DST}/$(basename "$py_file")"
    done
    # __init__.py for import support
    touch "${RUNTIME_DST}/__init__.py"
    log_ok "  Runtime モジュールを ${RUNTIME_DST}/ に配置しました"
else
    log_warn "  Runtime ソースが見つかりません: ${RUNTIME_SRC}"
fi

# ============================================================
# 7/8: アップグレードレポート出力
# ============================================================
log_info "7/8: アップグレードレポート出力"

REPORT_DIR=".vibe/upgrade-reports"
ensure_dir "$REPORT_DIR"

REPORT_FILE="${REPORT_DIR}/v4.1.0_to_v5.0.0_$(date +%Y%m%d-%H%M%S).json"

if command -v python3 &>/dev/null; then
    python3 -c "
import json, datetime

customized = '''$(printf '%s\n' "${CUSTOMIZED_FILES[@]:-}")'''.strip().split('\n')
customized = [f for f in customized if f]

report = {
    'migration': 'v4.1.0 -> v5.0.0',
    'timestamp': datetime.datetime.now().isoformat(),
    'customized_files': customized,
    'actions': [
        'Rules: .claude/rules/ deployed (iris-core, workflow-standard, workflow-patch, safety, playwright)',
        'Skills: vibeflow-kickoff, execute-issue, execute-all added, all skills updated',
        'Runtime: .vibe/runtime/ deployed (qa_judge, dependency_analyzer, etc.)',
        'CLAUDE.md: rewritten for v5 Iris-Only Architecture',
        'Multi-terminal: dev.sh removed',
        'Hooks: updated for v5',
        'Architecture: Iris-Only (single terminal, auto-dispatch, cross-review)',
    ],
    'customized_count': len(customized),
    'breaking_changes': [
        '/discuss is deprecated (Iris is always active)',
        'Dev Terminal / Patch Terminal removed (Iris auto-dispatches)',
        'Multi-terminal workflow replaced with single Iris terminal',
    ],
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
log_info "v5.0.0 の主な変更:"
log_info "  - Iris-Only Architecture: 単一ターミナルで完結"
log_info "  - Agent Dispatch: Claude Code (デフォルト実装) + Codex (レビュー/フォールバック)"
log_info "  - Cross-Review: コーディングしなかった agent が自動レビュー"
log_info "  - Auto QA: テスト + レビュー結果で自動判定、qa:auto は自動クローズ"
log_info "  - .claude/rules/: ルール定義を分離（CLAUDE.md をスリム化）"
log_info "  - /discuss 廃止: Iris は常にアクティブ"

if [ ${#CUSTOMIZED_FILES[@]} -gt 0 ]; then
    echo ""
    log_warn "以下のファイルはカスタマイズ済みのため更新されませんでした:"
    for cf in "${CUSTOMIZED_FILES[@]}"; do
        log_warn "  - $cf"
    done
    log_warn "最新版は ${FRAMEWORK}/examples/ を参照してください"
fi
