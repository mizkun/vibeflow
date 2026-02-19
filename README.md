# VibeFlow

AI-driven development methodology for Claude Code

## Overview

VibeFlow is an AI-driven development methodology designed for use with Claude Code. It enables efficient, high-quality development through role separation, automated workflows, and clear checkpoints.

## Features

- **Iris**: Strategic project partner role (named after the Greek goddess of the rainbow — a messenger bridging gods and humans, symbolizing the bridge between strategy and implementation). Manages project context, discussions, and planning in a permanent terminal
- **GitHub Issues Integration**: Task management via `gh` CLI — no local `issues/` directory needed
- **Multi-Terminal Operation**: Iris terminal (permanent) + Development terminal(s) (per-issue)
- **3-Tier Context Management**: `.vibe/context/` (always loaded) + `.vibe/references/` (hot) + `.vibe/archive/` (cold)
- **Issue-Driven Workflow**: Issue → Branch → TDD → PR → Review (single human checkpoint at PR review)
- **Role-Based Access Control**: Strict file permissions per role, enforced by `validate_access.py` hook
- **Discovery Phase**: Brainstorming mode (`/discuss`, `/conclude`) for product direction and technical decisions
- **Safety Rules**: Atomic UI changes, destructive operation protection, retry limits, plans/ directory blocking
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
# Terminal 1 (Iris): /discuss for brainstorming & context management
# Terminal 2 (Dev):  Implement issues with TDD
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
2. **Iris Terminal**: Use `/discuss` to brainstorm and validate product direction
3. Use `/conclude` to finalize discussion results into vision/spec/plan
4. **Dev Terminal**: Implement issues with TDD (Red-Green-Refactor)

## How It Works

### Multi-Terminal Operation

VibeFlow v3 uses a multi-terminal model:

| Terminal | Role | Lifecycle | Scope |
|----------|------|-----------|-------|
| **Iris** | Iris | Permanent | plan/vision/spec/context management |
| **Development** | Engineer / QA / PM | Per-issue | src/ implementation |

**Iris Terminal** is the strategic partner terminal that stays open throughout the project. It manages context, discussions, planning, and GitHub Issues.

**Development Terminal(s)** are opened per-issue for implementation work.

### Development Phases

**Discovery Phase** (brainstorming)
- Activated with `/discuss [topic]` in the Iris terminal
- Brainstorm product direction, technical decisions, and business strategy
- End with `/conclude` to reflect conclusions into vision.md / spec.md / plan.md

**Development Phase** (implementation)
- Issue-driven: Issue → Branch → TDD → PR → Review
- Single human checkpoint at PR review

### Core Concept: Role-Based Development Workflow

The most important innovation of VibeFlow is the **context-continuous role-based system**. All roles operate within a single context with dynamic permission switching:

| Role | Responsibilities |
|---|---|
| Iris | Context management, discussions, planning, GitHub Issues |
| Product Manager | Vision alignment, planning, issue management |
| Engineer | Branch, TDD, implementation, PR, merge |
| QA Engineer | Acceptance testing, code review |
| Infrastructure Manager | Hook permission setup/rollback |

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
Brainstorm and validate product direction with `/discuss`. The Iris role provides counterarguments, questions assumptions, and organizes discussion points. Conclusions are reflected back to vision.md, spec.md, and plan.md via `/conclude`.

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
│   │   ├── iris.md            # Iris (strategic partner)
│   │   ├── product-manager.md
│   │   ├── engineer.md
│   │   ├── qa-engineer.md
│   │   └── infra.md
│   ├── context/               # Always-loaded context (STATUS.md)
│   ├── references/            # Hot reference info
│   ├── archive/               # Archived info (YYYY-MM-DD-type-topic.md)
│   ├── backups/               # Upgrade backups
│   └── templates/             # Templates and config
│       ├── issue-templates.md
│       ├── claude-settings.json
│       └── e2e-scripts.json
├── .github/
│   └── ISSUE_TEMPLATE/        # GitHub Issue templates
├── tests/                     # E2E tests
│   └── e2e/
├── src/                       # Source code
├── CLAUDE.md                  # Framework documentation
├── vision.md                  # Product vision
├── spec.md                    # Specifications
└── plan.md                    # Development plan
```

## Available Commands

### Slash Commands

The framework provides 6 slash commands:

- `/discuss [topic]` - Start Iris session for brainstorming and direction validation
- `/conclude` - End session and reflect conclusions to vision/spec/plan + STATUS.md
- `/progress` - Check current progress (GitHub Issues integrated)
- `/healthcheck` - Verify repository consistency
- `/quickfix` - Enter quick fix mode for minor adjustments
- `/run-e2e` - Execute E2E tests with Playwright
- `/parallel-test` - Run tests in parallel

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
