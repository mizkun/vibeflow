#!/bin/bash
# VibeFlow Migration: v2.0.0 -> v3.0.0
# GitHub Issues, Iris, Multi-Terminal, 3-Tier Context

set -euo pipefail

PROJECT="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

cd "$PROJECT"

log_info "VibeFlow v2.0.0 → v3.0.0 マイグレーション開始"

# ============================================================
# 1/10: 新ディレクトリ作成
# ============================================================
log_info "1/10: ディレクトリ作成"
ensure_dir ".vibe/context"
ensure_dir ".vibe/references"
ensure_dir ".vibe/archive"
ensure_dir ".github/ISSUE_TEMPLATE"
ensure_dir ".vibe/tools"

# ============================================================
# 2/10: STATUS.md テンプレート生成
# ============================================================
log_info "2/10: STATUS.md テンプレート生成"
copy_if_absent "${FRAMEWORK}/examples/.vibe/context/STATUS.md" ".vibe/context/STATUS.md"

# ============================================================
# 3/10: GitHub Issue テンプレート配置
# ============================================================
log_info "3/10: GitHub Issue テンプレート配置"
copy_if_absent "${FRAMEWORK}/examples/.github/ISSUE_TEMPLATE/dev.md" ".github/ISSUE_TEMPLATE/dev.md"
copy_if_absent "${FRAMEWORK}/examples/.github/ISSUE_TEMPLATE/human.md" ".github/ISSUE_TEMPLATE/human.md"
copy_if_absent "${FRAMEWORK}/examples/.github/ISSUE_TEMPLATE/discussion.md" ".github/ISSUE_TEMPLATE/discussion.md"

# ============================================================
# 4/10: policy.yaml 更新 (discussion_partner → iris)
# ============================================================
log_info "4/10: policy.yaml 更新"
cp "${FRAMEWORK}/examples/.vibe/policy.yaml" ".vibe/policy.yaml"
log_ok "  policy.yaml を v3 に更新"

# ============================================================
# 5/10: state.yaml 構造更新
# ============================================================
log_info "5/10: state.yaml 構造更新"
# Use Python for safe YAML transformation
python3 - ".vibe/state.yaml" << 'PYTHON_SCRIPT'
import sys, re

state_file = sys.argv[1]

try:
    with open(state_file, 'r') as f:
        content = f.read()
except FileNotFoundError:
    print(f"[WARN] {state_file} not found, creating fresh v3 state", file=sys.stderr)
    content = ""

# Build new v3 state preserving key values
# Extract preservable values from v2
phase = "development"
phase_match = re.search(r'^phase:\s*(\S+)', content, re.MULTILINE)
if phase_match:
    phase = phase_match.group(1)

current_role = "Iris"
role_match = re.search(r'^current_role:\s*"?([^"\n]+)"?', content, re.MULTILINE)
if role_match:
    role = role_match.group(1).strip()
    if role == "Discussion Partner":
        current_role = "Iris"
    elif role == "Project Partner":
        current_role = "Iris"
    elif role == "P2":
        current_role = "Iris"
    else:
        current_role = role

# Check for current_issue
current_issue = "null"
issue_match = re.search(r'^current_issue:\s*"?([^"\n]*)"?', content, re.MULTILINE)
if issue_match and issue_match.group(1).strip() not in ('null', ''):
    current_issue = f'"{issue_match.group(1).strip()}"'

# Extract safety values if present
ui_mode = "atomic"
destructive_op = "require_confirmation"
max_fix = "3"

ui_match = re.search(r'ui_mode:\s*(\S+)', content)
if ui_match:
    ui_mode = ui_match.group(1)

dest_match = re.search(r'destructive_op:\s*(\S+)', content)
if dest_match:
    destructive_op = dest_match.group(1)

fix_match = re.search(r'max_fix_attempts:\s*(\d+)', content)
if fix_match:
    max_fix = fix_match.group(1)

# Write v3 state
new_state = f"""# VibeFlow v3 State
current_issue: {current_issue}
current_role: "{current_role}"

phase: {phase}

# Issues tracking (detailed state on GitHub labels)
issues_recent: []

# Quick fixes tracking
quick_fixes: []

# Discovery phase tracking
discovery:
  active: false
  last_session: null

# Safety tracking
safety:
  ui_mode: {ui_mode}
  destructive_op: {destructive_op}
  max_fix_attempts: {max_fix}
  failed_approach_log: []

# Infrastructure Manager audit log
infra_log:
  hook_changes: []
  rollback_pending: false
"""

with open(state_file, 'w') as f:
    f.write(new_state)

print(f"  state.yaml を v3 スキーマに変換")
PYTHON_SCRIPT
log_ok "  state.yaml 更新完了"

# ============================================================
# 6/10: ロールドキュメント更新
# ============================================================
log_info "6/10: ロールドキュメント更新"

# Archive old discussion-partner
if [ -f ".vibe/roles/discussion-partner.md" ]; then
    mv ".vibe/roles/discussion-partner.md" ".vibe/archive/$(date +%Y-%m-%d)-role-discussion-partner.md"
    log_ok "  discussion-partner.md → archive/"
fi

# Place new/updated roles
cp "${FRAMEWORK}/lib/roles/iris.md" ".vibe/roles/iris.md"
cp "${FRAMEWORK}/lib/roles/product-manager.md" ".vibe/roles/product-manager.md"
cp "${FRAMEWORK}/lib/roles/engineer.md" ".vibe/roles/engineer.md"
cp "${FRAMEWORK}/lib/roles/qa-engineer.md" ".vibe/roles/qa-engineer.md"
cp "${FRAMEWORK}/lib/roles/infra.md" ".vibe/roles/infra.md"
log_ok "  ロールドキュメントを v3 に更新"

# ============================================================
# 7/10: コマンドファイル更新
# ============================================================
log_info "7/10: コマンドファイル更新"

# Archive /next command (removed in v3)
if [ -f ".claude/commands/next.md" ]; then
    mv ".claude/commands/next.md" ".vibe/archive/$(date +%Y-%m-%d)-cmd-next.md"
    log_ok "  /next コマンドを archive/ に移動（v3で廃止）"
fi

# Update remaining commands
for cmd in discuss.md conclude.md progress.md healthcheck.md; do
    if [ -f "${FRAMEWORK}/lib/commands/${cmd}" ]; then
        cp "${FRAMEWORK}/lib/commands/${cmd}" ".claude/commands/${cmd}"
    fi
done
log_ok "  コマンドを v3 に更新"

# ============================================================
# 8/10: CLAUDE.md 更新
# ============================================================
log_info "8/10: CLAUDE.md 更新"
cp "${FRAMEWORK}/examples/CLAUDE.md" "CLAUDE.md"
log_ok "  CLAUDE.md を v3 に置換"

# ============================================================
# 9/10: discussions/ → references/ マイグレーション
# ============================================================
log_info "9/10: discussions/ → references/ マイグレーション"
if [ -d ".vibe/discussions" ]; then
    local_count=0
    for f in .vibe/discussions/*.md; do
        [ -f "$f" ] || continue
        basename_f=$(basename "$f")
        if [ "$basename_f" != ".gitkeep" ]; then
            cp "$f" ".vibe/references/${basename_f}"
            local_count=$((local_count + 1))
        fi
    done
    if [ "$local_count" -gt 0 ]; then
        log_ok "  ${local_count} ファイルを references/ にコピー"
    else
        log_warn "  discussions/ にファイルなし"
    fi
else
    log_warn "  .vibe/discussions/ が存在しません"
fi

# ============================================================
# 10/10: ツール配置 & Access Guard更新 & バージョン更新
# ============================================================
log_info "10/10: ツール・Hook・バージョン更新"

# Place issues migration tool
copy_if_absent "${FRAMEWORK}/examples/.vibe/tools/migrate-issues.sh" ".vibe/tools/migrate-issues.sh"
chmod +x ".vibe/tools/migrate-issues.sh" 2>/dev/null || true

# Update validate_access.py for v3 roles
if [ -f "${FRAMEWORK}/examples/.vibe/hooks/validate_access.py" ]; then
    cp "${FRAMEWORK}/examples/.vibe/hooks/validate_access.py" ".vibe/hooks/validate_access.py"
    chmod +x ".vibe/hooks/validate_access.py" 2>/dev/null || true
    log_ok "  validate_access.py を v3 に更新"
fi

# Version
echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "次のステップ（手動）:"
echo "  1. issues/ → GitHub Issues マイグレーション:"
echo "     bash .vibe/tools/migrate-issues.sh"
echo "  2. plan.md をロードマップ形式に更新"
echo "  3. /healthcheck でプロジェクトの整合性を確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
