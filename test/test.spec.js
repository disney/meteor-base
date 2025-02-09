import { test, expect } from '@playwright/test';

test('app functionality', async ({ page }) => {
	await page.goto('http://localhost/');

	await page.click('button');
	await page.click('button');
	await page.click('button');

	await expect(page.getByText('You\'ve pressed the button 3 times.')).toBeVisible();
});
