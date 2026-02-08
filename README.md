# VibeFlow

AI-driven development methodology for Claude Code

## Overview

VibeFlow is an AI-driven development methodology designed for use with Claude Code. It enables efficient, high-quality development through role separation, automated workflows, and clear checkpoints.

## Features

- **Context-Based Access Control**: Each step has a specific role with defined read/edit/create permissions
- **Strict Context Isolation**: Roles have defined permissions (e.g., Engineers can only edit code, PMs can only edit plan/issues)
- **Role-Based Context-Continuous System**: No separate agent files - role switching handled seamlessly within main context
- **Discovery Phase**: Brainstorming mode (`/discuss`, `/conclude`) for product direction and technical decisions before development
- **Agent Team / context: fork**: Multi-perspective discussions (Agent Team) and delegated execution (context: fork) for key steps
- **Safety Rules**: Atomic UI changes, destructive operation protection, retry limits, plans/ directory blocking
- **11-Step Development Workflow**: Automatic progression through development cycle with role-based permissions
- **Minimal Human Intervention**: Only 2 checkpoints where human validation is required
- **Automated Setup & Upgrade**: Complete development environment with a single command, and migration framework for version upgrades

## Quick Start

```bash
# Install VibeFlow
git clone https://github.com/mizkun/vibeflow.git ~/vibeflow
cd ~/vibeflow && ./install.sh

# Create a new project
mkdir my-project && cd my-project
vibeflow setup

# Start development
# Use /discuss for brainstorming, /next for development cycle
```

## Table of Contents

- [Installation](#installation)
- [Upgrading Existing Projects](#upgrading-existing-projects)
- [Detailed Setup Guide](#detailed-setup-guide)
- [How It Works](#how-it-works)
  - [Development Phases](#development-phases)
  - [Core Concept: Role-Based Development Workflow](#core-concept-role-based-development-workflow)
  - [Execution Modes](#execution-modes)
  - [Key Principles](#key-principles)
- [Built-in Features](#built-in-features)
- [Project Structure](#project-structure)
- [Available Commands](#available-commands)
  - [CLI Commands](#cli-commands)
  - [Slash Commands](#slash-commands)
- [Examples](#examples)
- [Technical Architecture](#technical-architecture)
  - [State Management](#state-management)
  - [Why This Architecture?](#why-this-architecture)
  - [Verification System](#verification-system)

## Installation

### Prerequisites

- macOS or Linux
- Bash shell
- Git
- Claude Code
- yq (`brew install yq` / `snap install yq`)

### Install

```bash
git clone https://github.com/mizkun/vibeflow.git ~/vibeflow
cd ~/vibeflow && ./install.sh
```

This installs the `vibeflow` command, making it available from anywhere.

### Quick Start

```bash
# New project
mkdir my-project && cd my-project
vibeflow setup

# Update framework and apply to existing project
cd ~/vibeflow && git pull
cd ~/my-project && vibeflow upgrade
```

### CLI Commands

| Command | Description |
|---|---|
| `vibeflow setup [options]` | Set up a new project |
| `vibeflow upgrade [options]` | Upgrade an existing project to latest version |
| `vibeflow version` | Show version information |
| `vibeflow doctor` | Diagnose environment issues |
| `vibeflow help` | Show help |

### Setup Options

```bash
vibeflow setup --force              # Skip confirmations
vibeflow setup --no-backup          # Skip backup
vibeflow setup --without-e2e        # Without E2E testing support
vibeflow setup --without-notifications  # Without notification sounds
```

### Uninstall

```bash
cd ~/vibeflow && ./uninstall.sh
```

## Upgrading Existing Projects

Upgrade existing VibeFlow projects to the latest version:

```bash
cd your-project
vibeflow upgrade
```

### Upgrade Options

| Option | Description |
|---|---|
| `--dry-run` | Show what would be done without making changes |
| `--force` | Skip confirmation prompts |
| `--no-backup` | Skip backup (not recommended) |

### How Upgrade Works

1. Compares `.vibe/version` with the framework `VERSION`
2. Identifies applicable migration scripts
3. Creates a backup (git commit + file copy)
4. Applies migrations in order
5. Updates the version file

Migrations are idempotent. If a migration fails midway, re-running will continue from where it left off.

### Adding Migrations (for contributors)

1. Update the `VERSION` file to the new version
2. Create `migrations/v{old}_to_v{new}.sh`
3. Source `"${VIBEFLOW_FRAMEWORK_DIR}/lib/migration_helpers.sh"` for helpers
4. Use idempotent helper functions:
   - `copy_if_absent src dst` -- Copy file if destination doesn't exist
   - `ensure_dir path` -- Create directory if it doesn't exist
   - `append_section_if_absent file marker content` -- Append section if marker not present
   - `replace_section file start end content` -- Replace section between markers
   - `add_yaml_field_if_absent file key value` -- Add YAML field if not present
   - `insert_hook_rule_if_absent file marker rule position` -- Insert hook rule if marker not present
5. `chmod +x` the migration script

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
2. Use `/discuss` to brainstorm and validate product direction
3. Use `/conclude` to finalize discussion results into vision/spec/plan
4. Use `/next` to progress through the development cycle

## How It Works

### Development Phases

VibeFlow has two phases:

**Discovery Phase** (outside development cycle)
- Activated with `/discuss [topic]`
- Role: Discussion Partner (all files read-only except `.vibe/discussions/`)
- Brainstorm product direction, technical decisions, and business strategy
- End with `/conclude` to reflect conclusions into vision.md / spec.md / plan.md

**Development Cycle** (the main workflow)
- Activated with `/next`
- 11 steps with role-based access control
- 2 human checkpoints (issue validation + runnable check)

### Core Concept: Role-Based Development Workflow

The most important innovation of VibeFlow is the **context-continuous role-based system**. All roles operate within a single context with dynamic permission switching:

| Role | Steps | Responsibilities |
|---|---|---|
| Product Manager | 1, 2 | Plan review, issue breakdown |
| Discussion Partner | Discovery | Brainstorming, direction validation |
| Infrastructure Manager | 2.5, 6.5 | Hook permission setup/rollback |
| Engineer | 3, 4, 5, 6, 8, 10, 11 | Branch, TDD, implementation, PR, merge, deploy |
| QA Engineer | 7, 9 | Acceptance testing, code review |

### Execution Modes

Each step has an execution mode:

- **solo**: Main agent executes directly (default)
- **team**: Agent Team spawns multiple perspectives (requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- **fork**: context: fork delegates to separate agent inheriting PM context (requires Claude Code 2.1.20+)

Agent Team / fork automatically falls back to solo if unavailable.

| Step | Mode | Team (if applicable) |
|---|---|---|
| Step 2: Issue Breakdown | team | PM (lead), Technical Feasibility Analyst, UX Critic, Devil's Advocate |
| Steps 4, 5, 6: TDD | fork | - |
| Step 7: Acceptance Test | team | QA Lead, Spec Compliance Checker, Edge Case Hunter, UI Visual Verifier |
| Step 9: Code Review | team | QA Lead, Security Reviewer, Performance Reviewer, Test Coverage Reviewer |

### Key Principles

1. **Context-Continuous Operation**: All roles operate within the same context with dynamic permission switching
2. **No Separate Agent Files**: Role-based permissions are embedded in the `/next` command logic
3. **Automated Progression**: Steps flow automatically with only 2 human checkpoints
4. **Verification at Each Step**: Each role verifies their own artifacts before proceeding
5. **Clear State Management**: state.yaml tracks current position and progress
6. **Safety First**: Atomic UI changes, destructive op protection, retry limits

## Built-in Features

### Discovery Phase
Brainstorm and validate product direction with `/discuss`. The Discussion Partner role provides counterarguments, questions assumptions, and organizes discussion points. Conclusions are reflected back to vision.md, spec.md, and plan.md via `/conclude`.

### Safety Rules
- **Atomic UI Changes**: CSS/HTML changes are made one at a time with user confirmation
- **Destructive Operation Protection**: `rm -rf`, `git reset --hard`, etc. require user confirmation
- **Retry Limits**: Same approach limited to 2 retries before requiring a different approach
- **plans/ Directory Blocking**: Write guard hook prevents creating plans/ directory (use plan.md or issues/ instead)
- **Hook Permission Control**: Infrastructure Manager role manages write permissions per issue

### E2E Testing with Playwright
Includes Playwright configuration, test structure (`tests/e2e/`), and `/run-e2e` command by default. Install with `npm install @playwright/test` and `npx playwright install`.

### Notification Sounds
OS-specific notification scripts and Claude Code hook configurations for task completion, waiting input, and error alerts. Enable by copying `.vibe/templates/claude-settings.json` to `~/.config/claude/settings.json`.

### Role-Based Permissions
Strict context isolation with Must Read/Can Edit/Can Create permissions for each role, enforced by `validate_access.py` hook.

## Project Structure

After setup, the following structure is created:

```
your-project/
├── .claude/
│   ├── settings.json          # Hook configuration
│   └── commands/              # Slash commands
│       ├── progress.md
│       ├── healthcheck.md
│       ├── next.md
│       ├── discuss.md         # Discovery Phase start
│       ├── conclude.md        # Discovery Phase end
│       └── run-e2e.md         # E2E test execution
├── .vibe/
│   ├── version                # VibeFlow version tracking
│   ├── state.yaml             # Cycle state management
│   ├── policy.yaml            # Role-based access policy
│   ├── hooks/                 # Access control hooks
│   │   ├── validate_access.py # Role-based access control
│   │   ├── validate_write.sh  # Write guard (plans/ block)
│   │   ├── task_complete.sh   # Notification sounds
│   │   ├── waiting_input.sh
│   │   └── error_occurred.sh
│   ├── roles/                 # Role documentation
│   │   ├── product-manager.md
│   │   ├── engineer.md
│   │   ├── qa-engineer.md
│   │   ├── discussion-partner.md
│   │   └── infra.md
│   ├── discussions/           # Discovery Phase discussions
│   ├── backups/               # Upgrade backups
│   └── templates/             # Templates and config
│       ├── issue-templates.md
│       ├── discussion-template.md
│       ├── claude-settings.json
│       └── e2e-scripts.json
├── tests/                     # E2E tests
│   └── e2e/
├── issues/                    # Implementation tasks
├── src/                       # Source code
├── CLAUDE.md                  # Framework documentation
├── vision.md                  # Product vision
├── spec.md                    # Specifications
└── plan.md                    # Development plan
```

## Available Commands

### Slash Commands

The framework provides 6 slash commands:

- `/discuss [topic]` - Start Discovery Phase for brainstorming and direction validation
- `/conclude` - End Discovery Phase and reflect conclusions to vision/spec/plan
- `/next` - Proceed to next step in development cycle (handles all role switching)
- `/progress` - Check current progress and position
- `/healthcheck` - Verify repository consistency
- `/run-e2e` - Execute E2E tests with Playwright

### Agent Team Environment Variable

To enable Agent Team mode (multi-perspective discussions at Steps 2, 7, 9):

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Without this, Agent Team steps fall back to solo mode.

## Example

The `examples/` directory contains a complete template showing the framework structure:

### Using the Example Template

1. **Copy the example structure**:
   ```bash
   cp -r vibeflow/examples/* your-project/
   cd your-project
   ```

2. **Edit the template files**:
   - `vision.md` - Define your product vision and goals
   - `spec.md` - Specify functional and technical requirements
   - `plan.md` - Create development milestones and tasks

3. **Start development**:
   ```bash
   /discuss "Product direction"   # Brainstorm first
   /conclude                      # Finalize direction
   /next                          # Start development cycle
   ```

### Creating from Scratch

```bash
mkdir my-project && cd my-project
vibeflow setup
```

## Technical Architecture

### State Management

The framework uses YAML files for state persistence:

- **state.yaml**: Tracks current cycle, step, issue, role, phase, safety settings, and infrastructure log
- **policy.yaml**: Defines role-based access permissions
- **templates/**: Contains issue and discussion templates

### Role-Based System Architecture

The framework uses a **context-continuous role-based system**:

- **No Agent Files**: Subagents are deprecated in favor of embedded role switching
- **Dynamic Permissions**: The `/next` command dynamically applies role-based permissions
- **Single Context**: All roles operate within the same conversation context
- **Hook Enforcement**: `validate_access.py` and `validate_write.sh` enforce permissions at the tool level

### Why This Architecture?

1. **Context Continuity**: Maintains conversation flow while enforcing role boundaries
2. **Prevents Context Contamination**: Engineers implement based on clear requirements, not interpretations of vision
3. **Ensures Traceability**: Every code change traces back to an issue, which traces to spec requirements
4. **Maintains Quality**: Multiple verification points catch issues early
5. **Enables Automation**: Clear role boundaries allow AI to execute most steps autonomously
6. **Simplified Management**: No need to manage separate agent files or contexts

### Verification System

Automated checks prevent common issues:

- File existence verification
- Test execution status
- Build success verification
- Acceptance criteria tracking

### Note on Bash Compatibility

Some features (e.g., `sort -V` in migration scripts) require Bash 4.0+. macOS ships with Bash 3.x by default. Install a newer version with `brew install bash` if needed.
