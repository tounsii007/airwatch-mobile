import 'strings_base.dart';

/// Italian locale — parity with airwatch-web's it.json (commit 96b8291).
///
/// <p>Aviation jargon (METAR, TAF, NOTAM, ICAO, IATA, squawk, AirWatch)
/// stays untranslated — same convention used by web.
class StringsIt extends AppStrings {
  @override
  String get map => 'MAPPA';
  @override
  String get search => 'CERCA';
  @override
  String get airport => 'AEROPORTI';
  @override
  String get favs => 'SALVATI';
  @override
  String get settings => 'IMPOSTAZIONI';

  @override
  String get flights => 'voli';
  @override
  String get aircraft => 'aeromobili';

  @override
  String get altitude => 'ALTITUDINE';
  @override
  String get speed => 'VELOCITÀ';
  @override
  String get heading => 'DIREZIONE';
  @override
  String get departure => 'PARTENZA';
  @override
  String get arrival => 'ARRIVO';
  @override
  String get operatedBy => 'Operato da';
  @override
  String get track => 'SEGUI';
  @override
  String get replay => 'REPLAY';
  @override
  String get history => 'CRONOLOGIA';
  @override
  String get favorite => 'SALVA';
  @override
  String get share => 'CONDIVIDI';

  @override
  String get enRoute => 'IN ROTTA';
  @override
  String get landed => 'ATTERRATO';
  @override
  String get scheduled => 'PROGRAMMATO';
  @override
  String get delayed => 'IN RITARDO';
  @override
  String get onTime => 'IN ORARIO';
  @override
  String get onGround => 'A TERRA';
  @override
  String get airborne => 'IN VOLO';

  @override
  String get searchHint => 'Volo, compagnia, immatricolazione...';
  @override
  String get noResults => 'Nessun risultato';

  @override
  String get appearance => 'ASPETTO';
  @override
  String get mapStyle => 'STILE MAPPA';
  @override
  String get units => 'UNITÀ';
  @override
  String get mapOptions => 'OPZIONI MAPPA';
  @override
  String get dataSource => 'FONTE DATI';
  @override
  String get language => 'LINGUA';

  @override
  String get flightHistory => 'CRONOLOGIA VOLO';
  @override
  String get searchingDays => 'Ricerca degli ultimi 7 giorni...';

  @override
  String get airportRadar => 'AEROPORTI';
  @override
  String get departures => 'PARTENZE';
  @override
  String get arrivals => 'ARRIVI';

  @override
  String get tagline => 'SEGUI IL CIELO IN TEMPO REALE';

  @override
  String get shareText => 'Guarda questo volo su AirWatch.';

  @override
  String get noFavorites => 'NULLA SALVATO ANCORA';

  @override
  String get arMode => 'MODALITÀ AR';
  @override
  String get pointSkyUp => 'Punta la fotocamera al cielo';

  @override
  String get airports => 'AEROPORTI';
  @override
  String get airlines => 'COMPAGNIE';
  @override
  String get cargo => 'CARGO';
  @override
  String get spotting => 'SPOTTING';
  @override
  String get dashboard => 'DASHBOARD';
  @override
  String get globe => 'GLOBO';
  @override
  String get stats => 'STATISTICHE';

  @override
  String get streetsStyle => 'Strade';
  @override
  String get terrainStyle => 'Terreno';

  @override
  String get adminLogin => 'Login admin';
  @override
  String get adminDashboard => 'Admin';
  @override
  String get adminUsername => 'Utente';
  @override
  String get adminPassword => 'Password';
  @override
  String get adminSignIn => 'Accedi';
  @override
  String get adminSignOut => 'Esci';
  @override
  String get adminHealth => 'Stato';
  @override
  String get adminMetrics => 'Metriche live';
  @override
  String get adminRpsLabel => 'Richieste / s';
  @override
  String get adminActive => 'Sessioni attive';
  @override
  String get adminHeap => 'Uso memoria';
  @override
  String get adminBadCreds => 'Utente o password errati';
  @override
  String get adminTotpLabel => 'TOTP (opzionale)';
  @override
  String get adminTotpHint =>
      'Necessario solo se questo account ha la 2FA attiva';
  @override
  String get adminErrorRate => 'Errori %';
  @override
  String get adminTotalReqs => 'Richieste totali al backend';
  @override
  String get adminFlightsKpi => 'Voli';
  @override
  String get adminOffline => 'Non connesso a airwatch-api';
  @override
  String get adminOfflineHint =>
      'La sessione potrebbe essere scaduta o il backend non è raggiungibile. '
      'Premi disconnetti e accedi di nuovo.';

  @override
  String get noAirlinesActive =>
      'Nessuna compagnia con voli in volo al momento';
  @override
  String get airlinesCarriers => 'Lista compagnie live';
  @override
  String get airlinesFlightOne => 'volo';
  @override
  String get airlinesFlightMany => 'voli';
  @override
  String get noCargoActive => 'Nessun volo cargo in aria al momento';
  @override
  String get cargoSubtitle => 'Solo voli cargo';
  @override
  String get spottingNoNearby => 'Nessun volo entro 60 km dalla tua posizione';
  @override
  String get spottingTabList => 'Lista';
  @override
  String get spottingTabMap => 'Mappa';
  @override
  String get spottingTryAgain => 'Riprova';
  @override
  String get spottingPermDenied => 'Permesso posizione negato';
  @override
  String get spottingPermErrPrefix => 'Posizione non disponibile';
  @override
  String get spottingSubtitle => 'Voli vicini — raggio 60 km';

  @override
  String get statsTracked => 'Tracciati';
  @override
  String get statsAirborne => 'In volo';
  @override
  String get statsOnGround => 'A terra';
  @override
  String get statsAirlabsCalls => 'Chiamate AirLabs';
  @override
  String get statsTopAirlines => 'Top compagnie (live)';
  @override
  String get statsNoData => 'Nessun dato';
  @override
  String get statsFlightsLabel => 'voli';

  @override
  String get statsFlightsTracked => 'VOLI TRACCIATI';
  @override
  String get statsAvgViewsPerFlight => 'VIS. MEDIE / VOLO';
  @override
  String get statsUniqueAirlines => 'COMPAGNIE';
  @override
  String get statsUniqueAirports => 'AEROPORTI';

  @override
  String get squawkEmergencyTitle => 'Squawk emergenza';
  @override
  String get squawkHijack => 'Dirottamento (7500)';
  @override
  String get squawkRadioFailure => 'Guasto radio (7600)';
  @override
  String get squawkGeneral => 'Emergenza generale (7700)';

  @override
  String get co2EstimateLabel => 'Stima CO₂';
  @override
  String get co2PerPaxLabel => 'per passeggero';

  @override
  String get searchCargoHint => 'Cerca callsign / compagnia / paese';
  @override
  String get cargoFlightsHeader => 'Voli cargo';
  @override
  String get cargoHint => 'Tocca una scheda per seguire sulla mappa';
  @override
  String get searchNoResults => 'Nessuna corrispondenza';
  @override
  String get cargoOperators => 'OPERATORI';
  @override
  String get cargoTotal => 'TOTALE';
  @override
  String get cargoAirborne => 'IN VOLO';
  @override
  String get cargoOnGround => 'A TERRA';

  @override
  String get airportsHeader => 'Aeroporti';
  @override
  String get popularAirports => 'Aeroporti popolari';
  @override
  String get departuresHeader => 'Partenze recenti';
  @override
  String get searchAirportsHint => 'IATA, città, paese (qualsiasi lingua)';

  @override
  String get compareFlights => 'Confronta voli';
  @override
  String get compareSubtitle => 'Confronto fianco a fianco';
  @override
  String get geofences => 'Geofence';
  @override
  String get geofencesSubtitle => 'Zone per voli in arrivo';
  @override
  String get voiceCommand => 'Comando vocale';
  @override
  String get voiceListening => 'In ascolto…';
  @override
  String get voiceUnsupported => 'Voce non supportata';

  @override
  String get dashLiveFlights => 'Voli live';
  @override
  String get dashSavedItems => 'Salvati';
  @override
  String get dashTopAirlines => 'Top compagnie';
  @override
  String get dashAltBands => 'Fasce di altitudine';
  @override
  String get dashSubtitle => 'Riepilogo personale';

  @override
  String get globeReload => 'Ricarica';
  @override
  String get globeSubtitle => 'Vista pianeta';

  @override
  String get featuresHeader => 'FUNZIONI';
  @override
  String get errorPrefix => 'Errore';
  @override
  String get retryButton => 'Riprova';

  // METAR / TAF / NOTAM
  @override
  String get metarTafTitle => 'METAR / TAF';
  @override
  String get metarTab => 'METAR';
  @override
  String get tafTab => 'TAF';
  @override
  String get metarUnavailable => 'METAR / TAF non disponibile';
  @override
  String get metarLabelWind => 'VENTO';
  @override
  String get metarLabelVisibility => 'VIS';
  @override
  String get metarLabelTemp => 'TEMP';
  @override
  String get metarLabelAltimeter => 'QNH';
  @override
  String get metarLabelClouds => 'NUVOLE';
  @override
  String get metarLabelWeather => 'TEMPO';
  @override
  String get metarShowRaw => 'Mostra grezzo';
  @override
  String get metarHideRaw => 'Nascondi grezzo';
  @override
  String get notamsTitle => 'NOTAMs';
  @override
  String get notamsUnavailable => 'NOTAMs non disponibili';
  @override
  String get notamsNone => 'Nessun NOTAM segnalato';
  @override
  String get notamsMore => '+{0} non mostrati';
  @override
  String get loadingShort => 'Caricamento';

  // FleetInfoCard
  @override
  String get fleetInfoTitle => 'INFO FLOTTA';
  @override
  String get fleetAge => '{0} a (costruito {1})';
  @override
  String get fleetSightings => '{0} avvistamenti';
  @override
  String get fleetFirstSeen => 'primo avvistamento {0}';
  @override
  String get fleetLastSeen => 'ultimo avvistamento {0}';

  // RouteStatsBadge
  @override
  String get routeTodayFlights => '{0} oggi';
  @override
  String get routeWeekFlights => '{0} questa settimana';
  @override
  String get routeMonthFlights => '{0} in 30 g';

  // AtcAudioPanel
  @override
  String get atcLiveTitle => 'ATC LIVE';
  @override
  String get atcUnavailable =>
      'Nessun feed catalogato per questo aeroporto';
  @override
  String get atcSearchFallback => 'Cerca su LiveATC.net';
  @override
  String get atcAttribution => 'Audio per gentile concessione di LiveATC.net';
  @override
  String get atcOpenInBrowser => 'Apri nel browser';

  // Airport detail tab labels
  @override
  String get infoTab => 'INFO';
  @override
  String get sortLabel => 'ORD.';
  @override
  String get sortByTime => 'ORA';
  @override
  String get sortByDelay => 'RITARDO';

  @override
  String get sectionUnavailable => 'SEZIONE NON DISPONIBILE';

  // Relative-time
  @override
  String get relTimeNow => 'proprio ora';
  @override
  String get relTimeMinutes => '{0} min fa';
  @override
  String get relTimeHours => '{0} h fa';
  @override
  String get relTimeDays => '{0} g fa';
  @override
  String get relTimeMonths => '{0} mesi fa';
  @override
  String get relTimeYears => '{0} anni fa';

  // ICS export
  @override
  String get exportIcs => 'Esporta .ics';
  @override
  String get exportIcsCalName => 'AirWatch — Salvati';
  @override
  String get exportNoItems => 'Nulla da esportare';
}
