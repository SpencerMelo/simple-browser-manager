# @simple-browser-manager/chromium

A slim Docker image that exposes a **Chromium-only** Playwright browser over WebSocket via `playwright run-server`. No Firefox or WebKit is installed. Consumers connect with the standard Playwright client API using `chromium.connect(...)`.

Part of the [`simple-browser-manager` monorepo](../../README.md).

## Why

Run a managed headless Chromium in a container and connect to it from any Node.js (or Python/Java/.NET) Playwright client over `ws://host:3000/`. Useful when you want a single, reusable browser instance rather than spawning one per process.

## Quick start

From this directory:

```sh
./scripts/build.sh       # builds simple-browser-manager-chromium:latest
./scripts/run.sh         # starts container on PORT (default 3000)

# In another shell:
node examples/client.mjs # → "Example Domain"
```

Or with the package's compose:

```sh
docker compose up -d --build
node examples/client.mjs
```

Or use the monorepo root compose to run **all** browsers together:

```sh
cd ../..
docker compose up -d --build chromium
```

## Use from your app

```js
import { chromium } from 'playwright';

const browser = await chromium.connect('ws://127.0.0.1:3000/');
const context = await browser.newContext();
const page = await context.newPage();
await page.goto('https://example.com');
console.log(await page.title());
```

Your app must install **`playwright >= 1.49.0`** to match the server protocol. Major-version mismatches will refuse to connect.

## Configuration

| Env var | Default | Notes                                                |
| ------- | ------- | ---------------------------------------------------- |
| `PORT`  | `3000`  | Port the server listens on inside the container. Maps 1:1 to the host. |

Override examples:

```sh
PORT=4000 ./scripts/run.sh
PORT=4000 docker compose up -d
```

## What's inside the image

- `node:22-bookworm-slim` base.
- Playwright `1.49.1` npm package.
- **Only** `chromium-headless-shell` and `ffmpeg` in `/ms-playwright/`. No Firefox, no WebKit, no full Chromium binary.
- The Chromium runtime dep set for Debian bookworm (libnss, libatk, libxcomposite, etc.).
- `tini` as PID 1 for clean signal forwarding.

Final image size: **~866 MB** (down from ~1.6 GB on first cut; the savings come from using `playwright install --only-shell chromium`, which skips the full Chromium binary since `run-server` is headless-only).

### Firefox/WebKit status

- No Firefox or WebKit **binaries** are installed — only `chromium-headless-shell` and `ffmpeg` live in `/ms-playwright/`.
- The `playwright-core` npm package ships ~3 MB of Firefox/WebKit driver JS which **cannot be removed**: the Playwright server loads these modules at startup for browser-type registration, and removing them breaks the server even though no Firefox/WebKit browser is ever launched.

## Smoke test

`scripts/smoke.sh` builds the image, starts it on `SMOKE_PORT` (default 3000), waits for `http://…/`, then runs `examples/client.mjs` against it.

```sh
./scripts/smoke.sh
```

## Upgrade Playwright

1. Bump the version in `package.json`.
2. `npm install` (regenerates `package-lock.json`).
3. `./scripts/build.sh`.

## Troubleshooting

- **"Chromium failed to launch"** — a runtime library is missing. The Dockerfile installs the Debian bookworm Chromium dep set explicitly; if you forked the Dockerfile, re-run `./scripts/build.sh` and confirm the `apt-get install` line succeeded.
- **Port already in use** — change `PORT` (e.g. `PORT=4000 ./scripts/run.sh`).
- **Client can't connect / version mismatch** — confirm your app's `playwright` is `^1.49.0`. The server logs the negotiated protocol version on first connect.
- **Plain HTTP shows "Running"** — that's the health marker the server returns to non-WebSocket requests. A WS upgrade returns `101 Switching Protocols`.

## Limitations / out of scope

- No HTTPS/WSS termination — put a reverse proxy in front.
- No auth on the WebSocket — bind only to trusted networks.
- Single Playwright server process per container. Scale horizontally by running more containers.
- Each container starts with a fresh browser profile (no persistent user-data-dir volume).