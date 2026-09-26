#!/usr/bin/env bash
# Run both chromium and firefox end-to-end tests, each on its own port.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CHROMIUM_TEST_PORT="${CHROMIUM_TEST_PORT:-3000}" \
  "$SCRIPT_DIR/test-chromium.sh"

FIREFOX_TEST_PORT="${FIREFOX_TEST_PORT:-4000}" \
  "$SCRIPT_DIR/test-firefox.sh"

echo ""
echo "==> all end-to-end tests passed"