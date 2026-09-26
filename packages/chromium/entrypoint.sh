#!/bin/sh
set -e
exec npx playwright run-server --host 0.0.0.0 --port "${PORT:-3000}"