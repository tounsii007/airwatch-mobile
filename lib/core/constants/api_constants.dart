import 'package:airwatch_mobile/core/constants/config.dart';

/// All routes the mobile app consumes on the `airwatch-api` backend.
///
/// <p>The mobile app mirrors the web frontend — same Spring Boot server, same
/// endpoints, same wire format. There is no direct call to OpenSky, Airlabs,
/// hexdb, Planespotters, etc.; all external data is proxied by the backend so
/// the mobile binary ships without any third-party API keys.
///
/// <p>Every route is rooted at [AppConfig#apiBaseUrl], which defaults to
/// `http://localhost:8080` for local dev and is overridden at build time
/// via the `--dart-define=API_BASE_URL=https://...` flag for prod builds.
class ApiConstants {
  ApiConstants._();

  // ── Helper ────────────────────────────────────────────────────────────────
  static String get _base => AppConfig.apiBaseUrl;

  // ── Public flight feed (mirrors /api/proxy/api/flights on the web) ───────
  /// Current live aircraft map — returns `{count, timestamp, data: [Aircraft]`}.
  static String get flights => '$_base/api/flights';

  /// Single aircraft by ICAO 24-bit hex. `null` → 404.
  static String flightByIcao24(String icao24) => '$_base/api/flights/$icao24';

  /// Search by callsign / IATA / ICAO / partial name. Max 50 matches.
  static String flightSearch(String query) =>
      '$_base/api/flights/search?q=${Uri.encodeQueryComponent(query)}';

  /// Position history for a specific aircraft, `hours` in [1, 24].
  static String flightHistoryByIcao(String icao24, {int hours = 24}) =>
      '$_base/api/flights/$icao24/history?hours=$hours';

  /// Position history for a callsign (e.g. "LH400").
  static String flightHistoryByCallsign(String callsign, {int hours = 24}) =>
      '$_base/api/flights/callsign/${Uri.encodeComponent(callsign)}/history?hours=$hours';

  // ── Airports / airlines / schedules (backend-proxied Airlabs + cached) ────
  static String airportByIata(String iata) => '$_base/api/airports/$iata';

  /// Departures for an airport. Backend handles Airlabs quota + caching.
  static String departures(String iata) =>
      '$_base/api/airports/$iata/departures';

  /// Arrivals for an airport.
  static String arrivals(String iata) =>
      '$_base/api/airports/$iata/arrivals';

  /// Airline details + flights.
  static String airlineByIcao(String icao) => '$_base/api/airlines/$icao';

  // ── Aircraft metadata, photos, weather (backend-proxied) ─────────────────
  static String aircraftByHex(String hex) => '$_base/api/hexdb/aircraft/$hex';
  static String photoByHex(String hex)    => '$_base/api/photos/$hex';
  static String weather(double lat, double lon) =>
      '$_base/api/weather/${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}';

  // ── Aggregated stats / replay ────────────────────────────────────────────
  static String get flightStats   => '$_base/api/stats';
  static String get replayAvail   => '$_base/api/replay/available';
  static String get replayStats   => '$_base/api/replay/stats';

  // ── Static data assets served by the backend (mirrors /public/data) ──────
  /// 4,800-city i18n translation table (en/de/fr). Same artefact the web
  /// frontend consumes, fetched at app boot and merged into the curated map.
  static String get cityI18n      => '$_base/data/city-i18n.json';
  /// IATA → {country, city, lat, lon} dataset (~8 k airports).
  static String get airportsIndex => '$_base/data/airports.json';

  // ── WebSocket channels ───────────────────────────────────────────────────
  /// Public live-flight push channel. Same feed every subscriber gets.
  static String get wsFlights {
    final scheme = AppConfig.apiBaseUrl.startsWith('https://') ? 'wss' : 'ws';
    final host   = AppConfig.apiBaseUrl.replaceFirst(RegExp('^https?://'), '');
    return '$scheme://$host/ws/flights';
  }

  // ── Tile map URLs (client-side only, no backend involvement) ─────────────
  static const String darkTileUrl =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
  static const String lightTileUrl =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
  static const String satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/'
      'MapServer/tile/{z}/{y}/{x}';
  static const String streetsTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String terrainTileUrl =
      'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}@2x.png';

  // ── Update intervals / limits ────────────────────────────────────────────
  static const int realtimeUpdateIntervalMs  = 5000;
  static const int positionInterpolationMs   = 1000;
  static const int trailRetentionSeconds     = 60;
  static const int maxAircraftOnScreen       = 20000;

  // ── Map defaults (unchanged) ─────────────────────────────────────────────
  static const double defaultLatitude  = 48.8566;
  static const double defaultLongitude = 2.3522;
  static const double defaultZoom      = 5.0;
  static const double minZoom          = 2.0;
  static const double maxZoom          = 18.0;

  // ── Clustering ───────────────────────────────────────────────────────────
  static const int clusterMaxZoom = 10;
  static const int clusterRadius  = 80;
}
