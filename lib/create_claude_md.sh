#!/bin/bash

# Vibe Coding Framework - CLAUDE.md Creation
# This script creates the main CLAUDE.md documentation file

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create CLAUDE.md
create_claude_md() {
    section "CLAUDE.md を作成中"
    
    local claude_md_content='# Vibe Coding Framework - Context-Continuous Development

**Language**: Communicate in Japanese (日本語) for all interactions.

## Role-Based Development System

This framework implements a role-based development system where each step is executed by a specific role with clearly defined permissions and responsibilities.

## Role Definitions and Permissions

### Product Manager Role
**Responsibility**: Vision alignment, planning, and issue detailing

**Must Read** (Mandatory context):
- vision.md - Product vision and goals
- spec.md - Technical and functional specifications  
- plan.md - Development plan and progress
- .vibe/state.yaml - Current state tracking
- .vibe/qa-reports/* - QA findings for planning decisions

**Can Edit**:
- plan.md - Update progress and TODOs
- issues/* - Modify issue files
- .vibe/state.yaml - Update workflow state

**Can Create**:
- issues/* - New issue files

### Engineer Role
**Responsibility**: Implementation, testing, and refactoring

**Must Read** (Mandatory context):
- spec.md - Technical requirements
- issues/* - Current issue details
- src/* - Source code
- .vibe/state.yaml - Current state

**Can Edit**:
- src/* - Source code files
- *.test.* - Test files
- .vibe/state.yaml - Update workflow state

**Can Create**:
- src/* - New source files
- *.test.* - New test files

### QA Engineer Role
**Responsibility**: Acceptance testing, quality verification, and review

**Must Read** (Mandatory context):
- spec.md - Requirements to verify against
- issues/* - Issue acceptance criteria
- src/* - Code to review
- .vibe/state.yaml - Current state
- .vibe/qa-reports/* - Previous QA findings

**Can Edit**:
- .vibe/test-results.log - Test execution results
- .vibe/qa-reports/* - QA findings and reports
- .vibe/state.yaml - Update workflow state

**Can Create**:
- .vibe/qa-reports/* - New QA reports
- .vibe/test-results.log - Test result logs

## Workflow Steps and Role Assignments

**Note**: For detailed execution instructions for each role, refer to:
- Product Manager: `.vibe/roles/product-manager.md`
- Engineer: `.vibe/roles/engineer.md`
- QA Engineer: `.vibe/roles/qa-engineer.md`

```yaml
workflow:
  step_1_plan_review:
    role: Product Manager
    mission: Review progress against vision/spec and update development plan
    
  step_2_issue_breakdown:
    role: Product Manager  
    mission: Create detailed, implementable issues from plan
    
  step_2a_issue_validation:
    role: Human
    mission: Validate issues are clear and implementable
    
  step_3_branch_creation:
    role: Engineer
    mission: Create feature branch for implementation
    
  step_4_test_writing:
    role: Engineer
    mission: Write failing tests first (TDD Red phase)
    
  step_5_implementation:
    role: Engineer
    mission: Write minimal code to pass tests (TDD Green phase)
    
  step_6_refactoring:
    role: Engineer
    mission: Improve code quality while keeping tests green (TDD Refactor phase)
    
  step_6a_code_sanity_check:
    role: QA Engineer
    mission: Run automated quality checks and linting
    
  step_7_acceptance_test:
    role: QA Engineer
    mission: Verify implementation meets requirements
    
  step_7a_runnable_check:
    role: Human
    mission: Manual testing of implemented features
    
  step_8_pull_request:
    role: Engineer
    mission: Create PR with comprehensive documentation
    
  step_9_review:
    role: QA Engineer
    mission: Code review and quality assessment
    
  step_10_merge:
    role: Engineer
    mission: Merge approved changes to main branch
    
  step_11_deployment:
    role: Engineer
    mission: Deploy to production environment
```

## Workflow Execution Protocol

For each step execution:

1. **Load State**: Read `.vibe/state.yaml` to understand current position
2. **Declare Role Transition**: Explicitly announce role change
3. **Enforce Permissions**: Only access files allowed for current role
4. **Update State**: Record progress in `.vibe/state.yaml`

### Role Transition Declaration Format
```
========================================
🔄 ROLE TRANSITION
Previous Step: [step_name] ([previous_role])
Current Step:  [step_name] ([current_role])
Issue:         [current_issue]
Now operating as: [CURRENT_ROLE]
Must read: [list of mandatory files]
Can modify: [list of editable files]
========================================
```

## Critical Rules

1. **Context Continuity**: All work executed in main context for information preservation
2. **TDD Enforcement**: Tests must be written before implementation (Red-Green-Refactor)
3. **File Verification**: Verify artifacts exist before proceeding to next step
4. **Human Checkpoints**: Only at step 2a (issue validation) and 7a (manual testing)
5. **Permission Enforcement**: Strictly follow role-based file access permissions
6. **State Management**: Always update state.yaml after completing each step

## Available Commands

- `/next` - Proceed to next step with role transition
- `/progress` - Check current progress and role status
- `/healthcheck` - Verify repository consistency
- `/quickfix` - Enter quick fix mode for minor adjustments
- `/exit-quickfix` - Exit quick fix mode
- `/parallel-test` - Run tests in parallel

## Quick Fix Mode

A streamlined mode for minor changes outside the normal workflow:
- **Execution**: Runs in main context with relaxed permissions
- **Allowed Changes**: UI styling, typo fixes, small bug fixes
- **Restrictions**: <5 files, <50 lines total changes

## State Management Structure

`.vibe/state.yaml` structure:
```yaml
current_cycle: 1
current_step: 1_plan_review
current_issue: null
current_role: "Product Manager"
last_role_transition: null
last_completed_step: null
next_step: 2_issue_breakdown

# Human checkpoint status
checkpoint_status:
  2a_issue_validation: pending
  7a_runnable_check: pending

# Issues tracking
issues_created: []
issues_completed: []

# Quick fixes tracking
quick_fixes: []
```

## Development Guidelines

1. **Role Immersion**: Fully embody the current role'\''s perspective
2. **Permission Compliance**: Strictly adhere to file access permissions
3. **Context Inheritance**: Ensure outputs from previous steps are utilized
4. **Explicit Transitions**: Always declare role changes clearly
5. **Quality Focus**: Each role ensures quality within their domain'

    if create_file_with_backup "CLAUDE.md" "$claude_md_content"; then
        # Append explicit user-interaction requirements (English)
        cat >> "CLAUDE.md" << 'EOF'

## User Interaction Requirements

1. Stop immediately: If any step requires user action, halt execution and wait for explicit user confirmation.
2. Step-by-step guidance: Provide clear, step-by-step instructions in Japanese for the user's actions.
3. Real data only: Never use mock data or dummy IDs; always work with real, provided data.
4. Explicit confirmation: When IDs, keys, or credentials are required, explicitly ask the user and confirm before proceeding.

### Situations that require stopping
- When configuration in Firebase Console is required
- When API keys or credentials are required
- When user-specific information (e.g., admin UID) is required
- When integration with external services must be configured
- When deploying or making changes to production environments

### Prohibited actions
- Using mock IDs or dummy data
- Using placeholders like "your-api-key" in implementation
- Assuming external service configuration without user confirmation
- Running tests without real credentials

## Hooks, Subagents, and Skills

### Hooks (Automatic Guardrails)

The framework uses Claude Code hooks for automatic safety and notification:

- **PreToolUse** (`validate_access.py`): Access control that blocks unauthorized file edits based on current role. Exit code 2 blocks the tool call.
- **PostToolUse** (`task_complete.sh`): Plays notification sound on Edit/Write/MultiEdit/TodoWrite completion.
- **Stop** (`waiting_input.sh`): Plays notification sound when waiting for user input.

Configuration: `.claude/settings.json`

### Available Subagents

Use these subagents for independent, context-isolated tasks:

- `qa-acceptance`: Validate acceptance criteria and generate QA reports under `.vibe/qa-reports/`
- `code-reviewer`: Read-only code review with checklist output (tools: Read, Grep, Glob only)
- `test-runner`: Parallel test execution for unit/integration/e2e tests

Invoke with: `/agents` command in Claude Code

### Available Skills

Skills are reusable procedure templates loaded on demand:

- `vibeflow-issue-template`: Create structured issue files with all required sections
- `vibeflow-tdd`: TDD Red-Green-Refactor cycle guidance

Skills location: `.claude/skills/*/SKILL.md`

### Disabling Hooks (Emergency)

If hooks cause issues, create `.claude/settings.local.json`:
```json
{
  "disableAllHooks": true
}
```

Template available at: `.vibe/templates/settings.local.json`
EOF
        
        success "CLAUDE.md の作成が完了しました"
        return 0
    else
        error "CLAUDE.md の作成に失敗しました"
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_claude_md
fi