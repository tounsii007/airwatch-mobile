import 'strings_base.dart';

/// Spanish locale — parity with airwatch-web's es.json (commit 96b8291).
///
/// <p>Aviation jargon (METAR, TAF, NOTAM, ICAO, IATA, squawk, AirWatch)
/// stays untranslated — same convention used by web.
class StringsEs extends AppStrings {
  @override
  String get map => 'MAPA';
  @override
  String get search => 'BUSCAR';
  @override
  String get airport => 'AEROPUERTOS';
  @override
  String get favs => 'GUARDADOS';
  @override
  String get settings => 'AJUSTES';

  @override
  String get flights => 'vuelos';
  @override
  String get aircraft => 'aeronaves';

  @override
  String get altitude => 'ALTITUD';
  @override
  String get speed => 'VELOCIDAD';
  @override
  String get heading => 'RUMBO';
  @override
  String get departure => 'SALIDA';
  @override
  String get arrival => 'LLEGADA';
  @override
  String get operatedBy => 'Operado por';
  @override
  String get track => 'SEGUIR';
  @override
  String get replay => 'REPETICIÓN';
  @override
  String get history => 'HISTORIAL';
  @override
  String get favorite => 'GUARDAR';
  @override
  String get share => 'COMPARTIR';

  @override
  String get enRoute => 'EN RUTA';
  @override
  String get landed => 'ATERRIZADO';
  @override
  String get scheduled => 'PROGRAMADO';
  @override
  String get delayed => 'RETRASADO';
  @override
  String get onTime => 'A TIEMPO';
  @override
  String get onGround => 'EN TIERRA';
  @override
  String get airborne => 'EN VUELO';

  @override
  String get searchHint => 'Vuelo, aerolínea, matrícula...';
  @override
  String get noResults => 'Sin resultados';

  @override
  String get appearance => 'APARIENCIA';
  @override
  String get mapStyle => 'ESTILO DEL MAPA';
  @override
  String get units => 'UNIDADES';
  @override
  String get mapOptions => 'OPCIONES DEL MAPA';
  @override
  String get dataSource => 'FUENTE DE DATOS';
  @override
  String get language => 'IDIOMA';

  @override
  String get flightHistory => 'HISTORIAL DE VUELO';
  @override
  String get searchingDays => 'Buscando los últimos 7 días...';

  @override
  String get airportRadar => 'AEROPUERTOS';
  @override
  String get departures => 'SALIDAS';
  @override
  String get arrivals => 'LLEGADAS';

  @override
  String get tagline => 'SIGUE EL CIELO EN TIEMPO REAL';

  @override
  String get shareText => 'Mira este vuelo en AirWatch.';

  @override
  String get noFavorites => 'NADA GUARDADO TODAVÍA';

  @override
  String get arMode => 'MODO RA';
  @override
  String get pointSkyUp => 'Apunta tu cámara al cielo';

  @override
  String get airports => 'AEROPUERTOS';
  @override
  String get airlines => 'AEROLÍNEAS';
  @override
  String get cargo => 'CARGA';
  @override
  String get spotting => 'AVISTAMIENTO';
  @override
  String get dashboard => 'PANEL';
  @override
  String get globe => 'GLOBO';
  @override
  String get stats => 'ESTADÍSTICAS';

  @override
  String get streetsStyle => 'Calles';
  @override
  String get terrainStyle => 'Terreno';

  @override
  String get adminLogin => 'Acceso admin';
  @override
  String get adminDashboard => 'Admin';
  @override
  String get adminUsername => 'Usuario';
  @override
  String get adminPassword => 'Contraseña';
  @override
  String get adminSignIn => 'Entrar';
  @override
  String get adminSignOut => 'Salir';
  @override
  String get adminHealth => 'Estado';
  @override
  String get adminMetrics => 'Métricas en vivo';
  @override
  String get adminRpsLabel => 'Solicitudes / s';
  @override
  String get adminActive => 'Sesiones activas';
  @override
  String get adminHeap => 'Uso de memoria';
  @override
  String get adminBadCreds => 'Usuario o contraseña incorrectos';
  @override
  String get adminTotpLabel => 'TOTP (opcional)';
  @override
  String get adminTotpHint =>
      'Solo necesario si esta cuenta tiene 2FA activado';
  @override
  String get adminErrorRate => 'Errores %';
  @override
  String get adminTotalReqs => 'Solicitudes totales al backend';
  @override
  String get adminFlightsKpi => 'Vuelos';
  @override
  String get adminOffline => 'Sin conexión a airwatch-api';
  @override
  String get adminOfflineHint =>
      'La sesión puede haber caducado o el backend no está disponible. '
      'Pulsa cerrar sesión y vuelve a entrar.';

  @override
  String get noAirlinesActive =>
      'Ninguna aerolínea con vuelos en el aire ahora mismo';
  @override
  String get airlinesCarriers => 'Lista de aerolíneas en vivo';
  @override
  String get airlinesFlightOne => 'vuelo';
  @override
  String get airlinesFlightMany => 'vuelos';
  @override
  String get noCargoActive => 'Ningún vuelo de carga en el aire ahora';
  @override
  String get cargoSubtitle => 'Solo vuelos de carga';
  @override
  String get spottingNoNearby => 'Sin vuelos a 60 km de tu posición';
  @override
  String get spottingTabList => 'Lista';
  @override
  String get spottingTabMap => 'Mapa';
  @override
  String get spottingTryAgain => 'Reintentar';
  @override
  String get spottingPermDenied => 'Permiso de ubicación denegado';
  @override
  String get spottingPermErrPrefix => 'Ubicación no disponible';
  @override
  String get spottingSubtitle => 'Vuelos cercanos — radio 60 km';

  @override
  String get statsTracked => 'Rastreados';
  @override
  String get statsAirborne => 'En vuelo';
  @override
  String get statsOnGround => 'En tierra';
  @override
  String get statsAirlabsCalls => 'Llamadas AirLabs';
  @override
  String get statsTopAirlines => 'Top aerolíneas (en vivo)';
  @override
  String get statsNoData => 'Sin datos aún';
  @override
  String get statsFlightsLabel => 'vuelos';

  @override
  String get statsFlightsTracked => 'VUELOS RASTREADOS';
  @override
  String get statsAvgViewsPerFlight => 'VISTAS PROM / VUELO';
  @override
  String get statsUniqueAirlines => 'AEROLÍNEAS';
  @override
  String get statsUniqueAirports => 'AEROPUERTOS';

  @override
  String get squawkEmergencyTitle => 'Squawk de emergencia';
  @override
  String get squawkHijack => 'Secuestro (7500)';
  @override
  String get squawkRadioFailure => 'Fallo de radio (7600)';
  @override
  String get squawkGeneral => 'Emergencia general (7700)';

  @override
  String get co2EstimateLabel => 'Estimación de CO₂';
  @override
  String get co2PerPaxLabel => 'por pasajero';

  @override
  String get searchCargoHint => 'Buscar matrícula / aerolínea / país';
  @override
  String get cargoFlightsHeader => 'Vuelos de carga';
  @override
  String get cargoHint => 'Toca una tarjeta para seguir en el mapa';
  @override
  String get searchNoResults => 'Sin coincidencias';
  @override
  String get cargoOperators => 'OPERADORES';
  @override
  String get cargoTotal => 'TOTAL';
  @override
  String get cargoAirborne => 'EN VUELO';
  @override
  String get cargoOnGround => 'EN TIERRA';

  @override
  String get airportsHeader => 'Aeropuertos';
  @override
  String get popularAirports => 'Aeropuertos populares';
  @override
  String get departuresHeader => 'Salidas recientes';
  @override
  String get searchAirportsHint => 'IATA, ciudad, país (cualquier idioma)';

  @override
  String get compareFlights => 'Comparar vuelos';
  @override
  String get compareSubtitle => 'Comparación lado a lado';
  @override
  String get geofences => 'Geocercas';
  @override
  String get geofencesSubtitle => 'Zonas para vuelos entrantes';
  @override
  String get voiceCommand => 'Comando de voz';
  @override
  String get voiceListening => 'Escuchando…';
  @override
  String get voiceUnsupported => 'Voz no compatible';

  @override
  String get dashLiveFlights => 'Vuelos en vivo';
  @override
  String get dashSavedItems => 'Guardados';
  @override
  String get dashTopAirlines => 'Top aerolíneas';
  @override
  String get dashAltBands => 'Bandas de altitud';
  @override
  String get dashSubtitle => 'Resumen personal';

  @override
  String get globeReload => 'Recargar';
  @override
  String get globeSubtitle => 'Vista del planeta';

  @override
  String get featuresHeader => 'FUNCIONES';
  @override
  String get errorPrefix => 'Error';
  @override
  String get retryButton => 'Reintentar';

  // METAR / TAF / NOTAM
  @override
  String get metarTafTitle => 'METAR / TAF';
  @override
  String get metarTab => 'METAR';
  @override
  String get tafTab => 'TAF';
  @override
  String get metarUnavailable => 'METAR / TAF no disponible';
  @override
  String get metarLabelWind => 'VIENTO';
  @override
  String get metarLabelVisibility => 'VIS';
  @override
  String get metarLabelTemp => 'TEMP';
  @override
  String get metarLabelAltimeter => 'QNH';
  @override
  String get metarLabelClouds => 'NUBES';
  @override
  String get metarLabelWeather => 'TIEMPO';
  @override
  String get metarShowRaw => 'Ver crudo';
  @override
  String get metarHideRaw => 'Ocultar crudo';
  @override
  String get notamsTitle => 'NOTAMs';
  @override
  String get notamsUnavailable => 'NOTAMs no disponibles';
  @override
  String get notamsNone => 'Sin NOTAMs reportados';
  @override
  String get notamsMore => '+{0} más no mostrados';
  @override
  String get loadingShort => 'Cargando';

  // FleetInfoCard
  @override
  String get fleetInfoTitle => 'INFO FLOTA';
  @override
  String get fleetAge => '{0} a (construido {1})';
  @override
  String get fleetSightings => '{0} avistamientos';
  @override
  String get fleetFirstSeen => 'primer avistamiento {0}';
  @override
  String get fleetLastSeen => 'último avistamiento {0}';

  // RouteStatsBadge
  @override
  String get routeTodayFlights => '{0} hoy';
  @override
  String get routeWeekFlights => '{0} esta semana';
  @override
  String get routeMonthFlights => '{0} en 30 d';

  // AtcAudioPanel
  @override
  String get atcLiveTitle => 'ATC EN VIVO';
  @override
  String get atcUnavailable =>
      'Sin feeds catalogados para este aeropuerto';
  @override
  String get atcSearchFallback => 'Buscar en LiveATC.net';
  @override
  String get atcAttribution => 'Audio cortesía de LiveATC.net';
  @override
  String get atcOpenInBrowser => 'Abrir en el navegador';

  // Airport detail tab labels
  @override
  String get infoTab => 'INFO';
  @override
  String get sortLabel => 'ORDEN';
  @override
  String get sortByTime => 'HORA';
  @override
  String get sortByDelay => 'RETRASO';

  @override
  String get sectionUnavailable => 'SECCIÓN NO DISPONIBLE';

  // Relative-time
  @override
  String get relTimeNow => 'ahora mismo';
  @override
  String get relTimeMinutes => 'hace {0} min';
  @override
  String get relTimeHours => 'hace {0} h';
  @override
  String get relTimeDays => 'hace {0} d';
  @override
  String get relTimeMonths => 'hace {0} m';
  @override
  String get relTimeYears => 'hace {0} a';

  // ICS export
  @override
  String get exportIcs => 'Exportar .ics';
  @override
  String get exportIcsCalName => 'AirWatch — Guardados';
  @override
  String get exportNoItems => 'Nada que exportar';
}
