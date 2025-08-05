# Vibe Coding Framework

AI-driven development methodology setup tool for Claude Code

## Overview

Vibe Coding Framework is an AI-driven development methodology designed for use with Claude Code. It enables efficient, high-quality development through role separation, automated workflows, and clear checkpoints.

## Features

- **Context-Based Access Control**: Each step has a specific role with defined read/edit/create permissions for different contexts
- **Strict Context Isolation**: Roles can only access contexts they need (e.g., Engineers read spec for implementation requirements, PMs cannot access code)
- **Role-Driven Development Cycle**: 11-step workflow with automatic role switching based on current step
- **Minimal Human Intervention**: Only 2 checkpoints where human validation is required
- **Automated Setup**: Complete development environment with a single command
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
2. Use the `/next` command to start the development cycle
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
      read: [vision.md, spec.md, plan.md, state.yaml, qa-reports/*]
      write: [plan.md, state.yaml]
      no_access: [src/*, *.test.*]
    purpose: Review and update development plan based on vision/spec
    
  step_2_issue_breakdown:
    role: Product Manager  
    access:
      read: [vision.md, spec.md, plan.md, state.yaml, qa-reports/*]
      write: [issues/*, state.yaml]
      no_access: [src/*, *.test.*]
    purpose: Create detailed, implementable issues from plan
    checkpoint: 2a_human_validation (required)
    
  step_3_branch_creation:
    role: Engineer
    access:
      read: [spec.md, issues/*, state.yaml]
      write: [.git/*, state.yaml]
      no_access: []
    purpose: Create feature branch for implementation
    
  step_4_test_writing:
    role: Engineer
    access:
      read: [spec.md, issues/*, src/*, state.yaml]
      write: [*.test.*, state.yaml]
      no_access: []
    purpose: Write failing tests first (TDD Red phase)
    
  step_5_implementation:
    role: Engineer
    access:
      read: [spec.md, issues/*, src/*, *.test.*, state.yaml]
      write: [src/*, state.yaml]
      no_access: []
    purpose: Implement code to pass tests (TDD Green phase)
    
  step_6_refactoring:
    role: Engineer
    access:
      read: [spec.md, issues/*, src/*, *.test.*, state.yaml]
      write: [src/*, state.yaml]
      no_access: []
    purpose: Improve code quality (TDD Refactor phase)
    checkpoint: 6a_code_sanity_check (automated)
    
  step_7_acceptance_test:
    role: QA Engineer
    access:
      read: [spec.md, issues/*, src/*, *.test.*, state.yaml, qa-reports/*]
      write: [test-results.log, qa-reports/*, state.yaml]
      no_access: [vision.md, plan.md]
    purpose: Verify implementation meets requirements
    checkpoint: 7a_human_runnable_check (required)
    
  step_8_pull_request:
    role: Engineer
    access:
      read: [spec.md, issues/*, src/*, state.yaml]
      write: [.git/*, state.yaml]
      no_access: []
    purpose: Create PR with proper documentation
    
  step_9_review:
    role: QA Engineer
    access:
      read: [spec.md, issues/*, src/*, state.yaml, qa-reports/*]
      write: [qa-reports/*, state.yaml]
      no_access: []
    purpose: Code review and quality check
    
  step_10_merge:
    role: Engineer
    access:
      read: [spec.md, src/*, state.yaml]
      write: [.git/*, state.yaml]
      no_access: []
    purpose: Merge approved changes to main
    
  step_11_deployment:
    role: Engineer
    access:
      read: [spec.md, src/*, state.yaml]
      write: [deployment.log, state.yaml]
      no_access: []
    purpose: Deploy to production
```

### Key Principles

1. **Context Isolation**: Each role can only see what they need - Engineers read spec for implementation requirements, PMs never see code to maintain abstraction
2. **Automated Progression**: Steps flow automatically with only 2 human checkpoints
3. **Verification at Each Step**: Each role verifies their own artifacts before proceeding
4. **Clear State Management**: state.yaml tracks current position and progress

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

All quick fixes are documented in git commit messages for tracking.

## Project Structure

After setup, the following structure is created:

```
your-project/
├── .claude/
│   ├── agents/         # Subagent definitions
│   │   ├── pm-auto.md
│   │   ├── engineer-auto.md
│   │   ├── qa-auto.md
│   │   └── quickfix-auto.md
│   └── commands/       # Slash commands
│       ├── progress.md
│       ├── healthcheck.md
│       └── ... (5 commands total)
├── .vibe/
│   ├── state.yaml      # Cycle state management
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

The framework provides 5 slash commands organized by category:

**Core Commands:**
- `/progress` - Check current progress and position
- `/healthcheck` - Verify repository consistency
- `/next` - Proceed to next step
- `/quickfix` - Enter Quick Fix mode for minor adjustments
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
- **templates/**: Contains issue templates for different types of development tasks

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

