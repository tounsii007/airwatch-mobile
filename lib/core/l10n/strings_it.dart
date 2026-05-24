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
  String get more => 'ALTRO';
  @override
  String get compare => 'CONFRONTA';
  @override
  String get moreFeatures => 'Altre funzioni';
  @override
  String get dashboardSubtitle => 'Riepilogo personale';
  @override
  String get statsSubtitle => 'Cronologia';
  @override
  String get airlinesSubtitle => 'Compagnie aeree live';
  @override
  String get spottingShortSubtitle => 'Voli vicini';

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

  // Personal-stats overhaul (parità con airwatch-web 1e24147).
  @override
  String get statsTrackingSince => 'TRACCIAMENTO DA';
  @override
  String get statsDaysActive => 'GIORNI ATTIVI';
  @override
  String get statsPeakHour => 'ORA DI PUNTA';
  @override
  String get statsActivityChart => 'ATTIVITÀ · 24 H';
  @override
  String get statsTopRoutes => 'TOP ROTTE';
  @override
  String get statsTopAirports => 'TOP AEROPORTI';
  @override
  String get statsRecentFlights => 'VOLI RECENTI';
  @override
  String get statsExport => 'Esporta';
  @override
  String get statsExportJson => 'Esporta come JSON';
  @override
  String get statsExportCsv => 'Esporta come CSV';
  @override
  String get statsExportJsonCopied => 'JSON copiato negli appunti';
  @override
  String get statsExportCsvCopied => 'CSV copiato negli appunti';
  @override
  String get statsClear => 'Cancella cronologia';
  @override
  String get statsClearConfirm =>
      'Questo rimuove definitivamente la cronologia locale. Continuare?';
  @override
  String get statsEmptyTitle => 'Nessun volo tracciato';
  @override
  String get statsEmptyHint =>
      'Tocca un volo sulla mappa per iniziare a registrare la cronologia personale.';
  @override
  String get overview => 'Panoramica';
  @override
  String get replayTitle => 'Replay';
  @override
  String get replayHeading => 'Replay 7 giorni';
  @override
  String get replayBody =>
      'Inserisci un indicativo o un numero di volo per vedere gli ultimi 7 giorni — ritardi, orari programmati vs effettivi e tracciato della rotta.';
  @override
  String get replayHint => 'Numero di volo (es. TU744)';
  @override
  String get replaySearchAction => 'Cerca';
  @override
  String get replayExamples => 'Esempi: TU744, DLH441, RYR1234';
  @override
  String get statsSearchHint => 'Cerca indicativo / rotta / compagnia…';
  @override
  String get statsSearchNoMatch => 'Nessun volo corrisponde al filtro.';
  @override
  String get statsSortByRecency => 'Ordina per recente';
  @override
  String get statsSortByViews => 'Ordina per visualizzazioni';
  @override
  String get wikiAbout => 'Informazioni';
  @override
  String get wikiReadMore => 'Leggi su Wikipedia';
  @override
  String get nearbyAirportsTitle => 'Aeroporti vicini';
  @override
  String get nearbyAirportsCta =>
      'Usa la tua posizione per trovare aeroporti nelle vicinanze.';
  @override
  String get useMyLocation => 'USA LA MIA POSIZIONE';
  @override
  String get locating => 'Localizzazione…';
  @override
  String get geoDenied => 'Permesso di posizione negato.';
  @override
  String get geoUnavailable => 'Servizio di posizione non disponibile.';
  @override
  String get noNearbyAirports => 'Nessun aeroporto a portata.';

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
  String get atcUnavailable => 'Nessun feed catalogato per questo aeroporto';
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

  // ── Geofence form ──────────────────────────────────────────────────────
  @override
  String get fenceFormTitle => 'Nuova geofence';
  @override
  String get fenceNewHeading => 'NUOVA GEOFENCE {0}';
  @override
  String get fenceTypeCircle => 'CERCHIO';
  @override
  String get fenceTypeRectangle => 'RETTANGOLO';
  @override
  String get fenceNameLabel => 'NOME';
  @override
  String get fenceNamePlaceholder => 'es. Avvicinamento Francoforte';
  @override
  String get fenceRadiusLabel => 'RAGGIO (KM)';
  @override
  String get fenceCenterLatLabel => 'LATITUDINE CENTRO';
  @override
  String get fenceCenterLonLabel => 'LONGITUDINE CENTRO';
  @override
  String get fenceNorthLabel => 'LATITUDINE NORD';
  @override
  String get fenceSouthLabel => 'LATITUDINE SUD';
  @override
  String get fenceEastLabel => 'LONGITUDINE EST';
  @override
  String get fenceWestLabel => 'LONGITUDINE OVEST';
  @override
  String get fenceMinAltLabel => 'ALT. MIN (FT)';
  @override
  String get fenceMaxAltLabel => 'ALT. MAX (FT)';
  @override
  String get fenceAirlineLabel => 'ICAO COMPAGNIA';
  @override
  String get fenceOptionalFilters => 'FILTRI OPZIONALI';
  @override
  String get fenceSaveButton => 'SALVA';
  @override
  String get fenceCancelButton => 'ANNULLA';
  @override
  String get fenceErrNameRequired => 'Nome richiesto';
  @override
  String get fenceErrLatRange => 'La latitudine deve essere tra -90 e 90';
  @override
  String get fenceErrLonRange => 'La longitudine deve essere tra -180 e 180';
  @override
  String get fenceErrRadius => 'Il raggio deve essere maggiore di 0 km';
  @override
  String get fenceErrBoundsRequired => 'Tutti e quattro i bordi richiesti';
  @override
  String get fenceErrNorthSouth => 'Nord deve essere maggiore di Sud';
  @override
  String get fenceErrEastWest => 'Est deve essere maggiore di Ovest';

  // ── Geofence list ──────────────────────────────────────────────────────
  @override
  String get fenceActiveHeading => 'GEOFENCE ATTIVE';
  @override
  String get fenceTotalCount => '{0} totali';
  @override
  String get fencesListEmpty =>
      'Nessuna geofence. Tocca DISEGNA o usa il modulo — gli avvisi appariranno qui quando un aereo entra nella zona.';
  @override
  String get fenceDelete => 'Elimina';
  @override
  String get fenceShapeCircle => '{0}° N, {1}° E · r {2} km';
  @override
  String get fenceShapeRect => 'S {0}° → N {1}° · O {2}° → E {3}°';
  @override
  String get fenceAirlineTooltip =>
      'Solo i voli di {0} ({1}) attivano questa geofence';
  @override
  String get fenceAirlineTooltipNoName => 'Filtro compagnia: {0}';
  @override
  String get fenceMinAltTooltip =>
      'Solo i voli a questa quota o superiore attivano la geofence';
  @override
  String get fenceMaxAltTooltip =>
      'Solo i voli a questa quota o inferiore attivano la geofence';

  // ── Draw screen ────────────────────────────────────────────────────────
  @override
  String get fenceDrawTitle => 'Disegna geofence';
  @override
  String get fenceDrawHintCircleFirst => 'Tocca per posizionare il centro';
  @override
  String get fenceDrawHintCircleSecond => 'Tocca per impostare il raggio';
  @override
  String get fenceDrawHintRectFirst => 'Tocca per impostare il primo angolo';
  @override
  String get fenceDrawHintRectSecond => 'Tocca per impostare l\'angolo opposto';
  @override
  String get fenceDrawHintReady => 'Salva quando pronto o tocca RESET';
  @override
  String get fenceDrawResetButton => 'RESET';
  @override
  String get fenceDrawNameTitle => 'Dai un nome a questa geofence';

  // ── Alerts panel ───────────────────────────────────────────────────────
  @override
  String get alertsCountOne => 'AVVISO';
  @override
  String get alertsCountMany => 'AVVISI';
  @override
  String get alertsClearAll => 'CANCELLA TUTTO';
  @override
  String get alertsClearAllTooltip =>
      'Cancella tutti gli avvisi (le geofence restano)';
  @override
  String get alertsDismiss => 'Ignora';
  @override
  String get alertsDismissTooltip =>
      'Ignora questo avviso (non influisce sullo storico)';
  @override
  String get alertsAllFilter => 'TUTTI';
  @override
  String get alertsFilterTooltip => 'Attiva/disattiva avvisi di "{0}"';
  @override
  String get alertsEmptyFilter =>
      'Nessun avviso corrisponde al filtro. Tocca TUTTI.';
  @override
  String get alertsShowOnMap => 'Mostra questo volo sulla mappa';

  // ── Fence stats badge ──────────────────────────────────────────────────
  @override
  String get fenceStatsHitsOne => '{0} ingresso';
  @override
  String get fenceStatsHitsMany => '{0} ingressi';
  @override
  String get fenceStatsAircraft => '{0} aerei';
  @override
  String get fenceStatsTopAirlineWithName =>
      'Top compagnia: {0} ({1}× questa geofence)';
  @override
  String get fenceStatsTopAirline => 'Top compagnia: {0}';
  @override
  String get fenceStatsTopLabel => 'top:';
  @override
  String get fenceStatsLast => 'ultimo {0}';

  // ── Fence import/export ────────────────────────────────────────────────
  @override
  String get fenceExport => 'ESPORTA';
  @override
  String get fenceImport => 'IMPORTA';
  @override
  String get fenceImporting => 'IMPORT…';
  @override
  String get fenceExportTooltip => 'Scarica le geofence come file JSON';
  @override
  String get fenceImportTooltip => 'Ripristina geofence da un file JSON';
  @override
  String get fenceExportEmpty => 'Nulla da esportare';
  @override
  String get fenceExportedOne => '1 geofence esportata';
  @override
  String get fenceExportedMany => '{0} geofence esportate';
  @override
  String get fenceReadingFile => 'Lettura del file…';
  @override
  String get fenceImportedOne => '1 geofence importata';
  @override
  String get fenceImportedMany => '{0} geofence importate';
  @override
  String get fenceImportedPartial => '{0} importate, {1} fallite ({2})';
  @override
  String get fenceReadFailed => 'Lettura fallita: {0}';
  @override
  String get fenceImportInvalidJson => 'JSON non valido: {0}';
  @override
  String get fenceImportSchemaMismatch =>
      'Schema non corrispondente a {0}: {1}';

  // ── Dashboard empty / honest states ────────────────────────────────────
  @override
  String get dashNoDataYet => 'Nessun dato';
  @override
  String get dashEmptyHint => 'Apri la mappa per iniziare a seguire i voli';

  // ── AR HUD compact stat labels ─────────────────────────────────────────
  @override
  String get arHudHdg => 'ROTTA';
  @override
  String get arHudPitch => 'BECC.';
  @override
  String get arHudInView => 'IN VISTA';

  // ── Favourite kind labels ──────────────────────────────────────────────
  @override
  String get kindFlight => 'Volo';
  @override
  String get kindAirline => 'Compagnia';
  @override
  String get kindAirport => 'Aeroporto';

  // ── Generic UI fallbacks ───────────────────────────────────────────────
  @override
  String get errorGeneric => 'Errore';
  @override
  String get geofencesActiveCount => '{0} ATTIVE';

  // ── Alert bell + sheet ─────────────────────────────────────────────────
  @override
  String get alertBellAria => 'Apri pannello avvisi';
  @override
  String get alertsNone => 'Nessun avviso attivo';

  // ── Generic dialog actions ─────────────────────────────────────────────
  @override
  String get actionClose => 'Chiudi';

  // ── Settings: Privacy Policy dialog ────────────────────────────────────
  @override
  String get privacyTitle => 'Informativa sulla privacy';
  @override
  String get privacyLastUpdated => 'Ultimo aggiornamento: {0} · v{1}';
  @override
  String get privacySummaryHeading => 'Riepilogo';
  @override
  String get privacySummary1 =>
      'Nessun account, nessun login, nessun dato personale raccolto.';
  @override
  String get privacySummary2 =>
      'Nessuna pubblicità, nessun SDK di analisi, nessuna telemetria.';
  @override
  String get privacySummary3 => 'Nessun dato venduto o condiviso con terzi.';
  @override
  String get privacyOnDeviceHeading => 'Solo sul dispositivo';
  @override
  String get privacyOnDeviceLocation =>
      'Posizione — usata per centrare la mappa e trovare aerei vicini. Mai caricata.';
  @override
  String get privacyOnDeviceCamera =>
      'Fotocamera (modalità AR) — i frame sono decodificati, disegnati e scartati. Mai caricati.';
  @override
  String get privacyOnDeviceMicrophone =>
      'Microfono (pulsante voce) — passato al riconoscimento vocale del sistema; solo la trascrizione raggiunge AirWatch ed è analizzata localmente.';
  @override
  String get privacyOnDeviceSensors =>
      'Sensori (bussola, accelerometro) — letti a 10 Hz per l\'HUD AR; mai memorizzati.';
  @override
  String get privacyOnDeviceStorage =>
      'Impostazioni, preferiti, geofence — salvati nella sandbox dell\'app tramite SharedPreferences / NSUserDefaults.';
  @override
  String get privacyNetworkHeading => 'Rete';
  @override
  String get privacyNetworkHosts =>
      'Parla solo con api.airwatch.app (TLS-pinned) e pics.avs.io per i loghi. Questa è l\'intera lista degli host.';
  @override
  String get privacyNetworkLogs =>
      'I log del backend sono conservati 30 giorni per il rate-limit; gli indirizzi IP non vengono incrociati con altri dataset.';
  @override
  String get privacyRightsHeading => 'I tuoi diritti';
  @override
  String get privacyRightsList =>
      'Accesso, rettifica, cancellazione, limitazione, portabilità, opposizione e revoca del consenso — scrivi a privacy@airwatch.app.';
  @override
  String get privacyRightsComplaint =>
      'Diritto di reclamo presso la tua autorità di protezione dei dati.';
  @override
  String get privacyFullTextHeading => 'Testo completo';
  @override
  String get privacyFullTextRef =>
      'Consulta PRIVACY.md nel repository per l\'informativa completa, incluse fonti di terze parti e trasferimenti internazionali.';
  // ── Aviation: METAR / TAF micro-labels ─────────────────────────────────
  @override
  String get metarTafValidPrefix => 'Valido {0} → {1}';
  @override
  String get metarTafNow => 'ORA';

  // ── Geofences: FAB action labels ───────────────────────────────────────
  @override
  String get geofencesDrawFab => 'DISEGNA';
  @override
  String get geofencesFormFabAria => 'Aggiungi tramite coordinate';
  // ── Map controls (a11y aria-labels) ────────────────────────────────────
  @override
  String get mapAriaSearch => 'Apri ricerca';
  @override
  String get mapAriaZoomIn => 'Ingrandisci';
  @override
  String get mapAriaZoomOut => 'Riduci';
  @override
  String get mapAriaMyLocation => 'Centra sulla mia posizione';
  @override
  String get mapAriaCargoToggle => 'Solo voli cargo';
}
