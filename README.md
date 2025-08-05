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
- [Project Structure](#project-structure)
- [Available Commands](#available-commands)
- [Examples](#examples)
- [Technical Architecture](#technical-architecture)
- [Contributing](#contributing)

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

### The 11-Step Development Cycle

1. **Plan Review**: Product Manager reviews the development plan
2. **Issue Breakdown**: Create specific implementation tasks
   - **Checkpoint 2a**: Human validates issues
3. **Branch Creation**: Create feature branches
4. **Test Writing**: Write tests before implementation (TDD)
5. **Implementation**: Engineer implements features
6. **Refactoring**: Improve code quality
   - **Checkpoint 6a**: Code quality check
7. **Acceptance Test**: QA Engineer validates implementation
   - **Checkpoint 7a**: Human runnable check
   - **7b**: Failure analysis if needed
8. **Pull Request**: Create PR for review
9. **Review**: Code review and feedback
10. **Merge**: Merge approved changes
11. **Deployment**: Deploy to production

### Role Separation

- **Product Manager**: Plans review, issue creation, project management
- **Engineer**: Implementation, testing, refactoring
- **QA Engineer**: Quality assurance, acceptance testing
- **Human**: Final validation at checkpoints

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

### Role-Based Access Control

Each role has specific permissions:

```yaml
PM:
  read: [vision.md, spec.md, plan.md, issues/, state.yaml]
  write: [plan.md, issues/, state.yaml]
  no_access: [src/]

Engineer:
  read: [issues/, src/, state.yaml]
  write: [src/, state.yaml]
  no_access: [vision.md, spec.md]
```

### Verification System

Automated checks prevent common issues:

- File existence verification
- Test execution status
- Build success verification
- Acceptance criteria tracking

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For major changes, please open an issue first to discuss what you would like to change.