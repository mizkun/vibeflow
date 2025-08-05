#!/bin/bash
# Vibe Coding Framework - Playwright E2E Test Setup

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Create Playwright configuration
create_playwright_config() {
    section "Setting up Playwright E2E Testing"
    
    info "Creating Playwright configuration"
    cat > playwright.config.js << 'EOF'
import { defineConfig, devices } from '@playwright/test';

/**
 * Vibe Coding Framework - Playwright Configuration
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './tests/e2e',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html'],
    ['list'],
    ['json', { outputFile: 'test-results/e2e-results.json' }]
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
    
    /* Video on failure */
    video: 'retain-on-failure',
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Test against mobile viewports. */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  /* Run your local dev server before starting the tests */
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
EOF
    
    success "Created playwright.config.js"
}

# Create E2E test directory structure
create_e2e_structure() {
    info "Creating E2E test directory structure"
    
    mkdir -p tests/e2e/{auth,features,utils,pageobjects}
    
    # Create a sample test helper
    cat > tests/e2e/utils/test-helpers.js << 'EOF'
/**
 * Vibe Coding Framework - E2E Test Helpers
 */

export const testUser = {
  email: 'test@example.com',
  password: 'testpassword123'
};

export async function login(page, email = testUser.email, password = testUser.password) {
  await page.goto('/login');
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('/dashboard');
}

export async function logout(page) {
  await page.getByRole('button', { name: 'User menu' }).click();
  await page.getByRole('menuitem', { name: 'Logout' }).click();
  await page.waitForURL('/login');
}
EOF
    
    # Create a sample page object
    cat > tests/e2e/pageobjects/login.page.js << 'EOF'
/**
 * Login Page Object
 */
export class LoginPage {
  constructor(page) {
    this.page = page;
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Password');
    this.loginButton = page.getByRole('button', { name: 'Sign in' });
    this.errorMessage = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email, password) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async getErrorMessage() {
    return await this.errorMessage.textContent();
  }
}
EOF
    
    # Create a sample test
    cat > tests/e2e/auth/login.spec.js << 'EOF'
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pageobjects/login.page';
import { testUser } from '../utils/test-helpers';

test.describe('Authentication', () => {
  test('successful login redirects to dashboard', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login(testUser.email, testUser.password);
    
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('Welcome')).toBeVisible();
  });

  test('invalid credentials show error', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('invalid@example.com', 'wrongpassword');
    
    const error = await loginPage.getErrorMessage();
    expect(error).toContain('Invalid credentials');
  });
});
EOF
    
    # Create README for E2E tests
    cat > tests/e2e/README.md << 'EOF'
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
EOF
    
    success "Created E2E test structure"
}

# Add E2E scripts to package.json template
create_e2e_scripts() {
    info "Creating E2E test scripts"
    
    cat > .vibe/templates/e2e-scripts.json << 'EOF'
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:headed": "playwright test --headed",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:report": "playwright show-report",
    "playwright:install": "playwright install --with-deps"
  },
  "devDependencies": {
    "@playwright/test": "^1.40.0"
  }
}
EOF
    
    success "Created E2E test scripts template"
}

# Update verification rules for E2E tests
update_verification_for_e2e() {
    info "Updating verification rules for E2E tests"
    
    # Add E2E test verification to existing rules
    if [ -f ".vibe/verification_rules.yaml" ]; then
        # Check if E2E rules already exist
        if ! grep -q "e2e_tests" ".vibe/verification_rules.yaml"; then
            cat >> .vibe/verification_rules.yaml << 'EOF'

  # E2E Test Verification
  7_acceptance_test_e2e:
    pre_conditions:
      - type: "tests_passing"
        error_message: "Unit tests must pass before E2E tests"
    post_conditions:
      - type: "command_exit_code"
        command: "npm run test:e2e -- --reporter=list"
        expected_code: 0
        error_message: "E2E tests failed"
      - type: "file_exists"
        path: "test-results/e2e-results.json"
        error_message: "E2E test results not generated"
EOF
        fi
    fi
    
    success "Updated verification rules for E2E tests"
}

# Main function to set up Playwright
setup_playwright() {
    create_playwright_config
    create_e2e_structure
    create_e2e_scripts
    update_verification_for_e2e
}

# Export functions
export -f setup_playwright
export -f create_playwright_config
export -f create_e2e_structure
export -f create_e2e_scripts
export -f update_verification_for_e2e