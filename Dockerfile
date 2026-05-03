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

# The upstream the `/api/*` location proxies to. Override at run time with
# `-e API_UPSTREAM=http://other-host:1234` if you point this image at a
# non-default backend.
ENV API_UPSTREAM=http://airwatch-api:18090

# nginx's docker-entrypoint runs `envsubst` over /etc/nginx/templates/*.
# By default it would also try to substitute nginx's own variables
# (`$host`, `$remote_addr`, `$proxy_add_x_forwarded_for`, …) and break
# the config. Restrict the substitution to JUST the variables we control;
# everything else is left as a literal `$name` for nginx to interpret.
ENV NGINX_ENVSUBST_FILTER="API_UPSTREAM"

COPY --from=flutter-build /app/build/web /usr/share/nginx/html

# Server config — kept as a checked-in file (nginx/default.conf.template)
# rather than an inline `printf` so:
#
#   * shell-quoting fragility goes away (escaping `$host` / regex `\.`
#     inside a multi-line printf was a recurring footgun);
#   * the config is reviewable as plain text in the repo;
#   * COPY auto-creates `/etc/nginx/templates/` on the way in, which is
#     the directory the official entrypoint scripts read from.
#
# The official image's `20-envsubst-on-templates.sh` entry-point hook
# renders this template at container start, substituting `${API_UPSTREAM}`
# (and only that — see NGINX_ENVSUBST_FILTER above) into
# `/etc/nginx/conf.d/default.conf`. The compose file mounts a tmpfs at
# /etc/nginx/conf.d so the rendered file can be written even though the
# rest of the root filesystem is read-only.
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template

# ─── Drop privileges ──────────────────────────────────────────────────────
# nginx:1.27-alpine ships an unprivileged `nginx` user (uid 101) but its
# default ENTRYPOINT still starts as root in order to write the master
# pid + listen on :80. The template above already binds :8080 (>1024,
# no CAP_NET_BIND_SERVICE needed); here we relocate the pid file to
# /tmp (which compose mounts as tmpfs) and chown all paths nginx will
# touch at runtime.
#
# This protects against the most common LPE primitive in container
# escapes: an attacker who exploits a memory-corruption bug in nginx
# would otherwise run as root inside the namespace. Now they run as
# uid 101 with a read-only filesystem (see compose file).
RUN rm -f /etc/nginx/conf.d/default.conf \
    && sed -i \
        -e 's|listen       80;|listen       8080;|g' \
        -e 's|/var/run/nginx.pid|/tmp/nginx.pid|g' \
        /etc/nginx/nginx.conf \
    && touch /tmp/nginx.pid \
    && chown -R nginx:nginx /var/cache/nginx /tmp/nginx.pid \
                            /etc/nginx/conf.d /etc/nginx/templates

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/ || exit 1
