import 'strings_base.dart';

class StringsDe extends AppStrings {
  @override
  String get map => 'KARTE';
  @override
  String get search => 'SUCHE';
  @override
  String get airport => 'FLUGHÄFEN';
  @override
  String get favs => 'GESPEICHERT';
  @override
  String get settings => 'EINSTELLUNGEN';

  @override
  String get flights => 'Flüge';
  @override
  String get aircraft => 'Flugzeuge';

  @override
  String get altitude => 'HÖHE';
  @override
  String get speed => 'GESCHWINDIGKEIT';
  @override
  String get heading => 'KURS';
  @override
  String get departure => 'ABFLUG';
  @override
  String get arrival => 'ANKUNFT';
  @override
  String get operatedBy => 'Durchgeführt von';
  @override
  String get track => 'FOLGEN';
  @override
  String get replay => 'REPLAY';
  @override
  String get history => 'VERLAUF';
  @override
  String get favorite => 'SPEICHERN';
  @override
  String get share => 'TEILEN';

  @override
  String get enRoute => 'UNTERWEGS';
  @override
  String get landed => 'GELANDET';
  @override
  String get scheduled => 'GEPLANT';
  @override
  String get delayed => 'VERSPÄTET';
  @override
  String get onTime => 'PÜNKTLICH';
  @override
  String get onGround => 'AM BODEN';
  @override
  String get airborne => 'IN DER LUFT';

  @override
  String get searchHint => 'Flug, Airline, Registrierung...';
  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get appearance => 'DESIGN';
  @override
  String get mapStyle => 'KARTENSTIL';
  @override
  String get units => 'EINHEITEN';
  @override
  String get mapOptions => 'KARTENOPTIONEN';
  @override
  String get dataSource => 'DATENQUELLE';
  @override
  String get language => 'SPRACHE';

  @override
  String get flightHistory => 'FLUGVERLAUF';
  @override
  String get searchingDays => 'Die letzten 7 Tage werden durchsucht...';

  @override
  String get airportRadar => 'FLUGHÄFEN';
  @override
  String get departures => 'ABFLÜGE';
  @override
  String get arrivals => 'ANKÜNFTE';

  @override
  String get tagline => 'VERFOLGE DEN HIMMEL IN ECHTZEIT';

  @override
  String get shareText => 'Sieh dir diesen Flug in AirWatch an.';

  @override
  String get noFavorites => 'NOCH NICHTS GESPEICHERT';

  @override
  String get arMode => 'AR-MODUS';
  @override
  String get pointSkyUp => 'Richte deine Kamera auf den Himmel';

  // Extended navigation (matches airwatch-web labels)
  @override
  String get airports => 'FLUGHÄFEN';
  @override
  String get airlines => 'AIRLINES';
  @override
  String get cargo => 'CARGO';
  @override
  String get spotting => 'SPOTTING';
  @override
  String get dashboard => 'DASHBOARD';
  @override
  String get globe => 'GLOBUS';
  @override
  String get stats => 'STATISTIK';
  @override
  String get more => 'MEHR';
  @override
  String get compare => 'VERGLEICH';
  @override
  String get moreFeatures => 'Weitere Funktionen';
  @override
  String get dashboardSubtitle => 'Persönliche Übersicht';
  @override
  String get statsSubtitle => 'Tracking-Verlauf';
  @override
  String get airlinesSubtitle => 'Live-Fluggesellschaften';
  @override
  String get spottingShortSubtitle => 'Flüge in der Nähe';

  @override
  String get streetsStyle => 'Straßen';
  @override
  String get terrainStyle => 'Gelände';

  // Admin (read-only)
  @override
  String get adminLogin => 'Admin-Login';
  @override
  String get adminDashboard => 'Admin';
  @override
  String get adminUsername => 'Benutzername';
  @override
  String get adminPassword => 'Passwort';
  @override
  String get adminSignIn => 'Anmelden';
  @override
  String get adminSignOut => 'Abmelden';
  @override
  String get adminHealth => 'Status';
  @override
  String get adminMetrics => 'Live-Metriken';
  @override
  String get adminRpsLabel => 'Requests / s';
  @override
  String get adminActive => 'Aktive Sitzungen';
  @override
  String get adminHeap => 'Heap-Auslastung';
  @override
  String get adminBadCreds => 'Benutzername oder Passwort falsch';
  @override
  String get adminTotpLabel => 'TOTP (optional)';
  @override
  String get adminTotpHint =>
      'Nur nötig, wenn für diesen Account 2FA aktiv ist';
  @override
  String get adminErrorRate => 'Fehler %';
  @override
  String get adminTotalReqs => 'Backend-Requests gesamt';
  @override
  String get adminFlightsKpi => 'Flüge';
  @override
  String get adminOffline => 'Keine Verbindung zur airwatch-api';
  @override
  String get adminOfflineHint =>
      'Sitzung möglicherweise abgelaufen, oder Backend nicht erreichbar. '
      'Logout drücken und neu anmelden.';

  // Airlines / Cargo / Spotting
  @override
  String get noAirlinesActive => 'Aktuell keine Airline mit Flügen in der Luft';
  @override
  String get airlinesCarriers => 'Live-Airline-Liste';
  @override
  String get airlinesFlightOne => 'Flug';
  @override
  String get airlinesFlightMany => 'Flüge';
  @override
  String get noCargoActive => 'Aktuell keine Frachtflüge in der Luft';
  @override
  String get cargoSubtitle => 'Nur Frachtflüge';
  @override
  String get spottingNoNearby => 'Keine Flüge innerhalb von 60 km';
  @override
  String get spottingTabList => 'Liste';
  @override
  String get spottingTabMap => 'Karte';
  @override
  String get spottingTryAgain => 'Erneut versuchen';
  @override
  String get spottingPermDenied => 'Standortberechtigung abgelehnt';
  @override
  String get spottingPermErrPrefix => 'Standort nicht verfügbar';
  @override
  String get spottingSubtitle => 'Nahe Flüge — 60 km Radius';

  // Stats
  @override
  String get statsTracked => 'Erfasst';
  @override
  String get statsAirborne => 'In der Luft';
  @override
  String get statsOnGround => 'Am Boden';
  @override
  String get statsAirlabsCalls => 'AirLabs-Calls';
  @override
  String get statsTopAirlines => 'Top-Airlines (live)';
  @override
  String get statsNoData => 'Noch keine Daten';
  @override
  String get statsFlightsLabel => 'Flüge';

  // Stats card overhaul (parität mit airwatch-web design-system commit).
  @override
  String get statsFlightsTracked => 'FLÜGE ERFASST';
  @override
  String get statsAvgViewsPerFlight => 'Ø AUFRUFE / FLUG';
  @override
  String get statsUniqueAirlines => 'AIRLINES';
  @override
  String get statsUniqueAirports => 'FLUGHÄFEN';

  // Personal-Stats Vollausbau (parität mit airwatch-web 1e24147).
  @override
  String get statsTrackingSince => 'TRACKING SEIT';
  @override
  String get statsDaysActive => 'AKTIVE TAGE';
  @override
  String get statsPeakHour => 'SPITZENSTUNDE';
  @override
  String get statsActivityChart => 'AKTIVITÄT · 24 STD';
  @override
  String get statsTopRoutes => 'TOP-ROUTEN';
  @override
  String get statsTopAirports => 'TOP-FLUGHÄFEN';
  @override
  String get statsRecentFlights => 'LETZTE FLÜGE';
  @override
  String get statsExport => 'Exportieren';
  @override
  String get statsExportJson => 'Als JSON exportieren';
  @override
  String get statsExportCsv => 'Als CSV exportieren';
  @override
  String get statsExportJsonCopied => 'JSON in die Zwischenablage kopiert';
  @override
  String get statsExportCsvCopied => 'CSV in die Zwischenablage kopiert';
  @override
  String get statsClear => 'Verlauf löschen';
  @override
  String get statsClearConfirm =>
      'Damit wird dein lokaler Tracking-Verlauf endgültig entfernt. Fortfahren?';
  @override
  String get statsEmptyTitle => 'Noch keine Flüge erfasst';
  @override
  String get statsEmptyHint =>
      'Tippe einen Flug auf der Karte an, um deinen Tracking-Verlauf zu starten.';

  // Overview (umbenannt von Dashboard, siehe DashboardScreen).
  @override
  String get overview => 'Übersicht';

  // Replay (Entry-Screen — die 7-Tage-Historie-Suche selbst lebt in
  // FlightHistoryScreen).
  @override
  String get replayTitle => 'Wiedergabe';
  @override
  String get replayHeading => '7-Tage-Flugwiedergabe';
  @override
  String get replayBody =>
      'Gib ein Rufzeichen oder eine Flugnummer ein, um die letzten 7 Tage zu sehen — inklusive Verspätungen, geplanter vs. tatsächlicher Zeiten und Routen-Track.';
  @override
  String get replayHint => 'Flugnummer (z. B. TU744)';
  @override
  String get replaySearchAction => 'Suchen';
  @override
  String get replayExamples => 'Beispiele: TU744, DLH441, RYR1234';
  @override
  String get statsSearchHint => 'Rufzeichen / Route / Airline suchen…';
  @override
  String get statsSearchNoMatch => 'Keine Flüge passen zu diesem Filter.';
  @override
  String get statsSortByRecency => 'Nach Aktualität sortieren';
  @override
  String get statsSortByViews => 'Nach Aufrufen sortieren';
  @override
  String get wikiAbout => 'Über';
  @override
  String get wikiReadMore => 'Auf Wikipedia weiterlesen';
  @override
  String get nearbyAirportsTitle => 'Flughäfen in deiner Nähe';
  @override
  String get nearbyAirportsCta =>
      'Nutze deinen Standort, um Flughäfen in der Nähe zu finden.';
  @override
  String get useMyLocation => 'MEINEN STANDORT VERWENDEN';
  @override
  String get locating => 'Standort wird ermittelt…';
  @override
  String get geoDenied => 'Standortberechtigung verweigert.';
  @override
  String get geoUnavailable => 'Standortdienst nicht verfügbar.';
  @override
  String get noNearbyAirports => 'Keine Flughäfen in Reichweite.';

  // Squawk emergency
  @override
  String get squawkEmergencyTitle => 'Notfall-Squawk';
  @override
  String get squawkHijack => 'Entführung (7500)';
  @override
  String get squawkRadioFailure => 'Funkausfall (7600)';
  @override
  String get squawkGeneral => 'Allgemeiner Notfall (7700)';

  // CO2
  @override
  String get co2EstimateLabel => 'CO₂-Schätzung';
  @override
  String get co2PerPaxLabel => 'pro Passagier';

  // Cargo overhaul (parität mit airwatch-web /cargo).
  @override
  String get searchCargoHint => 'Callsign / Airline / Land suchen';
  @override
  String get cargoFlightsHeader => 'Frachtflüge';
  @override
  String get cargoHint => 'Karte antippen, um auf Karte zu folgen';
  @override
  String get searchNoResults => 'Keine Treffer';
  @override
  String get cargoOperators => 'OPERATOREN';
  @override
  String get cargoTotal => 'GESAMT';
  @override
  String get cargoAirborne => 'IN DER LUFT';
  @override
  String get cargoOnGround => 'AM BODEN';

  // Airports / search shared.
  @override
  String get airportsHeader => 'Flughäfen';
  @override
  String get popularAirports => 'Beliebte Flughäfen';
  @override
  String get departuresHeader => 'Letzte Abflüge';
  @override
  String get searchAirportsHint => 'IATA, Stadt, Land (jede Sprache)';

  @override
  String get compareFlights => 'Flüge vergleichen';
  @override
  String get compareSubtitle => 'Side-by-Side Statistiken';
  @override
  String get geofences => 'Geofences';
  @override
  String get geofencesSubtitle => 'Zonen für eintreffende Flüge';
  @override
  String get voiceCommand => 'Sprachbefehl';
  @override
  String get voiceListening => 'Höre zu…';
  @override
  String get voiceUnsupported => 'Spracheingabe nicht verfügbar';

  // Dashboard
  @override
  String get dashLiveFlights => 'Live-Flüge';
  @override
  String get dashSavedItems => 'Gespeichert';
  @override
  String get dashTopAirlines => 'Top-Airlines';
  @override
  String get dashAltBands => 'Höhenbänder';
  @override
  String get dashSubtitle => 'Persönliche Übersicht';

  // Globe
  @override
  String get globeReload => 'Neu laden';
  @override
  String get globeSubtitle => 'Globusansicht';

  // FEATURES + misc
  @override
  String get featuresHeader => 'FUNKTIONEN';
  @override
  String get errorPrefix => 'Fehler';
  @override
  String get retryButton => 'Erneut versuchen';

  // METAR / TAF / NOTAM (Parität mit airwatch-web).
  @override
  String get metarTafTitle => 'METAR / TAF';
  @override
  String get metarTab => 'METAR';
  @override
  String get tafTab => 'TAF';
  @override
  String get metarUnavailable => 'METAR / TAF nicht verfügbar';
  @override
  String get metarLabelWind => 'WIND';
  @override
  String get metarLabelVisibility => 'SICHT';
  @override
  String get metarLabelTemp => 'TEMP';
  @override
  String get metarLabelAltimeter => 'QNH';
  @override
  String get metarLabelClouds => 'WOLKEN';
  @override
  String get metarLabelWeather => 'WETTER';
  @override
  String get metarShowRaw => 'Rohdaten zeigen';
  @override
  String get metarHideRaw => 'Rohdaten ausblenden';
  @override
  String get notamsTitle => 'NOTAMs';
  @override
  String get notamsUnavailable => 'NOTAMs nicht verfügbar';
  @override
  String get notamsNone => 'Keine NOTAMs gemeldet';
  @override
  String get notamsMore => '+{0} weitere nicht angezeigt';
  @override
  String get loadingShort => 'Lädt';

  // FleetInfoCard
  @override
  String get fleetInfoTitle => 'FLOTTENINFO';
  @override
  String get fleetAge => '{0} J alt (gebaut {1})';
  @override
  String get fleetSightings => '{0} Sichtungen';
  @override
  String get fleetFirstSeen => 'erstmals gesehen {0}';
  @override
  String get fleetLastSeen => 'zuletzt gesehen {0}';

  // RouteStatsBadge
  @override
  String get routeTodayFlights => '{0} heute';
  @override
  String get routeWeekFlights => '{0} diese Woche';
  @override
  String get routeMonthFlights => '{0} in 30 T';

  // AtcAudioPanel
  @override
  String get atcLiveTitle => 'LIVE ATC';
  @override
  String get atcUnavailable => 'Keine Feeds für diesen Flughafen katalogisiert';
  @override
  String get atcSearchFallback => 'Auf LiveATC.net suchen';
  @override
  String get atcAttribution => 'Audio bereitgestellt von LiveATC.net';
  @override
  String get atcOpenInBrowser => 'Im Browser öffnen';

  // Airport detail tab labels
  @override
  String get infoTab => 'INFO';
  @override
  String get sortLabel => 'SORT.';
  @override
  String get sortByTime => 'ZEIT';
  @override
  String get sortByDelay => 'VERSPÄT.';

  @override
  String get sectionUnavailable => 'BEREICH NICHT VERFÜGBAR';

  // Relative-time
  @override
  String get relTimeNow => 'gerade eben';
  @override
  String get relTimeMinutes => 'vor {0} Min.';
  @override
  String get relTimeHours => 'vor {0} Std.';
  @override
  String get relTimeDays => 'vor {0} T.';
  @override
  String get relTimeMonths => 'vor {0} Mon.';
  @override
  String get relTimeYears => 'vor {0} J.';

  // ICS export
  @override
  String get exportIcs => '.ics exportieren';
  @override
  String get exportIcsCalName => 'AirWatch — Gespeichert';
  @override
  String get exportNoItems => 'Nichts zum Exportieren';

  // ── Geofence form ──────────────────────────────────────────────────────
  @override
  String get fenceFormTitle => 'Neue Geofence';
  @override
  String get fenceNewHeading => 'NEUE {0}-GEOFENCE';
  @override
  String get fenceTypeCircle => 'KREIS';
  @override
  String get fenceTypeRectangle => 'RECHTECK';
  @override
  String get fenceNameLabel => 'NAME';
  @override
  String get fenceNamePlaceholder => 'z. B. Anflug Frankfurt';
  @override
  String get fenceRadiusLabel => 'RADIUS (KM)';
  @override
  String get fenceCenterLatLabel => 'MITTELPUNKT BREITE';
  @override
  String get fenceCenterLonLabel => 'MITTELPUNKT LÄNGE';
  @override
  String get fenceNorthLabel => 'NÖRDLICHE BREITE';
  @override
  String get fenceSouthLabel => 'SÜDLICHE BREITE';
  @override
  String get fenceEastLabel => 'ÖSTLICHE LÄNGE';
  @override
  String get fenceWestLabel => 'WESTLICHE LÄNGE';
  @override
  String get fenceMinAltLabel => 'MIN HÖHE (FT)';
  @override
  String get fenceMaxAltLabel => 'MAX HÖHE (FT)';
  @override
  String get fenceAirlineLabel => 'AIRLINE-ICAO';
  @override
  String get fenceOptionalFilters => 'OPTIONALE FILTER';
  @override
  String get fenceSaveButton => 'SPEICHERN';
  @override
  String get fenceCancelButton => 'ABBRECHEN';
  @override
  String get fenceErrNameRequired => 'Name erforderlich';
  @override
  String get fenceErrLatRange => 'Breitengrad muss zwischen -90 und 90 liegen';
  @override
  String get fenceErrLonRange => 'Längengrad muss zwischen -180 und 180 liegen';
  @override
  String get fenceErrRadius => 'Radius muss größer als 0 km sein';
  @override
  String get fenceErrBoundsRequired => 'Alle vier Grenzen sind erforderlich';
  @override
  String get fenceErrNorthSouth => 'Nord muss größer als Süd sein';
  @override
  String get fenceErrEastWest => 'Ost muss größer als West sein';

  // ── Geofence list ──────────────────────────────────────────────────────
  @override
  String get fenceActiveHeading => 'AKTIVE GEOFENCES';
  @override
  String get fenceTotalCount => '{0} insgesamt';
  @override
  String get fencesListEmpty =>
      'Noch keine Geofences. ZEICHNEN tippen oder über das Formular hinzufügen — Alarme erscheinen hier, sobald ein Flugzeug die Zone betritt.';
  @override
  String get fenceDelete => 'Löschen';
  @override
  String get fenceShapeCircle => '{0}° N, {1}° E · r {2} km';
  @override
  String get fenceShapeRect => 'S {0}° → N {1}° · W {2}° → O {3}°';
  @override
  String get fenceAirlineTooltip =>
      'Nur Flüge von {0} ({1}) lösen diese Geofence aus';
  @override
  String get fenceAirlineTooltipNoName => 'Airline-Filter: {0}';
  @override
  String get fenceMinAltTooltip =>
      'Nur Flüge ab dieser Höhe lösen die Geofence aus';
  @override
  String get fenceMaxAltTooltip =>
      'Nur Flüge bis zu dieser Höhe lösen die Geofence aus';

  // ── Draw screen ────────────────────────────────────────────────────────
  @override
  String get fenceDrawTitle => 'Geofence zeichnen';
  @override
  String get fenceDrawHintCircleFirst =>
      'Tippe, um den Mittelpunkt zu setzen';
  @override
  String get fenceDrawHintCircleSecond => 'Tippe, um den Radius zu setzen';
  @override
  String get fenceDrawHintRectFirst => 'Tippe, um die erste Ecke zu setzen';
  @override
  String get fenceDrawHintRectSecond =>
      'Tippe, um die gegenüberliegende Ecke zu setzen';
  @override
  String get fenceDrawHintReady =>
      'Speichern, wenn fertig, oder RESET tippen';
  @override
  String get fenceDrawResetButton => 'ZURÜCKSETZEN';
  @override
  String get fenceDrawNameTitle => 'Geofence benennen';

  // ── Alerts panel ───────────────────────────────────────────────────────
  @override
  String get alertsCountOne => 'ALARM';
  @override
  String get alertsCountMany => 'ALARME';
  @override
  String get alertsClearAll => 'ALLE LÖSCHEN';
  @override
  String get alertsClearAllTooltip =>
      'Alle Alarme löschen (Geofences bleiben)';
  @override
  String get alertsDismiss => 'Schließen';
  @override
  String get alertsDismissTooltip =>
      'Diesen Alarm schließen (Historie bleibt unberührt)';
  @override
  String get alertsAllFilter => 'ALLE';
  @override
  String get alertsFilterTooltip => 'Alarme von „{0}" umschalten';
  @override
  String get alertsEmptyFilter =>
      'Keine Alarme passen zum Filter. ALLE antippen.';
  @override
  String get alertsShowOnMap => 'Diesen Flug auf der Karte zeigen';

  // ── Fence stats badge ──────────────────────────────────────────────────
  @override
  String get fenceStatsHitsOne => '{0} Treffer';
  @override
  String get fenceStatsHitsMany => '{0} Treffer';
  @override
  String get fenceStatsAircraft => '{0} Flugzeuge';
  @override
  String get fenceStatsTopAirlineWithName =>
      'Top-Airline: {0} ({1}× diese Geofence)';
  @override
  String get fenceStatsTopAirline => 'Top-Airline: {0}';
  @override
  String get fenceStatsTopLabel => 'top:';
  @override
  String get fenceStatsLast => 'zuletzt {0}';

  // ── Fence import/export ────────────────────────────────────────────────
  @override
  String get fenceExport => 'EXPORT';
  @override
  String get fenceImport => 'IMPORT';
  @override
  String get fenceImporting => 'IMPORT…';
  @override
  String get fenceExportTooltip =>
      'Geofences als JSON-Datei herunterladen';
  @override
  String get fenceImportTooltip =>
      'Geofences aus JSON-Datei wiederherstellen';
  @override
  String get fenceExportEmpty => 'Nichts zu exportieren';
  @override
  String get fenceExportedOne => '1 Geofence exportiert';
  @override
  String get fenceExportedMany => '{0} Geofences exportiert';
  @override
  String get fenceReadingFile => 'Datei wird gelesen…';
  @override
  String get fenceImportedOne => '1 Geofence importiert';
  @override
  String get fenceImportedMany => '{0} Geofences importiert';
  @override
  String get fenceImportedPartial =>
      '{0} importiert, {1} fehlgeschlagen ({2})';
  @override
  String get fenceReadFailed => 'Lesen fehlgeschlagen: {0}';
  @override
  String get fenceImportInvalidJson => 'Ungültiges JSON: {0}';
  @override
  String get fenceImportSchemaMismatch =>
      'Schema-Konflikt bei {0}: {1}';

  // ── Dashboard empty / honest states ────────────────────────────────────
  @override
  String get dashNoDataYet => 'Noch keine Daten';
  @override
  String get dashEmptyHint =>
      'Öffne die Karte, um Flüge zu verfolgen';
}
