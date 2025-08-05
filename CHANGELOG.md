# Changelog

All notable changes to the Vibe Coding Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - 2024-12-20

### Added
- Quick Fix Mode for rapid minor adjustments outside the normal development cycle
- `/quickfix` and `/exit-quickfix` commands
- `quickfix-auto.md` subagent for handling quick fixes
- Quick fix logging in orchestrator.yaml

### Changed
- Updated framework version management
- Enhanced documentation with Quick Fix Mode usage

## [3.1.0] - 2024-12-20

### Added
- E2E testing support with Playwright integration
- Notification sounds for Claude Code hooks
- OS-specific notification scripts
- `/run-e2e` command for E2E test execution
- Optional setup flags: `--with-e2e` and `--with-notifications`

### Changed
- Enhanced QA process with E2E testing capabilities
- Improved user feedback with sound notifications

## [3.0.0] - 2024-12-19

### Added
- Orchestrator Context for cross-role coordination
- Automated verification system with `verification_rules.yaml`
- Health monitoring and warning accumulation
- `/verify-step`, `/orchestrator-status`, and `/health-check` commands
- Artifact registry for tracking created files
- Cross-role communication log

### Changed
- **BREAKING**: New state.yaml format with enhanced tracking
- All subagents updated to use Orchestrator Context
- Enhanced error prevention with verification requirements
- Improved project health visibility

### Fixed
- "Success theater" problem where AI reported completion without verification
- Context isolation issues between roles
- Missing feedback loops between steps

## [2.0.0] - 2024-12-15

### Added
- Modular architecture with separate lib/ directory
- Comprehensive error handling and validation
- Progress indicators during setup
- Backup functionality before overwriting files
- Command-line options (--force, --no-backup, --verbose)

### Changed
- **BREAKING**: Script structure completely modularized
- Improved user experience with colored output
- Better error messages and recovery options

### Fixed
- Slash command generation bug
- Directory creation race conditions
- Permission issues on some systems

## [1.0.0] - 2024-12-01

### Added
- Initial release of Vibe Coding Framework
- 11-step development cycle with role separation
- 4 specialized subagents (PM, Engineer, QA, Deploy)
- Basic slash commands for workflow control
- Context-based access control
- TDD enforcement
- Automated progression with human checkpoints

[3.2.0]: https://github.com/mizkun/vibeflow/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/mizkun/vibeflow/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/mizkun/vibeflow/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/mizkun/vibeflow/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/mizkun/vibeflow/releases/tag/v1.0.0