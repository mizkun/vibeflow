#!/bin/bash
# VibeFlow Migration: v4.0.0 -> v4.1.0
# Skills化, Playwright MCP, Plugin-compatible structure

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${VIBEFLOW_DRY_RUN:-0}"
ALLOW_DIRTY="${VIBEFLOW_ALLOW_DIRTY:-0}"

source "${FRAMEWORK}/lib/migration_helpers.sh"

cd "$PROJECT"

log_info "VibeFlow v4.0.0 → v4.1.0 マイグレーション開始"

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
    log_info "  - Skills 追加: vibeflow-ui-smoke, vibeflow-ui-explore"
    log_info "  - 既存 Skills の更新（カスタマイズ済みは保護）"
    log_info "  - Commands 互換レイヤの更新"
    log_info "  - Playwright MCP テンプレート配置 (.mcp.json.example)"
    log_info "  - Playwright スクリプト配置 (scripts/playwright_*.sh)"
    log_info "  - Plugin 構造配置 (.claude-plugin/plugin.json)"
    log_info "  - CLAUDE.md マネージドセクション更新"
    log_info "  - Hooks の更新（カスタマイズ済みは保護）"
    log_info "  - バージョン → 4.1.0"
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
results = classify_project('${PROJECT}', '4.0.0', '${FRAMEWORK}/core/baselines')
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
# 2/7: Skills 配置（新規 + 既存更新）
# ============================================================
log_info "2/7: Skills 配置"

ALL_SKILLS=(
    "vibeflow-issue-template"
    "vibeflow-tdd"
    "vibeflow-discuss"
    "vibeflow-conclude"
    "vibeflow-progress"
    "vibeflow-healthcheck"
    "vibeflow-ui-smoke"
    "vibeflow-ui-explore"
)

for skill_name in "${ALL_SKILLS[@]}"; do
    local_path=".claude/skills/${skill_name}/SKILL.md"
    src="${FRAMEWORK}/examples/.claude/skills/${skill_name}/SKILL.md"

    if [ ! -f "$src" ]; then
        log_warn "  ソースなし: ${src}"
        continue
    fi

    if [ ! -f "$local_path" ]; then
        # New skill — always deploy
        mkdir -p ".claude/skills/${skill_name}"
        cp "$src" "$local_path"
        log_ok "  新規配置: ${local_path}"
    elif ! is_customized "$local_path"; then
        # Existing stock — update
        cp "$src" "$local_path"
        log_ok "  更新: ${local_path}"
    else
        log_warn "  スキップ（カスタマイズ済み）: ${local_path}"
    fi
done

# ============================================================
# 3/7: Commands 互換レイヤ更新
# ============================================================
log_info "3/7: Commands 互換レイヤ更新"

ensure_dir ".claude/commands"

for cmd_file in "${FRAMEWORK}"/lib/commands/*.md; do
    [ -f "$cmd_file" ] || continue
    local_name=$(basename "$cmd_file")
    dst=".claude/commands/${local_name}"

    if [ ! -f "$dst" ]; then
        cp "$cmd_file" "$dst"
        log_ok "  新規配置: ${dst}"
    elif ! is_customized ".claude/commands/${local_name}"; then
        cp "$cmd_file" "$dst"
        log_ok "  更新: ${dst}"
    else
        log_warn "  スキップ（カスタマイズ済み）: ${dst}"
    fi
done

# ============================================================
# 4/7: Playwright MCP テンプレート + スクリプト配置
# ============================================================
log_info "4/7: Playwright MCP + スクリプト配置"

# .mcp.json.example
if [ -f "${FRAMEWORK}/examples/.mcp.json.example" ]; then
    copy_if_absent "${FRAMEWORK}/examples/.mcp.json.example" ".mcp.json.example"
fi

# Playwright scripts
ensure_dir "scripts"
for script_name in playwright_smoke.sh playwright_open_report.sh playwright_trace_pack.sh; do
    src="${FRAMEWORK}/examples/scripts/${script_name}"
    dst="scripts/${script_name}"
    if [ -f "$src" ]; then
        if [ ! -f "$dst" ]; then
            cp "$src" "$dst"
            chmod +x "$dst"
            log_ok "  新規配置: ${dst}"
        elif ! is_customized "scripts/${script_name}"; then
            cp "$src" "$dst"
            chmod +x "$dst"
            log_ok "  更新: ${dst}"
        else
            log_warn "  スキップ（カスタマイズ済み）: ${dst}"
        fi
    fi
done

# ============================================================
# 5/7: Plugin 構造配置 + Hooks 更新 + CLAUDE.md 更新
# ============================================================
log_info "5/7: Plugin 構造 + Hooks + CLAUDE.md 更新"

# Plugin metadata
if [ -f "${FRAMEWORK}/.claude-plugin/plugin.json" ]; then
    ensure_dir ".claude-plugin"
    copy_if_absent "${FRAMEWORK}/.claude-plugin/plugin.json" ".claude-plugin/plugin.json"
fi

# Hooks (update stock, protect customized)
for hook in validate_access.py validate_write.sh validate_step7a.py task_complete.sh waiting_input.sh checkpoint_alert.sh; do
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

# CLAUDE.md managed section update
if [ -f "CLAUDE.md" ]; then
    if grep -q "VF:BEGIN" "CLAUDE.md"; then
        if command -v python3 &>/dev/null && [ -f "${FRAMEWORK}/core/generators/generate_claude_md.py" ]; then
            cp "CLAUDE.md" "CLAUDE.md.v4.0-backup"
            log_ok "  バックアップ: CLAUDE.md.v4.0-backup"
            python3 "${FRAMEWORK}/core/generators/generate_claude_md.py" \
                --input "CLAUDE.md" \
                --schema-dir "${FRAMEWORK}/core/schema" \
                --output "CLAUDE.md" 2>/dev/null
            log_ok "  マネージドセクションを再生成（手書き部分は保持）"
        else
            log_warn "  python3 またはジェネレータが見つからないため CLAUDE.md 更新をスキップ"
        fi
    else
        log_warn "  CLAUDE.md に VF:BEGIN/VF:END マーカーがありません（スキップ）"
    fi

    # Append UI skills to Available Skills section if missing
    if ! grep -q "vibeflow-ui-smoke" "CLAUDE.md"; then
        if grep -q "vibeflow-tdd" "CLAUDE.md"; then
            # Insert after vibeflow-tdd line (macOS sed -i '' / GNU sed -i)
            sed -i '' '/vibeflow-tdd/a\
- `vibeflow-ui-smoke`: Run Playwright smoke tests for quick UI health check\
- `vibeflow-ui-explore`: Exploratory UI verification using Playwright MCP
' "CLAUDE.md" 2>/dev/null || \
            sed -i '/vibeflow-tdd/a\- `vibeflow-ui-smoke`: Run Playwright smoke tests for quick UI health check\n- `vibeflow-ui-explore`: Exploratory UI verification using Playwright MCP' "CLAUDE.md" 2>/dev/null || true
            log_ok "  Available Skills に UI skills を追加"
        elif grep -q "Skills location" "CLAUDE.md"; then
            # Available Skills section exists but without vibeflow-tdd anchor
            sed -i '' '/Skills location/i\
- `vibeflow-ui-smoke`: Run Playwright smoke tests for quick UI health check\
- `vibeflow-ui-explore`: Exploratory UI verification using Playwright MCP
' "CLAUDE.md" 2>/dev/null || \
            sed -i '/Skills location/i\- `vibeflow-ui-smoke`: Run Playwright smoke tests for quick UI health check\n- `vibeflow-ui-explore`: Exploratory UI verification using Playwright MCP' "CLAUDE.md" 2>/dev/null || true
            log_ok "  Available Skills に UI skills を追加"
        else
            # No anchor found — append section at end
            cat >> "CLAUDE.md" << 'SKILLEOF'

### UI Skills (v4.1.0)
- `vibeflow-ui-smoke`: Run Playwright smoke tests for quick UI health check
- `vibeflow-ui-explore`: Exploratory UI verification using Playwright MCP
SKILLEOF
            log_ok "  UI Skills セクションを末尾に追加"
        fi
    fi
else
    if [ -f "${FRAMEWORK}/examples/CLAUDE.md" ]; then
        cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
        log_ok "  CLAUDE.md を新規作成"
    fi
fi

# ============================================================
# 6/7: アップグレードレポート出力
# ============================================================
log_info "6/7: アップグレードレポート出力"

REPORT_DIR=".vibe/upgrade-reports"
ensure_dir "$REPORT_DIR"

REPORT_FILE="${REPORT_DIR}/v4.0.0_to_v4.1.0_$(date +%Y%m%d-%H%M%S).json"

if command -v python3 &>/dev/null; then
    python3 -c "
import json, datetime

customized = '''$(printf '%s\n' "${CUSTOMIZED_FILES[@]:-}")'''.strip().split('\n')
customized = [f for f in customized if f]

report = {
    'migration': 'v4.0.0 -> v4.1.0',
    'timestamp': datetime.datetime.now().isoformat(),
    'customized_files': customized,
    'actions': [
        'Skills: 8 skills deployed (2 new UI skills + 6 existing updated)',
        'Commands: compatibility wrappers updated',
        'Playwright: .mcp.json.example + 3 scripts deployed',
        'Plugin: .claude-plugin/plugin.json deployed',
        'Hooks: stock hooks updated (customized preserved)',
        'CLAUDE.md: managed sections regenerated',
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
# 7/7: バージョン更新
# ============================================================
log_info "7/7: バージョン更新"
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
echo ""
log_info "v4.1.0 の主な変更:"
log_info "  - Skills 化: discuss/conclude/progress/healthcheck を Skills に移行"
log_info "  - UI Skills: vibeflow-ui-smoke, vibeflow-ui-explore 追加"
log_info "  - Playwright MCP: .mcp.json.example + スクリプト配置"
log_info "  - Plugin 構造: .claude-plugin/plugin.json 追加"

if [ ${#CUSTOMIZED_FILES[@]} -gt 0 ]; then
    echo ""
    log_warn "以下のファイルはカスタマイズ済みのため更新されませんでした:"
    for cf in "${CUSTOMIZED_FILES[@]}"; do
        log_warn "  - $cf"
    done
    log_warn "最新版は ${FRAMEWORK}/examples/ を参照してください"
fi
