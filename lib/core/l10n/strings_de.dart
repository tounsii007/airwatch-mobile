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
}
