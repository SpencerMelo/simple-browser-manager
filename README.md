# simple-browser-manager

A monorepo of slim Docker images that each expose **one** Playwright browser over WebSocket via `playwright run-server`. Each image ships only one browser — no full browser suite per image.

| Package   | Browser                | Image                                       | Connect with         |
| --------- | ---------------------- | ------------------------------------------- | -------------------- |
| `chromium`| Chromium (headless)    | `simple-browser-manager-chromium:latest`    | `chromium.connect()` |
| `firefox` | Firefox (headless)     | `simple-browser-manager-firefox:latest`     | `firefox.connect()`  |

## Why

Run a managed headless browser in a container and connect to it from any Node.js (or Python/Java/.NET) Playwright client over `ws://host:3000/`. Useful when you want a single, reusable browser instance rather than spawning one per process, or when your automation needs a specific browser engine.

Each package is **fully independent**: own Dockerfile, own package.json, own docker-compose, own scripts. You can build and run just the one you need.

## Layout

```
.
├── docker-compose.yml          # optional: build & run both at once
├── README.md                   # this file
└── packages/
    ├── chromium/               # → packages/chromium/README.md
    │   ├── Dockerfile
    │   ├── docker-compose.yml
    │   ├── entrypoint.sh
    │   ├── package.json / package-lock.json
    │   ├── examples/client.mjs
    │   └── scripts/{build,run,smoke}.sh
    └── firefox/                # → packages/firefox/README.md
        ├── Dockerfile
        ├── docker-compose.yml
        ├── entrypoint.sh
        ├── package.json
        ├── examples/client.mjs
        └── scripts/{build,run,smoke}.sh
```

## Quick start (one browser)

```sh
cd packages/chromium
./scripts/build.sh
./scripts/run.sh         # → ws://127.0.0.1:3000/
node examples/client.mjs  # → "Example Domain"
```

Replace `chromium` with `firefox` for the Firefox image (uses `firefox.connect()`).

## Quick start (both at once)

From the repo root:

```sh
docker compose up -d --build
# chromium → ws://127.0.0.1:3000/
# firefox  → ws://127.0.0.1:4000/
```

The root compose maps Chromium to host port 3000 and Firefox to 4000 by default. Override with `CHROMIUM_PORT` / `FIREFOX_PORT` env vars.

To run just one:

```sh
docker compose up -d --build chromium
docker compose up -d --build firefox
```

## Configuration

Each container honors a single env var:

| Env var | Default | Notes                                                |
| ------- | ------- | ---------------------------------------------------- |
| `PORT`  | `3000`  | Port the server listens on inside the container. Maps 1:1 to the host. |

The root compose uses `CHROMIUM_PORT` and `FIREFOX_PORT` (default 3000 and 4000 respectively).

## What you'll need

Your app must install **`playwright >= 1.49.0`** to match the server protocol. Major-version mismatches will refuse to connect.

```js
// Chromium
import { chromium } from 'playwright';
const browser = await chromium.connect('ws://127.0.0.1:3000/');

// Firefox
import { firefox } from 'playwright';
const browser = await firefox.connect('ws://127.0.0.1:4000/');
```

## Per-package docs

- [`packages/chromium/README.md`](./packages/chromium/README.md) — Chromium-only image (~866 MB; uses `playwright install --only-shell chromium` to skip the full Chromium binary)
- [`packages/firefox/README.md`](./packages/firefox/README.md) — Firefox-only image (Firefox is a single binary; GTK/Pango/Cairo deps are larger than Chromium's)

## Smoke testing

Each package has its own smoke script that builds, starts the container, waits for the WS handshake, and runs the example client:

```sh
cd packages/chromium && ./scripts/smoke.sh
cd packages/firefox  && ./scripts/smoke.sh
```

## Upgrade Playwright

In each package:

1. Bump the version in `package.json`.
2. `npm install` (regenerates `package-lock.json`).
3. `./scripts/build.sh`.

## Limitations / out of scope

- No HTTPS/WSS termination — put a reverse proxy in front.
- No auth on the WebSocket — bind only to trusted networks.
- Single Playwright server process per container. Scale horizontally by running more containers.
- Each container starts with a fresh browser profile (no persistent user-data-dir volume).
- No WebKit image yet (easy to add as `packages/webkit/` following the same pattern).