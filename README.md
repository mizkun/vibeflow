# Vibe Coding Framework

An AI-driven development methodology with role separation and structured workflow automation.

## Overview

Vibe Coding Framework implements an 11-step development cycle with automated role switching and strict access control. The system uses 4 specialized subagents to handle different phases of development while humans participate only at 2 designated checkpoints.

## Workflow Steps

### Planning Phase
1. `plan_review` - Product Manager reviews progress and updates development plan
2. `issue_breakdown` - Product Manager creates issues for next sprint
3. `issue_validation` - Human validates issues (Checkpoint 1)

### Implementation Phase  
4. `branch_creation` - Engineer creates feature branch
5. `test_writing` - Engineer writes failing tests (TDD Red)
6. `implementation` - Engineer implements code to pass tests (TDD Green)
7. `refactoring` - Engineer improves code quality (TDD Refactor)
8. `code_sanity_check` - QA Engineer runs automated checks

### Validation Phase
9. `acceptance_test` - QA Engineer verifies requirements
10. `runnable_check` - Human tests feature functionality (Checkpoint 2)
11. `failure_analysis` - QA Engineer analyzes failures if needed

### Deployment Phase
12. `pull_request` - Engineer creates PR
13. `review` - QA Engineer reviews code quality
14. `merge` - Engineer merges approved changes
15. `deployment` - Engineer deploys to staging/production

## Workflow YAML Definition

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

## Roles and Access Rights

### Product Manager
- Read: vision.md, spec.md, plan.md
- Edit: plan.md
- Create: issues

### Engineer
- Read: issues, code
- Edit: code
- Create: code

### QA Engineer
- Read: spec.md, issues, code
- Edit: none
- Create: none

### Human
- Read: issues
- Edit: none
- Create: none

## Role YAML Definition

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

## Context Definitions

```yaml
contexts:
  vision:
    description: "Product vision - what you want to build"
    format: "Markdown document"
    created_by: "Human (initial phase)"
    example: |
      # Product Vision
      ## Problem to solve
      ## Target users
      ## Value proposition

  spec:
    description: "Functional requirements, specifications, and technical design"
    format: "Markdown document"
    created_by: "Human (initial phase)"
    example: |
      # Specification Document
      ## Functional requirements
      ## Non-functional requirements
      ## Technical stack
      ## Architecture
      ## Constraints

  plan:
    description: "Development plan and progress tracking"
    format: "Markdown document"
    created_by: "Human (initial phase)"
    updated_by: "product_manager (step_1)"
    example: |
      # Development Plan
      ## Milestones
      ## TODO List
      ## Completed items
      ## Next sprint plan

  issues:
    description: "Implementation task list"
    format: "GitHub Issues / Markdown"
    created_by: "product_manager (step_2)"
    example: |
      ## Title
      ## Overview
      ## Acceptance criteria
      ## Technical details

  code:
    description: "Source code (including implementation and tests)"
    format: "Programming language files"
    created_by: "engineer (step_4, step_5)"
    updated_by: "engineer (step_5, step_6)"
    note: "No distinction between test code and implementation code"
```

## Setup

```bash
git clone https://github.com/mizkun/vibeflow.git
cd vibeflow
./setup_vibeflow.sh
```

## Usage

1. Edit vision.md, spec.md, and plan.md with project details
2. Open project in Claude Code
3. Execute command: "開発サイクルを開始して"

## Available Commands

- `/progress` - Check current cycle position
- `/healthcheck` - Verify alignment between documents
- `/abort` - Stop current cycle
- `/next` - Continue to next step
- `/vibe-status` - Show configuration status

## Project Structure

```
/
├── .claude/agents/          # Subagent definitions
├── .claude/commands/        # Slash commands
├── .vibe/state.yaml        # Current cycle state
├── .vibe/templates/        # Issue templates
├── issues/                 # Implementation tasks
├── src/                   # Source code
├── vision.md              # Product vision
├── spec.md               # Specifications
├── plan.md               # Development plan
├── CLAUDE.md             # Framework documentation
└── setup_vibeflow.sh     # Setup script
```

## Rules

- Humans cannot access source code directly
- Each role has strict file access permissions
- TDD process must be followed
- Only 2 human checkpoints in entire cycle
- Automatic progression between non-human steps
