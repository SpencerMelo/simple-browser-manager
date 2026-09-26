#!/usr/bin/env bash
# Build the firefox image, run it, run the sanity test, clean up.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_lib.sh
source "$SCRIPT_DIR/_lib.sh"

PORT="${FIREFOX_TEST_PORT:-3000}"
IMAGE="${FIREFOX_IMAGE:-simple-browser-manager-firefox:latest}"
CONTAINER="e2e-firefox"

echo "==> building $IMAGE"
( cd "$ROOT_DIR/packages/firefox" && ./scripts/build.sh )

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --rm --name "$CONTAINER" -p "${PORT}:${PORT}" -e "PORT=${PORT}" "$IMAGE"

cleanup() { docker stop "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> waiting for ws://127.0.0.1:${PORT}/"
wait_for_server "http://127.0.0.1:${PORT}/" \
  || { echo "server never became ready" >&2; exit 1; }

echo "==> running firefox sanity test"
cd "$ROOT_DIR/packages/end-to-end"
PORT="${PORT}" node firefox/sanity-test.mjs
echo "firefox e2e OK"