#!/bin/bash

# Vibe Coding Framework - Slash Commands Creation
# This script creates slash commands for Claude Code

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create slash commands
create_slash_commands() {
    section "スラッシュコマンドを作成中"
    
    local commands=(
        "progress:現在の進捗確認"
        "healthcheck:状態ファイルと実際の整合性チェック"
        "next:次のステップへ進む"
        "abort:緊急停止（現在の処理を中断）"
        "quickfix:Quick Fixモードに入る（軽微な修正用）"
        "exit-quickfix:Quick Fixモードを終了"
    )
    
    local total=${#commands[@]}
    local current=0
    
    for cmd_info in "${commands[@]}"; do
        current=$((current + 1))
        IFS=':' read -r cmd_name cmd_title <<< "$cmd_info"
        
        show_progress $current $total "コマンド作成 (${cmd_name})"
        
        case "$cmd_name" in
            "progress")
                create_progress_command
                ;;
            "healthcheck")
                create_healthcheck_command
                ;;
            "next")
                create_next_command
                ;;
            "abort")
                create_abort_command
                ;;
            "quickfix")
                create_quickfix_command
                ;;
            "exit-quickfix")
                create_exit_quickfix_command
                ;;
        esac
    done
    
    success "スラッシュコマンドの作成が完了しました"
    return 0
}

# Individual command creation functions
create_progress_command() {
    local content='# 現在の進捗確認

Read .vibe/state.yaml and provide a comprehensive progress report including: current cycle number, current step, current issue being worked on, completed checkpoints, next required action, and remaining TODOs from plan.md. Present the information in Japanese with visual indicators (emojis) for better readability.'
    
    create_file_with_backup ".claude/commands/progress.md" "$content"
}

create_healthcheck_command() {
    local content='# 状態整合性チェック

Check the consistency between .vibe/state.yaml and the actual project state:

1. **Read state.yaml** to get:
   - current_step
   - current_issue
   - current_cycle
   - checkpoint_status

2. **Verify actual state**:
   - If current_issue is set, check if that issue file exists in issues/
   - Check Git branch matches expected pattern (feature/issue-XXX) if step >= 3
   - Verify expected artifacts exist based on current_step:
     - Step 2: Issue files should exist
     - Step 4: Test files should exist
     - Step 5-6: Implementation files should exist
   - Check if checkpoint status matches actual progress

3. **Report discrepancies**:
   - ✅ State matches reality
   - ⚠️ Minor inconsistencies (e.g., branch name)
   - ❌ Major problems (e.g., missing issue file, wrong step)

4. **Suggest fixes** if problems found:
   - Correct state.yaml values
   - Missing files that should be created
   - Next logical action to take

Present results in Japanese with clear status indicators.'
    
    create_file_with_backup ".claude/commands/healthcheck.md" "$content"
}

create_abort_command() {
    local content='# 緊急停止

Immediately stop the current development cycle. First, confirm with the user in Japanese: '\''サイクルを中断しますか？現在の進捗は保存されますが、作業中の内容は失われる可能性があります。本当に中断する場合は「はい」と答えてください。'\'' If confirmed, update .vibe/state.yaml to mark the cycle as aborted and save the current state for potential recovery.'
    
    create_file_with_backup ".claude/commands/abort.md" "$content"
}

create_next_command() {
    local content='# 次のステップへ / 開発サイクルを開始

Read .vibe/state.yaml to determine the current step and automatically proceed to the next step according to the Vibe Coding workflow. 

This command can be used to:
- Start a new development cycle from the beginning (Step 1: Plan Review)
- Continue to the next step in an ongoing cycle
- Resume after a human checkpoint

If at a human checkpoint, remind the user what needs to be done. Otherwise, delegate to the appropriate subagent for the next step.'
    
    create_file_with_backup ".claude/commands/next.md" "$content"
}


create_quickfix_command() {
    local content='# Quick Fix モード

通常の開発サイクルを一時停止し、軽微な修正を素早く行うモードに入ります。

## 使用方法
`/quickfix [修正内容の説明]`

例:
- `/quickfix ボタンの色を青に変更`
- `/quickfix ヘッダーの余白を調整`
- `/quickfix タイポを修正`

## 許可される変更
- UIスタイルの調整（色、間隔、フォント）
- テキストの修正（タイポ、ラベル変更）
- 小さなバグ修正（50行以内）
- エラーメッセージの改善

## 制限事項
- 新機能の追加は不可
- データベース構造の変更は不可
- APIの変更は不可
- 5ファイル以上の変更は不可

このコマンドを実行すると:
1. quickfix-auto サブエージェントが起動
2. 指定された修正を実装
3. ビルドチェックを実行
4. 変更をコミット

通常のサイクルに戻るには `/exit-quickfix` を使用してください。'
    
    create_file_with_backup ".claude/commands/quickfix.md" "$content"
}

create_exit_quickfix_command() {
    local content='# Quick Fix モード終了

Quick Fixモードを終了し、通常の開発サイクルに戻ります。

実行される処理:
1. 未コミットの変更があれば確認
2. ビルドの最終チェック
3. 通常モードに復帰

Quick Fix中の変更内容:
- 変更されたファイルのリスト
- 実行されたコミット
- ビルドステータス

これらの情報はGitコミットメッセージに記録されます。'
    
    create_file_with_backup ".claude/commands/exit-quickfix.md" "$content"
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_slash_commands
fi