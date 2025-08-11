# Vibe Coding Framework

AI-driven development methodology setup tool for Claude Code

## Overview

Vibe Coding Framework is an AI-driven development methodology designed for use with Claude Code. It enables efficient, high-quality development through role separation, automated workflows, and clear checkpoints.

## Features

- **Context-Based Access Control**: Each step has a specific role with defined read/edit/create permissions for different contexts
- **Strict Context Isolation**: Roles have defined read/edit/create permissions (e.g., Engineers can only edit code, PMs can only edit plan/issues)
- **Role-Based Context-Continuous System**: No separate agent files - role switching handled seamlessly within main context
- **11-Step Development Workflow**: Automatic progression through development cycle with role-based permissions
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
- [Built-in Features](#built-in-features)
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
   
   # Install without E2E testing support
   ./setup_vibeflow.sh --without-e2e
   
   # Install without notification sounds
   ./setup_vibeflow.sh --without-notifications
   
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

The most important innovation of Vibe Coding Framework is the **context-continuous role-based system**. Unlike traditional approaches with separate agent files, all roles operate within a single context with dynamic permission switching. Each step in the development cycle is executed by a specific role with precisely defined permissions:

```yaml
# Step-by-Step Role and Permission Definition
workflow:
  step_1_plan_review:
    role: Product Manager
    access:
      must_read: [vision.md, spec.md, plan.md, state.yaml, qa-reports/*]
      can_edit: [plan.md, state.yaml]
      can_create: []
    purpose: Review and update development plan based on vision/spec
    
  step_2_issue_breakdown:
    role: Product Manager  
    access:
      must_read: [vision.md, spec.md, plan.md, state.yaml, qa-reports/*]
      can_edit: [issues/*, state.yaml]
      can_create: [issues/*]
    purpose: Create detailed, implementable issues from plan
    checkpoint: 2a_human_validation (required)
    
  step_3_branch_creation:
    role: Engineer
    access:
      must_read: [spec.md, issues/*, state.yaml]
      can_edit: [.git/*, state.yaml]
      can_create: []
    purpose: Create feature branch for implementation
    
  step_4_test_writing:
    role: Engineer
    access:
      must_read: [spec.md, issues/*, src/*, state.yaml]
      can_edit: [*.test.*, state.yaml]
      can_create: [*.test.*]
    purpose: Write failing tests first (TDD Red phase)
    
  step_5_implementation:
    role: Engineer
    access:
      must_read: [spec.md, issues/*, src/*, *.test.*, state.yaml]
      can_edit: [src/*, state.yaml]
      can_create: [src/*]
    purpose: Implement code to pass tests (TDD Green phase)
    
  step_6_refactoring:
    role: Engineer
    access:
      must_read: [spec.md, issues/*, src/*, *.test.*, state.yaml]
      can_edit: [src/*, state.yaml]
      can_create: []
    purpose: Improve code quality (TDD Refactor phase)
    checkpoint: 6a_code_sanity_check (automated)
    
  step_7_acceptance_test:
    role: QA Engineer
    access:
      must_read: [spec.md, issues/*, src/*, *.test.*, state.yaml, qa-reports/*]
      can_edit: [test-results.log, qa-reports/*, state.yaml]
      can_create: [qa-reports/*, test-results.log]
    purpose: Verify implementation meets requirements
    checkpoint: 7a_human_runnable_check (required)
    
  step_8_pull_request:
    role: Engineer
    access:
      must_read: [spec.md, issues/*, src/*, state.yaml]
      can_edit: [.git/*, state.yaml]
      can_create: []
    purpose: Create PR with proper documentation
    
  step_9_review:
    role: QA Engineer
    access:
      must_read: [spec.md, issues/*, src/*, state.yaml, qa-reports/*]
      can_edit: [qa-reports/*, state.yaml]
      can_create: [qa-reports/*]
    purpose: Code review and quality check
    
  step_10_merge:
    role: Engineer
    access:
      must_read: [spec.md, src/*, state.yaml]
      can_edit: [.git/*, state.yaml]
      can_create: []
    purpose: Merge approved changes to main
    
  step_11_deployment:
    role: Engineer
    access:
      must_read: [spec.md, src/*, state.yaml]
      can_edit: [deployment.log, state.yaml]
      can_create: [deployment.log]
    purpose: Deploy to production
```

### Key Principles

1. **Context-Continuous Operation**: All roles operate within the same context with dynamic permission switching
2. **No Separate Agent Files**: Role-based permissions are embedded in the `/next` command logic
3. **Automated Progression**: Steps flow automatically with only 2 human checkpoints
4. **Verification at Each Step**: Each role verifies their own artifacts before proceeding
5. **Clear State Management**: state.yaml tracks current position and progress

## Built-in Features

### E2E Testing with Playwright
Includes Playwright configuration, test structure (`tests/e2e/`), and `/run-e2e` command by default. Install with `npm install @playwright/test` and `npx playwright install`.

### Notification Sounds  
OS-specific notification scripts and Claude Code hook configurations for task completion, waiting input, and error alerts. Enable by copying `.vibe/templates/claude-settings.json` to `~/.config/claude/settings.json`.

### Role-Based Permissions
Strict context isolation with Must Read/Can Edit/Can Create permissions for each role.


## Project Structure

After setup, the following structure is created:

```
your-project/
├── .claude/
│   └── commands/           # Slash commands
│       ├── progress.md
│       ├── healthcheck.md
│       ├── next.md
│       └── run-e2e.md      # E2E test execution
├── .vibe/
│   ├── state.yaml          # Cycle state management
│   ├── claude-hooks.json   # Hook configuration
│   ├── hooks/              # Notification scripts
│   │   ├── task_complete.sh
│   │   ├── waiting_input.sh
│   │   └── error_occurred.sh
│   ├── roles/              # Role documentation
│   │   ├── product-manager.md
│   │   ├── engineer.md
│   │   └── qa-engineer.md
│   └── templates/          # Templates and config
│       ├── issue-templates.md
│       ├── claude-settings.json
│       └── e2e-scripts.json
├── tests/                  # E2E tests
│   └── e2e/
│       ├── auth/
│       ├── features/
│       ├── pageobjects/
│       └── utils/
├── issues/                 # Implementation tasks
├── src/                    # Source code
├── playwright.config.js    # Playwright configuration
├── CLAUDE.md               # Framework documentation
├── vision.md               # Product vision
├── spec.md                 # Specifications
└── plan.md                 # Development plan
```

## Available Commands

### Slash Commands

The framework provides 4 slash commands:

- `/progress` - Check current progress and position
- `/healthcheck` - Verify repository consistency
- `/next` - Proceed to next step (handles all role switching)
- `/run-e2e` - Execute E2E tests with Playwright

### Script Options

```bash
# Display help
./setup_vibeflow.sh --help

# Force installation (skip confirmations)
./setup_vibeflow.sh --force

# Skip backup creation
./setup_vibeflow.sh --no-backup

# Install without E2E testing
./setup_vibeflow.sh --without-e2e

# Install without notification sounds
./setup_vibeflow.sh --without-notifications

# Display version
./setup_vibeflow.sh --version
```

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
   /next
   ```

### Creating from Scratch

Alternatively, create a new project:

1. **Setup project**:
   ```bash
   mkdir my-project
   cd my-project
   ../vibeflow/setup_vibeflow.sh
   ```

2. **Fill in the generated templates** following the same pattern as the examples directory

## Technical Architecture

### State Management

The framework uses YAML files for state persistence:

- **state.yaml**: Tracks current cycle, step, and issue
- **templates/**: Contains issue templates for different types of development tasks

### Role-Based System Architecture

The framework has evolved from separate subagent files to a **context-continuous role-based system**:

- **No Agent Files**: Subagents are deprecated in favor of embedded role switching
- **Dynamic Permissions**: The `/next` command dynamically applies role-based permissions
- **Single Context**: All roles operate within the same conversation context

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

