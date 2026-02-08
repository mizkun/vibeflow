#!/bin/bash
set -euo pipefail

# VibeFlow Migration: v1.0.0 → v2.0.0

source "${VIBEFLOW_FRAMEWORK_DIR}/lib/migration_helpers.sh"

PROJECT="${VIBEFLOW_PROJECT_DIR}"
FRAMEWORK="${VIBEFLOW_FRAMEWORK_DIR}"

cd "$PROJECT"

# ============================================================
# 1. 新規ディレクトリの作成
# ============================================================
log_info "1/8: ディレクトリ作成"
ensure_dir ".vibe/discussions"
ensure_dir ".vibe/backups"

# ============================================================
# 2. 新規ロール・テンプレートの追加
# ============================================================
log_info "2/8: ロール・テンプレートの追加"
copy_if_absent "${FRAMEWORK}/lib/roles/discussion-partner.md"      ".vibe/roles/discussion-partner.md"
copy_if_absent "${FRAMEWORK}/lib/roles/infra.md"                   ".vibe/roles/infra.md"
copy_if_absent "${FRAMEWORK}/lib/templates/discussion-template.md" ".vibe/templates/discussion-template.md"

# ============================================================
# 3. 新規コマンドの追加
# ============================================================
log_info "3/8: コマンドの追加"
copy_if_absent "${FRAMEWORK}/lib/commands/discuss.md"   ".claude/commands/discuss.md"
copy_if_absent "${FRAMEWORK}/lib/commands/conclude.md"  ".claude/commands/conclude.md"

# /next: 既存があれば拡張追記、なければコピー
if [ -f ".claude/commands/next.md" ]; then
  append_section_if_absent ".claude/commands/next.md" \
    "## /next 実行時の事前チェック（v2 追加）" \
    "$(cat "${FRAMEWORK}/lib/commands/next-v2-extension.md")"
else
  copy_if_absent "${FRAMEWORK}/lib/commands/next.md" ".claude/commands/next.md"
fi

# ============================================================
# 4. state.yaml のマイグレーション
# ============================================================
log_info "4/8: state.yaml の拡張"

add_yaml_field_if_absent ".vibe/state.yaml" '.phase' '"development"'
add_yaml_field_if_absent ".vibe/state.yaml" '.discovery' '{"id":"","started":"","topic":"","sessions":0}'
add_yaml_field_if_absent ".vibe/state.yaml" '.safety' '{"ui_mode":"atomic","destructive_op":"checkpoint_first","max_fix_attempts":2,"failed_approach_log":[]}'
add_yaml_field_if_absent ".vibe/state.yaml" '.infra_log' '{"step":"","hook_changes":[],"rollback_pending":false}'

# ============================================================
# 5. CLAUDE.md の更新
# ============================================================
log_info "5/8: CLAUDE.md の更新"

# Safety Rules の追記
if [ -f "${FRAMEWORK}/lib/claude-md-safety-rules.md" ]; then
  SAFETY_CONTENT=$(cat "${FRAMEWORK}/lib/claude-md-safety-rules.md")
  append_section_if_absent "CLAUDE.md" "## Safety Rules" "$SAFETY_CONTENT"
fi

# ワークフロー定義の更新
if [ -f "${FRAMEWORK}/lib/claude-md-workflow-v2.md" ]; then
  WORKFLOW_CONTENT=$(cat "${FRAMEWORK}/lib/claude-md-workflow-v2.md")

  if grep -qF "## Development Workflow" "CLAUDE.md" 2>/dev/null; then
    replace_section "CLAUDE.md" "## Development Workflow" "## " "$WORKFLOW_CONTENT"
  elif grep -qF "## workflow" "CLAUDE.md" 2>/dev/null; then
    replace_section "CLAUDE.md" "## workflow" "## " "$WORKFLOW_CONTENT"
  else
    append_section_if_absent "CLAUDE.md" "## Development Workflow" "$WORKFLOW_CONTENT"
  fi
fi

# ============================================================
# 6. validate_write.sh の配置
# ============================================================
log_info "6/8: validate_write.sh の配置"

if [ -f "${FRAMEWORK}/examples/.vibe/hooks/validate_write.sh" ]; then
  copy_if_absent "${FRAMEWORK}/examples/.vibe/hooks/validate_write.sh" ".vibe/hooks/validate_write.sh"
  chmod +x ".vibe/hooks/validate_write.sh" 2>/dev/null || true
else
  log_warn "  validate_write.sh テンプレートが見つかりません。スキップ。"
fi

# ============================================================
# 7. Issue テンプレートの更新
# ============================================================
log_info "7/8: Issue テンプレートの拡張"

IMPL_PLAN='## Implementation Plan
（Engineer が Step 4 開始時にここに記述）
- 対象ファイル: [src/..., tests/...]
- テスト対象: [tests/...]
- 依存 issue: [なし / TUNE-XXX]
- 並列実行可否: [可 / 不可（理由: ...）]

## Progress
- [ ] テスト作成
- [ ] 実装
- [ ] リファクタリング'

if [ -f ".vibe/templates/issue-templates.md" ]; then
  append_section_if_absent ".vibe/templates/issue-templates.md" "## Implementation Plan" "$IMPL_PLAN"
else
  log_warn "  issue-templates.md が見つかりません。スキップ。"
fi

# ============================================================
# 8. バージョンファイルの作成
# ============================================================
log_info "8/8: バージョン記録"

echo "${VIBEFLOW_TO_VERSION}" > ".vibe/version"
log_ok "  バージョン: v${VIBEFLOW_TO_VERSION}"

echo ""
log_ok "マイグレーション v${VIBEFLOW_FROM_VERSION} → v${VIBEFLOW_TO_VERSION} 完了"
