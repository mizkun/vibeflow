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
        "discuss:壁打ち（Discovery Phase）を開始"
        "conclude:議論を終了し開発フェーズに戻る"
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
            "discuss")
                create_discuss_command
                ;;
            "conclude")
                create_conclude_command
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
    local target_file=".claude/commands/next.md"
    mkdir -p ".claude/commands"
    if [ -f "$target_file" ]; then
        local backup_file="${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$target_file" "$backup_file"
        warning "既存ファイルをバックアップしました: $backup_file"
    fi
    cat > "$target_file" << 'NEXT_CMD_EOF'
# 次のステップへ進む

Execute the next workflow step following the VibeFlow role-based development system. This command should ALWAYS run in the main context, never as a subagent.

## Step 0: Phase Check
Load .vibe/state.yaml and check the `phase` field:
- If `phase: discovery` → ERROR: 「Discovery Phase が進行中です。/conclude で終了してから /next を使ってください。」
- If `phase: development` → Continue to Step 1

## Step 1: Read Current State
Load .vibe/state.yaml to understand:
- current_cycle
- current_step
- current_role
- next_step
- checkpoint_status

## Step 2: Determine Next Action
Based on current_step, identify:
- What needs to be done
- Which role should execute it
- Required permissions for this role
- Execution mode (solo/team/fork)

### Mode Determination
Check the workflow definition for the step's `mode`:

#### mode: solo (default)
Execute directly in main context. Standard role-based execution.

#### mode: team (Agent Team)
1. Check `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable
   - If not set → Fallback to solo mode with notice:
     「Agent Team が無効です。solo モードで実行します。有効にするには: export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1」
2. Spawn teammates as defined in team_config
3. If consensus_required: true, verify all teammates agree before proceeding

#### mode: fork (context: fork)
1. Execute step via context: fork, inheriting PM context
2. If fork unavailable → Fallback to solo mode
3. Return result summary to main context

## Step 3: Role Transition
Print role transition banner:

========================================
🔄 ROLE TRANSITION
Previous Step: [step_name] ([previous_role])
Current Step:  [next_step] ([new_role])
Issue:         [current_issue]
Now operating as: [NEW_ROLE]
Mode: [solo|team|fork]
Must read: [list of mandatory files]
Can modify: [list of editable files]
========================================

## Step 4: Execute as Role
Follow role-specific permissions strictly:

### For Product Manager Role (steps 1, 2):
- Must Read: vision.md, spec.md, plan.md, state.yaml, qa-reports/*
- Can Edit: plan.md, issues/*, state.yaml
- Can Create: issues/*
- Think like PM: Focus on user value and priorities

### For Engineer Role (steps 3, 4, 5, 6, 8, 10, 11):
- Must Read: spec.md, issues/*, src/*, state.yaml
- Can Edit: src/*, *.test.*, state.yaml
- Can Create: src/*, *.test.*
- Think like Engineer: Focus on implementation and code quality

### For QA Engineer Role (steps 6a, 7, 9):
- Must Read: spec.md, issues/*, src/*, state.yaml, qa-reports/*
- Can Edit: test-results.log, qa-reports/*, state.yaml
- Can Create: qa-reports/*, test-results.log
- Think like QA: Focus on validation and edge cases

### For Infrastructure Manager Role (steps 2.5, 6.5):
- Must Read: state.yaml, issues/*, .vibe/hooks/*
- Can Edit: .vibe/hooks/*, state.yaml
- Step 2.5: Read issue target files, update hook permissions, record in infra_log
- Step 6.5: Rollback permissions from infra_log, verify rollback_pending is false

## Step 5: Safety Rules Auto-Check
During execution, automatically enforce:
- CSS/HTML/TSX changes → apply atomic UI mode (1 change at a time)
- 2+ file rename/move/delete → create git checkpoint first
- Same fix approach failed before → check safety.failed_approach_log, force alternative if 2+ failures

## Step 6: Auto-Insert Steps
- After step 2a completes → automatically run step 2.5 (Hook Permission Setup)
- After step 6a completes → automatically run step 6.5 (Hook Rollback)
These steps do not require explicit /next invocation.

## Step 7: Update State
Update .vibe/state.yaml with:
- current_step: [next_step_number]
- current_role: [new_role]
- last_role_transition: [timestamp]
- last_completed_step: [previous_step]
- issues_created/issues_completed: update as needed

## Step 8: Checkpoint Handling
If step requires human validation:
- Print clear message about what needs review
- Save checkpoint state
- Wait for user confirmation before proceeding

IMPORTANT: Maintain all context in the main conversation. Do NOT use subagents for sequential workflow steps.
NEXT_CMD_EOF
    success "nextコマンドドキュメントを作成しました"
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
    local target_file=".claude/commands/exit-quickfix.md"
    mkdir -p ".claude/commands"
    if [ -f "$target_file" ]; then
        local backup_file="${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$target_file" "$backup_file"
        warning "既存ファイルをバックアップしました: $backup_file"
    fi
    cat > "$target_file" << 'EOF'
# Quick Fix モード終了

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

これらの情報はGitコミットメッセージに記録されます。
EOF
    success "exit-quickfixコマンドドキュメントを作成しました"
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

create_discuss_command() {
    local content='---
description: Start or continue a discovery discussion
---

# Discovery Discussion（壁打ち）を開始する

`/discuss [トピック]` で新しい議論を開始、`/discuss --continue` で前回のセッションを継続します。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、現在の phase を確認する。

### 2. 新規議論の場合（トピック指定あり）

1. **Phase 切り替え**: `phase: discovery` に更新
2. **DISC-ID 採番**: `.vibe/discussions/` 内の既存ファイルから最大番号を取得し +1
   - ファイルが存在しない場合は `DISC-001` から開始
3. **議論ファイル作成**: `.vibe/discussions/DISC-XXX-[topic-slug].md`
   - `.vibe/templates/discussion-template.md` のテンプレートを使用
   - トピック名、日付、IDを埋め込む
4. **State 更新**:
   ```yaml
   phase: discovery
   current_role: "Discussion Partner"
   discovery:
     id: "DISC-XXX"
     started: "YYYY-MM-DD"
     topic: "[トピック名]"
     sessions:
       - date: "YYYY-MM-DD"
         status: active
   ```
5. **ロール遷移バナー表示**:
   ```
   ========================================
   💬 DISCOVERY PHASE
   Topic: [トピック名]
   Discussion ID: DISC-XXX
   Now operating as: Discussion Partner
   ========================================
   ```
6. **壁打ち開始**: Discussion Partner として議論を開始

### 3. 継続の場合（--continue）

1. `discovery.id` から前回の議論ファイルを特定
2. 議論ファイルを読み込み、前回の内容をコンテキストとして復元
3. 新しいセッションエントリを追加
4. Discussion Partner として議論を再開

### 4. エラーケース
- トピックも `--continue` も指定されていない場合: 使い方を案内
- 既に discovery phase の場合（新規時）: 先に `/conclude` で終了するよう案内
- 継続する議論がない場合: 新規作成を案内

IMPORTANT: Discussion Partner ロールではファイル変更を行わない（discussions/ と state.yaml のみ例外）。コード生成・修正は一切行わず、議論のみに集中する。'

    create_file_with_backup ".claude/commands/discuss.md" "$content"
}

create_conclude_command() {
    local content='---
description: Conclude a discovery discussion and return to development
---

# 議論を終了し開発フェーズに戻る

`/conclude` で現在の Discovery Discussion を終了します。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、phase が `discovery` であることを確認する。
- `discovery` でない場合: 「現在議論中ではありません」とエラー表示

### 2. 議論の要約
1. 現在の議論ファイル（`.vibe/discussions/DISC-XXX-*.md`）を読み込む
2. 議論内容を要約し、以下をまとめる:
   - **合意事項（Agreements）**: 議論で合意した内容
   - **未解決事項（Open Issues）**: まだ結論が出ていない論点
   - **結論（Conclusion）**: 議論全体の結論
   - **アクションアイテム**: vision.md / spec.md / plan.md への反映事項

### 3. ユーザー承認
要約とアクションアイテムをユーザーに提示し、承認を求める:
```
📋 議論の要約

## 合意事項
- [合意1]
- [合意2]

## アクションアイテム
- [ ] vision.md に [内容] を追記
- [ ] spec.md に [内容] を追記
- [ ] plan.md に [内容] を追記

この内容で反映してよろしいですか？
```

### 4. 承認後の反映
ユーザーが承認した場合:
1. **ロール遷移**: Product Manager に切り替え
2. **ファイル反映**: 承認されたアクションアイテムを各ファイルに反映
   - vision.md への追記・修正
   - spec.md への追記・修正
   - plan.md への追記・修正
3. **議論ファイル更新**: Status を `concluded` に変更、Conclusion セクションを記入

### 5. Phase 復帰
```yaml
phase: development
current_role: "Product Manager"
discovery:
  id: null
  started: null
  topic: null
  sessions: []
```

### 6. 完了バナー表示
```
========================================
✅ DISCOVERY COMPLETE
Topic: [トピック名]
Discussion ID: DISC-XXX
Agreements: N items
Action items applied: N items
Returning to: Development Phase
========================================
```

IMPORTANT: 反映は必ずユーザーの承認を得てから行う。承認がない場合はファイル変更を行わず、議論ファイルの Status のみ更新する。'

    create_file_with_backup ".claude/commands/conclude.md" "$content"
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