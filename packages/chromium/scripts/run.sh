#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-3000}"
docker rm -f simple-browser-manager-chromium >/dev/null 2>&1 || true
exec docker run --rm -p "${PORT}:${PORT}" -e "PORT=${PORT}" --name simple-browser-manager-chromium simple-browser-manager-chromium:latest