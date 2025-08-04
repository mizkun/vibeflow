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
