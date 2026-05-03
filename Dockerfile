# ─── Flutter Web build → nginx static serve + reverse-proxy ───────────────
#
# This Dockerfile produces a *web preview* of the AirWatch mobile app — the
# same Dart code base, compiled with `flutter build web --release` and
# served by nginx. Useful for QA, design review, and CI smoke-tests that
# don't want to spin up an Android emulator.
#
# Camera, sensors, geolocation, push notifications, and home widgets
# DO NOT WORK in the web preview. Don't ship this to end users — real
# distribution still goes through `flutter build apk` / `flutter build ipa`
# from a developer machine.
#
# Topology (with the sibling docker-compose.yml in this repo):
#
#     ┌─────────┐  GET /                    ┌────────────────────┐
#     │ browser │ ────────────────────────► │ airwatch-mobile-web│
#     │ (host)  │ ◄──── Flutter bundle ──── │   nginx :80        │
#     └────┬────┘                           └─────────┬──────────┘
#          │                                          │ proxy_pass /api/
#          │  GET /api/airlabs/flights                ▼
#          └─────────────────────────────────► ┌─────────────────┐
#                                              │ airwatch-api    │
#                                              │   :18090        │
#                                              └─────────────────┘
#
# Same-origin from the browser's perspective (`http://localhost:18091/...`),
# which means no CORS preflight, no broken cookies, no surprise.
#
# ─── stage 1: install Flutter SDK + build the web bundle ───────────────────
FROM debian:stable-slim AS flutter-build

# Pin to a known Flutter channel — `stable` floats but anything else is a
# moving target without warning. The Dart SDK constraint in pubspec.yaml
# (^3.11.3) requires Flutter ≥ 3.30.
ARG FLUTTER_CHANNEL=stable

# git is needed because `flutter doctor` and `flutter precache` invoke it
# against $FLUTTER_HOME; curl/unzip/xz-utils are needed for SDK setup.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl ca-certificates unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter under /opt and add to PATH.
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin
RUN git clone --depth 1 -b ${FLUTTER_CHANNEL} \
        https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && git config --global --add safe.directory $FLUTTER_HOME \
    && flutter --version \
    && flutter precache --web --no-android --no-ios --no-linux --no-macos --no-windows

WORKDIR /app

# Cache deps separately from source so a code-only change doesn't re-resolve
# the entire pub graph (~50 packages for this app).
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Now the rest of the source.
COPY . .

# The Flutter web bundle bakes API_BASE_URL in at compile time via
# --dart-define, so the same image can target dev / staging / prod by
# rebuilding with a different value.
#
# Default `/api` is a path-only URL — `dio` on Flutter Web resolves it
# against `window.location.origin`, which is whatever host:port the user
# loaded the bundle from. Combined with the nginx `proxy_pass` block in
# stage 2, this means:
#
#   * The browser only ever sees one origin (the nginx container).
#   * No CORS preflight, no cookie-domain mismatch.
#   * The actual upstream URL is configured ONCE in the nginx block —
#     change `airwatch-api:18090` there to retarget without rebuilding
#     the Flutter bundle.
#
# To bake an absolute URL instead (e.g. for a hosted dashboard that
# can't run a same-origin proxy), pass:
#
#     docker build --build-arg FLUTTER_API_BASE_URL=https://api.example.com .
ARG FLUTTER_API_BASE_URL=/api
ENV FLUTTER_API_BASE_URL=$FLUTTER_API_BASE_URL

RUN flutter build web --release \
        --dart-define=API_BASE_URL=${FLUTTER_API_BASE_URL}

# ─── stage 2: tiny nginx serving the static bundle + API proxy ─────────────
FROM nginx:1.27-alpine AS runner

# Upstream URL for the /api/* reverse-proxy. Baked at build time via
# `envsubst` (see RUN block below) — that means:
#
#   * the rendered config lives in a read-only image layer at runtime,
#     so we don't need /etc/nginx/conf.d to be writable in the container;
#   * to retarget at a different backend (e.g. the Dart sidecar at
#     `http://airwatch-proxy:8080`), pass `--build-arg API_UPSTREAM=...`
#     or set API_UPSTREAM in the .env file (compose forwards it to the
#     build args block in docker-compose.yml).
#
# Doing the substitution at build time avoids two problems with the
# stock image's runtime envsubst entrypoint:
#   * /etc/nginx/conf.d is owned root:0755 by the base image; tmpfs
#     mounts in compose's short-form syntax inherit that mode and the
#     non-root nginx user can't write the rendered config.
#   * The entrypoint scripts run before USER takes effect; coordinating
#     ownership across both phases is fiddly.
ARG API_UPSTREAM=http://airwatch-api:18090

COPY --from=flutter-build /app/build/web /usr/share/nginx/html

# Replace the stock nginx.conf with our own — see comments in
# nginx/nginx.conf for why. The short version: every writable path is
# pinned to /tmp, which is tmpfs in compose and immune to read_only.
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Per-site config template + build-time envsubst. envsubst is preinstalled
# in nginx:alpine (it's part of the gettext package the official image
# pulls for its own runtime envsubst hook). The single-quoted argument
# `'${API_UPSTREAM}'` restricts substitution to that one variable so
# nginx's own $host / $remote_addr / $proxy_add_x_forwarded_for stay
# literal for nginx to interpret at request time.
COPY nginx/default.conf.template /tmp/default.conf.template
RUN envsubst '${API_UPSTREAM}' \
        < /tmp/default.conf.template \
        > /etc/nginx/conf.d/default.conf \
    && rm -f /tmp/default.conf.template

# ─── Drop privileges ──────────────────────────────────────────────────────
# nginx:1.27-alpine ships an unprivileged `nginx` user (uid 101) but the
# stock entrypoint still starts as root for pid + :80 binding. Our
# nginx.conf binds :8080 (>1024, no CAP_NET_BIND_SERVICE), redirects pid
# to /tmp, and uses /dev/std{out,err} for logs — all writable for nginx
# without any chowns. The chown below is just belt-and-suspenders for
# the conf.d file we baked.
#
# This blocks the most common LPE primitive in container escapes: an
# attacker who exploits a memory-corruption bug in nginx would otherwise
# run as root inside the namespace. Now they run as uid 101 with a
# read-only filesystem (see compose file).
RUN chown -R nginx:nginx /etc/nginx/conf.d

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/ || exit 1
