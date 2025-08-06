---
description: Run independent tests in parallel using subagents
---

Run multiple independent test suites in parallel:

This is one of the few cases where we DO use subagents, because:
- Tests are independent and don't need shared context
- Parallel execution saves significant time
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