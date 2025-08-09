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
        "quickfix:Quick Fixモードに入る（軽微な修正用）"
        "exit-quickfix:Quick Fixモードを終了"
        "parallel-test:並列テスト実行（Subagent使用）"
        "run-e2e:E2Eテストを実行"
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
            "quickfix")
                create_quickfix_command
                ;;
            "exit-quickfix")
                create_exit_quickfix_command
                ;;
            "parallel-test")
                create_parallel_test_command
                ;;
            "run-e2e")
                create_run_e2e_command
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
    local content='# リポジトリ整合性チェック

Perform comprehensive repository consistency verification:

## 1. **Core State Verification**
- Read `.vibe/state.yaml` and validate:
  - current_step, current_issue, current_cycle, checkpoint_status
  - State transitions are valid (no skipped steps)
  - Current issue file exists in issues/ if set

## 2. **Repository Structure Check**  
- **Required files exist**: vision.md, spec.md, plan.md, CLAUDE.md
- **Directory structure**: .vibe/, .claude/, issues/, src/
- **Command files**: All slash commands (.claude/commands/) are present

## 3. **Git State Verification**
- Check current branch matches expected pattern:
  - main/master branch for Step 1-2 
  - feature/issue-XXX for Step 3-11
- Verify git status is clean or has expected changes
- Check if remote tracking is properly configured

## 4. **Step-Specific Artifact Verification**
- **Step 2**: Issue files exist and are properly formatted
- **Step 4**: Test files exist for current issue
- **Step 5-6**: Implementation files exist and tests can run
- **Step 7**: QA reports exist (if available)
- **Step 8+**: PR exists or merged properly

## 5. **Build & Dependencies Check**
- **Package files**: package.json, requirements.txt, Cargo.toml (if exist)
- **Build status**: Run build command if available
- **Test status**: Run test suite if available
- **Lint status**: Check code quality if configured

## 6. **Framework Version Compatibility**
- Verify CLAUDE.md matches current framework version
- Check if .vibe/ structure is up to date
- Validate agent definitions match current version

## 7. **Cross-Role Consistency**
- Verify plan.md progress matches completed issues
- Check QA reports are accessible to appropriate roles
- Validate issue-to-code traceability

**Report Format**:
- ✅ Component OK
- ⚠️ Minor issues (warnings) 
- ❌ Critical problems (must fix)
- 🔧 Suggested fixes

Present comprehensive results in Japanese with actionable recommendations.'
    
    create_file_with_backup ".claude/commands/healthcheck.md" "$content"
}

create_next_command() {
    local content='---
description: Proceed to next step with role-based execution
---

Execute the next step in the Vibe Coding development cycle:

## Step 1: Load Current State
Read .vibe/state.yaml to understand:
- current_cycle
- current_step  
- current_issue
- current_role
- last_completed_step

## Step 2: Determine Next Step and Role
Based on current_step, identify:
- Next step number and name
- Required role (PM, Engineer, or QA)
- Files that role can access

## Step 3: Announce Role Transition
Print clear transition message:
========================================
🔄 ROLE TRANSITION
Previous Step: [step_X] ([role])
Current Step:  [step_Y] ([new_role])
Issue:         [current_issue]
Now operating as: [NEW_ROLE]
Access granted to: [list of accessible files]
========================================

## Step 4: Execute Step with Role Constraints

### For Product Manager Role (steps 1-2):
- Must Read: vision.md, spec.md, plan.md, state.yaml, qa-reports/*
- Can Edit: plan.md, issues/*, state.yaml
- Can Create: issues/*
- Think like a PM: Focus on user value and requirements

### For Engineer Role (steps 3-6, 8, 10-11):  
- Must Read: spec.md, issues/*, src/*, state.yaml
- Can Edit: src/*, *.test.*, state.yaml
- Can Create: src/*, *.test.*
- Think like an engineer: Focus on implementation quality
- Note: Cannot access vision.md to avoid scope creep

### For QA Engineer Role (steps 6a, 7, 9):
- Must Read: spec.md, issues/*, src/*, state.yaml, qa-reports/*
- Can Edit: test-results.log, qa-reports/*, state.yaml
- Can Create: qa-reports/*, test-results.log
- Think like QA: Focus on validation and edge cases

## Step 5: Update State
Update .vibe/state.yaml with:
- current_step: [next_step_number]
- current_role: [new_role]
- last_role_transition: [timestamp]
- last_completed_step: [previous_step]
- issues_created/issues_completed: update as needed

## Step 6: Checkpoint Handling
If step requires human validation:
- Print clear message about what needs review
- Save checkpoint state
- Wait for user confirmation before proceeding

IMPORTANT: Maintain all context in the main conversation. Do NOT use subagents for sequential workflow steps.'
    
    create_file_with_backup ".claude/commands/next.md" "$content"
}


create_quickfix_command() {
    local content='---
description: Enter quick fix mode for minor adjustments
---

Enter Quick Fix Mode - a streamlined mode for minor changes:

## Activation
Print mode change:
🔧 ENTERING QUICK FIX MODE

Bypassing normal workflow for minor adjustments
Allowed: UI tweaks, typos, small bug fixes
Max scope: 5 files, <50 lines total changes

## Constraints in Quick Fix Mode
- Can modify any file directly
- Must document all changes
- Cannot add new features
- Cannot modify database schema
- Must exit properly with /exit-quickfix

## Process
1. Make the requested minor changes
2. Run relevant tests if any
3. Document changes in state.yaml under "quick_fixes"
4. Commit with prefix: "quickfix: [description]"

## 使用方法
`/quickfix [修正内容の説明]`

例:
- `/quickfix ボタンの色を青に変更`
- `/quickfix ヘッダーの余白を調整`
- `/quickfix タイポを修正`

Note: This mode operates in the main context, not as a subagent. All changes are made directly while maintaining context continuity.'
    
    create_file_with_backup ".claude/commands/quickfix.md" "$content"
}

create_exit_quickfix_command() {
    local content='# Quick Fix モード終了

Quick Fixモードを終了し、通常の開発サイクルに戻ります。

実行される処理:
1. 未コミットの変更があれば確認
2. ビルドの最終チェック
3. 通常モードに復帰

Quick Fixの制約チェック（自動ガード例）:
```bash
# 直近の変更（未コミット含む）の統計
git diff --shortstat HEAD 2>/dev/null || git diff --shortstat

# 変更行数・変更ファイル数の簡易チェック（50行/5ファイル以内）
changed_files=$(git diff --name-only | wc -l | tr -d ' ')
changed_lines=$(git diff --numstat | awk '{add+=$1;del+=$2} END{print add+del+0}')
if [ "${changed_files}" -gt 5 ] || [ "${changed_lines}" -gt 50 ]; then
  echo "❌ Quick Fixの上限を超えています（ファイル:${changed_files}, 行:${changed_lines}）。通常フローに戻してください。"
  exit 1
fi
```

Quick Fix中の変更内容:
- 変更されたファイルのリスト
- 実行されたコミット
- ビルドステータス

これらの情報はGitコミットメッセージに記録されます。'
    
    create_file_with_backup ".claude/commands/exit-quickfix.md" "$content"
}

create_parallel_test_command() {
    local content='---
description: Run independent tests in parallel using subagents
---

Run multiple independent test suites in parallel:

This is one of the few cases where we DO use subagents, because:
- Tests are independent and don'\''t need shared context
- Parallel execution saves significant time
- Results can be aggregated after completion

Execute:
1. Create subagent tasks for:
   - Unit tests
   - Integration tests  
   - E2E tests \(if configured\)
   
2. Each subagent should:
   - Run its specific test suite
   - Report results to a designated output file
   - Return success/failure status

3. After all complete:
   - Aggregate results
   - Update test-results.log
   - Report summary to user

Note: This is the ONLY command where we intentionally use subagents in the Vibe Coding workflow, as parallel test execution benefits from true parallelism without context sharing requirements.'
    
    create_file_with_backup ".claude/commands/parallel-test.md" "$content"
}

# run-e2e command creation
create_run_e2e_command() {
    local src="${SCRIPT_DIR}/commands/run-e2e.md"
    if [ -f "$src" ]; then
        mkdir -p ".claude/commands"
        cp "$src" ".claude/commands/run-e2e.md"
        success "run-e2eコマンドドキュメントを作成しました"
    else
        local content='# E2Eテストを実行

プロジェクトにPlaywrightが導入されている場合、`/run-e2e` で E2E テストを実行します。未導入の場合は導入手順（`npm install -D @playwright/test && npx playwright install`）を案内してください。'
        create_file_with_backup ".claude/commands/run-e2e.md" "$content"
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_slash_commands
fi