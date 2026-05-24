import 'strings_base.dart';

class StringsFr extends AppStrings {
  @override
  String get map => 'CARTE';
  @override
  String get search => 'RECHERCHE';
  @override
  String get airport => 'AÉROPORTS';
  @override
  String get favs => 'ENREG.';
  @override
  String get settings => 'RÉGLAGES';

  @override
  String get flights => 'vols';
  @override
  String get aircraft => 'avions';

  @override
  String get altitude => 'ALTITUDE';
  @override
  String get speed => 'VITESSE';
  @override
  String get heading => 'CAP';
  @override
  String get departure => 'DÉPART';
  @override
  String get arrival => 'ARRIVÉE';
  @override
  String get operatedBy => 'Exploité par';
  @override
  String get track => 'SUIVRE';
  @override
  String get replay => 'RELECTURE';
  @override
  String get history => 'HISTORIQUE';
  @override
  String get favorite => 'ENREG.';
  @override
  String get share => 'PARTAGER';

  @override
  String get enRoute => 'EN ROUTE';
  @override
  String get landed => 'ATTERRI';
  @override
  String get scheduled => 'PRÉVU';
  @override
  String get delayed => 'RETARDÉ';
  @override
  String get onTime => "À L'HEURE";
  @override
  String get onGround => 'AU SOL';
  @override
  String get airborne => 'EN VOL';

  @override
  String get searchHint => 'Vol, compagnie, immatriculation...';
  @override
  String get noResults => 'Aucun résultat';

  @override
  String get appearance => 'APPARENCE';
  @override
  String get mapStyle => 'STYLE DE CARTE';
  @override
  String get units => 'UNITÉS';
  @override
  String get mapOptions => 'OPTIONS CARTE';
  @override
  String get dataSource => 'SOURCE DE DONNÉES';
  @override
  String get language => 'LANGUE';

  @override
  String get flightHistory => 'HISTORIQUE DES VOLS';
  @override
  String get searchingDays => 'Recherche sur les 7 derniers jours...';

  @override
  String get airportRadar => 'AÉROPORTS';
  @override
  String get departures => 'DÉPARTS';
  @override
  String get arrivals => 'ARRIVÉES';

  @override
  String get tagline => 'SUIVEZ LE CIEL EN TEMPS RÉEL';

  @override
  String get shareText => 'Découvrez ce vol dans AirWatch.';

  @override
  String get noFavorites => 'RIEN D’ENREGISTRÉ';

  @override
  String get arMode => 'MODE AR';
  @override
  String get pointSkyUp => 'Pointez votre caméra vers le ciel';

  // Extended navigation
  @override
  String get airports => 'AÉROPORTS';
  @override
  String get airlines => 'COMPAGNIES';
  @override
  String get cargo => 'CARGO';
  @override
  String get spotting => 'SPOTTING';
  @override
  String get dashboard => 'TABLEAU DE BORD';
  @override
  String get globe => 'GLOBE';
  @override
  String get stats => 'STATS';
  @override
  String get more => 'PLUS';
  @override
  String get compare => 'COMPARER';
  @override
  String get moreFeatures => 'Plus de fonctionnalités';
  @override
  String get dashboardSubtitle => 'Vue personnelle';
  @override
  String get statsSubtitle => 'Historique';
  @override
  String get airlinesSubtitle => 'Compagnies en direct';
  @override
  String get spottingShortSubtitle => 'Vols à proximité';

  @override
  String get streetsStyle => 'Rues';
  @override
  String get terrainStyle => 'Terrain';

  // Admin (read-only)
  @override
  String get adminLogin => 'Connexion Admin';
  @override
  String get adminDashboard => 'Admin';
  @override
  String get adminUsername => 'Identifiant';
  @override
  String get adminPassword => 'Mot de passe';
  @override
  String get adminSignIn => 'Connexion';
  @override
  String get adminSignOut => 'Déconnexion';
  @override
  String get adminHealth => 'Santé';
  @override
  String get adminMetrics => 'Métriques en direct';
  @override
  String get adminRpsLabel => 'Requêtes / s';
  @override
  String get adminActive => 'Sessions actives';
  @override
  String get adminHeap => 'Utilisation du tas';
  @override
  String get adminBadCreds => 'Identifiant ou mot de passe invalide';
  @override
  String get adminTotpLabel => 'TOTP (facultatif)';
  @override
  String get adminTotpHint =>
      'Requis uniquement si le 2FA est activé sur ce compte';
  @override
  String get adminErrorRate => 'Erreur %';
  @override
  String get adminTotalReqs => 'Requêtes backend totales';
  @override
  String get adminFlightsKpi => 'Vols';
  @override
  String get adminOffline => 'Non connecté à airwatch-api';
  @override
  String get adminOfflineHint =>
      'La session a peut-être expiré ou le backend est injoignable. '
      'Appuyez sur l\'icône de déconnexion et reconnectez-vous.';

  // Airlines / Cargo / Spotting
  @override
  String get noAirlinesActive => 'Aucune compagnie active actuellement';
  @override
  String get airlinesCarriers => 'Compagnies en direct';
  @override
  String get airlinesFlightOne => 'vol';
  @override
  String get airlinesFlightMany => 'vols';
  @override
  String get noCargoActive => 'Aucun vol cargo en l\'air actuellement';
  @override
  String get cargoSubtitle => 'Vols cargo uniquement';
  @override
  String get spottingNoNearby => 'Aucun vol dans un rayon de 60 km';
  @override
  String get spottingTabList => 'Liste';
  @override
  String get spottingTabMap => 'Carte';
  @override
  String get spottingTryAgain => 'Réessayer';
  @override
  String get spottingPermDenied => 'Permission de localisation refusée';
  @override
  String get spottingPermErrPrefix => 'Localisation indisponible';
  @override
  String get spottingSubtitle => 'Vols proches — rayon de 60 km';

  // Stats
  @override
  String get statsTracked => 'Suivis';
  @override
  String get statsAirborne => 'En vol';
  @override
  String get statsOnGround => 'Au sol';
  @override
  String get statsAirlabsCalls => 'Appels AirLabs';
  @override
  String get statsTopAirlines => 'Top compagnies (live)';
  @override
  String get statsNoData => 'Pas encore de données';
  @override
  String get statsFlightsLabel => 'vols';

  // Stats card overhaul (parité avec le commit design-system d\'airwatch-web).
  @override
  String get statsFlightsTracked => 'VOLS SUIVIS';
  @override
  String get statsAvgViewsPerFlight => 'VUES / VOL';
  @override
  String get statsUniqueAirlines => 'COMPAGNIES';
  @override
  String get statsUniqueAirports => 'AÉROPORTS';

  // Personal-stats overhaul (parité avec airwatch-web 1e24147).
  @override
  String get statsTrackingSince => 'SUIVI DEPUIS';
  @override
  String get statsDaysActive => 'JOURS ACTIFS';
  @override
  String get statsPeakHour => 'HEURE DE POINTE';
  @override
  String get statsActivityChart => 'ACTIVITÉ · 24 H';
  @override
  String get statsTopRoutes => 'TOP ROUTES';
  @override
  String get statsTopAirports => 'TOP AÉROPORTS';
  @override
  String get statsRecentFlights => 'VOLS RÉCENTS';
  @override
  String get statsExport => 'Exporter';
  @override
  String get statsExportJson => 'Exporter en JSON';
  @override
  String get statsExportCsv => 'Exporter en CSV';
  @override
  String get statsExportJsonCopied => 'JSON copié dans le presse-papiers';
  @override
  String get statsExportCsvCopied => 'CSV copié dans le presse-papiers';
  @override
  String get statsClear => 'Effacer l\'historique';
  @override
  String get statsClearConfirm =>
      'Ceci supprime définitivement votre historique local. Continuer ?';
  @override
  String get statsEmptyTitle => 'Aucun vol suivi pour l\'instant';
  @override
  String get statsEmptyHint =>
      'Touchez un vol sur la carte pour démarrer votre historique de suivi personnel.';
  @override
  String get overview => 'Vue d\'ensemble';
  @override
  String get replayTitle => 'Replay';
  @override
  String get replayHeading => 'Replay sur 7 jours';
  @override
  String get replayBody =>
      'Entrez un indicatif ou un numéro de vol pour voir les 7 derniers jours — retards, horaires prévus vs réels, et trace de la route.';
  @override
  String get replayHint => 'Numéro de vol (ex. TU744)';
  @override
  String get replaySearchAction => 'Rechercher';
  @override
  String get replayExamples => 'Exemples : TU744, DLH441, RYR1234';
  @override
  String get statsSearchHint => 'Rechercher indicatif / route / compagnie…';
  @override
  String get statsSearchNoMatch => 'Aucun vol ne correspond à ce filtre.';
  @override
  String get statsSortByRecency => 'Trier par récence';
  @override
  String get statsSortByViews => 'Trier par nombre de vues';
  @override
  String get wikiAbout => 'À propos';
  @override
  String get wikiReadMore => 'Lire sur Wikipédia';
  @override
  String get nearbyAirportsTitle => 'Aéroports près de vous';
  @override
  String get nearbyAirportsCta =>
      'Utilisez votre position pour trouver les aéroports à proximité.';
  @override
  String get useMyLocation => 'UTILISER MA POSITION';
  @override
  String get locating => 'Localisation…';
  @override
  String get geoDenied => 'Autorisation de localisation refusée.';
  @override
  String get geoUnavailable => 'Service de localisation indisponible.';
  @override
  String get noNearbyAirports => 'Aucun aéroport à portée.';

  // Squawk emergency
  @override
  String get squawkEmergencyTitle => 'Squawk d\'urgence';
  @override
  String get squawkHijack => 'Détournement (7500)';
  @override
  String get squawkRadioFailure => 'Panne radio (7600)';
  @override
  String get squawkGeneral => 'Urgence générale (7700)';

  // CO2
  @override
  String get co2EstimateLabel => 'Émission CO₂';
  @override
  String get co2PerPaxLabel => 'par passager';

  // Cargo overhaul (parité avec airwatch-web /cargo).
  @override
  String get searchCargoHint => 'Rechercher : indicatif / compagnie / pays';
  @override
  String get cargoFlightsHeader => 'Vols cargo';
  @override
  String get cargoHint => 'Tapez sur une carte pour suivre sur la carte';
  @override
  String get searchNoResults => 'Aucun résultat';
  @override
  String get cargoOperators => 'OPÉRATEURS';
  @override
  String get cargoTotal => 'TOTAL';
  @override
  String get cargoAirborne => 'EN VOL';
  @override
  String get cargoOnGround => 'AU SOL';

  // Airports / search shared.
  @override
  String get airportsHeader => 'Aéroports';
  @override
  String get popularAirports => 'Aéroports populaires';
  @override
  String get departuresHeader => 'Derniers départs';
  @override
  String get searchAirportsHint => 'IATA, ville, pays (toute langue)';

  @override
  String get compareFlights => 'Comparer les vols';
  @override
  String get compareSubtitle => 'Comparaison côte à côte';
  @override
  String get geofences => 'Géofences';
  @override
  String get geofencesSubtitle => 'Zones de surveillance';
  @override
  String get voiceCommand => 'Commande vocale';
  @override
  String get voiceListening => 'Écoute…';
  @override
  String get voiceUnsupported => 'Voix non disponible';

  // Dashboard
  @override
  String get dashLiveFlights => 'Vols en direct';
  @override
  String get dashSavedItems => 'Enregistrés';
  @override
  String get dashTopAirlines => 'Top compagnies';
  @override
  String get dashAltBands => 'Niveaux d\'altitude';
  @override
  String get dashSubtitle => 'Tableau personnel';

  // Globe
  @override
  String get globeReload => 'Recharger';
  @override
  String get globeSubtitle => 'Vue planète';

  // FEATURES + misc
  @override
  String get featuresHeader => 'FONCTIONNALITÉS';
  @override
  String get errorPrefix => 'Erreur';
  @override
  String get retryButton => 'Réessayer';

  // METAR / TAF / NOTAM (parité avec airwatch-web).
  @override
  String get metarTafTitle => 'METAR / TAF';
  @override
  String get metarTab => 'METAR';
  @override
  String get tafTab => 'TAF';
  @override
  String get metarUnavailable => 'METAR / TAF indisponible';
  @override
  String get metarLabelWind => 'VENT';
  @override
  String get metarLabelVisibility => 'VIS';
  @override
  String get metarLabelTemp => 'TEMP';
  @override
  String get metarLabelAltimeter => 'QNH';
  @override
  String get metarLabelClouds => 'NUAGES';
  @override
  String get metarLabelWeather => 'TEMPS';
  @override
  String get metarShowRaw => 'Voir le brut';
  @override
  String get metarHideRaw => 'Masquer le brut';
  @override
  String get notamsTitle => 'NOTAMs';
  @override
  String get notamsUnavailable => 'NOTAMs indisponibles';
  @override
  String get notamsNone => 'Aucun NOTAM signalé';
  @override
  String get notamsMore => '+{0} non affichés';
  @override
  String get loadingShort => 'Chargement';

  // FleetInfoCard
  @override
  String get fleetInfoTitle => 'FLOTTE';
  @override
  String get fleetAge => '{0} ans (construit {1})';
  @override
  String get fleetSightings => '{0} observations';
  @override
  String get fleetFirstSeen => 'première vue {0}';
  @override
  String get fleetLastSeen => 'dernière vue {0}';

  // RouteStatsBadge
  @override
  String get routeTodayFlights => '{0} aujourd\'hui';
  @override
  String get routeWeekFlights => '{0} cette semaine';
  @override
  String get routeMonthFlights => '{0} en 30 j';

  // AtcAudioPanel
  @override
  String get atcLiveTitle => 'ATC EN DIRECT';
  @override
  String get atcUnavailable => 'Aucun flux catalogué pour cet aéroport';
  @override
  String get atcSearchFallback => 'Rechercher sur LiveATC.net';
  @override
  String get atcAttribution => 'Audio fourni par LiveATC.net';
  @override
  String get atcOpenInBrowser => 'Ouvrir dans le navigateur';

  // Airport detail tab labels
  @override
  String get infoTab => 'INFO';
  @override
  String get sortLabel => 'TRI';
  @override
  String get sortByTime => 'HEURE';
  @override
  String get sortByDelay => 'RETARD';

  @override
  String get sectionUnavailable => 'SECTION INDISPONIBLE';

  // Relative-time
  @override
  String get relTimeNow => 'à l\'instant';
  @override
  String get relTimeMinutes => 'il y a {0} min';
  @override
  String get relTimeHours => 'il y a {0} h';
  @override
  String get relTimeDays => 'il y a {0} j';
  @override
  String get relTimeMonths => 'il y a {0} mois';
  @override
  String get relTimeYears => 'il y a {0} ans';

  // ICS export
  @override
  String get exportIcs => 'Exporter .ics';
  @override
  String get exportIcsCalName => 'AirWatch — Enregistrés';
  @override
  String get exportNoItems => 'Rien à exporter';

  // ── Geofence form ──────────────────────────────────────────────────────
  @override
  String get fenceFormTitle => 'Nouvelle géofence';
  @override
  String get fenceNewHeading => 'NOUVELLE GÉOFENCE {0}';
  @override
  String get fenceTypeCircle => 'CERCLE';
  @override
  String get fenceTypeRectangle => 'RECTANGLE';
  @override
  String get fenceNameLabel => 'NOM';
  @override
  String get fenceNamePlaceholder => 'ex. Approche Francfort';
  @override
  String get fenceRadiusLabel => 'RAYON (KM)';
  @override
  String get fenceCenterLatLabel => 'LATITUDE CENTRE';
  @override
  String get fenceCenterLonLabel => 'LONGITUDE CENTRE';
  @override
  String get fenceNorthLabel => 'LATITUDE NORD';
  @override
  String get fenceSouthLabel => 'LATITUDE SUD';
  @override
  String get fenceEastLabel => 'LONGITUDE EST';
  @override
  String get fenceWestLabel => 'LONGITUDE OUEST';
  @override
  String get fenceMinAltLabel => 'ALT. MIN (FT)';
  @override
  String get fenceMaxAltLabel => 'ALT. MAX (FT)';
  @override
  String get fenceAirlineLabel => 'ICAO COMPAGNIE';
  @override
  String get fenceOptionalFilters => 'FILTRES OPTIONNELS';
  @override
  String get fenceSaveButton => 'ENREGISTRER';
  @override
  String get fenceCancelButton => 'ANNULER';
  @override
  String get fenceErrNameRequired => 'Nom requis';
  @override
  String get fenceErrLatRange => 'La latitude doit être entre -90 et 90';
  @override
  String get fenceErrLonRange => 'La longitude doit être entre -180 et 180';
  @override
  String get fenceErrRadius => 'Le rayon doit être supérieur à 0 km';
  @override
  String get fenceErrBoundsRequired => 'Les quatre limites sont requises';
  @override
  String get fenceErrNorthSouth => 'Nord doit être supérieur à Sud';
  @override
  String get fenceErrEastWest => 'Est doit être supérieur à Ouest';

  // ── Geofence list ──────────────────────────────────────────────────────
  @override
  String get fenceActiveHeading => 'GÉOFENCES ACTIVES';
  @override
  String get fenceTotalCount => '{0} au total';
  @override
  String get fencesListEmpty =>
      'Aucune géofence. Tapez DESSINER ou utilisez le formulaire — les alertes s\'afficheront ici lorsqu\'un aéronef entrera dans la zone.';
  @override
  String get fenceDelete => 'Supprimer';
  @override
  String get fenceShapeCircle => '{0}° N, {1}° E · r {2} km';
  @override
  String get fenceShapeRect => 'S {0}° → N {1}° · O {2}° → E {3}°';
  @override
  String get fenceAirlineTooltip =>
      'Seuls les vols de {0} ({1}) déclenchent cette géofence';
  @override
  String get fenceAirlineTooltipNoName => 'Filtre compagnie : {0}';
  @override
  String get fenceMinAltTooltip =>
      'Seuls les vols à cette altitude ou plus déclenchent cette géofence';
  @override
  String get fenceMaxAltTooltip =>
      'Seuls les vols à cette altitude ou moins déclenchent cette géofence';

  // ── Draw screen ────────────────────────────────────────────────────────
  @override
  String get fenceDrawTitle => 'Dessiner une géofence';
  @override
  String get fenceDrawHintCircleFirst => 'Tapez pour placer le centre';
  @override
  String get fenceDrawHintCircleSecond => 'Tapez pour définir le rayon';
  @override
  String get fenceDrawHintRectFirst => 'Tapez pour définir le premier coin';
  @override
  String get fenceDrawHintRectSecond => 'Tapez pour définir le coin opposé';
  @override
  String get fenceDrawHintReady => 'Enregistrer quand prêt ou taper RESET';
  @override
  String get fenceDrawResetButton => 'RESET';
  @override
  String get fenceDrawNameTitle => 'Nommer cette géofence';

  // ── Alerts panel ───────────────────────────────────────────────────────
  @override
  String get alertsCountOne => 'ALERTE';
  @override
  String get alertsCountMany => 'ALERTES';
  @override
  String get alertsClearAll => 'TOUT EFFACER';
  @override
  String get alertsClearAllTooltip =>
      'Effacer toutes les alertes (les géofences sont conservées)';
  @override
  String get alertsDismiss => 'Ignorer';
  @override
  String get alertsDismissTooltip =>
      'Ignorer cette alerte (n\'affecte pas l\'historique)';
  @override
  String get alertsAllFilter => 'TOUTES';
  @override
  String get alertsFilterTooltip => 'Basculer les alertes de « {0} »';
  @override
  String get alertsEmptyFilter =>
      'Aucune alerte ne correspond au filtre. Tapez TOUTES.';
  @override
  String get alertsShowOnMap => 'Afficher ce vol sur la carte';

  // ── Fence stats badge ──────────────────────────────────────────────────
  @override
  String get fenceStatsHitsOne => '{0} déclenchement';
  @override
  String get fenceStatsHitsMany => '{0} déclenchements';
  @override
  String get fenceStatsAircraft => '{0} aéronefs';
  @override
  String get fenceStatsTopAirlineWithName =>
      'Top compagnie : {0} ({1}× cette géofence)';
  @override
  String get fenceStatsTopAirline => 'Top compagnie : {0}';
  @override
  String get fenceStatsTopLabel => 'top :';
  @override
  String get fenceStatsLast => 'dernier {0}';

  // ── Fence import/export ────────────────────────────────────────────────
  @override
  String get fenceExport => 'EXPORTER';
  @override
  String get fenceImport => 'IMPORTER';
  @override
  String get fenceImporting => 'IMPORT…';
  @override
  String get fenceExportTooltip => 'Télécharger vos géofences en JSON';
  @override
  String get fenceImportTooltip =>
      'Restaurer les géofences depuis un fichier JSON';
  @override
  String get fenceExportEmpty => 'Rien à exporter';
  @override
  String get fenceExportedOne => '1 géofence exportée';
  @override
  String get fenceExportedMany => '{0} géofences exportées';
  @override
  String get fenceReadingFile => 'Lecture du fichier…';
  @override
  String get fenceImportedOne => '1 géofence importée';
  @override
  String get fenceImportedMany => '{0} géofences importées';
  @override
  String get fenceImportedPartial => '{0} importée(s), {1} en échec ({2})';
  @override
  String get fenceReadFailed => 'Échec de lecture : {0}';
  @override
  String get fenceImportInvalidJson => 'JSON invalide : {0}';
  @override
  String get fenceImportSchemaMismatch => 'Schéma incompatible à {0} : {1}';

  // ── Dashboard empty / honest states ────────────────────────────────────
  @override
  String get dashNoDataYet => 'Aucune donnée';
  @override
  String get dashEmptyHint =>
      'Ouvrez la carte pour commencer à suivre des vols';

  // ── AR HUD compact stat labels ─────────────────────────────────────────
  @override
  String get arHudHdg => 'CAP';
  @override
  String get arHudPitch => 'TANG';
  @override
  String get arHudInView => 'EN VUE';

  // ── Favourite kind labels ──────────────────────────────────────────────
  @override
  String get kindFlight => 'Vol';
  @override
  String get kindAirline => 'Compagnie';
  @override
  String get kindAirport => 'Aéroport';

  // ── Generic UI fallbacks ───────────────────────────────────────────────
  @override
  String get errorGeneric => 'Erreur';
  @override
  String get geofencesActiveCount => '{0} ACTIVE(S)';

  // ── Alert bell + sheet ─────────────────────────────────────────────────
  @override
  String get alertBellAria => 'Ouvrir le panneau d\'alertes';
  @override
  String get alertsNone => 'Aucune alerte active';

  // ── Generic dialog actions ─────────────────────────────────────────────
  @override
  String get actionClose => 'Fermer';

  // ── Settings: Privacy Policy dialog ────────────────────────────────────
  @override
  String get privacyTitle => 'Politique de confidentialité';
  @override
  String get privacyLastUpdated => 'Dernière mise à jour : {0} · v{1}';
  @override
  String get privacySummaryHeading => 'Résumé';
  @override
  String get privacySummary1 =>
      'Aucun compte, aucune connexion, aucune donnée personnelle collectée.';
  @override
  String get privacySummary2 =>
      'Aucune publicité, aucun SDK d\'analyse, aucune télémétrie.';
  @override
  String get privacySummary3 =>
      'Aucune donnée vendue ou partagée avec des tiers.';
  @override
  String get privacyOnDeviceHeading => 'Sur l\'appareil uniquement';
  @override
  String get privacyOnDeviceLocation =>
      'Localisation — utilisée pour centrer la carte et trouver les avions proches. Jamais envoyée.';
  @override
  String get privacyOnDeviceCamera =>
      'Caméra (mode AR) — les images sont décodées, affichées, puis jetées. Jamais envoyées.';
  @override
  String get privacyOnDeviceMicrophone =>
      'Microphone (bouton vocal) — transmis au moteur vocal de l\'OS ; seule la transcription arrive à AirWatch, traitée localement.';
  @override
  String get privacyOnDeviceSensors =>
      'Capteurs (boussole, accéléromètre) — lus à 10 Hz pour le HUD AR ; jamais persistés.';
  @override
  String get privacyOnDeviceStorage =>
      'Paramètres, favoris, géofences — enregistrés dans le bac à sable de l\'app via SharedPreferences / NSUserDefaults.';
  @override
  String get privacyNetworkHeading => 'Réseau';
  @override
  String get privacyNetworkHosts =>
      'Parle uniquement à api.airwatch.app (TLS épinglé) et pics.avs.io pour les logos. C\'est toute la liste d\'hôtes.';
  @override
  String get privacyNetworkLogs =>
      'Les logs backend sont conservés 30 jours pour le rate-limit ; les adresses IP ne sont croisées avec aucun autre jeu de données.';
  @override
  String get privacyRightsHeading => 'Vos droits';
  @override
  String get privacyRightsList =>
      'Accès, rectification, effacement, limitation, portabilité, opposition et retrait du consentement — écrivez à privacy@airwatch.app.';
  @override
  String get privacyRightsComplaint =>
      'Droit d\'introduire une plainte auprès de votre autorité de protection des données.';
  @override
  String get privacyFullTextHeading => 'Texte intégral';
  @override
  String get privacyFullTextRef =>
      'Voir PRIVACY.md dans le dépôt pour la politique complète, sources tierces et transferts internationaux inclus.';
  // ── Aviation: METAR / TAF micro-labels ─────────────────────────────────
  @override
  String get metarTafValidPrefix => 'Valide {0} → {1}';
  @override
  String get metarTafNow => 'MAINT.';

  // ── Geofences: FAB action labels ───────────────────────────────────────
  @override
  String get geofencesDrawFab => 'DESSINER';
  @override
  String get geofencesFormFabAria => 'Ajouter par coordonnées';
  // ── Map controls (a11y aria-labels) ────────────────────────────────────
  @override
  String get mapAriaSearch => 'Ouvrir la recherche';
  @override
  String get mapAriaZoomIn => 'Zoom avant';
  @override
  String get mapAriaZoomOut => 'Zoom arrière';
  @override
  String get mapAriaMyLocation => 'Centrer sur ma position';
  @override
  String get mapAriaCargoToggle => 'Vols cargo uniquement';
  @override
  String get alertTileHint => 'Double-toucher pour afficher sur la carte';
}
