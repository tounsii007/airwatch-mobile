# ─── Flutter Web build → nginx static serve ────────────────────────────────
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
# --dart-define, so the same image can target staging vs prod by rebuilding.
# Defaulted to the API's MOBILE port on localhost — see top-level .env.
ARG FLUTTER_API_BASE_URL=http://localhost:18090
ENV FLUTTER_API_BASE_URL=$FLUTTER_API_BASE_URL

RUN flutter build web --release \
        --dart-define=API_BASE_URL=${FLUTTER_API_BASE_URL}

# ─── stage 2: tiny nginx serving the static bundle ─────────────────────────
FROM nginx:1.27-alpine AS runner

# Drop the default nginx config — we want SPA-aware routing (every path
# falls back to index.html so deep links work).
COPY --from=flutter-build /app/build/web /usr/share/nginx/html

RUN printf '%s\n' \
    'server {' \
    '    listen 80;' \
    '    server_name _;' \
    '    root /usr/share/nginx/html;' \
    '    index index.html;' \
    '    # Hashed assets: long cache + immutable so the browser does not' \
    '    # revalidate. Hashing is on the filename so cache busts naturally.' \
    '    location ~* \.(?:js|css|woff2?|ttf|otf|svg|png|jpg|jpeg|webp|wasm)$ {' \
    '        expires 1y;' \
    '        add_header Cache-Control "public, immutable";' \
    '        try_files $uri =404;' \
    '    }' \
    '    # SPA fallback — Flutter handles its own routing client-side.' \
    '    location / {' \
    '        try_files $uri $uri/ /index.html;' \
    '    }' \
    '    # Hide the Flutter build version from snoopers.' \
    '    server_tokens off;' \
    '}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1
