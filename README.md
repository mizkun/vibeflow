# Vibe Coding Framework

AI-driven development methodology setup tool for Claude Code

## Overview

Vibe Coding Framework is an AI-driven development methodology designed for use with Claude Code. It enables efficient, high-quality development through role separation, automated workflows, and clear checkpoints.

## Features

- **Context-Based Access Control**: Each step has a specific role with defined read/edit/create permissions for different contexts
- **Strict Context Isolation**: Roles can only access contexts they need (e.g., Engineers cannot read vision/spec, Humans cannot access code)
- **Role-Driven Development Cycle**: 11-step workflow with automatic role switching based on current step
- **Minimal Human Intervention**: Only 2 checkpoints where human validation is required
- **Automated Setup**: Complete development environment with a single command
- **Orchestrator Context**: Shared coordination space that tracks project health, artifacts, and cross-role communication
- **Automated Verification**: Each step verifies artifacts exist before proceeding, preventing "success theater"

## Quick Start

```bash
# Clone the repository
git clone https://github.com/mizkun/vibeflow.git

# Create a new project directory
mkdir my-project
cd my-project

# Run setup
../vibeflow/setup_vibeflow.sh
```

## Table of Contents

- [Installation](#installation)
- [Detailed Setup Guide](#detailed-setup-guide)
- [How It Works](#how-it-works)
  - [Core Concept: Role-Based Development Workflow](#core-concept-role-based-development-workflow)
  - [Key Principles](#key-principles)
- [Optional Features](#optional-features)
  - [E2E Testing with Playwright](#e2e-testing-with-playwright)
  - [Notification Sounds](#notification-sounds)
  - [Quick Fix Mode](#quick-fix-mode)
- [Project Structure](#project-structure)
- [Available Commands](#available-commands)
  - [Slash Commands](#slash-commands)
  - [Script Options](#script-options)
- [Examples](#examples)
- [Technical Architecture](#technical-architecture)
  - [State Management](#state-management)
  - [Why This Architecture?](#why-this-architecture)
  - [Verification System](#verification-system)

## Installation

### Prerequisites

- macOS or Linux
- Bash shell
- Git (optional, for project management)
- Claude Code

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/mizkun/vibeflow.git
   cd vibeflow
   ```

2. **Create a new project directory**:
   
   **Important**: Run setup_vibeflow.sh in the directory where you want to create your project. Do not run it directly in the repository.
   
   ```bash
   # Create a new project directory
   mkdir ~/my-vibe-project
   cd ~/my-vibe-project
   
   # Run the setup script
   ~/path/to/vibeflow/setup_vibeflow.sh
   ```

3. **Setup options**:
   ```bash
   # Show help
   ./setup_vibeflow.sh --help
   
   # Install without confirmation
   ./setup_vibeflow.sh --force
   
   # Skip backup
   ./setup_vibeflow.sh --no-backup
   
   # Install with E2E testing support (Playwright)
   ./setup_vibeflow.sh --with-e2e
   
   # Install with notification sounds
   ./setup_vibeflow.sh --with-notifications
   
   # Install with all features
   ./setup_vibeflow.sh --with-e2e --with-notifications
   
   # Check version
   ./setup_vibeflow.sh --version
   ```

## Detailed Setup Guide

### Initial Configuration

After setup completes, edit the following files to define your project:

#### 1. vision.md
Define your product vision:
- Problem to solve
- Target users
- Value proposition
- Product overview
- Success criteria

#### 2. spec.md
Define specifications and technical design:
- Functional requirements (must-have, nice-to-have)
- Non-functional requirements (performance, security, availability)
- Technology stack
- Architecture
- Constraints

#### 3. plan.md
Define development plan and TODOs:
- Milestones
- TODO list (by priority)
- Completed items
- Next sprint plan

### Using with Claude Code

1. Open the project directory in Claude Code
2. Type "Start the development cycle" (or in Japanese: "開発サイクルを開始して")
3. AI will automatically proceed with the development flow

## How It Works

### Core Concept: Role-Based Development Workflow

The most important innovation of Vibe Coding Framework is the **strict role separation with context-based access control**. Each step in the development cycle is executed by a specific role with precisely defined permissions:

```yaml
# Step-by-Step Role and Permission Definition
workflow:
  step_1_plan_review:
    role: Product Manager
    access:
      read: [vision.md, spec.md, plan.md, state.yaml, orchestrator.yaml]
      write: [plan.md, state.yaml, orchestrator.yaml]
      no_access: [src/*, *.test.*]
    purpose: Review and update development plan based on vision/spec
    
  step_2_issue_breakdown:
    role: Product Manager  
    access:
      read: [vision.md, spec.md, plan.md, state.yaml, orchestrator.yaml]
      write: [issues/*, state.yaml, orchestrator.yaml]
      no_access: [src/*, *.test.*]
    purpose: Create detailed, implementable issues from plan
    checkpoint: 2a_human_validation (required)
    
  step_3_branch_creation:
    role: Engineer
    access:
      read: [issues/*, state.yaml, orchestrator.yaml]
      write: [.git/*, state.yaml]
      no_access: [vision.md, spec.md, plan.md]
    purpose: Create feature branch for implementation
    
  step_4_test_writing:
    role: Engineer
    access:
      read: [issues/*, src/*, state.yaml, orchestrator.yaml]
      write: [*.test.*, state.yaml, orchestrator.yaml]
      no_access: [vision.md, spec.md, plan.md]
    purpose: Write failing tests first (TDD Red phase)
    
  step_5_implementation:
    role: Engineer
    access:
      read: [issues/*, src/*, *.test.*, state.yaml, orchestrator.yaml]
      write: [src/*, state.yaml, orchestrator.yaml]
      no_access: [vision.md, spec.md, plan.md]
    purpose: Implement code to pass tests (TDD Green phase)
    
  step_6_refactoring:
    role: Engineer
    access:
      read: [issues/*, src/*, *.test.*, state.yaml, orchestrator.yaml]
      write: [src/*, state.yaml, orchestrator.yaml]
      no_access: [vision.md, spec.md, plan.md]
    purpose: Improve code quality (TDD Refactor phase)
    checkpoint: 6a_code_sanity_check (automated)
    
  step_7_acceptance_test:
    role: QA Engineer
    access:
      read: [spec.md, issues/*, src/*, *.test.*, state.yaml, orchestrator.yaml]
      write: [test-results.log, state.yaml, orchestrator.yaml]
      no_access: [vision.md, plan.md]
    purpose: Verify implementation meets requirements
    checkpoint: 7a_human_runnable_check (required)
    
  step_8_pull_request:
    role: Engineer
    access:
      read: [issues/*, src/*, state.yaml, orchestrator.yaml]
      write: [.git/*, state.yaml, orchestrator.yaml]
      no_access: [vision.md, spec.md, plan.md]
    purpose: Create PR with proper documentation
    
  step_9_review:
    role: QA Engineer
    access:
      read: [spec.md, issues/*, src/*, state.yaml, orchestrator.yaml]
      write: [state.yaml, orchestrator.yaml]
      no_access: [vision.md, plan.md]
    purpose: Code review and quality check
    
  step_10_merge:
    role: Engineer
    access:
      read: [src/*, state.yaml, orchestrator.yaml]
      write: [.git/*, state.yaml, orchestrator.yaml]
      no_access: [vision.md, spec.md, plan.md]
    purpose: Merge approved changes to main
    
  step_11_deployment:
    role: Engineer
    access:
      read: [src/*, state.yaml, orchestrator.yaml]
      write: [deployment.log, plan.md, state.yaml, orchestrator.yaml]
      no_access: [vision.md, spec.md]
    purpose: Deploy to production and update plan
```

### Key Principles

1. **Context Isolation**: Each role can only see what they need - Engineers never see the vision to avoid bias, PMs never see code to maintain abstraction
2. **Automated Progression**: Steps flow automatically with only 2 human checkpoints
3. **Verification at Each Step**: Orchestrator tracks artifacts and verifies completion
4. **Cross-Role Communication**: Orchestrator serves as shared space for critical information without breaking isolation

## Optional Features

### E2E Testing with Playwright

When installed with `--with-e2e`, the framework includes:

- Playwright configuration for cross-browser testing
- E2E test directory structure (`tests/e2e/`)
- Sample test files and page objects
- Integration with the QA verification process
- New command: `/run-e2e` to execute E2E tests

To use E2E testing:
1. Install dependencies: `npm install @playwright/test`
2. Install browsers: `npx playwright install`
3. Write tests in `tests/e2e/`
4. Run tests: `npm run test:e2e` or `/run-e2e`

### Notification Sounds

When installed with `--with-notifications`, the framework includes:

- OS-specific notification scripts
- Claude Code hook configurations
- Sound notifications for:
  - Task completion
  - Waiting for user input
  - Error occurrences

To enable notifications:
1. Copy `.vibe/templates/claude-settings.json` to `~/.config/claude/settings.json`
2. Restart Claude Code
3. Test with: `.vibe/hooks/task_complete.sh`

### Quick Fix Mode

Quick Fix Mode allows rapid minor adjustments outside the normal development cycle:

- **Purpose**: UI tweaks, typo fixes, small bug fixes without full TDD process
- **Activation**: `/quickfix [description of changes]`
- **Deactivation**: `/exit-quickfix`

**Allowed changes:**
- CSS/style adjustments
- Text content updates
- Small logic fixes (< 50 lines)
- UI component tweaks

**Restrictions:**
- No new features
- No database changes
- No API modifications
- Maximum 5 files per fix

All quick fixes are logged in `.vibe/orchestrator.yaml` for tracking.

## Project Structure

After setup, the following structure is created:

```
your-project/
├── .claude/
│   ├── agents/         # Subagent definitions
│   │   ├── pm-auto.md
│   │   ├── engineer-auto.md
│   │   ├── qa-auto.md
│   │   ├── deploy-auto.md
│   │   └── quickfix-auto.md
│   └── commands/       # Slash commands
│       ├── progress.md
│       ├── healthcheck.md
│       └── ... (15 commands total)
├── .vibe/
│   ├── state.yaml      # Cycle state management
│   ├── orchestrator.yaml # Project health and cross-role coordination
│   ├── verification_rules.yaml # Automated verification rules
│   └── templates/      # Issue templates
├── issues/             # Implementation tasks
├── src/                # Source code
├── CLAUDE.md           # Framework documentation
├── vision.md           # Product vision
├── spec.md             # Specifications
└── plan.md             # Development plan
```

## Available Commands

### Slash Commands

The framework provides 13 slash commands organized by category:

**Flow Control:**
- `/progress` - Show current development progress
- `/next` - Proceed to next step
- `/restart-cycle` - Restart the development cycle
- `/abort` - Abort current operation
- `/skip-tests` - Skip test execution (use with caution)

**Status & Diagnostics:**
- `/vibe-status` - Show Vibe framework status
- `/health-check` - Comprehensive project health assessment
- `/orchestrator-status` - View project health and accumulated warnings
- `/verify-step` - Verify current step artifacts and requirements

**Testing:**
- `/run-e2e` - Run E2E tests using Playwright (requires --with-e2e setup)

**Role Management:**
- `/role-product_manager` - Switch to Product Manager role
- `/role-engineer` - Switch to Engineer role
- `/role-qa_engineer` - Switch to QA Engineer role
- `/role-reset` - Reset role to default

**Quick Fix Mode:**
- `/quickfix` - Enter Quick Fix mode for minor UI adjustments
- `/exit-quickfix` - Exit Quick Fix mode and return to normal cycle

### Script Options

```bash
# Display help
./setup_vibeflow.sh --help

# Force installation (skip confirmations)
./setup_vibeflow.sh --force

# Skip backup creation
./setup_vibeflow.sh --no-backup

# Display version
./setup_vibeflow.sh --version
```

## Examples

### Creating a Todo App

1. Setup project:
   ```bash
   mkdir todo-app
   cd todo-app
   ../vibeflow/setup_vibeflow.sh
   ```

2. Define vision.md:
   ```markdown
   # Todo App Vision
   
   ## Problem
   Users need a simple, fast way to manage daily tasks
   
   ## Target Users
   Busy professionals who need quick task management
   
   ## Success Criteria
   - Users can create/edit/delete tasks in < 2 seconds
   - 95% uptime
   - Works on mobile and desktop
   ```

3. Define spec.md and plan.md similarly

4. Start development:
   ```
   Claude Code: "Start the development cycle"
   ```

## Technical Architecture

### State Management

The framework uses YAML files for state persistence:

- **state.yaml**: Tracks current cycle, step, and issue
- **orchestrator.yaml**: Maintains project health and cross-role communication
- **verification_rules.yaml**: Defines automated checks for each step

### Why This Architecture?

1. **Prevents Context Contamination**: Engineers implement based on clear requirements, not interpretations of vision
2. **Ensures Traceability**: Every code change traces back to an issue, which traces to spec/vision
3. **Maintains Quality**: Multiple verification points catch issues early
4. **Enables Automation**: Clear role boundaries allow AI to execute most steps autonomously

### Verification System

Automated checks prevent common issues:

- File existence verification
- Test execution status
- Build success verification
- Acceptance criteria tracking

