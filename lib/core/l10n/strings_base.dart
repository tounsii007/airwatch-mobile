/// Base class defining all translatable strings.
/// Each language implements this with its own translations.
abstract class AppStrings {
  String get appName => 'AirWatch';

  // Navigation
  String get map;
  String get search;
  String get airport;
  String get airports => 'Airports';
  String get airlines => 'Airlines';
  String get favs;
  String get settings;

  // Extended navigation (feature parity with airwatch-web)
  String get cargo => 'Cargo';
  String get spotting => 'Spotting';
  String get dashboard => 'Dashboard';
  String get globe => 'Globe';
  String get stats => 'Stats';

  // Map-style extras
  String get streetsStyle => 'Streets';
  String get terrainStyle => 'Terrain';
  String get osmLabel => 'OpenStreetMap';
  String get stadiaLabel => 'Stadia Stamen';

  // Admin (read-only)
  String get adminLogin => 'Admin Login';
  String get adminDashboard => 'Admin';
  String get adminUsername => 'Username';
  String get adminPassword => 'Password';
  String get adminSignIn => 'Sign in';
  String get adminSignOut => 'Sign out';
  String get adminHealth => 'Health';
  String get adminMetrics => 'Live metrics';
  String get adminRpsLabel => 'Requests / s';
  String get adminActive => 'Active sessions';
  String get adminHeap => 'Heap usage';
  String get adminBadCreds => 'Invalid username or password';
  String get adminTotpLabel => 'TOTP (optional)';
  String get adminTotpHint =>
      'Only required if 2FA is enabled for this account';
  String get adminErrorRate => 'Error %';
  String get adminTotalReqs => 'Total backend requests';
  String get adminFlightsKpi => 'Flights';
  String get adminOffline => 'Not connected to airwatch-api';
  String get adminOfflineHint =>
      'Session may have expired or the backend is unreachable. '
      'Tap the logout icon and sign in again.';

  // Airlines / Cargo / Spotting
  String get noAirlinesActive => 'No airborne flights match an airline yet';
  String get airlinesCarriers => 'Live carrier list';
  String get airlinesFlightOne => 'flight';
  String get airlinesFlightMany => 'flights';
  String get noCargoActive => 'No cargo flights airborne right now';
  String get cargoSubtitle => 'Cargo flights only';
  String get spottingNoNearby => 'No flights within 60 km of your position';
  String get spottingTabList => 'List';
  String get spottingTabMap => 'Map';
  String get spottingTryAgain => 'Try again';
  String get spottingPermDenied => 'Location permission denied';
  String get spottingPermErrPrefix => 'Location unavailable';
  String get spottingSubtitle => 'Nearby flights — 60 km radius';

  // Stats
  String get statsTracked => 'Tracked';
  String get statsAirborne => 'Airborne';
  String get statsOnGround => 'On ground';
  String get statsAirlabsCalls => 'AirLabs calls';
  String get statsTopAirlines => 'Top airlines (live)';
  String get statsNoData => 'No data yet';
  String get statsFlightsLabel => 'flights';

  // Stats card overhaul (mirrors airwatch-web's design-system commit).
  // Used by the rich StatCard variant on the stats screen — labels stay
  // SHORT-UPPERCASE per the design tokens.
  String get statsFlightsTracked => 'FLIGHTS TRACKED';
  String get statsAvgViewsPerFlight => 'AVG VIEWS / FLIGHT';
  String get statsUniqueAirlines => 'UNIQUE AIRLINES';
  String get statsUniqueAirports => 'UNIQUE AIRPORTS';

  // Squawk emergency-alert banner (mirrors airwatch-web's
  // useSquawkAlerts hook). 7500 → hijack, 7600 → radio failure,
  // 7700 → general emergency. Always show the squawk code itself —
  // pilots / ATC users recognise the codes faster than the labels.
  String get squawkEmergencyTitle => 'Emergency squawk';
  String get squawkHijack => 'Hijack (7500)';
  String get squawkRadioFailure => 'Radio failure (7600)';
  String get squawkGeneral => 'General emergency (7700)';

  // CO2 estimate (mirrors airwatch-web's EmissionsFooter). Shown as a
  // sub-line on the flight-details panel — kt CO2 total, plus the
  // per-passenger split for the typical load factor (~80 %).
  String get co2EstimateLabel => 'CO₂ estimate';
  String get co2PerPaxLabel => 'per passenger';

  // Cargo screen overhaul — labels for the search field, list header,
  // empty-states and stats pills. Mirrors the web frontend's `/cargo`
  // page so the two stay in lock-step.
  String get searchCargoHint => 'Search callsign / airline / country';
  String get cargoFlightsHeader => 'Cargo flights';
  String get cargoHint => 'Tap a card to track on the map';
  String get searchNoResults => 'No matches';
  String get cargoOperators => 'OPERATORS';
  String get cargoTotal => 'TOTAL';
  String get cargoAirborne => 'AIRBORNE';
  String get cargoOnGround => 'ON GROUND';

  // Airports / search shared.
  String get airportsHeader => 'Airports';
  String get popularAirports => 'Popular airports';
  String get departuresHeader => 'Recent departures';
  String get searchAirportsHint => 'IATA, city, country (any language)';

  // Compare flights screen + Geofences screen — both new in this
  // round, mirroring the web frontend's `/compare` and `/geofences`
  // routes. Subtitle phrasing matches the web's QuickLinks copy.
  String get compareFlights => 'Compare flights';
  String get compareSubtitle => 'Side-by-side stat comparison';
  String get geofences => 'Geofences';
  String get geofencesSubtitle => 'Watch zones for inbound aircraft';

  // Voice command button.
  String get voiceCommand => 'Voice command';
  String get voiceListening => 'Listening…';
  String get voiceUnsupported => 'Voice not supported';

  // Dashboard
  String get dashLiveFlights => 'Live flights';
  String get dashSavedItems => 'Saved items';
  String get dashTopAirlines => 'Top airlines';
  String get dashAltBands => 'Altitude bands';
  String get dashSubtitle => 'Personal summary';

  // Globe
  String get globeReload => 'Reload';
  String get globeSubtitle => 'Planet view';

  // Misc / FEATURES section
  String get featuresHeader => 'FEATURES';
  String get errorPrefix => 'Error';
  String get retryButton => 'Retry';

  // Map
  String get live => 'LIVE';
  String get flights;
  String get aircraft;

  // Flight Details
  String get altitude;
  String get speed;
  String get heading;
  String get verticalSpeed => 'V/S';
  String get departure;
  String get arrival;
  String get operatedBy;
  String get track;
  String get replay;
  String get history;
  String get favorite;
  String get share;

  // Status
  String get enRoute;
  String get landed;
  String get scheduled;
  String get delayed;
  String get onTime;
  String get onGround;
  String get airborne;

  // Search
  String get searchHint;
  String get noResults;

  // Settings
  String get appearance;
  String get mapStyle;
  String get units;
  String get mapOptions;
  String get dataSource;
  String get language;

  // Flight History
  String get flightHistory;
  String get searchingDays;

  // Airport
  String get airportRadar;
  String get departures;
  String get arrivals;

  // Splash
  String get tagline;

  // Share
  String get shareText;

  // Favorites
  String get noFavorites;

  // AR
  String get arMode;
  String get pointSkyUp;
}
