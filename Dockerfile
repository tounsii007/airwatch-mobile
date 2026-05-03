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

# nginx config template — `envsubst` substitutes ${API_UPSTREAM} at
# container start so the same image works against different backends
# without a rebuild.
RUN printf '%s\n' \
    'server {' \
    '    listen 80;' \
    '    server_name _;' \
    '    root /usr/share/nginx/html;' \
    '    index index.html;' \
    '' \
    '    # Hashed assets: long cache + immutable so the browser does not' \
    '    # revalidate. Hashing is on the filename so cache busts naturally.' \
    '    location ~* \\.(?:js|css|woff2?|ttf|otf|svg|png|jpg|jpeg|webp|wasm)$ {' \
    '        expires 1y;' \
    '        add_header Cache-Control "public, immutable";' \
    '        try_files $uri =404;' \
    '    }' \
    '' \
    '    # API reverse-proxy. Flutter calls /api/airlabs/... → strip the' \
    '    # /api prefix and forward to the airwatch-api container. The trailing' \
    '    # slash on proxy_pass is what does the strip.' \
    '    location /api/ {' \
    '        proxy_pass         ${API_UPSTREAM}/;' \
    '        proxy_http_version 1.1;' \
    '        proxy_set_header   Host              $host;' \
    '        proxy_set_header   X-Real-IP         $remote_addr;' \
    '        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;' \
    '        proxy_set_header   X-Forwarded-Proto $scheme;' \
    '        # WebSocket upgrade for the live-flights stream.' \
    '        proxy_set_header   Upgrade           $http_upgrade;' \
    '        proxy_set_header   Connection        "upgrade";' \
    '        # The poll cycle is 60 s — give the upstream room to answer' \
    '        # without nginx tearing the connection down too aggressively.' \
    '        proxy_read_timeout 75s;' \
    '    }' \
    '' \
    '    # SPA fallback — Flutter handles its own routing client-side.' \
    '    # NB: this comes AFTER /api/ so API requests do not get rewritten.' \
    '    location / {' \
    '        try_files $uri $uri/ /index.html;' \
    '    }' \
    '' \
    '    # Hide the Flutter build version from snoopers.' \
    '    server_tokens off;' \
    '}' > /etc/nginx/templates/default.conf.template

# nginx 1.19+ auto-runs envsubst over /etc/nginx/templates/*.template at
# startup, populating /etc/nginx/conf.d/. Drop the stock default.conf so
# our template wins.
RUN rm -f /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1
