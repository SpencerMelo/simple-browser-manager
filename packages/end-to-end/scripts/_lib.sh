#!/usr/bin/env bash
# Shared helpers for test-chromium.sh and test-firefox.sh.

set -euo pipefail

# Resolve paths relative to this file (packages/end-to-end/scripts/..).
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
# SCRIPT_DIR is packages/end-to-end/scripts; go up 3 to reach the monorepo root.
ROOT_DIR="$(cd "$TEST_DIR/../../.." && pwd)"

# wait_for_server URL
# Polls the HTTP health marker up to 60 seconds.
wait_for_server() {
  local url="$1"
  for _ in $(seq 1 60); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}