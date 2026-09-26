# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

# Runtime libraries needed by Firefox on Debian bookworm.
# Listed explicitly (instead of relying on `playwright install-deps`) so the
# image is reproducible and doesn't pull in Chromium/WebKit deps.
# These are the packages Firefox's `libxul.so` actually links against
# (verified via `ldd`); the Playwright `install-deps` list includes some
# extras (like fonts and xvfb) that headless mode doesn't need.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      libasound2 \
      libatk-bridge2.0-0 \
      libatk1.0-0 \
      libatspi2.0-0 \
      libcairo2 \
      libcairo-gobject2 \
      libdbus-1-3 \
      libepoxy0 \
      libfontconfig1 \
      libfreetype6 \
      libfribidi0 \
      libgdk-pixbuf-2.0-0 \
      libglib2.0-0 \
      libgtk-3-0 \
      libharfbuzz0b \
      liblcms2-2 \
      libnss3 \
      libnspr4 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libpangoft2-1.0-0 \
      libpixman-1-0 \
      libstdc++6 \
      libwayland-client0 \
      libwayland-cursor0 \
      libwayland-egl1 \
      libx11-6 \
      libx11-xcb1 \
      libxau6 \
      libxcb-render0 \
      libxcb-shm0 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxdmcp6 \
      libxext6 \
      libxfixes3 \
      libxi6 \
      libxinerama1 \
      libxkbcommon0 \
      libxrandr2 \
      libxrender1 \
      libxres1 \
      tini \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies first for layer caching.
COPY package.json package-lock.json ./
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
# Firefox is one binary (no headless-shell variant like Chromium). We install
# Firefox only; WebKit/Chromium are explicitly skipped.
RUN npm ci --omit=dev \
 && npx playwright install firefox

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV PORT=3000
EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]