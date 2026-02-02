import { createBdd } from 'playwright-bdd';

const { Given, When, Then } = createBdd();

// ========== 通用步驟 ==========

Given('使用者已開啟瀏覽器', async ({ page }) => {
  // 瀏覽器已由 Playwright 自動啟動
});

Given('使用者在 {word} 列表頁面', async ({ page }, pageName: string) => {
  const routes: Record<string, string> = {
    Agent: '/agents',
    LLM: '/llms',
    Tool: '/tools',
  };
  await page.goto(routes[pageName] || `/${pageName.toLowerCase()}s`);
});

When('使用者導航到 {string} 頁面', async ({ page }, path: string) => {
  await page.goto(path);
});

When('使用者點擊 {string} 按鈕', async ({ page }, buttonText: string) => {
  await page.getByRole('button', { name: buttonText }).click();
});

When('使用者在 {string} 欄位輸入 {string}', async ({ page }, fieldLabel: string, value: string) => {
  await page.getByLabel(fieldLabel).fill(value);
});

Then('頁面標題應包含 {string}', async ({ page }, expectedText: string) => {
  await page.waitForSelector(`text=${expectedText}`);
});

Then('應顯示成功訊息', async ({ page }) => {
  await page.waitForSelector('[role="alert"]');
});

Then('列表應包含 {string}', async ({ page }, itemName: string) => {
  await page.waitForSelector(`text=${itemName}`);
});
