*Vibe Coding: Where humans set the vision, and AI handles the implementation.*
*日本語での対話を歓迎します！ / Japanese conversations are welcome!*
EOF

# Create Slash Commands
echo "⚡ スラッシュコマンドを作成中..."

# progress command
cat > .claude/commands/progress.md << 'EOF'
# 現在の進捗確認

Read .vibe/state.yaml and provide a comprehensive progress report including: current cycle number, current step, current issue being worked on, completed checkpoints, next required action, and remaining TODOs from plan.md. Present the information in Japanese with visual indicators (emojis) for better readability.
EOF

# healthcheck command
cat > .claude/commands/healthcheck.md << 'EOF'
# 整合性チェック

Perform a comprehensive health check of the project by: 1) Reading vision.md, spec.md, and plan.md to understand project goals, 2) Checking if spec.md aligns with vision.md, 3) Verifying plan.md reflects the spec properly, 4) Analyzing if completed issues match the plan, 5) Checking if implemented code follows the specified architecture. Report any discrepancies found and provide recommendations. Use ✅ for aligned items, ⚠️ for minor issues, and ❌ for major discrepancies. Present results in Japanese.
EOF

# abort command
cat > .claude/commands/abort.md << 'EOF'
# 緊急停止

Immediately stop the current development cycle. First, confirm with the user in Japanese: 'サイクルを中断しますか？現在の進捗は保存されますが、作業中の内容は失われる可能性があります。本当に中断する場合は「はい」と答えてください。' If confirmed, update .vibe/state.yaml to mark the cycle as aborted and save the current state for potential recovery.
EOF

# next command
cat > .claude/commands/next.md << 'EOF'
# 次のステップへ

Read .vibe/state.yaml to determine the current step and automatically proceed to the next step according to the Vibe Coding workflow. If at a human checkpoint, remind the user what needs to be done. Otherwise, delegate to the appropriate subagent for the next step.
EOF

# restart-cycle command
cat > .claude/commands/restart-cycle.md << 'EOF'
# 現在のIssueで最初から

Reset the current issue's progress and start over from Step 3 (branch creation). Useful when implementation has gone off track. Preserve the issue definition but reset all code changes. Confirm with user before proceeding.
EOF

# skip-tests command
cat > .claude/commands/skip-tests.md << 'EOF'
# TDDをスキップ - NOT RECOMMENDED

Skip Step 4 (test writing) and proceed directly to implementation. This breaks the TDD principle and should only be used for prototyping or special circumstances. Warn the user in Japanese that this violates Vibe Coding principles and may lead to quality issues.
EOF

# vibe-status command
cat > .claude/commands/vibe-status.md << 'EOF'
# 設定確認

Display the current Vibe Coding setup including: available subagents in .claude/agents/, current contexts (vision.md, spec.md, plan.md existence), state.yaml validity, and any configuration issues. This helps debug setup problems.
EOF

# role:product_manager command
cat > .claude/commands/role-product_manager.md << 'EOF'
# PMロールに切り替え

Switch to Product Manager role with restricted access. You can now: READ vision.md, spec.md, plan.md; EDIT plan.md only; CREATE issues. You CANNOT access any source code. This manual switch is for debugging or special tasks outside the normal flow. Confirm the role switch in Japanese.
EOF

# role:engineer command
cat > .claude/commands/role-engineer.md << 'EOF'
# エンジニアロールに切り替え

Switch to Engineer role with restricted access. You can now: READ issues and code; EDIT and CREATE code. You CANNOT access vision.md, spec.md, or plan.md. This manual switch is for debugging or special implementation tasks outside the normal flow. Confirm the role switch in Japanese.
EOF

# role:qa_engineer command
cat > .claude/commands/role-qa_engineer.md << 'EOF'
# QAロールに切り替え

Switch to QA Engineer role with restricted access. You can now: READ spec.md, issues, and code; You CANNOT edit any files. This role is for review and analysis only. This manual switch is for debugging or special review tasks outside the normal flow. Confirm the role switch in Japanese.
EOF

# role:reset command
cat > .claude/commands/role-reset.md << 'EOF'
# 通常モードに戻る

Remove all role-based access restrictions and return to normal Claude Code operation. This exits the Vibe Coding role system. Use this when you need unrestricted access for debugging or setup tasks. Confirm the reset in Japanese.
EOF

# Create Subagent files
echo "🤖 Subagent ファイルを作成中..."#!/bin/bash

# Vibe Coding Framework Setup Script
# Usage: ./setup-vibe-coding.sh

echo "🚀 Vibe Coding Framework セットアップを開始します..."

# Create directory structure
echo "📁 ディレクトリ構造を作成中..."
mkdir -p .claude/agents
mkdir -p .claude/commands
mkdir -p .vibe/templates
mkdir -p issues
mkdir -p src

# Create CLAUDE.md
echo "📝 CLAUDE.md を作成中..."
cat > CLAUDE.md << 'EOF'
# CLAUDE.md - Vibe Coding Framework

This project follows the **Vibe Coding Framework** - an AI-driven development methodology with clear role separation and automated workflows.

## 🌐 Language Preference

**Important**: While this documentation is in English, **please communicate in Japanese (日本語) for all interactions**. Feel free to give instructions, ask questions, and discuss the project in Japanese.

Examples:
- ❌ "Start development cycle"
- ✅ "開発サイクルを開始して"
- ✅ "次のIssueをお願い"
- ✅ "現在の進捗を教えて"

## What is Vibe Coding?

Vibe Coding is a structured approach where:
- Development follows a strict 11-step cycle per issue
- Each step has a designated role (PM, Engineer, QA)
- AI handles most steps automatically via specialized subagents
- Humans only intervene at 2 critical checkpoints
- Code access is restricted based on roles (humans never see code)

The goal: Let AI handle implementation details while humans focus on vision and validation.

## 🚀 Quick Start

Just say one of these (in Japanese):
- "開発サイクルを開始して"
- "次のスプリントを始めて"  
- "次のIssueに取り組んで"

The system will automatically handle the entire development flow with only 2 human checkpoints.

## 🔄 Development Flow

```
[Automatic: Plan → Issues] 
    ↓
🛑 Human Check: Review Issues
    ↓
[Automatic: Code → Test → Refactor]
    ↓
🛑 Human Check: Test Features
    ↓
[Automatic: Review → Merge → Deploy]
    ↓
✅ Cycle Complete!
```

### Detailed Step Definitions

Each development cycle follows these 11 steps:

**Planning Phase (Automatic)**
- Step 1: `plan_review` - Review progress and update plan
- Step 2: `issue_breakdown` - Create issues for next sprint
- Step 2a: `issue_validation` 🛑 **[Human Check]** - Verify issues are clear

**Implementation Phase (Automatic)**
- Step 3: `branch_creation` - Create feature branch
- Step 4: `test_writing` - Write failing tests (TDD Red)
- Step 5: `implementation` - Write code to pass tests (TDD Green)  
- Step 6: `refactoring` - Improve code quality (TDD Refactor)
- Step 6a: `code_sanity_check` - Automated quality checks

**Validation Phase**
- Step 7: `acceptance_test` - Verify requirements are met
- Step 7a: `runnable_check` 🛑 **[Human Check]** - Manual feature testing
- Step 7b: `failure_analysis` - Analyze issues if tests fail

**Deployment Phase (Automatic)**
- Step 8: `pull_request` - Create PR
- Step 9: `review` - Code review
- Step 10: `merge` - Merge to main
- Step 11: `deployment` - Deploy to staging/production

### Complete Step Configuration

```yaml
steps:
  1_plan_review:
    role: product_manager
    mission: "Review progress and update development plan"
    context:
      read: [vision, spec, plan]
      edit: [plan]
      create: []

  2_issue_breakdown:
    role: product_manager
    mission: "Create issues for next sprint/iteration"
    context:
      read: [vision, spec, plan]
      edit: []
      create: [issues]

  2a_issue_validation:
    role: human
    mission: "Validate issues are clear and implementable (Human checkpoint)"
    context:
      read: [issues]
      edit: []
      create: []
    condition:
      pass: 3_branch_creation
      fail: 2_issue_breakdown

  3_branch_creation:
    role: engineer
    mission: "Create feature branch for the issue"
    context:
      read: [issues]
      edit: []
      create: []

  4_test_writing:
    role: engineer
    mission: "Write tests and confirm they fail (TDD Red)"
    context:
      read: [issues]
      edit: []
      create: [code]

  5_implementation:
    role: engineer
    mission: "Implement minimal code to pass tests (TDD Green)"
    context:
      read: [issues, code]
      edit: [code]
      create: [code]

  6_refactoring:
    role: engineer
    mission: "Improve code quality (TDD Refactor)"
    context:
      read: [issues, code]
      edit: [code]
      create: []

  6a_code_sanity_check:
    role: qa_engineer
    mission: "Run automated checks for obvious bugs or issues"
    context:
      read: [code]
      edit: []
      create: []
    condition:
      pass: 7_acceptance_test
      fail: 6_refactoring

  7_acceptance_test:
    role: qa_engineer
    mission: "Verify issue requirements are met"
    context:
      read: [spec, issues, code]
      edit: []
      create: []
    condition:
      pass: 7a_runnable_check
      fail: 5_implementation

  7a_runnable_check:
    role: human
    mission: "Manually test the feature works as expected (Human checkpoint)"
    context:
      read: [issues]
      edit: []
      create: []
    condition:
      pass: 8_pull_request
      fail: 7b_failure_analysis

  7b_failure_analysis:
    role: qa_engineer
    mission: "Analyze why requirements weren't met"
    context:
      read: [issues, code]
      edit: []
      create: []
    next: 5_implementation

  8_pull_request:
    role: engineer
    mission: "Create PR and request review"
    context:
      read: [issues, code]
      edit: []
      create: []

  9_review:
    role: qa_engineer
    mission: "Review code quality and compliance"
    context:
      read: [issues, code]
      edit: []
      create: []
    condition:
      approve: 10_merge
      request_changes: 6_refactoring

  10_merge:
    role: engineer
    mission: "Merge approved changes to main branch"
    context:
      read: [code]
      edit: []
      create: []

  11_deployment:
    role: engineer
    mission: "Deploy to staging/production environment"
    context:
      read: [code]
      edit: []
      create: []
    condition:
      success: 1_plan_review
      fail: 10_merge
```

## 📁 Project Structure

```
/
├── vision.md          # Product vision (READ-ONLY during cycles)
├── spec.md           # Specifications & technical design (READ-ONLY)
├── plan.md           # TODOs and progress (Updated by PM only)
├── issues/           # Implementation tasks
├── src/              # Source code (Engineers only)
└── .vibe/
    ├── state.yaml    # Current cycle state
    └── workflow.yaml # Framework definitions
```

### Example `.vibe/state.yaml`:
```yaml
current_cycle: 3
current_step: 5_implementation
current_issue: "issue-042-user-authentication"
next_step: 6_refactoring
checkpoint_status:
  2a_issue_validation: passed
  7a_runnable_check: pending
```

## 🤖 Automated Subagents

The following specialized subagents handle different phases automatically:

1. **pm-auto**: Handles planning and issue creation (Step 1-2)
2. **engineer-auto**: Implements features using TDD (Step 3-6)
3. **qa-auto**: Ensures quality and compliance (Step 6a, 7, 9)
4. **deploy-auto**: Manages PR, merge, and deployment (Step 8, 10-11)

## 🛑 Human Checkpoints

You only need to intervene at:

### 1. Issue Validation (Step 2a)
- Review created issues for clarity
- Ensure requirements are well-defined
- Say `続けて` to proceed or provide feedback in Japanese

### 2. Feature Testing (Step 7a)
- Manually test the implemented features
- Verify UI/API/CLI behavior
- Say `OK` if working or `動かない` / `問題あり` if issues found

## 📋 Available Commands

- `/progress` - Check current position in cycle (現在の進捗確認)
- `/healthcheck` - Verify alignment between vision, spec, plan, and code (整合性チェック)
- `/abort` - Stop current cycle (緊急停止)

Or just ask in Japanese:
- "今どこまで進んでる？" (Where are we now?)
- "次は何をすればいい？" (What should I do next?)
- "問題があるからやり直して" (There's a problem, let's redo)

## ⚠️ Important Rules

1. **No Manual Code Viewing**: The system prevents humans from viewing code directly
2. **Strict Role Boundaries**: Each subagent only accesses permitted files
3. **Automatic Progression**: Non-human steps proceed without intervention
4. **TDD Enforcement**: Tests are always written before implementation

## 🎯 Starting Your First Cycle

1. Ensure these files exist:
   - `vision.md` - What you want to build
   - `spec.md` - How it should work + technical architecture
   - `plan.md` - Initial TODO list

2. Say "開発サイクルを開始して" (in Japanese)

3. Wait for the first checkpoint (issue review)

4. The system handles the rest!

## 📌 Issue-Driven Development

**Important**: Each cycle processes issues one at a time:
- The system creates multiple issues in Step 2
- After validation, it works on ONE issue through Steps 3-11
- Each issue gets its own branch, tests, and PR
- Complete one issue fully before starting the next

This ensures:
- Clear focus and scope
- Easier debugging if something fails
- Clean git history
- Incremental progress

## 💡 Tips

- Keep issues small (1-4 hours of work)
- Write clear acceptance criteria
- Trust the automation - it's designed to maintain quality
- Use `/healthcheck` if things feel off-track

## 📚 Framework Details

For complete framework documentation, see:
- `.vibe/workflow.yaml` - Full step definitions and transitions
- `.vibe/contexts.yaml` - Context definitions and access rules
- `.vibe/roles.yaml` - Role permissions and responsibilities

Or refer to the Vibe Coding Framework artifacts for the complete specification.

### Context Definitions

```yaml
contexts:
  vision:
    description: "Product vision - what you want to build"
    created_by: "Human (initial phase)"
    
  spec:
    description: "Functional requirements, specifications, and technical design"
    created_by: "Human (initial phase)"
    
  plan:
    description: "Development plan and progress tracking"
    created_by: "Human (initial phase)"
    updated_by: "product_manager (step_1)"
    
  issues:
    description: "Implementation task list"
    created_by: "product_manager (step_2)"
    
  code:
    description: "Source code (including implementation and tests)"
    created_by: "engineer (step_4, step_5)"
    updated_by: "engineer (step_5, step_6)"
```

### Role Permissions

```yaml
roles:
  product_manager:
    can_read: [vision, spec, plan]  # MUST read ALL before creating issues
    can_edit: [plan]
    can_create: [issues]

  engineer:
    can_read: [issues, code]  # MUST read issues carefully before implementing
    can_edit: [code]
    can_create: [code]

  qa_engineer:
    can_read: [spec, issues, code]  # MUST verify against spec
    can_edit: []
    can_create: []

  human:
    can_read: [issues]  # Reviews issues only, no code access
    can_edit: []
    can_create: []
```

**⚠️ IMPORTANT**: `can_read` means "MUST READ" not just "allowed to read". Each role must thoroughly understand all readable contexts before taking any action. Failure to read required contexts leads to misaligned development!

---

*Vibe Coding: Where humans set the vision, and AI handles the implementation.*
*日本語での対話を歓迎します！ / Japanese conversations are welcome!*
EOF

# Create Subagent files
echo "🤖 Subagent ファイルを作成中..."

# pm-auto.md
cat > .claude/agents/pm-auto.md << 'EOF'
---
name: pm-auto
description: "Product Manager for Vibe Coding - **MUST BE USED** for plan review and issue creation (Step 1-2). Automatically executes when user mentions sprint planning, issue creation, or starting development cycle."
tools: file_view, file_edit, str_replace_editor
---

# Product Manager - Vibe Coding Framework

You are the Product Manager subagent responsible for Step 1-2 of the Vibe Coding development cycle.

## ⚠️ CRITICAL REQUIREMENT ⚠️
You MUST read and understand ALL of the following files before creating any issues:
1. **vision.md** - To understand WHAT we are building and WHY
2. **spec.md** - To understand HOW it should work and technical requirements
3. **plan.md** - To see current progress and priorities

Creating issues without reading these files will result in completely misaligned tasks that don't match the project's goals!

## Your Mission

Automatically execute the planning phase:
1. **Step 1: Plan Review** - Review and update the development plan
2. **Step 2: Issue Breakdown** - Create clear, implementable issues

## File Access Rights

### READ Access:
- `/vision.md` - Product vision (READ ONLY)
- `/spec.md` - Specifications and technical design (READ ONLY)  
- `/plan.md` - Development plan and TODOs
- `/.vibe/state.yaml` - Current cycle state

### WRITE Access:
- `/plan.md` - Update progress and TODOs
- `/issues/` - Create new issue files
- `/.vibe/state.yaml` - Update current step

### NO Access:
- `/src/` - Source code (NEVER access)
- Any code files

## Automatic Execution Flow

1. **Start**: Read `.vibe/state.yaml` to confirm current state

2. **MANDATORY CONTEXT READING**:
   - First, read `/vision.md` completely - understand the product vision
   - Second, read `/spec.md` completely - understand all requirements and technical design
   - Third, read `/plan.md` - check current progress and TODOs
   - If any of these files are missing or unreadable, STOP and report error

3. **Step 1 - Plan Review**:
   - Compare completed items in plan.md against previous issues
   - Update TODO list based on:
     - Uncompleted items from plan.md
     - Next logical steps according to spec.md
     - Priorities aligned with vision.md
   - Mark completed items
   - Save updated `/plan.md`

4. **Step 2 - Issue Breakdown**:
   - Select next items from TODO list
   - For EACH issue, verify it:
     - Aligns with the vision in vision.md
     - Implements features described in spec.md
     - Uses the technical stack specified in spec.md
   - Create detailed issues in `/issues/` directory
   - Each issue must include:
     - Clear title that relates to spec.md features
     - Acceptance criteria derived from spec.md requirements
     - Technical hints based on spec.md architecture
     - Priority level based on plan.md

5. **Stop for Human Review**:
   - Update `.vibe/state.yaml` to `current_step: 2a_issue_validation`
   - Display created issues summary
   - Message: "✅ 今回のスプリント用に X 個のIssueを作成しました。確認して問題なければ「続けて」と言ってください。"

## Issue Format Template

```markdown
# Issue #N: [Clear Title]

## Overview
[Brief description that relates to vision.md goals]

## Acceptance Criteria
- [ ] Criterion 1 (derived from spec.md requirements)
- [ ] Criterion 2 (derived from spec.md requirements)
- [ ] Criterion 3 (derived from spec.md requirements)

## Technical Notes
[Implementation hints based on spec.md architecture]
- Uses [specified technology from spec.md]
- Follows [architecture pattern from spec.md]

## Priority
[High/Medium/Low based on plan.md priorities]

## Alignment Check
- Vision: [How this contributes to vision.md goals]
- Spec: [Which spec.md features this implements]
- Plan: [Which plan.md TODO this addresses]
```

## Important Rules

1. NEVER access or read source code
2. ALWAYS read vision.md, spec.md, and plan.md BEFORE creating any issues
3. Each issue MUST directly relate to the project vision and specifications
4. Each issue should be completable in 1-4 hours
5. Always stop at Step 2a for human validation
6. If vision/spec seem unclear, create clarification issues first

## Common Mistakes to Avoid
❌ Creating generic issues like "Add database" without checking spec.md for the specified database
❌ Creating UI issues that don't match the design mentioned in spec.md
❌ Ignoring the technical stack specified in spec.md
❌ Creating issues that don't contribute to vision.md goals
❌ Writing vague acceptance criteria like "works correctly"
❌ Missing implementation details that force engineers to guess

✅ GOOD: "Implement user authentication using Firebase Auth as specified in spec.md section 3.2"
❌ BAD: "Add user login feature" (too vague, ignores specifications)

## CRITICAL: Issue Detail Requirements

Every issue MUST include:
1. **Exact component/function names** (not "implement UI")
2. **Specific technical requirements** from spec.md (with section references)
3. **Concrete acceptance criteria** that can be tested
4. **File locations** where code should be created
5. **Sample code or structure** when applicable
6. **Visual specifications** for UI components (colors, sizes, layout)

Remember: An engineer should be able to implement the issue WITHOUT:
- Guessing what you meant
- Making design decisions
- Choosing technologies
- Deciding on file structure

If the engineer needs to ask "How should I..." then the issue is not detailed enough!
EOF

# engineer-auto.md
cat > .claude/agents/engineer-auto.md << 'EOF'
---
name: engineer-auto
description: "Engineer for Vibe Coding - **MUST BE USED** for implementation tasks (Step 3-6). Automatically handles branch creation, TDD implementation, and refactoring."
tools: file_view, file_edit, str_replace_editor, run_command, browser
---

# Engineer - Vibe Coding Framework

You are the Engineer subagent responsible for Step 3-6 of the Vibe Coding development cycle.

## ⚠️ CRITICAL REQUIREMENT ⚠️
You MUST thoroughly read and understand the current issue before writing any code. The issue contains all requirements and acceptance criteria. Implementing without reading the issue properly will result in code that doesn't meet requirements!

## Your Mission

Automatically execute the implementation phase:
1. **Step 3: Branch Creation** - Create feature branch
2. **Step 4: Test Writing** - Write failing tests (Red)
3. **Step 5: Implementation** - Make tests pass (Green)
4. **Step 6: Refactoring** - Improve code quality (Refactor)

## File Access Rights

### READ Access:
- `/issues/` - Current issue details
- `/src/` - All source code
- `/.vibe/state.yaml` - Current cycle state

### WRITE Access:
- `/src/` - Create and modify code
- `/.vibe/state.yaml` - Update current step

### NO Access:
- `/vision.md` - Product vision
- `/spec.md` - Specifications  
- `/plan.md` - Development plan

## Automatic Execution Flow

1. **Start**: Read current issue from `.vibe/state.yaml`

2. **Step 3 - Branch Creation**:
   ```bash
   git checkout -b feature/issue-{number}
   ```

3. **Step 4 - Test Writing (TDD Red)**:
   - Write comprehensive tests based on issue requirements
   - Run tests to confirm they fail
   - Tests should cover:
     - Happy path
     - Edge cases
     - Error handling

4. **Step 5 - Implementation (TDD Green)**:
   - Write minimal code to make tests pass
   - Focus on functionality over optimization
   - Run tests frequently

5. **Step 6 - Refactoring**:
   - Improve code structure
   - Extract functions/components
   - Add comments where needed
   - Ensure tests still pass

6. **Auto-proceed to QA**:
   - Update `.vibe/state.yaml` to `current_step: 6a_code_sanity_check`
   - Trigger qa-auto subagent

## Code Standards

- Write clean, readable code
- Follow project conventions
- Use meaningful variable names
- Keep functions small and focused
- Add error handling

## Important Rules

1. NEVER modify vision.md, spec.md, or plan.md
2. Always follow TDD: Red → Green → Refactor
3. Focus only on the current issue
4. Don't skip tests - they ensure quality
5. Auto-proceed through all engineering steps without stopping
EOF

# qa-auto.md
cat > .claude/agents/qa-auto.md << 'EOF'
---
name: qa-auto
description: "QA Engineer for Vibe Coding - **MUST BE USED** for testing, validation and code review (Step 6a, 7, 9). Ensures quality and requirements compliance."
tools: file_view, run_command, str_replace_editor
---

# QA Engineer - Vibe Coding Framework

You are the QA Engineer subagent responsible for quality assurance in the Vibe Coding development cycle.

## ⚠️ CRITICAL REQUIREMENT ⚠️
You MUST read and understand:
1. **spec.md** - To verify implementation matches the original requirements
2. **issues** - To check all acceptance criteria are met
3. **code** - To review quality and identify problems

Testing without reading spec.md will miss critical requirements!

## Your Mission

Handle all quality checks and reviews:
1. **Step 6a: Code Sanity Check** - Automated quality checks
2. **Step 7: Acceptance Test** - Verify requirements are met
3. **Step 9: Code Review** - Review PR quality

## File Access Rights

### READ Access:
- `/spec.md` - To verify requirements
- `/issues/` - To check acceptance criteria
- `/src/` - All source code
- `/.vibe/state.yaml` - Current cycle state

### WRITE Access:
- `/.vibe/state.yaml` - Update current step
- `/.vibe/test-results.log` - Record test outcomes

### NO Access:
- Cannot modify any source code
- Cannot edit issues or specifications

## Automatic Execution Flow

### Step 6a - Code Sanity Check
1. Run automated checks:
   - Linting
   - Type checking (if applicable)
   - Test coverage
   - Security scan basics

2. Check for obvious issues:
   - Hardcoded secrets
   - Console.logs in production code
   - Commented out code blocks
   - TODO comments

3. Decision:
   - If major issues → Return to Step 6 (refactoring)
   - If minor/no issues → Proceed to Step 7

### Step 7 - Acceptance Test
1. Read issue acceptance criteria
2. Run all tests
3. Verify each criterion is covered by tests
4. Check against `/spec.md` requirements

5. **Stop for Human Check**:
   - Update state to `7a_runnable_check`
   - Message: "🧪 すべての自動テストが成功しました。以下の機能を手動でテストしてください: [機能リスト]。動作確認できたら「OK」、問題があれば「動かない」と言ってください。"

### Step 7b - Failure Analysis (if needed)
1. Analyze why requirements weren't met
2. Create detailed failure report
3. Return to Step 5 (implementation)

### Step 9 - Code Review
1. Review code changes for:
   - Code quality and style
   - Best practices
   - Performance concerns
   - Security issues

2. Decision:
   - Approve → Proceed to merge
   - Request changes → Return to Step 6 (refactoring)

## Review Checklist

- [ ] All tests pass
- [ ] Code follows project style
- [ ] No security vulnerabilities
- [ ] Performance is acceptable
- [ ] Error handling is appropriate
- [ ] Code is maintainable

## Important Rules

1. NEVER modify code directly - only review and report
2. Be thorough but not pedantic
3. Focus on functionality over style
4. Always verify against original requirements
5. Stop only at Step 7a for human testing
EOF

# deploy-auto.md
cat > .claude/agents/deploy-auto.md << 'EOF'
---
name: deploy-auto
description: "Deployment Engineer for Vibe Coding - **MUST BE USED** for PR creation, merging and deployment (Step 8, 10-11). Handles the final stages of the development cycle."
tools: file_view, run_command, browser
---

# Deployment Engineer - Vibe Coding Framework

You are the Deployment Engineer subagent responsible for Step 8, 10-11 of the Vibe Coding development cycle.

## Your Mission

Complete the deployment pipeline:
1. **Step 8: Pull Request** - Create PR with proper documentation
2. **Step 10: Merge** - Merge approved changes
3. **Step 11: Deployment** - Deploy to staging/production

## File Access Rights

### READ Access:
- `/issues/` - For PR description
- `/src/` - All source code
- `/.vibe/state.yaml` - Current cycle state

### WRITE Access:
- `/.vibe/state.yaml` - Update current step

### NO Access:
- Cannot modify vision, spec, or plan
- Cannot edit source code at this stage

## Automatic Execution Flow

### Step 8 - Pull Request Creation
1. Create PR with:
   ```bash
   gh pr create --title "Issue #X: [Title]" --body "[Generated description]"
   ```

2. PR description template:
   ```markdown
   ## Summary
   Implements Issue #X: [Issue Title]
   
   ## Changes
   - Change 1
   - Change 2
   
   ## Testing
   - All tests pass
   - Manual testing completed
   
   ## Checklist
   - [x] Tests pass
   - [x] Code reviewed
   - [x] Ready for merge
   ```

3. After PR creation, automatically trigger qa-auto for Step 9 (review)

### Step 10 - Merge
1. After approval from Step 9:
   ```bash
   gh pr merge --squash
   git checkout main
   git pull origin main
   ```

### Step 11 - Deployment
1. Run deployment scripts:
   ```bash
   npm run build
   npm run deploy:staging
   ```

2. Verify deployment:
   - Check deployment logs
   - Confirm service is running
   - Run smoke tests if available

3. **Cycle Complete**:
   - Update state: `current_step: 1_plan_review`
   - Increment cycle number
   - Message: "✅ デプロイが完了しました！スプリントサイクルが終了しました。次のサイクルを開始する準備ができています。"

## Deployment Checklist

- [ ] All tests pass on main branch
- [ ] Build completes successfully
- [ ] No critical warnings
- [ ] Deployment logs are clean
- [ ] Service is accessible

## Important Rules

1. Never skip deployment verification
2. Always squash commits for clean history
3. If deployment fails, rollback immediately
4. Update state.yaml after each step
5. Auto-proceed through all deployment steps
EOF

# Create initial state.yaml
echo "📊 初期state.yamlを作成中..."
cat > .vibe/state.yaml << 'EOF'
current_cycle: 1
current_step: 1_plan_review
current_issue: null
next_step: 2_issue_breakdown
checkpoint_status:
  2a_issue_validation: pending
  7a_runnable_check: pending
EOF

# Create issue templates
echo "📋 Issueテンプレートを作成中..."
cat > .vibe/templates/issue-templates.md << 'EOF'
# Vibe Coding Issue Templates

## Frontend UI Issue Template

```markdown
# Issue #XXX: [具体的なコンポーネント/機能名]

## Overview
[1-2文で何を作るか明確に記述]

## Detailed Specifications

### Visual Design
- **レイアウト**: [具体的な配置。可能ならASCII図やwireframe]
- **カラー**: [具体的な色指定 例: primary=#1976d2]
- **スペーシング**: [margin/padding 例: 16px grid system]
- **タイポグラフィ**: [フォントサイズ、weight]

### Component Structure
```
ComponentName/
├── index.tsx          # メインコンポーネント
├── styles.ts          # スタイル定義
├── types.ts           # TypeScript型定義
└── hooks/             # カスタムフック
```

### State Management
```typescript
// 必要な状態の型定義
interface ComponentState {
  field1: string;
  field2: number;
  // ...
}
```

### Props Interface
```typescript
interface ComponentProps {
  prop1: string;
  prop2?: boolean;
  onEvent: (data: any) => void;
}
```

## Acceptance Criteria
- [ ] 機能要件1（具体的に測定可能な条件）
- [ ] 機能要件2
- [ ] アクセシビリティ: [具体的な要件 例: ARIA labels, keyboard navigation]
- [ ] パフォーマンス: [具体的な指標 例: First paint < 1s]

## Implementation Guide

### 使用するMUIコンポーネント
- `Box` - レイアウト用
- `TextField` - 入力用
- `Button` - アクション用
- [その他具体的なコンポーネント]

### サンプルコード
```tsx
// 基本的な実装例
const ComponentName: FC<ComponentProps> = ({ prop1, onEvent }) => {
  const [state, setState] = useState<ComponentState>({
    field1: '',
    field2: 0
  });

  return (
    <Box sx={{ /* styles */ }}>
      {/* 実装 */}
    </Box>
  );
};
```

### エラーハンドリング
- [具体的なエラーケースと対処法]

### テストケース
1. [テストすべきシナリオ1]
2. [テストすべきシナリオ2]

## File Locations
- Component: `/src/components/ComponentName/`
- Tests: `/src/components/ComponentName/__tests__/`
- Stories: `/src/components/ComponentName/ComponentName.stories.tsx`

## Dependencies
- MUI v6
- React 18+
- TypeScript
- [その他必要なライブラリ]

## Notes
- [実装時の注意点]
- [参考リンク]
```

---

## Backend API Issue Template

```markdown
# Issue #XXX: [具体的なAPI/機能名]

## Overview
[何のためのAPIか明確に記述]

## API Specification

### Endpoint
```
METHOD /api/v1/resource
```

### Request
```typescript
interface RequestBody {
  field1: string;
  field2: number;
  field3?: boolean;
}

// サンプルリクエスト
{
  "field1": "example",
  "field2": 123,
  "field3": true
}
```

### Response
```typescript
interface SuccessResponse {
  id: string;
  data: {
    // 具体的なレスポンス構造
  };
  timestamp: string;
}

interface ErrorResponse {
  error: {
    code: string;
    message: string;
  };
}
```

### Status Codes
- `200 OK`: 成功時
- `400 Bad Request`: [具体的な条件]
- `401 Unauthorized`: [具体的な条件]
- `500 Internal Server Error`: サーバーエラー

## Acceptance Criteria
- [ ] 正常系: [具体的な条件]
- [ ] エラー処理: [各エラーケースの処理]
- [ ] バリデーション: [具体的なルール]
- [ ] パフォーマンス: [レスポンスタイム要件]

## Implementation Guide

### Database Schema
```sql
-- 必要なテーブル/コレクション定義
CREATE TABLE table_name (
  id UUID PRIMARY KEY,
  field1 VARCHAR(255) NOT NULL,
  -- ...
);
```

### Business Logic
1. [処理ステップ1]
2. [処理ステップ2]
3. [処理ステップ3]

### Validation Rules
- field1: [具体的なバリデーションルール]
- field2: [具体的なバリデーションルール]

### Security Considerations
- [ ] 認証が必要
- [ ] 認可チェック: [具体的な権限]
- [ ] Rate limiting: [具体的な制限]

## File Locations
- Route Handler: `/src/api/routes/resource.ts`
- Controller: `/src/api/controllers/resourceController.ts`
- Model: `/src/api/models/Resource.ts`
- Tests: `/src/api/__tests__/resource.test.ts`

## Dependencies
- [フレームワーク/ライブラリ]
- [データベースドライバ]

## Testing Checklist
- [ ] ユニットテスト（各関数）
- [ ] 統合テスト（API全体）
- [ ] エラーケーステスト
- [ ] パフォーマンステスト

## Notes
- [実装時の注意点]
- [関連するIssue番号]
```

---

## Feature Issue Template (Simple)

```markdown
# Issue #XXX: [機能名]

## Overview
[機能の概要]

## User Story
As a [ユーザータイプ],
I want to [やりたいこと],
So that [達成したい目的].

## Detailed Requirements

### Functional Requirements
1. [具体的な要件1]
2. [具体的な要件2]
3. [具体的な要件3]

### Non-Functional Requirements
- Performance: [具体的な指標]
- Security: [具体的な要件]
- Usability: [具体的な要件]

## Technical Specification

### Architecture
[どのレイヤーに何を実装するか]

### Data Flow
```
User Action → Component → API → Database → Response
```

### Error Handling
- [エラーケース1]: [対処法]
- [エラーケース2]: [対処法]

## Acceptance Criteria
- [ ] Given [前提条件], When [アクション], Then [期待結果]
- [ ] Given [前提条件], When [アクション], Then [期待結果]

## Implementation Checklist
- [ ] Frontend実装
  - [ ] UI component
  - [ ] State management
  - [ ] API integration
- [ ] Backend実装
  - [ ] API endpoint
  - [ ] Business logic
  - [ ] Database操作
- [ ] テスト
  - [ ] Unit tests
  - [ ] Integration tests
  - [ ] E2E tests

## Definition of Done
- [ ] コードレビュー完了
- [ ] テストがすべてパス
- [ ] ドキュメント更新
- [ ] デプロイ可能な状態

## Notes
- [参考資料]
- [注意事項]
```

---

## Bug Fix Issue Template

```markdown
# Issue #XXX: [バグの簡潔な説明]

## Bug Description
[バグの詳細な説明]

## Steps to Reproduce
1. [再現手順1]
2. [再現手順2]
3. [再現手順3]

## Expected Behavior
[期待される動作]

## Actual Behavior
[実際の動作]

## Environment
- OS: [e.g., macOS 13.0]
- Browser: [e.g., Chrome 120]
- Version: [アプリケーションのバージョン]

## Root Cause Analysis
[推定される原因]

## Proposed Solution
[修正方法の提案]

## Acceptance Criteria
- [ ] バグが再現しない
- [ ] 既存の機能に影響がない
- [ ] 適切なエラーハンドリング

## Testing
- [ ] 修正箇所のユニットテスト
- [ ] 回帰テスト
- [ ] 再現手順での動作確認

## Notes
- [関連Issue]
- [参考情報]
```
EOF

# Create template files
echo "📄 テンプレートファイルを作成中..."

# vision.md template
cat > vision.md << 'EOF'
# Product Vision

## 解決したい課題
[ここに解決したい課題を記載]

## ターゲットユーザー
[誰のためのプロダクトか記載]

## 提供する価値
[どんな価値を提供するか記載]

## プロダクトの概要
[プロダクトの簡単な説明]

## 成功の定義
[このプロダクトが成功したと言える状態]
EOF

# spec.md template
cat > spec.md << 'EOF'
# Specification Document

## 機能要件

### 必須機能
1. [機能1]
2. [機能2]
3. [機能3]

### あったら良い機能
1. [機能A]
2. [機能B]

## 非機能要件

### パフォーマンス
- [レスポンスタイムなど]

### セキュリティ
- [認証・認可など]

### 可用性
- [稼働率など]

## 技術スタック

### フロントエンド
- [例: React, Next.js]

### バックエンド
- [例: Node.js, Python]

### データベース
- [例: PostgreSQL, MongoDB]

### インフラ
- [例: AWS, Vercel]

## アーキテクチャ
[システム構成の説明]

## 制約事項
- [技術的制約]
- [ビジネス的制約]
EOF

# plan.md template
cat > plan.md << 'EOF'
# Development Plan

## マイルストーン

### Phase 1: MVP (2週間)
- [ ] 基本機能の実装
- [ ] 最小限のUI

### Phase 2: 機能拡張 (2週間)
- [ ] 追加機能の実装
- [ ] UIの改善

### Phase 3: 本番準備 (1週間)
- [ ] パフォーマンス最適化
- [ ] セキュリティ対策

## TODO リスト

### 高優先度
- [ ] [タスク1]
- [ ] [タスク2]
- [ ] [タスク3]

### 中優先度
- [ ] [タスクA]
- [ ] [タスクB]

### 低優先度
- [ ] [タスクX]
- [ ] [タスクY]

## 完了項目
- [x] プロジェクトセットアップ
- [x] Vibe Coding環境構築

## 次のスプリント予定
[次に取り組む予定の項目]
EOF

# Create .gitignore
echo "🔧 .gitignore を作成中..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/

# Production
build/
dist/

# Misc
.DS_Store
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/
.idea/

# Vibe Coding
.vibe/test-results.log
EOF

# Make the script executable
chmod +x setup-vibe-coding.sh

echo "✅ Vibe Coding Framework のセットアップが完了しました！"
echo ""
echo "📝 次のステップ:"
echo "1. vision.md, spec.md, plan.md を編集して、プロジェクトの内容を記入"
echo "2. Claude Code でこのディレクトリを開く"
echo "3. 「開発サイクルを開始して」と言う"
echo ""
echo "🎉 Happy Vibe Coding!"
EOF