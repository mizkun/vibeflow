# E2E Tests - Vibe Coding Framework

This directory contains end-to-end tests using Playwright.

## Structure

- `auth/` - Authentication related tests
- `features/` - Feature-specific tests
- `pageobjects/` - Page Object Model classes
- `utils/` - Test helpers and utilities

## Running Tests

```bash
# Run all tests
npm run test:e2e

# Run tests in specific browser
npm run test:e2e -- --project=chromium

# Run tests in headed mode
npm run test:e2e -- --headed

# Run specific test file
npm run test:e2e auth/login.spec.js

# Debug tests
npm run test:e2e -- --debug
```

## Writing Tests

Follow the Page Object Model pattern:

1. Create page objects in `pageobjects/`
2. Write test specs in appropriate directories
3. Use test helpers from `utils/`
4. Follow the naming convention: `*.spec.js`

## Best Practices

1. Keep tests independent and isolated
2. Use Page Object Model for maintainability
3. Prefer user-facing selectors (role, label, text)
4. Set up test data programmatically when possible
5. Clean up after tests
