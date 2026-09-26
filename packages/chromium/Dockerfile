# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

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

# Install dependencies first for layer caching.
COPY package.json package-lock.json ./
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
# `--only-shell`: `run-server` runs headless, so it only ever launches
# chromium-headless-shell. The full ~400 MB Chromium binary would be
# dead weight, so skip it. ffmpeg is still installed because it is needed
# for video recording, which is a supported client feature.
RUN npm ci --omit=dev \
 && npx playwright install --only-shell chromium

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV PORT=3000
EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]