# 次のステップへ進む

Execute the next workflow step following the VibeFlow role-based development system. This command should ALWAYS run in the main context, never as a subagent.

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

## Step 3: Role Transition
Print role transition banner:

========================================
🔄 ROLE TRANSITION
Previous Step: [step_name] ([previous_role])
Current Step:  [next_step] ([new_role])
Issue:         [current_issue]
Now operating as: [NEW_ROLE]
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

## Step 5: Update State
Update .vibe/state.yaml with:
- current_step: [next_step_number]
- current_role: [new_role]
- last_role_transition: [timestamp]
- last_completed_step: [previous_step]
- issues_created/issues_completed: update as needed

## Step 6: Checkpoint Handling
If step requires human validation:
- Print clear message about what needs review
- Save checkpoint state
- Wait for user confirmation before proceeding

IMPORTANT: Maintain all context in the main conversation. Do NOT use subagents for sequential workflow steps.

