#!/usr/bin/env bash
set -euo pipefail
PORT="${SMOKE_PORT:-3000}"

./scripts/build.sh

docker rm -f smoke-firefox >/dev/null 2>&1 || true
docker run -d --rm --name smoke-firefox -p "${PORT}:${PORT}" -e "PORT=${PORT}" simple-browser-manager-firefox:latest

cleanup() { docker stop smoke-firefox >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Waiting for ws://127.0.0.1:${PORT}/"
ready=false
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
if [ "$ready" != "true" ]; then
  echo "server never became ready" >&2
  exit 1
fi

# Verify a WebSocket upgrade is accepted (proves the Playwright protocol is
# live, not just the HTTP health marker). Actual browser launching is the
# job of packages/end-to-end/. `--max-time` because the server keeps the
# WS connection open waiting for frames after the 101.
status=$(curl -s --max-time 3 -o /dev/null -w '%{http_code}' \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "http://127.0.0.1:${PORT}/" 2>/dev/null || echo "000")
case "$status" in
  101*) echo "smoke OK (HTTP 200 + WS upgrade 101)"; exit 0 ;;
  *)    echo "smoke FAILED (WS upgrade returned $status, expected 101)" >&2; exit 1 ;;
esac