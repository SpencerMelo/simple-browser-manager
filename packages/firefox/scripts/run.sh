#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-3000}"
docker rm -f simple-browser-manager-firefox >/dev/null 2>&1 || true
exec docker run --rm -p "${PORT}:${PORT}" -e "PORT=${PORT}" --name simple-browser-manager-firefox simple-browser-manager-firefox:latest