# E2Eテストを実行

Run end-to-end tests using Playwright to verify the application works correctly from a user's perspective.

## What this command does:

1. Check if E2E tests are set up
2. Start the development server if needed
3. Run Playwright tests
4. Show test results
5. Open HTML report if tests fail

## Prerequisites:

- Playwright must be installed (`npm run playwright:install`)
- Application must be runnable (`npm run dev`)
- E2E tests must exist in `tests/e2e/`

## Command Flow:

```bash
# Check if Playwright is installed
if ! npm list @playwright/test >/dev/null 2>&1; then
    echo "Playwright is not installed. Run: npm run playwright:install"
    exit 1
fi

# Run E2E tests
npm run test:e2e

# If tests fail, open the report
if [ $? -ne 0 ]; then
    npm run test:e2e:report
fi
```

## Options:

- Run in headed mode: `npm run test:e2e:headed`
- Debug tests: `npm run test:e2e:debug`
- Run specific test: `npm run test:e2e auth/login.spec.js`

Report results in Japanese with clear pass/fail status.

