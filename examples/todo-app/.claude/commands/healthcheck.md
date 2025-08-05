# 状態整合性チェック

Check the consistency between .vibe/state.yaml and the actual project state:

1. **Read state.yaml** to get:
   - current_step
   - current_issue
   - current_cycle
   - checkpoint_status

2. **Verify actual state**:
   - If current_issue is set, check if that issue file exists in issues/
   - Check Git branch matches expected pattern (feature/issue-XXX) if step >= 3
   - Verify expected artifacts exist based on current_step:
     - Step 2: Issue files should exist
     - Step 4: Test files should exist
     - Step 5-6: Implementation files should exist
   - Check if checkpoint status matches actual progress

3. **Report discrepancies**:
   - ✅ State matches reality
   - ⚠️ Minor inconsistencies (e.g., branch name)
   - ❌ Major problems (e.g., missing issue file, wrong step)

4. **Suggest fixes** if problems found:
   - Correct state.yaml values
   - Missing files that should be created
   - Next logical action to take

Present results in Japanese with clear status indicators.
