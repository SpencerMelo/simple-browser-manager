# @simple-browser-manager/end-to-end

End-to-end sanity tests for the `chromium` and `firefox` packages. Each test builds the corresponding image, starts a container, connects via the Playwright client, and prints `https://example.com`'s title. Exit code 0 means everything works.

This package is **not** part of any deployable image — it exists only to verify the other two packages actually do what they claim. The Docker packages (`packages/chromium/`, `packages/firefox/`) are kept clean of test code.

## Layout

```
end-to-end/
├── package.json                  # devDependency on playwright (test client only)
├── package-lock.json
├── chromium/
│   └── sanity-test.mjs           # chromium.connect → example.com
├── firefox/
│   └── sanity-test.mjs           # firefox.connect → example.com
├── scripts/
│   ├── _lib.sh                   # shared helpers
│   ├── test-chromium.sh          # build + run + sanity-test chromium
│   ├── test-firefox.sh           # build + run + sanity-test firefox
│   └── test-all.sh               # run both
└── README.md
```

## Quick start

From this directory:

```sh
npm install                            # one-time
./scripts/test-chromium.sh             # build & sanity-test chromium
./scripts/test-firefox.sh              # build & sanity-test firefox
./scripts/test-all.sh                  # both
```

Or via npm scripts:

```sh
npm run chromium
npm run firefox
npm test                               # both
```

## Configuration

Each test script honors these env vars (defaults shown):

| Var                    | Default                              | Notes                                                |
| ---------------------- | ------------------------------------ | ---------------------------------------------------- |
| `CHROMIUM_TEST_PORT`   | `3000`                               | Port chromium container listens on                   |
| `FIREFOX_TEST_PORT`    | `3000`                               | Port firefox container listens on (test-all uses 4000 to avoid collision) |
| `CHROMIUM_IMAGE`       | `simple-browser-manager-chromium:latest` | Override to test a custom-built chromium image  |
| `FIREFOX_IMAGE`        | `simple-browser-manager-firefox:latest`  | Same for firefox                                |
| `TARGET_URL`           | `https://example.com`                | URL the sanity test navigates to                  |

`test-all.sh` sets `FIREFOX_TEST_PORT=4000` by default so both can run on the same host without colliding.

## Version pinning (important)

The Playwright version in **this** package.json (`devDependencies.playwright`) is the **client** version. It must match the server version (the `PLAYWRIGHT_VERSION` ARG in the Dockerfiles) at the **same minor** — patches within a minor are interchangeable.

The Dockerfiles currently default to `PLAYWRIGHT_VERSION=1.63.0`, and this package pins `playwright@1.63.0` to match. If you bump the Dockerfiles' `PLAYWRIGHT_VERSION` (e.g. to `1.70.0`), bump it here too:

1. Edit `package.json` → change `"playwright": "1.63.0"` to the new version
2. `npm install`
3. Re-run the tests

If versions are mismatched, you'll see `HTTP 428 Precondition Required: Playwright version mismatch` on the client side.

## What the tests verify

| Step                | chromium test                          | firefox test                          |
| ------------------- | -------------------------------------- | ------------------------------------- |
| Build image         | `packages/chromium/scripts/build.sh`   | `packages/firefox/scripts/build.sh`   |
| Start container     | `docker run` on `$CHROMIUM_TEST_PORT`  | `docker run` on `$FIREFOX_TEST_PORT`  |
| Wait for server     | `GET http://.../` returns `Running`    | same                                  |
| Launch browser      | `chromium.connect()`                   | `firefox.connect()`                   |
| Navigate            | `page.goto('https://example.com')`     | same                                  |
| Assert              | prints `Example Domain`                | same                                  |
| Cleanup             | `docker stop`                          | same                                  |

The image's own `scripts/smoke.sh` only verifies HTTP responds + WebSocket upgrade is accepted (proves the server is up and speaking the Playwright protocol). Browser launching is this package's job.

## Smoke vs end-to-end

Each Docker package still has its own `scripts/smoke.sh` that runs as part of `scripts/build.sh`-adjacent CI. That smoke test:

- is fast (~seconds after image build)
- doesn't need a Playwright client installed
- only proves the server is alive

The end-to-end tests here are slower (downloads browser binary if not cached, launches real browser, fetches a real URL) but prove the full pipeline works. Run end-to-end before releases; run smoke in CI per push.