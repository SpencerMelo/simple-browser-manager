// Sanity test for the chromium image.
// Connects to a running simple-browser-manager-chromium container, opens
// example.com, prints the title. Exits non-zero on any failure.
//
// Usage:
//   PORT=3000 node chromium/sanity-test.mjs
//
// Requires: a chromium container running on $PORT, and this package's
// playwright (^1.63.0) to match the server's PLAYWRIGHT_VERSION.

import { chromium } from 'playwright';

const port = process.env.PORT ?? 3000;
const url = process.env.TARGET_URL ?? 'https://example.com';

const browser = await chromium.connect(`ws://127.0.0.1:${port}/`);
try {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(url);
  const title = await page.title();
  console.log(title);
} finally {
  await browser.close();
}