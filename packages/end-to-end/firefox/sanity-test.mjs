// Sanity test for the firefox image.
// Connects to a running simple-browser-manager-firefox container, opens
// example.com, prints the title. Exits non-zero on any failure.
//
// Usage:
//   PORT=3000 node firefox/sanity-test.mjs
//
// Requires: a firefox container running on $PORT, and this package's
// playwright (^1.49.0) to match the server's PLAYWRIGHT_VERSION.

import { firefox } from 'playwright';

const port = process.env.PORT ?? 3000;
const url = process.env.TARGET_URL ?? 'https://example.com';

const browser = await firefox.connect(`ws://127.0.0.1:${port}/`);
try {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto(url);
  const title = await page.title();
  console.log(title);
} finally {
  await browser.close();
}