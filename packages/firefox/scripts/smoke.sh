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

echo "Running client smoke test"
if PORT="${PORT}" node examples/client.mjs; then
  echo "smoke OK"
  exit 0
else
  echo "smoke FAILED" >&2
  exit 1
fi