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
        "run-e2e:E2Eテスト実行"
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



create_run_e2e_command() {
    local content='---
description: Execute E2E tests with Playwright
---

Execute E2E tests using Playwright:

## Prerequisites Check
1. Verify Playwright is installed:
   - Check if `node_modules/@playwright/test` exists
   - If not, run: `npm install @playwright/test`
   - Install browsers if needed: `npx playwright install`

## Test Execution
1. **Environment Setup**
   - Ensure development server is running (if required)
   - Check test database is prepared (if applicable)
   - Verify test environment variables

2. **Run E2E Tests**
   ```bash
   # Run all E2E tests
   npm run test:e2e
   
   # Or directly with Playwright
   npx playwright test
   ```

3. **Test Results**
   - Review test output and screenshots
   - Check for failed tests and error details
   - Generate test report if configured

## Test Structure
Tests are organized in `tests/e2e/`:
- `auth/` - Authentication related tests
- `features/` - Feature-specific test scenarios  
- `pageobjects/` - Page Object Model classes
- `utils/` - Test utilities and helpers

## Common Issues
- **Port conflicts**: Ensure dev server runs on expected port
- **Timing issues**: Review wait strategies in failing tests
- **Browser issues**: Update browsers with `npx playwright install`
- **Screenshots**: Check `test-results/` for failure screenshots

Report results and any failures found during execution.'
    
    create_file_with_backup ".claude/commands/run-e2e.md" "$content"
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_slash_commands
fi