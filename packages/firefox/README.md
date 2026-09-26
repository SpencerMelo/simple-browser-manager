# @simple-browser-manager/firefox

A slim Docker image that exposes a **Firefox-only** Playwright browser over WebSocket via `playwright run-server`. No Chromium or WebKit is installed. Consumers connect with the standard Playwright client API using `firefox.connect(...)`.

Part of the [`simple-browser-manager` monorepo](../../README.md).

## Why

Run a managed headless Firefox in a container and connect to it from any Node.js (or Python/Java/.NET) Playwright client over `ws://host:3000/`. Useful when you want a single, reusable Firefox instance rather than spawning one per process, or when your automation needs Firefox-specific behavior.

## Quick start

From this directory:

```sh
./scripts/build.sh       # builds simple-browser-manager-firefox:latest
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
docker compose up -d --build firefox
```

## Use from your app

```js
import { firefox } from 'playwright';

const browser = await firefox.connect('ws://127.0.0.1:3000/');
const context = await browser.newContext();
const page = await context.newPage();
await page.goto('https://example.com');
console.log(await page.title());
```

Your app must install **`playwright >= 1.49.0`** to match the server protocol. Major-version mismatches will refuse to connect. **Use `firefox.connect(...)`, not `chromium.connect(...)`.**

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
- **Only** Firefox in `/ms-playwright/firefox-*`. No Chromium, no WebKit.
- The Firefox runtime dep set for Debian bookworm (libgtk-3, libnss, libpango, libcairo, X11 client libs, Wayland clients, etc.).
- `tini` as PID 1 for clean signal forwarding.

Final image size: roughly comparable to the Chromium one (~800–900 MB); Firefox's binary itself is smaller (~70 MB) but its GTK/Pango/Cairo dep set is larger than Chromium-headless-shell's.

### Firefox vs Chromium

- Firefox is a single binary that runs both headless and headed; there is no separate headless-shell to install.
- Firefox requires GTK 3, Pango/Cairo, and Wayland client libs at runtime — Chromium-headless-shell does not. That's why this image isn't dramatically smaller than the Chromium one despite Firefox's binary being ~5× smaller.
- We deliberately omit the `playwright install-deps` extras (font packages, `xvfb`) — they are not required for headless operation.

### Chromium/WebKit status

- No Chromium or WebKit **binaries** are installed — only Firefox lives in `/ms-playwright/`.
- The `playwright-core` npm package ships ~3 MB of Chromium/WebKit driver JS which **cannot be removed**: the Playwright server loads these modules at startup for browser-type registration, and removing them breaks the server even though no Chromium/WebKit browser is ever launched.

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

- **"Firefox failed to launch"** — a runtime library is missing. The Dockerfile installs the Debian bookworm Firefox dep set explicitly (verified against `ldd` on `libxul.so`); if you forked the Dockerfile, re-run `./scripts/build.sh` and confirm the `apt-get install` line succeeded.
- **Port already in use** — change `PORT` (e.g. `PORT=4000 ./scripts/run.sh`).
- **Client can't connect / version mismatch** — confirm your app's `playwright` is `^1.49.0`. Use `firefox.connect(...)`, not `chromium.connect(...)`.
- **Plain HTTP shows "Running"** — that's the health marker the server returns to non-WebSocket requests. A WS upgrade returns `101 Switching Protocols`.

## Limitations / out of scope

- No HTTPS/WSS termination — put a reverse proxy in front.
- No auth on the WebSocket — bind only to trusted networks.
- Single Playwright server process per container. Scale horizontally by running more containers.
- Each container starts with a fresh Firefox profile (no persistent user-data-dir volume).