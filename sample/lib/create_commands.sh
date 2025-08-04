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
        "healthcheck:整合性チェック"
        "abort:緊急停止"
        "next:次のステップへ"
        "restart-cycle:現在のIssueで最初から"
        "skip-tests:TDDをスキップ - NOT RECOMMENDED"
        "vibe-status:設定確認"
        "role-product_manager:PMロールに切り替え"
        "role-engineer:エンジニアロールに切り替え"
        "role-qa_engineer:QAロールに切り替え"
        "role-reset:通常モードに戻る"
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
            "abort")
                create_abort_command
                ;;
            "next")
                create_next_command
                ;;
            "restart-cycle")
                create_restart_cycle_command
                ;;
            "skip-tests")
                create_skip_tests_command
                ;;
            "vibe-status")
                create_vibe_status_command
                ;;
            "role-product_manager")
                create_role_pm_command
                ;;
            "role-engineer")
                create_role_engineer_command
                ;;
            "role-qa_engineer")
                create_role_qa_command
                ;;
            "role-reset")
                create_role_reset_command
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
    local content='# 整合性チェック

Perform a comprehensive health check of the project by: 1) Reading vision.md, spec.md, and plan.md to understand project goals, 2) Checking if spec.md aligns with vision.md, 3) Verifying plan.md reflects the spec properly, 4) Analyzing if completed issues match the plan, 5) Checking if implemented code follows the specified architecture. Report any discrepancies found and provide recommendations. Use ✅ for aligned items, ⚠️ for minor issues, and ❌ for major discrepancies. Present results in Japanese.'
    
    create_file_with_backup ".claude/commands/healthcheck.md" "$content"
}

create_abort_command() {
    local content='# 緊急停止

Immediately stop the current development cycle. First, confirm with the user in Japanese: '\''サイクルを中断しますか？現在の進捗は保存されますが、作業中の内容は失われる可能性があります。本当に中断する場合は「はい」と答えてください。'\'' If confirmed, update .vibe/state.yaml to mark the cycle as aborted and save the current state for potential recovery.'
    
    create_file_with_backup ".claude/commands/abort.md" "$content"
}

create_next_command() {
    local content='# 次のステップへ

Read .vibe/state.yaml to determine the current step and automatically proceed to the next step according to the Vibe Coding workflow. If at a human checkpoint, remind the user what needs to be done. Otherwise, delegate to the appropriate subagent for the next step.'
    
    create_file_with_backup ".claude/commands/next.md" "$content"
}

create_restart_cycle_command() {
    local content='# 現在のIssueで最初から

Reset the current issue'\''s progress and start over from Step 3 (branch creation). Useful when implementation has gone off track. Preserve the issue definition but reset all code changes. Confirm with user before proceeding.'
    
    create_file_with_backup ".claude/commands/restart-cycle.md" "$content"
}

create_skip_tests_command() {
    local content='# TDDをスキップ - NOT RECOMMENDED

Skip Step 4 (test writing) and proceed directly to implementation. This breaks the TDD principle and should only be used for prototyping or special circumstances. Warn the user in Japanese that this violates Vibe Coding principles and may lead to quality issues.'
    
    create_file_with_backup ".claude/commands/skip-tests.md" "$content"
}

create_vibe_status_command() {
    local content='# 設定確認

Display the current Vibe Coding setup including: available subagents in .claude/agents/, current contexts (vision.md, spec.md, plan.md existence), state.yaml validity, and any configuration issues. This helps debug setup problems.'
    
    create_file_with_backup ".claude/commands/vibe-status.md" "$content"
}

create_role_pm_command() {
    local content='# PMロールに切り替え

Switch to Product Manager role with restricted access. You can now: READ vision.md, spec.md, plan.md; EDIT plan.md only; CREATE issues. You CANNOT access any source code. This manual switch is for debugging or special tasks outside the normal flow. Confirm the role switch in Japanese.'
    
    create_file_with_backup ".claude/commands/role-product_manager.md" "$content"
}

create_role_engineer_command() {
    local content='# エンジニアロールに切り替え

Switch to Engineer role with restricted access. You can now: READ issues and code; EDIT and CREATE code. You CANNOT access vision.md, spec.md, or plan.md. This manual switch is for debugging or special implementation tasks outside the normal flow. Confirm the role switch in Japanese.'
    
    create_file_with_backup ".claude/commands/role-engineer.md" "$content"
}

create_role_qa_command() {
    local content='# QAロールに切り替え

Switch to QA Engineer role with restricted access. You can now: READ spec.md, issues, and code; You CANNOT edit any files. This role is for review and analysis only. This manual switch is for debugging or special review tasks outside the normal flow. Confirm the role switch in Japanese.'
    
    create_file_with_backup ".claude/commands/role-qa_engineer.md" "$content"
}

create_role_reset_command() {
    local content='# 通常モードに戻る

Remove all role-based access restrictions and return to normal Claude Code operation. This exits the Vibe Coding role system. Use this when you need unrestricted access for debugging or setup tasks. Confirm the reset in Japanese.'
    
    create_file_with_backup ".claude/commands/role-reset.md" "$content"
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_slash_commands
fi