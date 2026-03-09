# AGENTS.md — Codex Instruction Layer
# Auto-generated from VibeFlow schema. Do not edit manually.
# Source: core/schema/policy.yaml, workflow.yaml, roles.yaml

## Overview

This file provides instructions for Codex (or any headless worker) executing
tasks in a VibeFlow-managed project. All rules here derive from the same
schema that governs Claude Code via CLAUDE.md.

## File Access Rules

Workers must respect the following file access constraints.
These are enforced by the VibeFlow hook system and validated post-execution.

### Role Permissions


#### Iris
- **Description**: Default project entry point — triage, dispatch, and context management
- **can_write**: vision.md, spec.md, plan.md, .vibe/context/*, .vibe/references/*, .vibe/archive/*, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **can_read**: vision.md, spec.md, plan.md, .vibe/context/**, .vibe/references/**, .vibe/archive/**, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, src/**
- **enforcement**: hard


#### Product Manager
- **Description**: Vision alignment, planning, and issue management
- **can_write**: plan.md, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **can_read**: vision.md, spec.md, plan.md, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, .vibe/qa-reports/**
- **enforcement**: hard


#### Engineer
- **Description**: Implementation, testing, and refactoring
- **can_write**: src/*, tests/*, **/*.test.*, **/__tests__/*, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, .vibe/test-results.log
- **can_read**: spec.md, src/**, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **enforcement**: hard


#### QA Engineer
- **Description**: Acceptance testing, quality verification, and review
- **can_write**: .vibe/qa-reports/*, .vibe/test-results.log, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **can_read**: spec.md, src/**, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, .vibe/qa-reports/**
- **enforcement**: hard


#### Infrastructure Manager
- **Description**: Hook and guardrail management
- **can_write**: .vibe/hooks/*, validate-write*, validate_write*, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **can_read**: .vibe/hooks/**, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, .claude/settings.json
- **enforcement**: hard


#### Human
- **Description**: Human checkpoint for manual verification
- **can_write**: .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **can_read**: (none)
- **enforcement**: hard



### Default Forbidden Paths

The following paths are always forbidden for workers, regardless of role:

- `plans/*` — planning documents are read-only for workers
- `.vibe/hooks/*` — hook scripts must not be modified by workers
- `.claude/settings.json` — settings are managed by the framework

### Constraints

- **max_files_changed**: Workers should not modify more than the limit specified
  in the handoff packet (default: 20 files). Exceeding this limit signals scope creep.
- **allowed_paths**: Only write to paths listed in the handoff packet's
  `constraints.allowed_paths`. These derive from the role's `can_write` permissions.
- **forbidden_paths**: Never write to paths in `constraints.forbidden_paths`.

## Workflow Rules

Workers receive tasks via handoff packets that specify which workflow to follow.


### Standard Workflow
Standard development workflow — 11 core steps + infra gates (2.5/6.5) and QA checkpoint (7a)

| Step | Role | Mode |
|------|------|------|

| 1_issue_review | product_manager | solo |

| 2_task_breakdown | product_manager | team |

| 2.5_hook_permission_setup | infra_manager | solo |

| 3_branch_creation | engineer | solo |

| 4_test_writing | engineer | fork |

| 5_implementation | engineer | fork |

| 6_refactoring | engineer | fork |

| 6.5_hook_rollback | infra_manager | solo |

| 7_acceptance_test | qa_engineer | team |

| 7a_human_checkpoint | human | checkpoint |

| 8_pr_creation | engineer | solo |

| 9_code_review | qa_engineer | team |

| 10_merge | engineer | solo |

| 11_deployment | engineer | solo |



### Patch Workflow
Lightweight patch loop for scoped fixes from QA/review feedback

| Step | Role | Mode |
|------|------|------|

| 1_scope_review | engineer | solo |

| 2_fix_implementation | engineer | solo |

| 3_targeted_test | qa_engineer | solo |

| 4_commit | engineer | solo |



### Spike Workflow
Exploration and discovery — produces decisions, not production code

| Step | Role | Mode |
|------|------|------|

| 1_question_framing | iris | solo |

| 2_exploration | engineer | solo |

| 3_decision_summary | iris | solo |



### Ops Workflow
Non-development project tasks (release, docs, backlog grooming)

| Step | Role | Mode |
|------|------|------|

| 1_task_review | iris | solo |

| 2_execution | iris | solo |

| 3_completion | iris | solo |




## Task Execution Protocol

1. **Read the handoff packet** — it contains goal, acceptance criteria, constraints,
   and validation commands.
2. **Check constraints** — verify allowed_paths and forbidden_paths before writing.
3. **Execute the task** — implement the goal within the specified constraints.
4. **Run validation** — execute all commands in `validation.required_commands`.
5. **Report results** — update artifacts (qa_report, pr_number, branch).

## Validation

After task execution, the following validation rules apply:

- All commands in `validation.required_commands` must pass (exit code 0).
- Modified files must be within `constraints.allowed_paths`.
- No files in `constraints.forbidden_paths` may be modified.
- Total files changed must not exceed `constraints.max_files_changed`.

## Handoff Packet Format

Workers receive a JSON packet with this structure:

```json
{
  "task_id": "task-123-dev",
  "task_type": "dev | patch | spike | ops",
  "source_of_truth": { "issue_number": 123, "repo": "owner/repo" },
  "goal": "One-line description from Issue title",
  "acceptance_criteria": ["..."],
  "constraints": {
    "allowed_paths": ["src/**", "tests/**"],
    "forbidden_paths": ["plans/*", ".vibe/hooks/*"],
    "max_files_changed": 20
  },
  "must_read": ["vision.md", "spec.md"],
  "validation": { "required_commands": ["npm test"] },
  "worker_type": "claude | codex | human"
}
```
