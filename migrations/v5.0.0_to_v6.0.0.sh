#!/bin/bash
# VibeFlow Migration: v5.0.0 -> v6.0.0
# Structured Spec: loose spec.md is replaced by structured spec (Story/Contract).
# v5 の Iris-Only / Issue 駆動 / standard workflow / TDD / Cross-Review / QA はそのまま。

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${VIBEFLOW_DRY_RUN:-0}"
ALLOW_DIRTY="${VIBEFLOW_ALLOW_DIRTY:-0}"
FROM_VERSION="${VIBEFLOW_FROM_VERSION:-5.0.0}"
TO_VERSION="${VIBEFLOW_TO_VERSION:-6.0.0}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v${FROM_VERSION} → v${TO_VERSION} マイグレーション開始"

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
    log_info "  - .claude/rules/ を更新（新規: spec-loop.md — 構造化 spec ループ）"
    log_info "  - Skills を更新（vibeflow-kickoff を v6 Bootstrap/scratch 対応に）"
    log_info "  - CLAUDE.md を v6 に更新（CLAUDE.md.v5-backup にバックアップ）"
    log_info "  - .vibe/spec/{stories,contracts}/ を新規作成（構造化 spec の置き場所）"
    log_info "  - Hooks + settings.json を更新（validate_step7a.py = Spec Gate）"
    log_info "  - Runtime モジュールを更新（新規: spec_verify.py — spec drift 検証）"
    log_info "  - バージョン → ${TO_VERSION}"
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
results = classify_project('${PROJECT}', '${FROM_VERSION}', '${FRAMEWORK}/core/baselines')
for path, cls in sorted(results.items()):
    print(f'{path}|{cls}')
" 2>/dev/null || true)
fi

if [ ${#CUSTOMIZED_FILES[@]} -gt 0 ]; then
    log_warn "${#CUSTOMIZED_FILES[@]} 個のカスタマイズ済みファイルを検出（上書きしません）"
else
    log_ok "  カスタマイズ済みファイルなし（または v${FROM_VERSION} baseline 未登録）"
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
# 2/8: .claude/rules/ 更新（spec-loop.md 新規）
# ============================================================
log_info "2/8: .claude/rules/ 更新"

ensure_dir ".claude/rules"

for rule_file in "${FRAMEWORK}/examples/.claude/rules/"*.md; do
    [ -f "$rule_file" ] || continue
    rule_name=$(basename "$rule_file")
    dst=".claude/rules/${rule_name}"

    if [ ! -f "$dst" ]; then
        cp "$rule_file" "$dst"
        log_ok "  新規配置: ${dst}"
    elif ! is_customized ".claude/rules/${rule_name}"; then
        cp "$rule_file" "$dst"
        log_ok "  更新: ${dst}"
    else
        log_warn "  スキップ（カスタマイズ済み）: ${dst}"
    fi
done

# ============================================================
# 3/8: Skills 更新
# ============================================================
log_info "3/8: Skills 更新"

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
# 4/8: CLAUDE.md v6 更新
# ============================================================
log_info "4/8: CLAUDE.md v6 更新"

if [ -f "CLAUDE.md" ]; then
    cp "CLAUDE.md" "CLAUDE.md.v5-backup"
    log_ok "  バックアップ: CLAUDE.md.v5-backup"
fi

if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
    cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
    log_ok "  CLAUDE.md を v6 に更新"
fi

# ============================================================
# 5/8: 構造化 spec の置き場所を作成（v6 新規）
# ============================================================
log_info "5/8: 構造化 spec ディレクトリ作成"

ensure_dir ".vibe/spec/stories"
ensure_dir ".vibe/spec/contracts"

for keep in ".vibe/spec/stories/.gitkeep" ".vibe/spec/contracts/.gitkeep"; do
    [ -f "$keep" ] || touch "$keep"
done
log_ok "  .vibe/spec/{stories,contracts}/ を作成しました"

if [ -f "spec.md" ]; then
    log_warn "  緩い spec.md が残っています。v6 では構造化 spec (.vibe/spec/) を使います"
    log_warn "  /kickoff の Bootstrap で既存コードから As-Is spec を生成してください"
fi

# ============================================================
# 6/8: Hooks + settings.json 更新
# ============================================================
log_info "6/8: Hooks + settings.json 更新"

for hook in validate_access.py validate_write.sh validate_step7a.py task_complete.sh \
            waiting_input.sh checkpoint_alert.sh postwrite_lint.sh stop_test_gate.sh; do
    src="${FRAMEWORK}/examples/.vibe/hooks/${hook}"
    dst=".vibe/hooks/${hook}"
    if [ -f "$src" ]; then
        ensure_dir ".vibe/hooks"
        if ! is_customized ".vibe/hooks/${hook}"; then
            cp "$src" "$dst"
            chmod +x "$dst" 2>/dev/null || true
            log_ok "  更新: $dst"
        else
            log_warn "  スキップ（カスタマイズ済み）: $dst"
        fi
    fi
done

if [ -f "${FRAMEWORK}/examples/.claude/settings.json" ]; then
    if ! is_customized ".claude/settings.json"; then
        ensure_dir ".claude"
        cp "${FRAMEWORK}/examples/.claude/settings.json" ".claude/settings.json"
        log_ok "  更新: .claude/settings.json"
    else
        log_warn "  スキップ（カスタマイズ済み）: .claude/settings.json"
    fi
fi

# ============================================================
# 6b/8: Runtime モジュール更新（spec_verify.py 新規）
# ============================================================
log_info "6b/8: Runtime モジュール更新"

RUNTIME_SRC="${FRAMEWORK}/core/runtime"
RUNTIME_DST=".vibe/runtime"

if [ -d "$RUNTIME_SRC" ]; then
    ensure_dir "$RUNTIME_DST"
    for py_file in "${RUNTIME_SRC}/"*.py; do
        [ -f "$py_file" ] || continue
        cp "$py_file" "${RUNTIME_DST}/$(basename "$py_file")"
    done
    touch "${RUNTIME_DST}/__init__.py"
    log_ok "  Runtime モジュールを ${RUNTIME_DST}/ に更新しました（spec_verify.py を含む）"
else
    log_warn "  Runtime ソースが見つかりません: ${RUNTIME_SRC}"
fi

# ============================================================
# 7/8: アップグレードレポート出力
# ============================================================
log_info "7/8: アップグレードレポート出力"

REPORT_DIR=".vibe/upgrade-reports"
ensure_dir "$REPORT_DIR"

REPORT_FILE="${REPORT_DIR}/v${FROM_VERSION}_to_v${TO_VERSION}_$(date +%Y%m%d-%H%M%S).json"

if command -v python3 &>/dev/null; then
    python3 -c "
import json, datetime

customized = '''$(printf '%s\n' "${CUSTOMIZED_FILES[@]:-}")'''.strip().split('\n')
customized = [f for f in customized if f]

report = {
    'migration': 'v${FROM_VERSION} -> v${TO_VERSION}',
    'timestamp': datetime.datetime.now().isoformat(),
    'customized_files': customized,
    'actions': [
        'Rules: .claude/rules/ updated (spec-loop.md added — structured spec loop)',
        'Skills: all skills updated (vibeflow-kickoff v6 Bootstrap/scratch)',
        'CLAUDE.md: updated for v6 (backup at CLAUDE.md.v5-backup)',
        'Spec: .vibe/spec/{stories,contracts}/ created (structured spec home)',
        'Hooks: updated, validate_step7a.py is the v6 Spec Gate',
        'Runtime: .vibe/runtime/ updated (spec_verify.py added)',
    ],
    'customized_count': len(customized),
    'breaking_changes': [
        'loose spec.md is replaced by structured spec (.vibe/spec/ Story/Contract)',
        'PRs that change .vibe/spec/ require a human checkpoint (Spec Gate); qa:auto cannot self-approve',
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
echo "${TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${TO_VERSION}"

echo ""
log_ok "マイグレーション v${FROM_VERSION} → v${TO_VERSION} 完了"
echo ""
log_info "v${TO_VERSION} の主な変更:"
log_info "  - 構造化 spec: 緩い spec.md を Story / Contract に置き換え"
log_info "  - .vibe/spec/{stories,contracts}/: 仕様の置き場所（コードと 1:1）"
log_info "  - spec-loop.md: Issue = Spec 差分（As-Is → To-Be）のループモデル"
log_info "  - spec_verify.py / vibeflow spec-verify: spec とコードの drift 検証"
log_info "  - Spec Gate: spec を変更した PR は Human Checkpoint 必須"
echo ""
log_info "次のステップ: /kickoff の Bootstrap で既存コードから As-Is spec を生成してください"

if [ ${#CUSTOMIZED_FILES[@]} -gt 0 ]; then
    echo ""
    log_warn "以下のファイルはカスタマイズ済みのため更新されませんでした:"
    for cf in "${CUSTOMIZED_FILES[@]}"; do
        log_warn "  - $cf"
    done
    log_warn "最新版は ${FRAMEWORK}/examples/ を参照してください"
fi
