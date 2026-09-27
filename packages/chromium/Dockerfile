# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

# Playwright version pinned at build time. To bump, either edit the default
# below or pass `--build-arg PLAYWRIGHT_VERSION=X.Y.Z` at build time.
# This is the **server's** Playwright version — clients connecting via
# `chromium.connect()` must share the same minor (^X.Y.0).
ARG PLAYWRIGHT_VERSION=1.63.0

# Runtime libraries needed by Chromium on Debian bookworm.
# Listed explicitly (instead of relying on `playwright install-deps`) so the
# image is reproducible and doesn't pull in Firefox/WebKit deps.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      fonts-liberation \
      libasound2 \
      libatk-bridge2.0-0 \
      libatk1.0-0 \
      libatspi2.0-0 \
      libc6 \
      libcairo2 \
      libcups2 \
      libdbus-1-3 \
      libdrm2 \
      libexpat1 \
      libfontconfig1 \
      libgbm1 \
      libgcc-s1 \
      libglib2.0-0 \
      libnss3 \
      libnspr4 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libstdc++6 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxi6 \
      libxkbcommon0 \
      libxrandr2 \
      libxrender1 \
      libxss1 \
      libxtst6 \
      tini \
      wget \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
# Install Playwright at the pinned version (independent of any package.json).
# `--no-save` because there is no package.json in this image — we don't want
# to create one. `--omit=dev` skips Playwright's own dev tooling.
# `--only-shell` skips the full Chromium binary since `run-server` is headless.
RUN npm install "playwright@${PLAYWRIGHT_VERSION}" --no-save --omit=dev \
 && npx playwright install --only-shell chromium

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV PORT=3000
EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]