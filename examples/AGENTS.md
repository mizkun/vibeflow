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
- **Description**: プロジェクトの唯一のインターフェース (default entry point) — triage、dispatch、QA判断、クローズ
- **can_write**: vision.md, spec.md, plan.md, .vibe/**
- **can_read**: vision.md, spec.md, plan.md, .vibe/context/**, .vibe/references/**, .vibe/archive/**, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, src/**
- **enforcement**: hard


#### Coding Agent (Claude Code / Codex)
- **Description**: コーディング、テスト、リファクタリング
- **can_write**: src/*, tests/*, **/*.test.*, **/__tests__/*, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml, .vibe/test-results.log
- **can_read**: spec.md, src/**, tests/**, .vibe/project_state.yaml, .vibe/sessions/*.yaml, .vibe/state.yaml
- **enforcement**: hard



### Default Restricted Paths

The following paths are restricted by default unless explicitly allowed
by the role's policy permissions and the handoff packet constraints:

- `plans/*` — planning documents, typically read-only for workers
- `.vibe/hooks/*` — hook scripts, restricted unless the role (e.g., Infrastructure Manager) has explicit write permission
- `.claude/settings.json` — settings, managed by the framework

### Constraints

- **max_files_changed**: Workers should not modify more than the limit specified
  in the handoff packet (default: 20 files). Exceeding this limit signals scope creep.
- **allowed_paths**: Only write to paths listed in the handoff packet's
  `constraints.allowed_paths`. These derive from the role's `can_write` permissions.
- **forbidden_paths**: Never write to paths in `constraints.forbidden_paths`.

## Workflow Rules

Workers receive tasks via handoff packets that specify which workflow to follow.


### Standard Workflow
Standard development workflow — Iris dispatches to Coding Agent, reviews results

| Step | Role | Mode |
|------|------|------|

| 1_issue_review | iris | solo |

| 2_task_breakdown | iris | solo |

| 3_branch_creation | coding_agent | solo |

| 4_test_writing | coding_agent | solo |

| 5_implementation | coding_agent | solo |

| 6_refactoring | coding_agent | solo |

| 7_acceptance_test | iris | solo |

| 8_pr_creation | coding_agent | solo |

| 9_code_review | iris | solo |

| 10_merge | coding_agent | solo |



### Patch Workflow
Lightweight patch loop for scoped fixes from QA/review feedback

| Step | Role | Mode |
|------|------|------|

| 1_scope_review | iris | solo |

| 2_fix_implementation | coding_agent | solo |

| 3_targeted_test | coding_agent | solo |

| 4_commit | coding_agent | solo |



### Spike Workflow
Exploration and discovery — produces decisions, not production code

| Step | Role | Mode |
|------|------|------|

| 1_question_framing | iris | solo |

| 2_exploration | coding_agent | solo |

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
