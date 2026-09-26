#!/usr/bin/env bash
# Build the chromium image, run it, run the sanity test, clean up.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_lib.sh
source "$SCRIPT_DIR/_lib.sh"

PORT="${CHROMIUM_TEST_PORT:-3000}"
IMAGE="${CHROMIUM_IMAGE:-simple-browser-manager-chromium:latest}"
CONTAINER="e2e-chromium"

echo "==> building $IMAGE"
( cd "$ROOT_DIR/packages/chromium" && ./scripts/build.sh )

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --rm --name "$CONTAINER" -p "${PORT}:${PORT}" -e "PORT=${PORT}" "$IMAGE"

cleanup() { docker stop "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> waiting for ws://127.0.0.1:${PORT}/"
wait_for_server "http://127.0.0.1:${PORT}/" \
  || { echo "server never became ready" >&2; exit 1; }

echo "==> running chromium sanity test"
cd "$ROOT_DIR/packages/end-to-end"
PORT="${PORT}" node chromium/sanity-test.mjs
echo "chromium e2e OK"