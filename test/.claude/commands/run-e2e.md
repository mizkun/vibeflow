---
description: Execute E2E tests with Playwright
---

Execute E2E tests using Playwright:

## Prerequisites Check
1. Verify Playwright is installed:
   - Check if `node_modules/@playwright/test` exists
   - If not, run: `npm install @playwright/test`
   - Install browsers if needed: `npx playwright install`

## Test Execution
1. **Environment Setup**
   - Ensure development server is running (if required)
   - Check test database is prepared (if applicable)
   - Verify test environment variables

2. **Run E2E Tests**
   ```bash
   # Run all E2E tests
   npm run test:e2e
   
   # Or directly with Playwright
   npx playwright test
   ```

3. **Test Results**
   - Review test output and screenshots
   - Check for failed tests and error details
   - Generate test report if configured

## Test Structure
Tests are organized in `tests/e2e/`:
- `auth/` - Authentication related tests
- `features/` - Feature-specific test scenarios  
- `pageobjects/` - Page Object Model classes
- `utils/` - Test utilities and helpers

## Common Issues
- **Port conflicts**: Ensure dev server runs on expected port
- **Timing issues**: Review wait strategies in failing tests
- **Browser issues**: Update browsers with `npx playwright install`
- **Screenshots**: Check `test-results/` for failure screenshots

Report results and any failures found during execution.
