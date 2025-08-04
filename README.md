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

## Context Definitions

- **vision**: Product vision document (Markdown)
- **spec**: Functional requirements and technical specifications (Markdown)
- **plan**: Development plan and progress tracking (Markdown)
- **issues**: Implementation task list (Markdown/GitHub Issues)
- **code**: Source code including tests (Programming language files)

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
