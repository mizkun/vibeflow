---
description: Exit quick fix mode and return to normal workflow
---

Exit Quick Fix Mode and return to normal workflow:

## Process
1. Verify all quick fix changes are documented in .vibe/state.yaml
2. Print summary of changes made during quick fix session
3. Print mode change:

🔧 EXITING QUICK FIX MODE

Quick fix session complete.
Changes made: [list changes]
Returning to normal workflow at step: [current_step]

## Post-Exit
- Restore normal role-based permissions
- Continue from where workflow was paused
- Run /healthcheck if needed to verify state consistency

Note: Ensure all changes made during quick fix are properly documented before exiting.

