# 次のステップへ進む

Execute the next workflow step following the VibeFlow role-based development system. This command should ALWAYS run in the main context, never as a subagent.

## Step 0: Phase Check
Load .vibe/state.yaml and check the `phase` field:
- If `phase: discovery` → ERROR: 「Discovery Phase が進行中です。/conclude で終了してから /next を使ってください。」
- If `phase: development` → Continue to Step 1

## Step 1: Read Current State
Load .vibe/state.yaml to understand:
- current_cycle
- current_step
- current_role
- next_step
- checkpoint_status

## Step 2: Determine Next Action
Based on current_step, identify:
- What needs to be done
- Which role should execute it
- Required permissions for this role
- Execution mode (solo/team/fork)

### Mode Determination
Check the workflow definition for the step's `mode`:

#### mode: solo (default)
Execute directly in main context. Standard role-based execution.

#### mode: team (Agent Team)
1. Check `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable
   - If not set → Fallback to solo mode with notice:
     「Agent Team が無効です。solo モードで実行します。有効にするには: export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1」
2. Spawn teammates as defined in team_config
3. If consensus_required: true, verify all teammates agree before proceeding

#### mode: fork (context: fork)
1. Execute step via context: fork, inheriting PM context
2. If fork unavailable → Fallback to solo mode
3. Return result summary to main context

## Step 3: Role Transition
Print role transition banner:

========================================
🔄 ROLE TRANSITION
Previous Step: [step_name] ([previous_role])
Current Step:  [next_step] ([new_role])
Issue:         [current_issue]
Now operating as: [NEW_ROLE]
Mode: [solo|team|fork]
Must read: [list of mandatory files]
Can modify: [list of editable files]
========================================

## Step 4: Execute as Role
Follow role-specific permissions strictly:

### For Product Manager Role (steps 1, 2):
- Must Read: vision.md, spec.md, plan.md, state.yaml, qa-reports/*
- Can Edit: plan.md, issues/*, state.yaml
- Can Create: issues/*
- Think like PM: Focus on user value and priorities

### For Engineer Role (steps 3, 4, 5, 6, 8, 10, 11):
- Must Read: spec.md, issues/*, src/*, state.yaml
- Can Edit: src/*, *.test.*, state.yaml
- Can Create: src/*, *.test.*
- Think like Engineer: Focus on implementation and code quality

### For QA Engineer Role (steps 6a, 7, 9):
- Must Read: spec.md, issues/*, src/*, state.yaml, qa-reports/*
- Can Edit: test-results.log, qa-reports/*, state.yaml
- Can Create: qa-reports/*, test-results.log
- Think like QA: Focus on validation and edge cases

### For Infrastructure Manager Role (steps 2.5, 6.5):
- Must Read: state.yaml, issues/*, .vibe/hooks/*
- Can Edit: .vibe/hooks/*, state.yaml
- Step 2.5: Read issue target files, update hook permissions, record in infra_log
- Step 6.5: Rollback permissions from infra_log, verify rollback_pending is false

## Step 5: Safety Rules Auto-Check
During execution, automatically enforce:
- CSS/HTML/TSX changes → apply atomic UI mode (1 change at a time)
- 2+ file rename/move/delete → create git checkpoint first
- Same fix approach failed before → check safety.failed_approach_log, force alternative if 2+ failures

## Step 6: Auto-Insert Steps
- After step 2a completes → automatically run step 2.5 (Hook Permission Setup)
- After step 6a completes → automatically run step 6.5 (Hook Rollback)
These steps do not require explicit /next invocation.

## Step 7: Update State
Update .vibe/state.yaml with:
- current_step: [next_step_number]
- current_role: [new_role]
- last_role_transition: [timestamp]
- last_completed_step: [previous_step]
- issues_created/issues_completed: update as needed

## Step 8: Checkpoint Handling
If step requires human validation:
- Print clear message about what needs review
- Save checkpoint state
- Wait for user confirmation before proceeding

IMPORTANT: Maintain all context in the main conversation. Do NOT use subagents for sequential workflow steps.
