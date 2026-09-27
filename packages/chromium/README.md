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
```

Or with the package's compose:

```sh
docker compose up -d --build
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

Your app must install **`playwright` at the same minor version as the server's `PLAYWRIGHT_VERSION`** (patches within a minor are interchangeable). The server currently defaults to `1.63.0`; your client must be `^1.63.0`. Major/minor mismatches return `HTTP 428 Precondition Required`.

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
- Playwright **at the version pinned by `PLAYWRIGHT_VERSION`** (default `1.63.0`, set via the Dockerfile `ARG` — independent of any package.json).
- **Only** `chromium-headless-shell` and `ffmpeg` in `/ms-playwright/`. No Firefox, no WebKit, no full Chromium binary.
- The Chromium runtime dep set for Debian bookworm (libnss, libatk, libxcomposite, etc.).
- `tini` as PID 1 for clean signal forwarding.

Final image size: **~866 MB** (down from ~1.6 GB on first cut; the savings come from using `playwright install --only-shell chromium`, which skips the full Chromium binary since `run-server` is headless-only).

### Bumping the Playwright version

The version is pinned at the **Docker layer**, not in any package.json:

```sh
# Either edit the default ARG in this Dockerfile, or pass at build time:
docker build --build-arg PLAYWRIGHT_VERSION=1.55.0 -t simple-browser-manager-chromium:1.55.0 .
```

When you bump the server version, **clients must also bump to the same minor** — including the test client in `packages/end-to-end/`.

### Firefox/WebKit status

- No Firefox or WebKit **binaries** are installed — only `chromium-headless-shell` and `ffmpeg` live in `/ms-playwright/`.
- The `playwright-core` npm package ships ~3 MB of Firefox/WebKit driver JS which **cannot be removed**: the Playwright server loads these modules at startup for browser-type registration, and removing them breaks the server even though no Firefox/WebKit browser is ever launched.

## Smoke test

`scripts/smoke.sh` builds the image, starts it on `SMOKE_PORT` (default 3000), waits for `http://…/` to return `Running`, and verifies a WebSocket upgrade is accepted (HTTP 101).

```sh
./scripts/smoke.sh
```

This does **not** launch a browser — that's the job of [`packages/end-to-end/`](../end-to-end/), which performs a full headless browser test against this image.

## End-to-end test

From the monorepo:

```sh
cd packages/end-to-end
npm install
./scripts/test-chromium.sh   # or: npm run chromium
```

This builds the chromium image, starts a container, connects with `chromium.connect()`, navigates to `https://example.com`, and prints `Example Domain`. Run this before releases.

## Troubleshooting

- **"Chromium failed to launch"** — a runtime library is missing. The Dockerfile installs the Debian bookworm Chromium dep set explicitly; if you forked the Dockerfile, re-run `./scripts/build.sh` and confirm the `apt-get install` line succeeded.
- **Port already in use** — change `PORT` (e.g. `PORT=4000 ./scripts/run.sh`).
- **Client can't connect / version mismatch** — confirm your app's `playwright` matches the server's minor (currently `^1.63.0`). The server returns `HTTP 428 Playwright version mismatch` on connect failure.
- **Plain HTTP shows "Running"** — that's the health marker the server returns to non-WebSocket requests. A WS upgrade returns `101 Switching Protocols`.

## Limitations / out of scope

- No HTTPS/WSS termination — put a reverse proxy in front.
- No auth on the WebSocket — bind only to trusted networks.
- Single Playwright server process per container. Scale horizontally by running more containers.
- Each container starts with a fresh browser profile (no persistent user-data-dir volume).