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
