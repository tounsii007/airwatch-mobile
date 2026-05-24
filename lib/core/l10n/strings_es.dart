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
  String get more => 'MÁS';
  @override
  String get compare => 'COMPARAR';
  @override
  String get moreFeatures => 'Más funciones';
  @override
  String get dashboardSubtitle => 'Resumen personal';
  @override
  String get statsSubtitle => 'Historial';
  @override
  String get airlinesSubtitle => 'Aerolíneas en vivo';
  @override
  String get spottingShortSubtitle => 'Vuelos cercanos';

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

  // Personal-stats overhaul (paridad con airwatch-web 1e24147).
  @override
  String get statsTrackingSince => 'RASTREO DESDE';
  @override
  String get statsDaysActive => 'DÍAS ACTIVOS';
  @override
  String get statsPeakHour => 'HORA PUNTA';
  @override
  String get statsActivityChart => 'ACTIVIDAD · 24 H';
  @override
  String get statsTopRoutes => 'RUTAS TOP';
  @override
  String get statsTopAirports => 'AEROPUERTOS TOP';
  @override
  String get statsRecentFlights => 'VUELOS RECIENTES';
  @override
  String get statsExport => 'Exportar';
  @override
  String get statsExportJson => 'Exportar como JSON';
  @override
  String get statsExportCsv => 'Exportar como CSV';
  @override
  String get statsExportJsonCopied => 'JSON copiado al portapapeles';
  @override
  String get statsExportCsvCopied => 'CSV copiado al portapapeles';
  @override
  String get statsClear => 'Borrar historial';
  @override
  String get statsClearConfirm =>
      'Esto eliminará permanentemente tu historial local. ¿Continuar?';
  @override
  String get statsEmptyTitle => 'Aún no hay vuelos rastreados';
  @override
  String get statsEmptyHint =>
      'Toca un vuelo en el mapa para empezar a registrar tu historial personal.';
  @override
  String get overview => 'Resumen';
  @override
  String get replayTitle => 'Reproducción';
  @override
  String get replayHeading => 'Reproducción de 7 días';
  @override
  String get replayBody =>
      'Introduce un indicativo o número de vuelo para ver los últimos 7 días — retrasos, horarios programados vs reales y trazado de la ruta.';
  @override
  String get replayHint => 'Número de vuelo (ej. TU744)';
  @override
  String get replaySearchAction => 'Buscar';
  @override
  String get replayExamples => 'Ejemplos: TU744, DLH441, RYR1234';
  @override
  String get statsSearchHint => 'Buscar indicativo / ruta / aerolínea…';
  @override
  String get statsSearchNoMatch => 'Ningún vuelo coincide con este filtro.';
  @override
  String get statsSortByRecency => 'Ordenar por reciente';
  @override
  String get statsSortByViews => 'Ordenar por vistas';
  @override
  String get wikiAbout => 'Acerca de';
  @override
  String get wikiReadMore => 'Leer en Wikipedia';
  @override
  String get nearbyAirportsTitle => 'Aeropuertos cerca de ti';
  @override
  String get nearbyAirportsCta =>
      'Usa tu ubicación para encontrar aeropuertos cercanos.';
  @override
  String get useMyLocation => 'USAR MI UBICACIÓN';
  @override
  String get locating => 'Localizando…';
  @override
  String get geoDenied => 'Permiso de ubicación denegado.';
  @override
  String get geoUnavailable => 'Servicio de ubicación no disponible.';
  @override
  String get noNearbyAirports => 'Sin aeropuertos al alcance.';

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
  String get atcUnavailable => 'Sin feeds catalogados para este aeropuerto';
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

  // ── Geofence form ──────────────────────────────────────────────────────
  @override
  String get fenceFormTitle => 'Nueva geofence';
  @override
  String get fenceNewHeading => 'NUEVA GEOFENCE {0}';
  @override
  String get fenceTypeCircle => 'CÍRCULO';
  @override
  String get fenceTypeRectangle => 'RECTÁNGULO';
  @override
  String get fenceNameLabel => 'NOMBRE';
  @override
  String get fenceNamePlaceholder => 'p. ej. Aproximación Frankfurt';
  @override
  String get fenceRadiusLabel => 'RADIO (KM)';
  @override
  String get fenceCenterLatLabel => 'LATITUD CENTRO';
  @override
  String get fenceCenterLonLabel => 'LONGITUD CENTRO';
  @override
  String get fenceNorthLabel => 'LATITUD NORTE';
  @override
  String get fenceSouthLabel => 'LATITUD SUR';
  @override
  String get fenceEastLabel => 'LONGITUD ESTE';
  @override
  String get fenceWestLabel => 'LONGITUD OESTE';
  @override
  String get fenceMinAltLabel => 'ALT. MIN (FT)';
  @override
  String get fenceMaxAltLabel => 'ALT. MAX (FT)';
  @override
  String get fenceAirlineLabel => 'ICAO AEROLÍNEA';
  @override
  String get fenceOptionalFilters => 'FILTROS OPCIONALES';
  @override
  String get fenceSaveButton => 'GUARDAR';
  @override
  String get fenceCancelButton => 'CANCELAR';
  @override
  String get fenceErrNameRequired => 'Se requiere nombre';
  @override
  String get fenceErrLatRange => 'La latitud debe estar entre -90 y 90';
  @override
  String get fenceErrLonRange => 'La longitud debe estar entre -180 y 180';
  @override
  String get fenceErrRadius => 'El radio debe ser mayor que 0 km';
  @override
  String get fenceErrBoundsRequired => 'Se requieren los cuatro límites';
  @override
  String get fenceErrNorthSouth => 'Norte debe ser mayor que Sur';
  @override
  String get fenceErrEastWest => 'Este debe ser mayor que Oeste';

  // ── Geofence list ──────────────────────────────────────────────────────
  @override
  String get fenceActiveHeading => 'GEOFENCES ACTIVAS';
  @override
  String get fenceTotalCount => '{0} en total';
  @override
  String get fencesListEmpty =>
      'Sin geofences. Toca DIBUJAR o usa el formulario — las alertas aparecerán aquí cuando una aeronave entre en la zona.';
  @override
  String get fenceDelete => 'Eliminar';
  @override
  String get fenceShapeCircle => '{0}° N, {1}° E · r {2} km';
  @override
  String get fenceShapeRect => 'S {0}° → N {1}° · O {2}° → E {3}°';
  @override
  String get fenceAirlineTooltip =>
      'Solo los vuelos de {0} ({1}) activan esta geofence';
  @override
  String get fenceAirlineTooltipNoName => 'Filtro aerolínea: {0}';
  @override
  String get fenceMinAltTooltip =>
      'Solo los vuelos a esta altitud o superior activan la geofence';
  @override
  String get fenceMaxAltTooltip =>
      'Solo los vuelos a esta altitud o inferior activan la geofence';

  // ── Draw screen ────────────────────────────────────────────────────────
  @override
  String get fenceDrawTitle => 'Dibujar geofence';
  @override
  String get fenceDrawHintCircleFirst => 'Toca para colocar el centro';
  @override
  String get fenceDrawHintCircleSecond => 'Toca para fijar el radio';
  @override
  String get fenceDrawHintRectFirst => 'Toca para fijar la primera esquina';
  @override
  String get fenceDrawHintRectSecond => 'Toca para fijar la esquina opuesta';
  @override
  String get fenceDrawHintReady => 'Guarda cuando esté listo o toca RESET';
  @override
  String get fenceDrawResetButton => 'RESET';
  @override
  String get fenceDrawNameTitle => 'Nombrar la geofence';

  // ── Alerts panel ───────────────────────────────────────────────────────
  @override
  String get alertsCountOne => 'ALERTA';
  @override
  String get alertsCountMany => 'ALERTAS';
  @override
  String get alertsClearAll => 'BORRAR TODO';
  @override
  String get alertsClearAllTooltip =>
      'Borrar todas las alertas (las geofences se mantienen)';
  @override
  String get alertsDismiss => 'Descartar';
  @override
  String get alertsDismissTooltip =>
      'Descartar esta alerta (no afecta al historial)';
  @override
  String get alertsAllFilter => 'TODAS';
  @override
  String get alertsFilterTooltip => 'Alternar alertas de «{0}»';
  @override
  String get alertsEmptyFilter =>
      'Ninguna alerta coincide con el filtro. Toca TODAS.';
  @override
  String get alertsShowOnMap => 'Mostrar este vuelo en el mapa';

  // ── Fence stats badge ──────────────────────────────────────────────────
  @override
  String get fenceStatsHitsOne => '{0} impacto';
  @override
  String get fenceStatsHitsMany => '{0} impactos';
  @override
  String get fenceStatsAircraft => '{0} aeronaves';
  @override
  String get fenceStatsTopAirlineWithName =>
      'Top aerolínea: {0} ({1}× esta geofence)';
  @override
  String get fenceStatsTopAirline => 'Top aerolínea: {0}';
  @override
  String get fenceStatsTopLabel => 'top:';
  @override
  String get fenceStatsLast => 'último {0}';

  // ── Fence import/export ────────────────────────────────────────────────
  @override
  String get fenceExport => 'EXPORTAR';
  @override
  String get fenceImport => 'IMPORTAR';
  @override
  String get fenceImporting => 'IMPORTANDO…';
  @override
  String get fenceExportTooltip => 'Descargar geofences como JSON';
  @override
  String get fenceImportTooltip => 'Restaurar geofences desde un archivo JSON';
  @override
  String get fenceExportEmpty => 'Nada que exportar';
  @override
  String get fenceExportedOne => '1 geofence exportada';
  @override
  String get fenceExportedMany => '{0} geofences exportadas';
  @override
  String get fenceReadingFile => 'Leyendo archivo…';
  @override
  String get fenceImportedOne => '1 geofence importada';
  @override
  String get fenceImportedMany => '{0} geofences importadas';
  @override
  String get fenceImportedPartial => '{0} importadas, {1} fallidas ({2})';
  @override
  String get fenceReadFailed => 'Lectura fallida: {0}';
  @override
  String get fenceImportInvalidJson => 'JSON inválido: {0}';
  @override
  String get fenceImportSchemaMismatch => 'Esquema incompatible en {0}: {1}';

  // ── Dashboard empty / honest states ────────────────────────────────────
  @override
  String get dashNoDataYet => 'Sin datos aún';
  @override
  String get dashEmptyHint => 'Abre el mapa para empezar a seguir vuelos';

  // ── AR HUD compact stat labels ─────────────────────────────────────────
  @override
  String get arHudHdg => 'RUMBO';
  @override
  String get arHudPitch => 'CABE.';
  @override
  String get arHudInView => 'A LA VISTA';

  // ── Favourite kind labels ──────────────────────────────────────────────
  @override
  String get kindFlight => 'Vuelo';
  @override
  String get kindAirline => 'Aerolínea';
  @override
  String get kindAirport => 'Aeropuerto';

  // ── Generic UI fallbacks ───────────────────────────────────────────────
  @override
  String get errorGeneric => 'Error';
  @override
  String get geofencesActiveCount => '{0} ACTIVAS';

  // ── Alert bell + sheet ─────────────────────────────────────────────────
  @override
  String get alertBellAria => 'Abrir panel de alertas';
  @override
  String get alertsNone => 'Sin alertas activas';

  // ── Generic dialog actions ─────────────────────────────────────────────
  @override
  String get actionClose => 'Cerrar';

  // ── Settings: Privacy Policy dialog ────────────────────────────────────
  @override
  String get privacyTitle => 'Política de privacidad';
  @override
  String get privacyLastUpdated => 'Última actualización: {0} · v{1}';
  @override
  String get privacySummaryHeading => 'Resumen';
  @override
  String get privacySummary1 =>
      'Sin cuentas, sin inicios de sesión, sin recopilación de datos personales.';
  @override
  String get privacySummary2 =>
      'Sin anuncios, sin SDK de analítica, sin telemetría.';
  @override
  String get privacySummary3 => 'Sin venta ni cesión de datos a terceros.';
  @override
  String get privacyOnDeviceHeading => 'Solo en el dispositivo';
  @override
  String get privacyOnDeviceLocation =>
      'Ubicación — usada para centrar el mapa y encontrar aviones cercanos. Nunca se sube.';
  @override
  String get privacyOnDeviceCamera =>
      'Cámara (modo AR) — los fotogramas se decodifican, dibujan y descartan. Nunca se suben.';
  @override
  String get privacyOnDeviceMicrophone =>
      'Micrófono (botón de voz) — se entrega al reconocedor del SO; solo la transcripción llega a AirWatch, y se procesa localmente.';
  @override
  String get privacyOnDeviceSensors =>
      'Sensores (brújula, acelerómetro) — leídos a 10 Hz para el HUD AR; nunca se almacenan.';
  @override
  String get privacyOnDeviceStorage =>
      'Ajustes, favoritos, geocercas — guardados en el sandbox de la app vía SharedPreferences / NSUserDefaults.';
  @override
  String get privacyNetworkHeading => 'Red';
  @override
  String get privacyNetworkHosts =>
      'Solo habla con api.airwatch.app (TLS-pinned) y pics.avs.io para logos. Esa es toda la lista de hosts.';
  @override
  String get privacyNetworkLogs =>
      'Los logs del backend se conservan 30 días para limitar peticiones; las IP no se cruzan con ningún otro conjunto de datos.';
  @override
  String get privacyRightsHeading => 'Tus derechos';
  @override
  String get privacyRightsList =>
      'Acceso, rectificación, supresión, limitación, portabilidad, oposición y retirada del consentimiento — escribe a privacy@airwatch.app.';
  @override
  String get privacyRightsComplaint =>
      'Derecho a presentar una reclamación ante tu autoridad de protección de datos.';
  @override
  String get privacyFullTextHeading => 'Texto completo';
  @override
  String get privacyFullTextRef =>
      'Consulta PRIVACY.md en el repositorio para la política completa, incluidas fuentes externas y transferencias internacionales.';
  // ── Aviation: METAR / TAF micro-labels ─────────────────────────────────
  @override
  String get metarTafValidPrefix => 'Válido {0} → {1}';
  @override
  String get metarTafNow => 'AHORA';

  // ── Geofences: FAB action labels ───────────────────────────────────────
  @override
  String get geofencesDrawFab => 'DIBUJAR';
  @override
  String get geofencesFormFabAria => 'Añadir zona por coordenadas';
}
