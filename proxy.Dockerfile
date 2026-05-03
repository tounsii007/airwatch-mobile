# ─── Dart proxy server → AOT-compiled binary ─────────────────────────────
#
# Containerises `proxy/bin/proxy_server.dart`, the lightweight
# Airlabs+OpenMeteo+hexdb+Planespotters CORS proxy that local development
# uses when no `airwatch-api` container is running. In a full container
# stack you'd point Flutter Web straight at `airwatch-api:18090` and skip
# this image entirely; it's here as a "drop-in replacement when the
# Spring Boot API isn't available" — handy for offline demos and CI.
#
# Two stages:
#   1. dart:stable-sdk + AOT compile → /server.exe
#   2. debian:stable-slim runtime  → ~25 MB image, no SDK in the runtime
#
# Why AOT, not JIT?
#   * 6× smaller cold-start (single binary, no SDK).
#   * No need to ship the pub cache or run `dart pub get` at runtime.
#   * Same wire behaviour — proxy_server.dart has no dynamic loading.
#
# Run it standalone:
#   docker build -f proxy.Dockerfile -t airwatch-proxy:local .
#   docker run --rm -p 18090:8080 -e AIRLABS_KEY=... airwatch-proxy:local
#
# Or via the sibling docker-compose.yml under the `proxy` profile:
#   docker compose --profile proxy up

# ─── stage 1: AOT compile ─────────────────────────────────────────────────
FROM dart:stable AS proxy-build

WORKDIR /app

# proxy_server.dart is a single file with no pubspec — but `dart compile
# exe` still needs a minimal pubspec for the SDK constraint, so we
# generate one inline. (If proxy/ ever grows a real pubspec, drop this
# block and just COPY the directory.)
RUN printf '%s\n' \
    'name: airwatch_proxy' \
    'description: AirWatch Dart CORS proxy (containerised).' \
    'environment:' \
    '  sdk: ">=3.0.0 <4.0.0"' > pubspec.yaml \
    && dart pub get

COPY proxy/bin/proxy_server.dart bin/server.dart

RUN dart compile exe bin/server.dart -o /server

# ─── stage 2: tiny runtime ────────────────────────────────────────────────
FROM debian:stable-slim AS runner

# ca-certificates so HttpClient can talk to airlabs.co / planespotters.net
# over HTTPS; tini reaps zombie processes if the proxy spawns subprocesses
# (it currently doesn't, but the cost is one binary).
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

# Copy the AOT binary AND the dart runtime that AOT-compiled binaries
# need. `dart compile exe` bundles a self-contained snapshot but still
# expects libc + libpthread, which debian:stable-slim provides.
COPY --from=proxy-build /server /usr/local/bin/airwatch-proxy

# Create an unprivileged user — same defence-in-depth motivation as the
# nginx Dockerfile. system/no-shell so a runtime exploit can't drop into
# an interactive shell.
RUN useradd --system --no-create-home --shell /usr/sbin/nologin proxy

# `proxy_server.dart` reads PROXY_HOST/PORT/AIRLABS_KEY from env. Default
# to 0.0.0.0 so the container is reachable from the Docker network — the
# Dart code defaults to `localhost`, which would only bind the loopback
# interface inside the container and reject neighbours.
ENV PROXY_HOST=0.0.0.0
ENV PORT=8080

USER proxy

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/ || exit 1

# tini as PID 1 so SIGTERM/SIGINT propagate cleanly to the Dart process.
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/airwatch-proxy"]
