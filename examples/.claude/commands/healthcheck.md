# リポジトリ整合性チェック

Perform comprehensive repository consistency verification:

## 1. **Core State Verification**
- Read `.vibe/state.yaml` and validate:
  - current_step, current_issue, current_cycle, checkpoint_status
  - State transitions are valid (no skipped steps)
  - Current issue file exists in issues/ if set

## 2. **Repository Structure Check**  
- **Required files exist**: vision.md, spec.md, plan.md, CLAUDE.md
- **Directory structure**: .vibe/, .claude/, issues/, src/
- **Command files**: All slash commands (.claude/commands/) are present

## 3. **Git State Verification**
- Check current branch matches expected pattern:
  - main/master branch for Step 1-2 
  - feature/issue-XXX for Step 3-11
- Verify git status is clean or has expected changes
- Check if remote tracking is properly configured

## 4. **Step-Specific Artifact Verification**
- **Step 2**: Issue files exist and are properly formatted
- **Step 4**: Test files exist for current issue
- **Step 5-6**: Implementation files exist and tests can run
- **Step 7**: QA reports exist (if available)
- **Step 8+**: PR exists or merged properly

## 5. **Build & Dependencies Check**
- **Package files**: package.json, requirements.txt, Cargo.toml (if exist)
- **Build status**: Run build command if available
- **Test status**: Run test suite if available
- **Lint status**: Check code quality if configured

## 6. **Framework Version Compatibility**
- Verify CLAUDE.md matches current framework version
- Check if .vibe/ structure is up to date
- Validate agent definitions match current version

## 7. **Cross-Role Consistency**
- Verify plan.md progress matches completed issues
- Check QA reports are accessible to appropriate roles
- Validate issue-to-code traceability

**Report Format**:
- ✅ Component OK
- ⚠️ Minor issues (warnings) 
- ❌ Critical problems (must fix)
- 🔧 Suggested fixes

Present comprehensive results in Japanese with actionable recommendations.