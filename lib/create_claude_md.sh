#!/bin/bash

# Vibe Coding Framework - CLAUDE.md Creation
# This script creates the main CLAUDE.md documentation file

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create CLAUDE.md
create_claude_md() {
    section "CLAUDE.md を作成中"
    
    local claude_md_content='# CLAUDE.md - Vibe Coding Framework

**Language**: Communicate in Japanese (日本語) for all interactions.

This project follows the **Vibe Coding Framework** - an 11-step TDD development cycle with strict role separation.

## Workflow Steps

**Note**: Each role'\''s detailed mission and instructions are defined in `.claude/agents/{role}-auto.md`. Always refer to the specific agent file for complete implementation guidance.

```yaml
workflow:
  1_plan_review:       { role: product_manager, mission: "Review progress and update development plan" }
  2_issue_breakdown:   { role: product_manager, mission: "Create detailed implementable issues" }
  2a_issue_validation: { role: human, mission: "Validate issues are clear and implementable" }
  3_branch_creation:   { role: engineer, mission: "Create feature branch for implementation" }
  4_test_writing:      { role: engineer, mission: "Write failing tests (TDD Red phase)" }
  5_implementation:    { role: engineer, mission: "Write code to pass tests (TDD Green phase)" }
  6_refactoring:       { role: engineer, mission: "Improve code quality (TDD Refactor phase)" }
  6a_code_sanity_check: { role: qa_engineer, mission: "Run automated quality checks" }
  7_acceptance_test:   { role: qa_engineer, mission: "Verify requirements are met" }
  7a_runnable_check:   { role: human, mission: "Manual feature testing" }
  8_pull_request:      { role: engineer, mission: "Create PR with documentation" }
  9_review:            { role: qa_engineer, mission: "Code review and quality check" }
  10_merge:            { role: engineer, mission: "Merge approved changes to main" }
  11_deployment:       { role: engineer, mission: "Deploy to production" }
```

## Role Permissions

```yaml
roles:
  product_manager:
    Must_Read: [vision, spec, plan, qa_reports]
    Can_Edit: [plan, issues]
    Can_Create: [issues]

  engineer:
    Must_Read: [spec, issues, code, qa_reports]
    Can_Edit: [code]
    Can_Create: [code]

  qa_engineer:
    Must_Read: [spec, issues, code, qa_reports]
    Can_Edit: [qa_reports]
    Can_Create: [qa_reports]
```

## Critical Rules

1. **TDD Enforcement**: Tests written before implementation (Red-Green-Refactor)
2. **File Verification**: Each step must verify artifacts exist before proceeding
3. **Human Checkpoints**: Only 2a (issue validation) and 7a (manual testing)
4. **Must_Read Mandatory**: All roles must read required contexts before action
5. **State Updates**: Always update .vibe/state.yaml after each step

## Available Commands

- `/next` - Proceed to next step
- `/progress` - Check current progress  
- `/healthcheck` - Verify repository consistency
- `/quickfix` - Enter Quick Fix mode
- `/exit-quickfix` - Exit Quick Fix mode

## Subagents

- **pm-auto**: Steps 1-2 (planning, issue creation)
- **engineer-auto**: Steps 3-6, 8, 10-11 (implementation, PR, merge, deploy)
- **qa-auto**: Steps 6a, 7, 9 (quality assurance, testing, review)
- **quickfix-auto**: Minor fixes outside main cycle'

    if create_file_with_backup "CLAUDE.md" "$claude_md_content"; then
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