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
