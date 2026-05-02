# AirWatch Mobile

Real-time flight tracker for Android and iOS — the mobile companion to the
[`airwatch-web`](../airwatch-web) dashboard. Same data, same backend, same
visual language; native gestures, push notifications, AR HUD, and a home-
screen widget.

> **Status:** v2.0.0 — feature-complete and production-ready. CI green,
> 524 tests passing, lint-clean against a strict ruleset.

---

## What it does

* **Live radar.** 7,000+ aircraft worldwide on an interactive map, updated
  every few seconds via WebSocket. Marker colour by altitude, true-track
  rotation, and clustering for dense airspace.
* **Flight details.** Tap any aircraft to open a glass-panel drawer with
  callsign, route, ETA, delay prediction, CO₂ estimate, photo, and 7-day
  history.
* **Airports & airlines.** 20,845 airports and 6,244 airlines indexed
  locally — searchable in EN/DE/FR with diacritic-insensitive matching.
* **AR mode.** Point the phone at the sky to see aircraft labels overlaid
  on the camera feed, driven by magnetometer + accelerometer at 10 Hz.
* **3D globe.** Spin the world to find traffic anywhere; tap a marker to
  open the same flight panel as the 2D map.
* **Geofences & squawk alerts.** Draw a polygon on the map, get a push
  notification when an aircraft enters / leaves it. Emergency squawks
  (7500 / 7600 / 7700) trigger automatically.
* **Spotting screen.** "What's flying near me right now?" with a 60 km
  radar disc and a sortable list view.
* **Home-screen widget** (Android). Live-flight count + top airline,
  refreshing every 30 s.
* **Voice commands.** "Show map", "Search Lufthansa", "Open Madrid airport"
  — works in EN/DE/FR with accent-tolerant parsing.
* **Compare, Cargo, Photo Gallery, Replay-3D, Predictions, Turbulence** —
  the full feature set is at parity with the web dashboard.

---

## Stack

| Layer            | Pick                                                      |
|------------------|-----------------------------------------------------------|
| Framework        | Flutter 3.41.x · Dart 3.11                                |
| State            | Riverpod 3.x with code-gen (`riverpod_annotation`)        |
| Map              | flutter_map 8.3 + flutter_map_marker_cluster              |
| Globe            | flutter_earth_globe 2.2                                   |
| Charts           | fl_chart 0.69 (chart_theme.dart wraps it)                 |
| Networking       | dio + web_socket_channel + SHA-256 SPKI cert pinning      |
| Storage          | shared_preferences                                        |
| Notifications    | flutter_local_notifications 21.0                          |
| Sensors          | sensors_plus, geolocator, camera, speech_to_text          |
| Home widget      | home_widget 0.9 + Kotlin AppWidgetProvider                |
| i18n             | EN / DE / FR via static `S.of(...)` factory               |

---

## Getting started

```bash
# 1. Clone and install
git clone https://github.com/<you>/airwatch-mobile.git
cd airwatch-mobile
flutter pub get

# 2. Run on a connected device or emulator
flutter run

# 3. Run the test suite
flutter test
```

The app talks to the airwatch-api backend by default at
`https://api.airwatch.app`. Override via `lib/core/constants/config.dart`
or the `AIRWATCH_API_BASE` env var if you're proxying locally.

### Local proxy (optional)

`proxy/` ships a Dart CLI that mirrors the web app's same-origin proxy —
useful for offline development and avoiding CORS hassles in the web build.

```bash
dart run proxy/bin/proxy_server.dart   # default port 18090
```

---

## Project layout

```
lib/
├── core/                # cross-cutting: theme, l10n, network, widgets
├── features/
│   ├── ar/              # AR HUD (compass, horizon, aircraft labels)
│   ├── airline/         # airline detail & directory
│   ├── airport/         # airport detail, weather, webcam, schedules
│   ├── cargo/           # cargo-only filter view
│   ├── compare/         # side-by-side flight comparison
│   ├── dashboard/       # tile-grid home screen
│   ├── favorites/       # favorites + pinning
│   ├── flight_details/  # detail panel, replay 2D/3D, prediction
│   ├── geofences/       # polygon drawing + alert engine
│   ├── globe/           # 3D earth view
│   ├── home_widget/     # Dart side of the Android widget
│   ├── map/             # map screen, layers, providers
│   ├── notifications/   # alert hub + push delivery
│   ├── search/          # cross-entity search service
│   ├── settings/        # units, language, themes
│   ├── spotting/        # nearby flights radar
│   ├── stats/           # aggregate stats
│   └── voice/           # speech-to-command parser
├── app.dart             # AppEntry + provider scopes + listeners
└── main.dart            # bootstrap
```

* **Tests** live in `test/{unit,widget,integration}/` — currently 524.
* **Tooling** lives in `tool/` (icon generator, db generator).
* **Native code** in `android/app/src/main/kotlin/` and `ios/Runner/`.

---

## Internationalisation

Three locales are first-class: **English, German, French**. Strings live in
`lib/core/l10n/app_strings.dart` as a typed interface plus three impl
classes; the active locale comes from `languageProvider` and falls back to
the device locale, then English.

The search service normalises diacritics (`"München" ↔ "Munchen"`,
`"Tunisie" ↔ "Tunesien" ↔ "Tunisia"`) so country / city queries work
regardless of which language the user typed.

---

## Tests

```
flutter test              # full suite (524 tests)
flutter test test/unit/   # pure-Dart logic
flutter test test/widget/ # widget rendering
flutter test test/integration/ # multi-provider flows
```

The most interesting ones are in `test/unit/*_edge_cases_test.dart` — they
exist to flush out floating-point and boundary bugs (e.g. the altitude
geofence FP rounding bug, the SIGMET NaN-polygon bug, the MapStylePicker
hit-test bug). Add new edge tests when you ship anything that crosses
those classes of error.

---

## Production readiness

* **Phase 1** — permissions, push, persistence, perf, widget tests.
* **Phase 2** — AR HUD, globe overlays, integration tests, home widget,
  strict lint sweep (260 fixes / 70 files via `dart fix`).
* **Phase 3** — launcher icons, release signing, CI/CD, privacy policy.
  See `RELEASE.md` for the cut-a-release runbook and `PRIVACY.md` for the
  data-handling disclosure.

---

## Contributing

Internal project, but the contribution flow is the standard one:

1. Branch from `main`, name it `feat/...` or `fix/...`.
2. `flutter analyze` and `flutter test` must be green before you open a PR.
3. Add tests for any new logic that isn't pure UI.
4. Keep `CHANGELOG.md` up to date — the release pipeline reads it.

---

## License

Proprietary. © 2026 Ridha Abderrahmen. See [LICENSE](LICENSE) for the full
terms.
