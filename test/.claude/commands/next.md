---
description: Proceed to next step with role-based execution
---

Execute the next step in the Vibe Coding development cycle:

## Step 1: Load Current State
Read .vibe/state.yaml to understand:
- current_cycle
- current_step  
- current_issue
- current_role
- last_completed_step

## Step 2: Determine Next Step and Role
Based on current_step, identify:
- Next step number and name
- Required role (PM, Engineer, or QA)
- Files that role can access

## Step 3: Announce Role Transition
Print clear transition message:
========================================
🔄 ROLE TRANSITION
Previous Step: [step_X] ([role])
Current Step:  [step_Y] ([new_role])
Issue:         [current_issue]
Now operating as: [NEW_ROLE]
Access granted to: [list of accessible files]
========================================

## Step 4: Execute Step with Role Constraints

### For Product Manager Role (steps 1-2):
- Must Read: vision.md, spec.md, plan.md, state.yaml, qa-reports/*
- Can Edit: plan.md, issues/*, state.yaml
- Can Create: issues/*
- Think like a PM: Focus on user value and requirements

### For Engineer Role (steps 3-6, 8, 10-11):  
- Must Read: spec.md, issues/*, src/*, state.yaml
- Can Edit: src/*, *.test.*, state.yaml
- Can Create: src/*, *.test.*
- Think like an engineer: Focus on implementation quality

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
