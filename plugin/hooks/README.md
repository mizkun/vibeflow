# Plugin Hooks Mapping

VibeFlow が提供する Claude Code Hooks の一覧と配置マッピング。

## Source of Truth

`examples/.vibe/hooks/` が実体の置き場所です。

## Provided Hooks

### Guard Hooks (PreToolUse)

| Hook | Source | Target | Purpose |
|------|--------|--------|---------|
| `validate_access.py` | `examples/.vibe/hooks/validate_access.py` | `.vibe/hooks/validate_access.py` | ロールベースアクセス制御 |
| `validate_write.sh` | `examples/.vibe/hooks/validate_write.sh` | `.vibe/hooks/validate_write.sh` | plans/ 書き込みブロック |
| `validate_step7a.py` | `examples/.vibe/hooks/validate_step7a.py` | `.vibe/hooks/validate_step7a.py` | Step 7a QA チェックポイント |

### Notification Hooks (PostToolUse / Stop)

| Hook | Source | Target | Purpose |
|------|--------|--------|---------|
| `task_complete.sh` | `examples/.vibe/hooks/task_complete.sh` | `.vibe/hooks/task_complete.sh` | 操作完了通知音 |
| `waiting_input.sh` | `examples/.vibe/hooks/waiting_input.sh` | `.vibe/hooks/waiting_input.sh` | 入力待ち通知音 |
| `checkpoint_alert.sh` | `examples/.vibe/hooks/checkpoint_alert.sh` | `.vibe/hooks/checkpoint_alert.sh` | Step 7a ブロック通知音 |

## Hook Registration

Hooks は `.claude/settings.json` に登録されます。Standalone では `lib/create_claude_settings.sh` が生成、Plugin install では settings への merge が必要です。

## Standalone 対応

Standalone setup では `lib/create_access_guard.sh` と `lib/create_claude_settings.sh` が配置を担当します。
