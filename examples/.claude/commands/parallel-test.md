# 並列テスト実行（Subagent使用）

Run tests in parallel using subagents. This is the ONLY workflow step where subagents are intentionally used, as parallel test execution benefits from true parallelism.

## When to Use:
- Running comprehensive test suites
- CI/CD pipeline test phases
- Pre-merge validation

## Subagent Configuration:
Each test type runs in its own subagent:
- Unit tests subagent
- Integration tests subagent
- E2E tests subagent (if configured)

## Key Points:
- Each subagent has independent context
- Results can be aggregated after completion

Execute:
1. Create subagent tasks for:
   - Unit tests
   - Integration tests  
   - E2E tests (if configured)
   
2. Each subagent should:
   - Run its specific test suite
   - Report results to a designated output file
   - Return success/failure status

3. After all complete:
   - Aggregate results
   - Update test-results.log
   - Report summary to user

Note: This is the ONLY command where we intentionally use subagents in the Vibe Coding workflow, as parallel test execution benefits from true parallelism without context sharing requirements.

