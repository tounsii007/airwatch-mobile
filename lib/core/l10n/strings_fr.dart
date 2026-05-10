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
}
