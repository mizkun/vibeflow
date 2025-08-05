# Vibe Coding Framework

AI-driven development methodology for Claude Code with strict role separation and automated workflows.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/mizkun/vibeflow.git
mkdir my-project && cd my-project
../vibeflow/setup_vibeflow.sh

# With optional features
../vibeflow/setup_vibeflow.sh --with-e2e --with-notifications
```

## Key Features

- **Context-Based Access Control**: Each role has specific read/write permissions
- **11-Step Development Cycle**: Automated workflow with role switching
- **Orchestrator Context**: Tracks project health and prevents "success theater"
- **Minimal Human Intervention**: Only 2 validation checkpoints
- **Optional E2E Testing**: Playwright integration with `--with-e2e`
- **Optional Notifications**: Sound alerts with `--with-notifications`

## How It Works

1. **Setup**: Define vision.md, spec.md, and plan.md
2. **Start**: Tell Claude Code to "Start development cycle"
3. **Roles**: PM → Engineer → QA → Human (validation only)
4. **Automation**: Framework handles role switching and verification

## Project Structure

```
your-project/
├── .claude/          # Claude Code configuration
│   ├── agents/       # Role-specific agents
│   └── commands/     # Slash commands
├── .vibe/            # Framework state
│   ├── orchestrator.yaml    # Project health tracking
│   ├── state.yaml          # Current progress
│   └── verification_rules.yaml
├── vision.md         # Product vision
├── spec.md          # Technical specifications
├── plan.md          # Development plan
└── issues/          # Auto-generated tasks
```

## Commands

- `/progress` - Check current status
- `/next` - Proceed to next step
- `/health-check` - Project health assessment
- `/orchestrator-status` - View warnings and risks
- `/run-e2e` - Run E2E tests (requires --with-e2e)

## License

MIT License - See [LICENSE](LICENSE) for details

## Links

- [Documentation](https://github.com/mizkun/vibeflow/wiki)
- [Issues](https://github.com/mizkun/vibeflow/issues)
- [Discussions](https://github.com/mizkun/vibeflow/discussions)