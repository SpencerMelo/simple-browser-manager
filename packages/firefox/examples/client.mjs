import { firefox } from 'playwright';

const port = process.env.PORT ?? 3000;
const url = process.env.TARGET_URL ?? 'https://example.com';

const browser = await firefox.connect(`ws://127.0.0.1:${port}/`);
try {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(url);
  const title = await page.title();
} finally {
  await browser.close();
}
