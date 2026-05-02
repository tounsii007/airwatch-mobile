# Changelog

All notable changes to AirWatch Mobile are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] — 2026-05-03

### Added — Phase 3 (production release)

* Launcher icons — procedural radar-dome design generated at every
  Android (`mipmap-{m,h,x,xx,xxx}dpi`) and iOS (`Icon-App-*.png`) size from
  `tool/generate_launcher_icons.dart`. Adaptive icon foreground/background
  pair for Android 8.0+ vendor masks.
* Release signing — `android/app/build.gradle.kts` now reads either
  `key.properties` (local) or environment variables (CI), with a debug-key
  fallback for `flutter run --release` on a clean machine.
* Documentation — full `README.md` rewrite, `RELEASE.md` runbook,
  `PRIVACY.md` disclosure, `CHANGELOG.md` (this file). Stub README and
  marketing-only `store_listing.md` are no longer the source of truth for
  developers.
* CI/CD — `.github/workflows/ci.yml` rewritten to gate on lint+widget+
  integration tests, plus a new `.github/workflows/release.yml` that
  signs and publishes a Play Store AAB on `v*.*.*` tags.

### Added — Phase 2 (production parity)

* AR-Mode HUD — pure-math `ar_math.dart` module (bearing, elevation,
  shortest-angle-diff, projection). Compass-strip, horizon-line, and
  aircraft-label overlays driven by magnetometer + accelerometer at 10 Hz.
* Globe overlays — altitude-coloured markers, tap-to-select, AIR/GND/SHOWN
  stats overlay, altitude legend.
* Integration tests — favorites pin/unpin/remove flow, geofence alert
  engine end-to-end (stream-override pattern), 22 ar_math unit tests.
* Home-screen widget — `HomeWidgetService` Dart side + Kotlin
  `FlightWidgetProvider` AppWidgetProvider. 30 s refresh cadence.
* Strict lint sweep — `unawaited_futures`, `cancel_subscriptions`,
  `prefer_const_*`, `use_build_context_synchronously`, etc.
  `dart fix --apply`: 260 fixes across 70 files.

### Added — Phase 1 (production hardening)

* Runtime permission flow on first use (location, mic, camera,
  notifications) with rationale dialogs + settings deeplink fallback.
* Local push notifications for squawks + geofence breaches via
  `flutter_local_notifications` 21.0 with Android channels and iOS
  `UNUserNotificationCenter` integration.
* Persistence — favorites, geofences, settings, dashboard layout, and
  alert read-state all backed by `SharedPreferences`-aware notifiers.
* Perf — marker virtualisation pass, RepaintBoundary scoping, debounced
  search, lazy-loaded photo gallery.
* Widget-test coverage for every screen-level widget.

### Added — Edge-case tests + 2 real bug fixes

* Altitude geofence FP rounding bug — `12192 m × 3.28084 = 40000.001` was
  rejecting the boundary. Replaced multiplication-by-approximated-ratio
  with division-by-exact-SI-constant (`baroAltitude / 0.3048`).
* SIGMET parser NaN bug — `double.tryParse('NaN')` returns NaN (not null),
  producing garbage polygons. Now rejects any token that parses to NaN.
* MapStylePicker dead-tap — popover positioned outside Stack hit-test
  bounds. Refactored to a `Row` with the popover as a normal sibling.

### Added — Round-out commit

* Voice button microphone permission UX.
* Alert hub bottom-sheet + bell-with-badge in the app bar.
* Sortable schedules tab in airport detail.
* Polygon drawing for geofences.
* Replay-3D scrubber with speed control.

### Initial release scope

* Full feature parity with `airwatch-web` — map, search, favorites, flight
  details, airport / airline directory, settings, dashboard, stats, voice,
  3D replay, photo gallery, predictions, turbulence, compare.
* Locales: EN, DE, FR.
* SHA-256 SPKI certificate pinning for the production API host.
* Local JSON databases for cities (with diacritic fold), airports, airlines.

[Unreleased]: https://github.com/<you>/airwatch-mobile/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/<you>/airwatch-mobile/releases/tag/v2.0.0
