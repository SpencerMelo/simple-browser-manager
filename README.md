# simple-browser-manager

A monorepo of slim Docker images that each expose **one** Playwright browser over WebSocket via `playwright run-server`. Each image ships only one browser — no full browser suite per image.

| Package       | Browser                | Image                                       | Connect with         |
| ------------- | ---------------------- | ------------------------------------------- | -------------------- |
| `chromium`    | Chromium (headless)    | `simple-browser-manager-chromium:latest`    | `chromium.connect()` |
| `firefox`     | Firefox (headless)     | `simple-browser-manager-firefox:latest`     | `firefox.connect()`  |
| `end-to-end`  | — (tests only)         | — (no image)                                | —                    |

## Why

Run a managed headless browser in a container and connect to it from any Node.js (or Python/Java/.NET) Playwright client over `ws://host:3000/`. Useful when you want a single, reusable browser instance rather than spawning one per process, or when your automation needs a specific browser engine.

The `chromium` and `firefox` packages are **fully independent** deployable artifacts: own Dockerfile, own scripts. The `end-to-end` package contains the actual browser-launching sanity tests, kept separate so the deployable packages stay clean.

## Layout

```
.
├── docker-compose.yml          # optional: build & run both at once
├── README.md                   # this file
└── packages/
    ├── chromium/               # deployable: → packages/chromium/README.md
    │   ├── Dockerfile          #   pins PLAYWRIGHT_VERSION via ARG
    │   ├── docker-compose.yml
    │   ├── entrypoint.sh
    │   ├── scripts/{build,run,smoke}.sh
    │   └── README.md
    ├── firefox/                # deployable: → packages/firefox/README.md
    │   ├── Dockerfile          #   pins PLAYWRIGHT_VERSION via ARG
    │   ├── docker-compose.yml
    │   ├── entrypoint.sh
    │   ├── scripts/{build,run,smoke}.sh
    │   └── README.md
    └── end-to-end/             # tests only: → packages/end-to-end/README.md
        ├── package.json        #   playwright pinned as devDependency
        ├── chromium/sanity-test.mjs
        ├── firefox/sanity-test.mjs
        └── scripts/{test-chromium,test-firefox,test-all}.sh
```

## Where the Playwright version is set

**Per Docker package, via the `PLAYWRIGHT_VERSION` ARG in each Dockerfile** (currently `1.49.1`). The Docker packages have **no `package.json`** — Playwright is installed at build time with `npm install playwright@${PLAYWRIGHT_VERSION} --no-save`. To bump:

```sh
# Edit the default ARG in packages/chromium/Dockerfile and packages/firefox/Dockerfile,
# or override at build time:
docker build --build-arg PLAYWRIGHT_VERSION=1.55.0 -t simple-browser-manager-chromium:1.55.0 packages/chromium
```

The `end-to-end` package pins its **client** Playwright version in its own `package.json` (currently `1.49.1`). It must match the server's minor — patches within a minor are interchangeable. If you bump the Dockerfiles' `PLAYWRIGHT_VERSION`, bump `end-to-end`'s `package.json` and run `npm install`.

Mismatched clients get a clear error: `HTTP 428 Precondition Required: Playwright version mismatch`.

## Quick start (one browser)

```sh
cd packages/chromium
./scripts/build.sh
./scripts/run.sh         # → ws://127.0.0.1:3000/
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

## End-to-end tests

From the repo root:

```sh
cd packages/end-to-end
npm install
./scripts/test-chromium.sh     # or: npm run chromium
./scripts/test-firefox.sh      # or: npm run firefox
./scripts/test-all.sh          # or: npm test
```

Each script builds the corresponding image, starts a container, connects with `chromium.connect()` / `firefox.connect()`, navigates to `https://example.com`, and prints the title. Tests use distinct ports (`3000` and `4000`) so they can run in parallel.

## What you'll need in your app

```js
// Chromium
import { chromium } from 'playwright';
await chromium.connect('ws://127.0.0.1:3000/');

// Firefox
import { firefox } from 'playwright';
await firefox.connect('ws://127.0.0.1:4000/');
```

Your app's `playwright` version must match the server's `PLAYWRIGHT_VERSION` at the same minor (currently `^1.49.0`).

## Per-package docs

- [`packages/chromium/README.md`](./packages/chromium/README.md) — Chromium-only image (~866 MB; uses `playwright install --only-shell chromium` to skip the full Chromium binary)
- [`packages/firefox/README.md`](./packages/firefox/README.md) — Firefox-only image (Firefox is a single binary; GTK/Pango/Cairo deps are larger than Chromium's)
- [`packages/end-to-end/README.md`](./packages/end-to-end/README.md) — End-to-end sanity tests for both browsers

## Smoke vs end-to-end

Each Docker package has its own `scripts/smoke.sh` that:

- is fast (no Playwright client install needed)
- verifies the server responds to HTTP and accepts a WebSocket upgrade

The `end-to-end` package has the heavier tests that actually launch a headless browser and fetch a real URL. Run smoke in CI; run end-to-end before releases.

## Limitations / out of scope

- No HTTPS/WSS termination — put a reverse proxy in front.
- No auth on the WebSocket — bind only to trusted networks.
- Single Playwright server process per container. Scale horizontally by running more containers.
- Each container starts with a fresh browser profile (no persistent user-data-dir volume).
- No WebKit image yet (easy to add as `packages/webkit/` following the same pattern).