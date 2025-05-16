import { test, expect } from '@playwright/test';

test.describe('Login Page', () => {
  test('should allow a user to login and navigate to dashboard', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input#email', 'angelo.sagnori@gmail.com');
    await page.fill('input#password', 'admin123');
    await page.click('button[type="submit"]');
    // wait for navigation to dashboard
    await page.waitForURL('**/dashboard');
    // verify dashboard heading
    await expect(page.locator('h1')).toHaveText('Dashboard');
  });
});