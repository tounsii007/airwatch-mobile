/// Centralised app configuration.
///
/// <p>The mobile app is a thin client on top of `airwatch-api`. Any
/// third-party API that the web frontend reaches via the Next.js rewrite
/// (Airlabs, hexdb, Planespotters, Open-Meteo) is reached from mobile through
/// the same backend endpoints — the mobile binary never embeds an API key.
///
/// <p>Override the backend URL at build time:
/// ```
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://api.airwatch.example.com
/// ```
///
/// <p>Defaults to `http://10.0.2.2:8080` on Android emulators (which is
/// how the emulator reaches the host's `localhost`) and
/// `http://localhost:8080` everywhere else.
class AppConfig {
  AppConfig._();

  // ═══════════════════════════════════════════════════════════════════════
  //  Backend URL
  // ═══════════════════════════════════════════════════════════════════════
  /// Base URL of the `airwatch-api` Spring Boot server.
  ///
  /// <p>Resolution order:
  /// <ol>
  ///   <li>`--dart-define=API_BASE_URL=...` at build time (prod),</li>
  ///   <li>`http://10.0.2.2:8080` on Android emulator (automatic),</li>
  ///   <li>`http://localhost:8080` fallback (real devices, iOS sim).</li>
  /// </ol>
  static const String _definedBase =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_definedBase.isNotEmpty) return _definedBase;
    // Fallback — developers on a real device should pass API_BASE_URL.
    // Hits the API's MOBILE port (18090). The web port (18080) and the
    // management port (19091) reject mobile clients with 404 (web), or are
    // bound to loopback only (management). See MultiPortServerConfig in
    // airwatch-api for the per-port allow-list.
    return 'http://localhost:18090';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Backend-proxied base URLs
  //
  //  The airwatch-api backend exposes third-party APIs under its own paths
  //  (/airlabs, /hexdb, /photo, /weather, etc.). These helpers keep existing
  //  call-sites working while transparently routing every request through
  //  our backend — no API keys embedded in the mobile binary, one rate-limit
  //  pool shared with the web app, one place to cache.
  // ═══════════════════════════════════════════════════════════════════════
  /// Backend-proxied Airlabs root (was: `https://airlabs.co/api/v9`).
  static String get airlabsUrl       => '$apiBaseUrl/airlabs';
  /// Backend-proxied OpenSky root (was: `https://opensky-network.org`).
  static String get openSkyUrl       => apiBaseUrl;
  /// Backend-proxied hexdb aircraft lookup (was: `hexdb.io/api/v1/aircraft`).
  static String get hexdbUrl         => '$apiBaseUrl/hexdb';
  /// Backend-proxied hexdb airport lookup.
  static String get airportLookupUrl => '$apiBaseUrl/airport';
  /// Backend-proxied Planespotters photo API.
  static String get photoApiUrl      => '$apiBaseUrl/photo';

  /// Backend-proxied image fetch — used for any Planespotters image URL we
  /// received from the photo API. The backend strips CORS issues and caches.
  static String imageProxyUrl(String originalUrl) =>
      '$apiBaseUrl/img/${Uri.encodeComponent(originalUrl)}';

  /// Backend-proxied photo lookup by ICAO hex.
  static String photoLookupUrl(String hex) => '$photoApiUrl/$hex';

  /// Backend-proxied Open-Meteo weather.
  static String weatherUrl(double lat, double lon) =>
      '$apiBaseUrl/weather/${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}';

  /// Backend aggregated lookup endpoint.
  static String lookupUrl(String icao24, String callsign, String airlineIata) =>
      '$apiBaseUrl/lookup?icao24=$icao24&callsign=$callsign'
      '&airline_iata=$airlineIata';

  // ── Airlabs URL builders (routed through backend proxy) ─────────────────
  static String flightUrl({String? flightIcao, String? flightIata}) {
    final q = (flightIcao != null && flightIcao.isNotEmpty)
        ? 'flight_icao=$flightIcao'
        : 'flight_iata=${flightIata ?? ""}';
    return '$airlabsUrl/flight?$q';
  }

  static String routesUrl({String? flightIcao, String? flightIata}) {
    final q = (flightIcao != null && flightIcao.isNotEmpty)
        ? 'flight_icao=$flightIcao'
        : 'flight_iata=${flightIata ?? ""}';
    return '$airlabsUrl/routes?$q';
  }

  static String flightsUrl([String query = '']) =>
      query.isEmpty ? '$airlabsUrl/flights' : '$airlabsUrl/flights?$query';

  static String airportUrl(String iataCode) =>
      '$airlabsUrl/airports?iata_code=$iataCode';

  static String schedulesUrl(String iataCode, {bool departures = true}) =>
      '$airlabsUrl/schedules?'
      '${departures ? "dep_iata" : "arr_iata"}=$iataCode';

  static String scheduleByFlightUrl({String? flightIcao, String? flightIata}) {
    if (flightIata != null && flightIata.isNotEmpty) {
      return '$airlabsUrl/schedules?flight_iata=$flightIata';
    }
    return '$airlabsUrl/schedules?flight_icao=${flightIcao ?? ''}';
  }

  static String scheduleByAirlineUrl({String? airlineIcao, String? airlineIata}) {
    if (airlineIata != null && airlineIata.isNotEmpty) {
      return '$airlabsUrl/schedules?airline_iata=$airlineIata';
    }
    return '$airlabsUrl/schedules?airline_icao=${airlineIcao ?? ''}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Timeouts
  // ═══════════════════════════════════════════════════════════════════════
  static const Duration apiTimeout   = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout  = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════════════════
  //  Update Intervals
  // ═══════════════════════════════════════════════════════════════════════
  static const Duration flightUpdateInterval = Duration(minutes: 5);
  static const Duration historySearchDelay   = Duration(milliseconds: 150);
  static const Duration searchDebounce       = Duration(milliseconds: 300);

  // ═══════════════════════════════════════════════════════════════════════
  //  Cache
  // ═══════════════════════════════════════════════════════════════════════
  static const Duration staleCacheThreshold = Duration(seconds: 180);
  static const int maxTrailPoints = 50;

  // ═══════════════════════════════════════════════════════════════════════
  //  Map Defaults
  // ═══════════════════════════════════════════════════════════════════════
  static const double defaultLat = 48.5;
  static const double defaultLon = 9.0;
  static const double defaultZoom = 5.5;
  static const double minZoom = 2.0;
  static const double maxZoom = 18.0;

  // ═══════════════════════════════════════════════════════════════════════
  //  UI Constants
  // ═══════════════════════════════════════════════════════════════════════
  static const double panelBorderRadius  = 20.0;
  static const double cardBorderRadius   = 14.0;
  static const double buttonBorderRadius = 22.0;
  static const double glassBlur    = 14.0;
  static const double glassOpacity = 0.22;

  // ═══════════════════════════════════════════════════════════════════════
  //  Font Families (match airwatch-web Google Fonts)
  // ═══════════════════════════════════════════════════════════════════════
  static const String fontHeading = 'Orbitron';
  static const String fontBody    = 'Rajdhani';

  // ═══════════════════════════════════════════════════════════════════════
  //  Light Theme Colors
  // ═══════════════════════════════════════════════════════════════════════
  static const int lightPrimary       = 0xFF4A6B8A;
  static const int lightBackground    = 0xFFF0F4F8;
  static const int lightSurface       = 0xFFFFFFFF;
  static const int lightText          = 0xFF1A1A2E;
  static const int lightTextSecondary = 0xFF6B7280;
  static const int lightTextMuted     = 0xFF9CA3AF;
  static const int lightBorder        = 0xFFE2E8F0;

  // ═══════════════════════════════════════════════════════════════════════
  //  Altitude Thresholds (feet)
  // ═══════════════════════════════════════════════════════════════════════
  static const double altitudeLowMax    = 10000;
  static const double altitudeMedMax    = 30000;
  static const double altitudeGroundMax = 100;

  // ═══════════════════════════════════════════════════════════════════════
  //  Aircraft Colors
  // ═══════════════════════════════════════════════════════════════════════
  static const int groundColor    = 0xFF6B7280;
  static const int selectedColor  = 0xFFE0F0FF;
  static const int airportDotColor = 0xFF4A90D9;

  // ═══════════════════════════════════════════════════════════════════════
  //  Map Clustering
  // ═══════════════════════════════════════════════════════════════════════
  static const double clusterZoomThreshold   = 5.0;
  static const int    clusterMinCount        = 500;
  static const int    maxVisibleMarkers      = 800;
  static const double maxMarkersSamplingZoom = 7.0;
  static const int    maxMarkersSamplingTarget = 600;
  static const double viewportMarginBase = 20.0;
  static const double viewportMarginMin  = 0.5;
  static const double viewportMarginMax  = 5.0;
  static const double clusterCellSizeBase = 8.0;
  static const double clusterCellSizeMin  = 1.0;
  static const double clusterCellSizeMax  = 6.0;
  static const int    clusterSmallThreshold = 3;

  // ═══════════════════════════════════════════════════════════════════════
  //  Marker Sizing
  // ═══════════════════════════════════════════════════════════════════════
  static const double markerZoomScaleDivisor = 6.0;
  static const double markerZoomScaleMin     = 0.6;
  static const double markerZoomScaleMax     = 2.0;
  static const double selectedMarkerSize     = 48.0;
  static const double markerSizeMin          = 14.0;
  static const double markerSizeMax          = 40.0;
  static const double selectedMarkerOverflowWidth = 100.0;
  static const double selectedMarkerExtraHeight   = 30.0;
  static const Map<int, double> categoryMarkerSizes = {
    6: 34.0, 5: 32.0, 4: 30.0, 7: 28.0, 3: 24.0,
    8: 22.0, 2: 18.0, 9: 16.0, 10: 14.0, 14: 14.0,
  };
  static const double categoryMarkerSizeDefault = 26.0;

  // ═══════════════════════════════════════════════════════════════════════
  //  Marker Animation
  // ═══════════════════════════════════════════════════════════════════════
  static const Duration markerPulseDuration = Duration(milliseconds: 1500);
  static const double   markerPulseScale = 0.15;
  static const double   markerOverflowMaxHeight = 80.0;
  static const double   markerOverflowMaxWidth  = 100.0;

  // ═══════════════════════════════════════════════════════════════════════
  //  Panel Layout
  // ═══════════════════════════════════════════════════════════════════════
  static const double panelMaxHeightRatio  = 0.65;
  static const double panelTopOffset       = 56.0;
  static const double panelGlassBlurDark   = 15.0;
  static const double panelGlassOpacityDark  = 0.25;
  static const double panelGlassOpacityLight = 0.92;

  // ═══════════════════════════════════════════════════════════════════════
  //  Border Radii
  // ═══════════════════════════════════════════════════════════════════════
  static const double chipBorderRadius       = 8.0;
  static const double tagBorderRadius        = 6.0;
  static const double inputBorderRadius      = 12.0;
  static const double tileBorderRadius       = 10.0;
  static const double filterChipBorderRadius = 20.0;

  // ═══════════════════════════════════════════════════════════════════════
  //  Aircraft Categories (ADS-B Emitter Category 1–14)
  // ═══════════════════════════════════════════════════════════════════════
  static const int categoryNoInfo      = 0;
  static const int categoryLight       = 1;
  static const int categorySmall       = 2;
  static const int categoryLarge       = 3;
  static const int categoryHighVortex  = 4;
  static const int categoryHeavy       = 5;
  static const int categoryHighPerf    = 6;
  static const int categoryRotorcraft  = 7;
  static const int categoryHelicopter  = 8;
  static const int categorySurface     = 9;

  // ═══════════════════════════════════════════════════════════════════════
  //  Trail Settings
  // ═══════════════════════════════════════════════════════════════════════
  static const double trailWidth = 2.0;

  // ═══════════════════════════════════════════════════════════════════════
  //  Animations
  // ═══════════════════════════════════════════════════════════════════════
  static const Duration markerAnimDuration = Duration(milliseconds: 800);
  static const Duration panelAnimDuration  = Duration(milliseconds: 400);
  static const Duration radarSweepDuration = Duration(seconds: 4);

  // ═══════════════════════════════════════════════════════════════════════
  //  Search
  // ═══════════════════════════════════════════════════════════════════════
  static const int maxSearchResults = 50;

  // ═══════════════════════════════════════════════════════════════════════
  //  Airline logo — remote, unchanged
  // ═══════════════════════════════════════════════════════════════════════
  static String airlineLogoUrl(String iataCode) =>
      'https://pics.avs.io/200/80/${iataCode.toUpperCase()}.png';
}
