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

  /// Bottom-nav overflow trigger — opens the secondary-routes sheet.
  /// Mirrors the web app's "More" button in BottomNav.tsx.
  String get more => 'More';

  /// Short label for the /compare route. The longer "Compare flights"
  /// (compareFlights) stays in place for the page title; this is the
  /// nav-bar label only.
  String get compare => 'Compare';

  /// Sheet header shown above the secondary-routes grid.
  String get moreFeatures => 'More features';

  /// Default short subtitle for the dashboard tile in the More sheet
  /// (the personal-overview tile grid — NOT the web's airport-monitoring
  /// dashboard).
  String get dashboardSubtitle => 'Personal overview';

  /// Page title for the mobile "Dashboard" — renamed to "Overview" to
  /// disambiguate from airwatch-web's `/dashboard` (which monitors
  /// tracked airports). Mobile's screen is a personal tile grid with
  /// live flights / saved items / top airlines / altitude bands.
  /// Falls back to "Overview" in English; locales can override.
  String get overview => 'Overview';

  /// Default short subtitle for the stats tile in the More sheet.
  String get statsSubtitle => 'Tracking history';

  /// Default short subtitle for the airlines tile.
  String get airlinesSubtitle => 'Live carrier list';

  /// Default short subtitle for the spotting tile.
  String get spottingShortSubtitle => 'Nearby flights';

  // NOTE: a comprehensive geofence i18n set (fence form + list + alerts
  // panel + stats badge + I/O toolbar + dashboard empty states) already
  // lives near the END of this class — kept there so the locale-override
  // files don't have to walk past every fence key when editing nav
  // strings. Don't re-add them above; the resolver picks them up the
  // same way regardless of source-line position.

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

  // Personal-stats screen overhaul (mirrors airwatch-web 1e24147).
  // Activity meta strip + 24h chart + top lists + export.
  String get statsTrackingSince => 'TRACKING SINCE';
  String get statsDaysActive => 'DAYS ACTIVE';
  String get statsPeakHour => 'PEAK HOUR';
  String get statsActivityChart => 'ACTIVITY · 24H';
  String get statsTopRoutes => 'TOP ROUTES';
  String get statsTopAirports => 'TOP AIRPORTS';
  String get statsRecentFlights => 'RECENT FLIGHTS';
  String get statsExport => 'Export';
  String get statsExportJson => 'Export as JSON';
  String get statsExportCsv => 'Export as CSV';
  String get statsExportJsonCopied => 'JSON copied to clipboard';
  String get statsExportCsvCopied => 'CSV copied to clipboard';
  String get statsClear => 'Clear history';
  String get statsClearConfirm =>
      'This permanently removes your local viewing history. Continue?';
  String get statsEmptyTitle => 'No flights tracked yet';
  String get statsEmptyHint =>
      'Tap a flight on the map to start recording your personal tracking history.';

  // Wiki panel (mirrors airwatch-web WikiPanel commit d99d3c2).
  /// Section title — "About" / "Über" / "À propos" etc.
  String get wikiAbout => 'About';

  /// CTA link to the canonical Wikipedia page.
  String get wikiReadMore => 'Read on Wikipedia';

  // Nearby Airports panel (mirrors airwatch-web NearbyAirportsPanel
  // commit d99d3c2).
  String get nearbyAirportsTitle => 'Airports near you';
  String get nearbyAirportsCta => 'Use your location to find airports nearby.';
  String get useMyLocation => 'USE MY LOCATION';
  String get locating => 'Locating…';
  String get geoDenied => 'Location permission denied.';
  String get geoUnavailable => 'Location service unavailable.';
  String get noNearbyAirports => 'No airports within range.';

  // Replay screen — entry point for the 7-day flight history search.
  // Mirrors airwatch-web's /replay landing page.
  String get replayTitle => 'Replay';
  String get replayHeading => '7-day flight replay';
  String get replayBody =>
      'Enter a callsign or flight number to see the last 7 days of flights, including delays, scheduled vs actual times, and the route track.';
  String get replayHint => 'Flight number (e.g. TU744)';
  String get replaySearchAction => 'Search';
  String get replayExamples => 'Examples: TU744, DLH441, RYR1234';

  // RecentFlightsList search / sort (mirrors web 1e24147).
  String get statsSearchHint => 'Search callsign / route / airline…';
  String get statsSearchNoMatch => 'No flights match this filter.';
  String get statsSortByRecency => 'Sort by recency';
  String get statsSortByViews => 'Sort by view count';

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

  // ── Aviation weather + NOTAMs (mirrors airwatch-web's MetarPanel +
  // NotamPanel commits d29081e + 8fef4f3). The METAR/TAF panel sits
  // on the airport detail screen between the weather strip and the
  // schedule tabs; the NOTAM panel hugs the bottom of the same view.
  // Three states across both: loading / unavailable / empty — none
  // can be silent, the operator must always know the panel loaded.
  String get metarTafTitle => 'METAR / TAF';
  String get metarTab => 'METAR';
  String get tafTab => 'TAF';
  String get metarUnavailable => 'METAR / TAF unavailable';
  String get metarLabelWind => 'WIND';
  String get metarLabelVisibility => 'VIS';
  String get metarLabelTemp => 'TEMP';
  String get metarLabelAltimeter => 'QNH';
  String get metarLabelClouds => 'CLOUDS';
  String get metarLabelWeather => 'WX';
  String get metarShowRaw => 'Show raw';
  String get metarHideRaw => 'Hide raw';
  String get notamsTitle => 'NOTAMs';
  String get notamsUnavailable => 'NOTAMs unavailable';
  String get notamsNone => 'No NOTAMs reported';
  String get notamsMore => '+{0} more not shown';
  String get loadingShort => 'Loading';

  // ── FleetInfoCard (mirrors web f8fff87) ───────────────────────────────
  String get fleetInfoTitle => 'FLEET INFO';

  /// "{0} years old (built {1})"
  String get fleetAge => '{0} y old (built {1})';

  /// "{0} sightings" (number is locale-formatted by the caller).
  String get fleetSightings => '{0} sightings';

  /// "first seen {0}" with {0} a relative time like "3mo ago".
  String get fleetFirstSeen => 'first seen {0}';
  String get fleetLastSeen => 'last seen {0}';

  // ── RouteStatsBadge (mirrors web 22e4cc0) ─────────────────────────────
  /// "{0} today", "{0} this week", "{0} in 30 d".
  String get routeTodayFlights => '{0} today';
  String get routeWeekFlights => '{0} this week';
  String get routeMonthFlights => '{0} in 30 d';

  // ── AtcAudioPanel (mirrors web c8c53b5) ───────────────────────────────
  String get atcLiveTitle => 'LIVE ATC';
  String get atcUnavailable => 'No catalogued feeds for this airport';

  /// Search-on-LiveATC fallback when the airport isn't in the catalog
  /// or the api errored. The button opens `liveatc.net/search?icao=…`.
  String get atcSearchFallback => 'Search on LiveATC.net';

  /// Attribution line — required by LiveATC.net's terms.
  String get atcAttribution => 'Audio courtesy of LiveATC.net';
  String get atcOpenInBrowser => 'Open in browser';

  // ── Airport detail tab labels + sort pills (i18n leak audit) ──────────
  /// "INFO" tab on the airport detail screen alongside DEP / ARR.
  String get infoTab => 'INFO';

  /// "SORT" prefix on the schedules sort pill row.
  String get sortLabel => 'SORT';

  /// "TIME" sort pill — sort by scheduled time.
  String get sortByTime => 'TIME';

  /// "DELAY" sort pill — sort by delay magnitude.
  String get sortByDelay => 'DELAY';

  // ── ErrorBoundary fallback (i18n leak audit) ──────────────────────────
  /// Shown when a screen segment crashes — see core/widgets/error_boundary.
  String get sectionUnavailable => 'SECTION UNAVAILABLE';

  // ── Relative-time formatter (used by FleetInfoCard sightings rows) ────
  /// "just now" — no quantity.
  String get relTimeNow => 'just now';

  /// "{0}m ago" — quantity + unit suffix is the parser; keep this string
  /// in template form so locales can reorder.
  String get relTimeMinutes => '{0}m ago';
  String get relTimeHours => '{0}h ago';
  String get relTimeDays => '{0}d ago';
  String get relTimeMonths => '{0}mo ago';
  String get relTimeYears => '{0}y ago';

  // ── ICS export — Saved screen → calendar ──────────────────────────────
  String get exportIcs => 'Export .ics';
  String get exportIcsCalName => 'AirWatch — Saved items';
  String get exportNoItems => 'Nothing to export';

  // ── Geofence form (mirrors web 4a6ea68 + e22ca75) ─────────────────────
  /// AppBar title on the form screen.
  String get fenceFormTitle => 'New geofence';

  /// "NEW {0} GEOFENCE" — {0} resolves to "CIRCLE" or "RECTANGLE".
  String get fenceNewHeading => 'NEW {0} GEOFENCE';
  String get fenceTypeCircle => 'CIRCLE';
  String get fenceTypeRectangle => 'RECTANGLE';
  String get fenceNameLabel => 'NAME';
  String get fenceNamePlaceholder => 'e.g. Frankfurt approach';
  String get fenceRadiusLabel => 'RADIUS (KM)';
  String get fenceCenterLatLabel => 'CENTER LATITUDE';
  String get fenceCenterLonLabel => 'CENTER LONGITUDE';
  String get fenceNorthLabel => 'NORTH LATITUDE';
  String get fenceSouthLabel => 'SOUTH LATITUDE';
  String get fenceEastLabel => 'EAST LONGITUDE';
  String get fenceWestLabel => 'WEST LONGITUDE';
  String get fenceMinAltLabel => 'MIN ALT (FT)';
  String get fenceMaxAltLabel => 'MAX ALT (FT)';
  String get fenceAirlineLabel => 'AIRLINE ICAO';
  String get fenceOptionalFilters => 'OPTIONAL FILTERS';
  String get fenceSaveButton => 'SAVE';
  String get fenceCancelButton => 'CANCEL';
  // Validation errors
  String get fenceErrNameRequired => 'Name required';
  String get fenceErrLatRange => 'Latitude must be between -90 and 90';
  String get fenceErrLonRange => 'Longitude must be between -180 and 180';
  String get fenceErrRadius => 'Radius must be greater than 0 km';
  String get fenceErrBoundsRequired => 'All four bounds are required';
  String get fenceErrNorthSouth => 'North must be greater than south';
  String get fenceErrEastWest => 'East must be greater than west';

  // ── Geofence list (mirrors web FencesList.tsx) ────────────────────────
  String get fenceActiveHeading => 'ACTIVE FENCES';

  /// "{0} total" — count of fences shown next to ACTIVE FENCES heading.
  String get fenceTotalCount => '{0} total';
  String get fencesListEmpty =>
      'No fences yet. Tap DRAW or the edit button to add one — alerts will appear here when an aircraft enters the zone.';
  String get fenceDelete => 'Delete';

  /// Shape one-liner — "50.04° N, 8.56° E · r 50.5 km".
  /// {0} = lat, {1} = lon, {2} = radius km.
  String get fenceShapeCircle => '{0}° N, {1}° E · r {2} km';

  /// "S 47.0° → N 51.0° · W 5.0° → E 12.0°".
  /// {0} = south, {1} = north, {2} = west, {3} = east.
  String get fenceShapeRect => 'S {0}° → N {1}° · W {2}° → E {3}°';

  /// "Only Lufthansa (DLH) flights trigger this fence".
  String get fenceAirlineTooltip => 'Only {0} ({1}) flights trigger this fence';
  String get fenceAirlineTooltipNoName => 'Airline filter: {0}';
  String get fenceMinAltTooltip =>
      'Only flights at or above this altitude trigger this fence';
  String get fenceMaxAltTooltip =>
      'Only flights at or below this altitude trigger this fence';

  // ── Draw screen (mirrors web GeoFenceDrawMap) ────────────────────────
  String get fenceDrawTitle => 'Draw geofence';
  String get fenceDrawHintCircleFirst => 'Tap to place the center';
  String get fenceDrawHintCircleSecond => 'Tap to set the radius';
  String get fenceDrawHintRectFirst => 'Tap to set the first corner';
  String get fenceDrawHintRectSecond => 'Tap to set the opposite corner';
  String get fenceDrawHintReady => 'Save when ready, or tap Reset to redraw';
  String get fenceDrawResetButton => 'RESET';
  String get fenceDrawNameTitle => 'Name this fence';

  // ── Alerts panel (mirrors web AlertsPanel.tsx 01d0841) ───────────────
  /// Header word — singular "ALERT" vs plural "ALERTS".
  String get alertsCountOne => 'ALERT';
  String get alertsCountMany => 'ALERTS';
  String get alertsClearAll => 'CLEAR ALL';
  String get alertsClearAllTooltip => 'Clear all alerts (keeps fences)';
  String get alertsDismiss => 'Dismiss';
  String get alertsDismissTooltip =>
      'Dismiss this alert (does not affect history)';
  String get alertsAllFilter => 'ALL';

  /// "Toggle alerts from \"{0}\"" — {0} is the fence name.
  String get alertsFilterTooltip => 'Toggle alerts from "{0}"';
  String get alertsEmptyFilter =>
      'No alerts match the active filter. Tap ALL to clear.';
  String get alertsShowOnMap => 'Show this flight on the live map';

  // ── Fence stats badge (mirrors web FenceStatsBadge.tsx 982c6d2) ──────
  String get fenceStatsHitsOne => '{0} hit';
  String get fenceStatsHitsMany => '{0} hits';
  String get fenceStatsAircraft => '{0} aircraft';
  String get fenceStatsTopAirlineWithName =>
      'Top airline: {0} ({1}× this fence)';
  String get fenceStatsTopAirline => 'Top airline: {0}';

  /// "top:" prefix before the airline ICAO badge in the stats row.
  String get fenceStatsTopLabel => 'top:';

  /// "last 3m" — relative time prefix.
  String get fenceStatsLast => 'last {0}';

  // ── Fence import/export toolbar (mirrors web FenceIOToolbar.tsx) ─────
  String get fenceExport => 'EXPORT';
  String get fenceImport => 'IMPORT';
  String get fenceImporting => 'IMPORTING…';
  String get fenceExportTooltip => 'Download your fences as a JSON file';
  String get fenceImportTooltip => 'Restore fences from a JSON file';
  String get fenceExportEmpty => 'Nothing to export';
  String get fenceExportedOne => 'Exported 1 fence';
  String get fenceExportedMany => 'Exported {0} fences';
  String get fenceReadingFile => 'Reading file…';
  String get fenceImportedOne => 'Imported 1 fence';
  String get fenceImportedMany => 'Imported {0} fences';

  /// "Imported {0}, failed {1} ({2})" — partial-success status message.
  String get fenceImportedPartial => 'Imported {0}, failed {1} ({2})';
  String get fenceReadFailed => 'Read failed: {0}';
  String get fenceImportInvalidJson => 'Invalid JSON: {0}';
  String get fenceImportSchemaMismatch => 'Schema mismatch at {0}: {1}';

  // ── Dashboard empty / honest states (mirrors web 83ab6b2) ────────────
  /// Used when a tile would otherwise render a misleading "0" KPI.
  String get dashNoDataYet => 'No data yet';
  String get dashEmptyHint => 'Open the map to start tracking flights';

  // ── AR HUD compact stat labels ───────────────────────────────────────
  /// Three-letter abbreviation for compass heading, shown in the AR HUD
  /// next to the live degree value. Mirrors the web's AR overlay layout.
  String get arHudHdg => 'HDG';
  String get arHudPitch => 'PITCH';
  String get arHudInView => 'IN VIEW';

  // ── Favourite kind labels (used by the .ics calendar export) ─────────
  /// Singular noun for "Flight" — used in the ICS event title prefix when
  /// exporting saved favourites. Web equivalent: `t('kindFlight')`.
  String get kindFlight => 'Flight';
  String get kindAirline => 'Airline';
  String get kindAirport => 'Airport';

  // ── Generic UI fallbacks ─────────────────────────────────────────────
  /// Last-resort error label shown when an upstream message is unavailable.
  /// Used by the nearby-airports panel retry row, etc.
  String get errorGeneric => 'Error';

  /// Pluralised "{0} active" — geofence badge shown under the page title.
  /// {0} is substituted with the active-fence count.
  String get geofencesActiveCount => '{0} ACTIVE';

  // ── Alert bell + sheet ───────────────────────────────────────────────
  /// Aria label for the bell icon button in the top-right corner.
  String get alertBellAria => 'Open alerts panel';

  /// Empty-state caption shown in the alerts sheet when there are none.
  String get alertsNone => 'No active alerts';

  // ── Generic dialog actions ───────────────────────────────────────────
  /// "Close" — used as the dismiss action on info-only dialogs.
  String get actionClose => 'Close';

  // ── Settings: Privacy Policy dialog ──────────────────────────────────
  // Web parity: PRIVACY.md is shown as a localised dialog; mirrors the
  // /privacy route in airwatch-web. Keep wording short — the dialog is
  // narrow on phones and long sentences wrap awkwardly.
  String get privacyTitle => 'Privacy Policy';

  /// "Last updated: {0} · v{1}" — {0} = date string, {1} = app version.
  String get privacyLastUpdated => 'Last updated: {0} · v{1}';

  String get privacySummaryHeading => 'Summary';
  String get privacySummary1 =>
      'No accounts, no logins, no personal data collected.';
  String get privacySummary2 =>
      'No ads, no analytics SDKs, no telemetry beacons.';
  String get privacySummary3 => 'No data sold or shared with third parties.';

  String get privacyOnDeviceHeading => 'On-device only';
  String get privacyOnDeviceLocation =>
      'Location — used to centre the map and find nearby aircraft. Never uploaded.';
  String get privacyOnDeviceCamera =>
      'Camera (AR mode) — frames are decoded, drawn, and discarded. Never uploaded.';
  String get privacyOnDeviceMicrophone =>
      'Microphone (voice button) — handed to the OS speech recogniser; only the transcript reaches AirWatch, and even that is parsed locally.';
  String get privacyOnDeviceSensors =>
      'Sensors (compass, accelerometer) — read at 10 Hz for the AR HUD; never persisted.';
  String get privacyOnDeviceStorage =>
      'Settings, favourites, geofences — saved in the app sandbox via SharedPreferences / NSUserDefaults.';

  String get privacyNetworkHeading => 'Network';
  String get privacyNetworkHosts =>
      'Talks to api.airwatch.app (TLS-pinned) and pics.avs.io for airline logos. That\'s the entire host list.';
  String get privacyNetworkLogs =>
      'Backend logs are kept 30 days for rate-limiting; IP addresses are not joined with any other dataset.';

  String get privacyRightsHeading => 'Your rights';
  String get privacyRightsList =>
      'Access, rectification, erasure, restriction, portability, objection, and consent withdrawal — write to privacy@airwatch.app.';
  String get privacyRightsComplaint =>
      'Right to lodge a complaint with your local data-protection authority.';

  String get privacyFullTextHeading => 'Full text';
  String get privacyFullTextRef =>
      'See PRIVACY.md in the repository for the complete policy, including third-party data sources and international-transfer details.';
  // ── Aviation: METAR / TAF micro-labels ───────────────────────────────
  /// "Valid {0} → {1}" — TAF validity window prefix. {0} = from, {1} = to.
  String get metarTafValidPrefix => 'Valid {0} → {1}';

  /// "NOW" — short pill shown on the TAF "INITIAL" window row, telling
  /// the operator they're looking at the currently-active forecast.
  String get metarTafNow => 'NOW';

  // ── Geofences: FAB action labels ─────────────────────────────────────
  /// Primary FAB on the geofences screen — opens the draw-on-map screen.
  String get geofencesDrawFab => 'DRAW';

  /// Aria label for the small "open numeric form" FAB next to DRAW.
  String get geofencesFormFabAria => 'Add fence by entering coordinates';
  // ── Map controls (a11y aria-labels) ──────────────────────────────────
  // Screen-reader labels for the icon-only map control stack on the right
  // edge of the map screen. The icons are universally understood
  // visually but a TalkBack/VoiceOver user gets just "button" without
  // these. Mirrors airwatch-web's MapToolbar aria attributes.
  String get mapAriaSearch => 'Open search';
  String get mapAriaZoomIn => 'Zoom in';
  String get mapAriaZoomOut => 'Zoom out';
  String get mapAriaMyLocation => 'Center on my location';
  String get mapAriaCargoToggle => 'Cargo flights only';
}
