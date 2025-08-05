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
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)
- [Technical Architecture](#technical-architecture)
- [Contributing](#contributing)
- [License](#license)

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

## Project Structure

After setup, the following structure is created:

```
your-project/
├── .claude/
│   ├── agents/         # Subagent definitions
│   │   ├── pm-auto.md
│   │   ├── engineer-auto.md
│   │   ├── qa-auto.md
│   │   └── deploy-auto.md
│   └── commands/       # Slash commands
│       ├── progress.md
│       ├── healthcheck.md
│       └── ... (11 commands total)
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

The framework provides 11 slash commands for controlling the development flow:

- `/progress` - Show current development progress
- `/healthcheck` - Check project health status
- `/abort` - Abort current operation
- `/next` - Proceed to next step
- `/restart-cycle` - Restart the development cycle
- `/skip-tests` - Skip test execution (use with caution)
- `/vibe-status` - Show Vibe framework status
- `/role-product_manager` - Switch to Product Manager role
- `/role-engineer` - Switch to Engineer role
- `/role-qa_engineer` - Switch to QA Engineer role
- `/role-reset` - Reset role to default
- `/verify-step` - Verify current step artifacts and requirements
- `/orchestrator-status` - View project health and accumulated warnings
- `/health-check` - Comprehensive project health assessment

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

## Troubleshooting

### Common Issues

#### Error: "lib directory not found"
```bash
❌ Error: lib directory not found at /path/to/lib
```

**Cause**: Script cannot find the lib directory.

**Solution**:
1. Verify repository is correctly cloned
2. Ensure setup_vibeflow.sh and lib directory are in the same location
3. Try running with full path instead of relative path

#### Error: "command not found"
```bash
bash: git: command not found
```

**Cause**: Required tools are not installed.

**Solution**:
- macOS: `brew install git`
- Linux: `sudo apt-get install git` or `sudo yum install git`

#### Existing Configuration Warning
```
⚠️  Existing Vibe Coding configuration found.
```

**Solution**:
1. Create backup and continue: Type "y"
2. Run in different directory: Create new directory and run there
3. Force install: Use `--force` option

#### Slash Commands Not Working

**Cause**: Command files may not be generated correctly.

**Solution**:
1. Check `.claude/commands/` directory
2. Verify command files (.md) exist
3. Re-run setup if necessary

#### "Subagent not found" Error

**Cause**: Subagent files are missing.

**Solution**:
1. Check `.claude/agents/` directory
2. Verify all 4 Subagent files exist:
   - pm-auto.md
   - engineer-auto.md
   - qa-auto.md
   - deploy-auto.md

#### Development Cycle Not Progressing

**Cause**: state.yaml may not be updating correctly.

**Solution**:
1. Check `.vibe/state.yaml` contents
2. Manually fix if needed:
   ```yaml
   current_cycle: 1
   current_step: 1_plan_review
   current_issue: null
   next_step: 2_issue_breakdown
   ```

### Platform-Specific Issues

#### Windows (WSL/Git Bash)

**Issue**: Line ending errors

**Solution**:
```bash
# Convert line endings to LF
dos2unix setup_vibeflow.sh
dos2unix lib/*.sh
```

#### macOS

**Issue**: Old Bash version errors

**Solution**:
```bash
# Install newer Bash with Homebrew
brew install bash
# Change shell
chsh -s /usr/local/bin/bash
```

### Getting Support

If issues persist, create an issue with the following information:

1. Full error message
2. Command executed
3. OS information: `uname -a`
4. Bash version: `bash --version`
5. setup_vibeflow.sh version: `./setup_vibeflow.sh --version`

Create issue at: https://github.com/mizkun/vibeflow/issues

## Examples

The `examples/` directory contains a complete example showing the file structure generated by setup_vibeflow.sh. See [examples/todo-app/](examples/todo-app/) for a practical example of how the framework structures a project.

## Orchestrator Context

The Orchestrator Context is a key innovation that addresses the "success theater" problem where AI agents report completion without actual verification.

### What it does:
- **Tracks Project Health**: Monitors overall status (healthy/warning/critical)
- **Verifies Artifacts**: Ensures files actually exist before proceeding
- **Shares Critical Information**: Allows roles to communicate important constraints
- **Accumulates Warnings**: Multiple issues escalate project health status
- **Enables Better Decisions**: Provides full context at human checkpoints

### How it works:
Each role can read and write to `.vibe/orchestrator.yaml`, which maintains:
- Step completion registry with artifacts
- Critical decisions pending
- Risk register
- Communication log
- Shared technical constraints
- Project metrics

## Technical Architecture

### Core Concepts

#### 1. Role-Based Access Control

The framework defines 4 roles with specific access permissions:

```yaml
roles:
  product_manager:
    can_read: [vision, spec, plan]
    can_edit: [plan]
    can_create: [issues]
    
  engineer:
    can_read: [issues, code]
    can_edit: [code]
    can_create: [code]
    
  qa_engineer:
    can_read: [spec, issues, code]
    can_edit: []
    can_create: []
    
  human:
    can_read: [issues]
    can_edit: []
    can_create: []
```

#### 2. Context Separation

Each context contains specific information with role-based access:

- **vision**: Product vision (read-only)
- **spec**: Specifications and technical design (read-only)
- **plan**: Development plan (PM edit only)
- **issues**: Implementation tasks (PM creates, Engineer reads)
- **code**: Source code (Engineer access only)

#### 3. State Management

`.vibe/state.yaml` manages cycle state:

```yaml
current_cycle: 3
current_step: 5_implementation
current_issue: "issue-042-user-authentication"
next_step: 6_refactoring
checkpoint_status:
  2a_issue_validation: passed
  7a_runnable_check: pending
```

### Subagent Architecture

Each Subagent has specific roles and toolsets:

1. **pm-auto**
   - Tools: file_view, file_edit, str_replace_editor
   - Responsibilities: Plan review, issue creation

2. **engineer-auto**
   - Tools: file_view, file_edit, str_replace_editor, run_command, browser
   - Responsibilities: Implementation, test creation, refactoring

3. **qa-auto**
   - Tools: file_view, run_command, str_replace_editor
   - Responsibilities: Quality checks, acceptance testing

4. **deploy-auto**
   - Tools: file_view, run_command, browser
   - Responsibilities: PR creation, merging, deployment

### Security and Access Control

#### Principles

1. **Least Privilege**: Each role has minimal necessary access
2. **Read-Only Documents**: vision.md and spec.md are immutable during development
3. **No Human Code Access**: Humans cannot directly access source code

#### Implementation

- Control via AI instructions, not filesystem-level
- Each Subagent accesses only permitted files
- state.yaml tracks current role and permissions

### Automation Flow

#### Triggers and Transitions

1. **Automatic Transitions**: Non-human steps proceed automatically
2. **Conditional Branches**: Based on test results and reviews
3. **Loop-back**: Return to appropriate step on failure

#### Parallel Processing

When possible, execute multiple tasks in parallel:
- Create multiple issues simultaneously
- Optimize test and implementation iterations

### Extensibility

#### Adding Custom Subagents

To add a new Subagent:

```markdown
---
name: custom-agent
description: "Custom agent description"
tools: file_view, custom_tool
---

# Detailed agent description and rules
```

#### Workflow Customization

Define custom workflows in `.vibe/workflow.yaml` (future feature)

### Performance Considerations

1. **Context Size**: Each Subagent loads only necessary files
2. **State Persistence**: state.yaml saves progress for resumption
3. **Error Recovery**: Error handling at each step

### Future Extensions

1. **Multi-project Support**: Parallel management of multiple projects
2. **Custom Workflows**: YAML-based workflow definitions
3. **Metrics Collection**: Development efficiency measurement
4. **Plugin System**: Custom tools and Subagents

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License