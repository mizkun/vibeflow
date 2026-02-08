# 状態ファイルと実際の整合性チェック

Perform a comprehensive health check of the VibeFlow repository state. Verify:

## Checks to Perform:

1. **State File Consistency**
   - Read .vibe/state.yaml
   - Verify current_step matches actual progress
   - Check if current_issue exists in issues/
   - Validate checkpoint statuses

2. **File Structure Verification**
   - Required files exist: vision.md, spec.md, plan.md
   - issues/ directory structure is correct
   - src/ matches expected project structure

3. **Role Permission Compliance**
   - Check if recent modifications align with current_role permissions
   - Flag any potential permission violations

4. **Documentation Sync**
   - plan.md TODOs match issues_created in state
   - Completed issues are marked in both plan.md and state.yaml

## Output Format:
Present findings in Japanese with:
- ✅ for passing checks
- ⚠️ for warnings
- ❌ for failures

Include specific remediation steps for any issues found.

