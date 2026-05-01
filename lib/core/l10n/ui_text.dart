import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/conversion_constants.dart';
import '../constants/settings_provider.dart';
// `app_strings.dart` re-exports `AppStrings` so this single import is enough.
import 'app_strings.dart';

extension UiTextContext on BuildContext {
  AppStrings get s => S.ofLocale(Localizations.localeOf(this));

  String tr(String key) {
    final languageCode = Localizations.localeOf(this).languageCode;
    return UiText._translations[languageCode]?[key] ??
        UiText._translations['en']?[key] ??
        key;
  }

  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}

class UiText {
  static const _translations = <String, Map<String, String>>{
    'en': {
      'airports': 'AIRPORTS',
      'favorites': 'FAVORITES',
      'all': 'ALL',
      'live': 'LIVE',
      'airlines': 'AIRLINES',
      'countries': 'COUNTRIES',
      'flights_upper': 'FLIGHTS',
      'airports_upper': 'AIRPORTS',
      'search_airport_hint': 'Search airport (FRA, Tunis, CDG...)',
      'search_flights_hint': 'Flight, airline, registration...',
      'search_map_hint': 'Search flight, airline, airport...',
      'search_flights_prompt': 'Search flights, airlines, or aircraft',
      'search_examples': 'Try: TU, LH, DLH123, Ryanair...',
      'no_results': 'No results found',
      'no_flights_found': 'No flights found',
      'unable_to_load_data': 'Unable to load data',
      'popular_airports': 'POPULAR AIRPORTS',
      'recent_departures': 'RECENT DEPARTURES',
      'cruising_flights': 'CRUISING FLIGHTS',
      'airborne': 'AIRBORNE',
      'on_ground': 'ON GROUND',
      'total': 'TOTAL',
      'flights_count': 'Flights',
      'airlines_count': 'Airlines',
      'airports_count': 'Airports',
      'no_favorites_help': 'Tap the star icon on any flight,\nairline, or airport to save it here.',
      'dark_radar': 'Dark Radar',
      'neon_theme': 'Neon theme',
      'light_aviation': 'Light Aviation',
      'clean_theme': 'Clean theme',
      'system': 'System',
      'follow_os': 'Follow OS',
      'satellite': 'Satellite',
      'cartodb_dark': 'CartoDB dark',
      'cartodb_light': 'CartoDB light',
      'arcgis_imagery': 'ArcGIS imagery',
      'altitude_short': 'Altitude',
      'speed_short': 'Speed',
      'feet': 'Feet',
      'meters': 'Meters',
      'knots': 'Knots',
      'refresh': 'Refresh',
      'aircraft_trails': 'Aircraft Trails',
      'flight_path': 'Flight path',
      'aircraft_labels': 'Aircraft Labels',
      'callsign_label': 'Callsign label',
      'airport_labels': 'Airport Labels',
      'iata_codes': 'IATA codes',
      'density_heatmap': 'Density Heatmap',
      'overlay': 'Overlay',
      'provider': 'Provider',
      'search_flights': 'Search flights...',
      'weather_clear': 'Clear',
      'weather_partly_cloudy': 'Partly cloudy',
      'weather_fog': 'Fog',
      'weather_drizzle': 'Drizzle',
      'weather_rain': 'Rain',
      'weather_snow': 'Snow',
      'weather_rain_showers': 'Rain showers',
      'weather_snow_showers': 'Snow showers',
      'weather_thunderstorm': 'Thunderstorm',
      'weather_cloudy': 'Cloudy',
      'loading_route': 'Loading route...',
      'track': 'TRACK',
      'replay': 'REPLAY',
      'history': 'HISTORY',
      'favorite': 'FAVORITE',
      'ground': 'Ground',
      'flight_replay': 'FLIGHT REPLAY',
      'searching': 'Searching...',
      'found': 'found',
      'time_windows': 'time windows',
      'search_callsign_hint': 'Flight number (e.g. TU744 or TAR744)',
      'search_callsign_prompt': 'Search for a flight number or callsign\nto see 7-day history',
      'on_time': 'On Time',
      'delayed': 'Delayed',
      'avg_delay': 'Avg Delay',
      'departure': 'DEPARTURE',
      'arrival': 'ARRIVAL',
      'scheduled_short': 'Sched',
      'actual': 'Actual',
      'late': 'late',
      'early': 'early',
      'dep': 'Dep',
      'arr': 'Arr',
      'cancelled_short': 'CANCEL',
      'scheduled_badge': 'SCHED',
      'landed_badge': 'LANDED',
      'ground_badge': 'GROUND',
      'live_badge': 'LIVE',
      'initializing': 'Initializing flight systems...',
      'airwatch_tagline': 'TRACK THE SKIES IN REAL TIME',
      'no_track_data': 'No track data available',
      'failed_to_load_track': 'Failed to load track',
      'unknown': 'Unknown',
      'unknown_airport': 'Unknown Airport',
      'ar_native_required': 'AR mode requires native mobile build',
      'operated_by': 'Operated by',
      'loading': 'Loading...',
      'airport_word': 'Airport',
      'international_word': 'International',
      'active_flights': 'ACTIVE FLIGHTS',
      'no_flights': 'No flights found',
      'routes': 'ROUTES',
    },
    'de': {
      'airports': 'FLUGHÄFEN',
      'favorites': 'FAVORITEN',
      'all': 'ALLE',
      'live': 'LIVE',
      'airlines': 'AIRLINES',
      'countries': 'LÄNDER',
      'flights_upper': 'FLÜGE',
      'airports_upper': 'FLUGHÄFEN',
      'search_airport_hint': 'Flughafen suchen (FRA, Tunis, CDG...)',
      'search_flights_hint': 'Flug, Airline, Registrierung...',
      'search_map_hint': 'Flug, Airline, Flughafen suchen...',
      'search_flights_prompt': 'Suche nach Flügen, Airlines oder Flugzeugen',
      'search_examples': 'Beispiele: TU, LH, DLH123, Ryanair...',
      'no_results': 'Keine Ergebnisse',
      'no_flights_found': 'Keine Flüge gefunden',
      'unable_to_load_data': 'Daten konnten nicht geladen werden',
      'popular_airports': 'BELIEBTE FLUGHÄFEN',
      'recent_departures': 'AKTUELLE ABFLÜGE',
      'cruising_flights': 'REISEFLÜGE',
      'airborne': 'IN DER LUFT',
      'on_ground': 'AM BODEN',
      'total': 'GESAMT',
      'flights_count': 'Flüge',
      'airlines_count': 'Airlines',
      'airports_count': 'Flughäfen',
      'no_favorites_help': 'Tippe auf das Sternsymbol bei einem Flug,\neiner Airline oder einem Flughafen, um ihn hier zu speichern.',
      'dark_radar': 'Dunkles Radar',
      'neon_theme': 'Neon-Design',
      'light_aviation': 'Helle Aviation',
      'clean_theme': 'Klares Design',
      'system': 'System',
      'follow_os': 'Wie Betriebssystem',
      'satellite': 'Satellit',
      'cartodb_dark': 'CartoDB dunkel',
      'cartodb_light': 'CartoDB hell',
      'arcgis_imagery': 'ArcGIS Satellit',
      'altitude_short': 'Höhe',
      'speed_short': 'Geschwindigkeit',
      'feet': 'Fuß',
      'meters': 'Meter',
      'knots': 'Knoten',
      'refresh': 'Aktualisieren',
      'aircraft_trails': 'Flugspuren',
      'flight_path': 'Flugpfad',
      'aircraft_labels': 'Flugzeug-Labels',
      'callsign_label': 'Rufzeichen',
      'airport_labels': 'Flughafen-Labels',
      'iata_codes': 'IATA-Codes',
      'density_heatmap': 'Dichte-Heatmap',
      'overlay': 'Overlay',
      'provider': 'Anbieter',
      'search_flights': 'Flüge suchen...',
      'weather_clear': 'Klar',
      'weather_partly_cloudy': 'Teilweise bewölkt',
      'weather_fog': 'Nebel',
      'weather_drizzle': 'Nieselregen',
      'weather_rain': 'Regen',
      'weather_snow': 'Schnee',
      'weather_rain_showers': 'Regenschauer',
      'weather_snow_showers': 'Schneeschauer',
      'weather_thunderstorm': 'Gewitter',
      'weather_cloudy': 'Bewölkt',
      'loading_route': 'Route wird geladen...',
      'track': 'VERFOLGEN',
      'replay': 'WIEDERGABE',
      'history': 'VERLAUF',
      'favorite': 'FAVORIT',
      'ground': 'Boden',
      'flight_replay': 'FLUG-WIEDERGABE',
      'searching': 'Suche...',
      'found': 'gefunden',
      'time_windows': 'Zeitfenster',
      'search_callsign_hint': 'Flugnummer (z. B. TU744 oder TAR744)',
      'search_callsign_prompt': 'Suche nach einer Flugnummer oder einem Rufzeichen,\num den 7-Tage-Verlauf zu sehen',
      'on_time': 'Pünktlich',
      'delayed': 'Verspätet',
      'avg_delay': 'Ø Verspätung',
      'departure': 'ABFLUG',
      'arrival': 'ANKUNFT',
      'scheduled_short': 'Plan',
      'actual': 'Ist',
      'late': 'zu spät',
      'early': 'zu früh',
      'dep': 'Abf',
      'arr': 'Ank',
      'cancelled_short': 'ANNULL.',
      'scheduled_badge': 'GEPLANT',
      'landed_badge': 'GELANDET',
      'ground_badge': 'BODEN',
      'live_badge': 'LIVE',
      'initializing': 'Flugsysteme werden initialisiert...',
      'airwatch_tagline': 'VERFOLGE DEN HIMMEL IN ECHTZEIT',
      'no_track_data': 'Keine Trackdaten verfügbar',
      'failed_to_load_track': 'Fehler beim Laden des Tracks',
      'unknown': 'Unbekannt',
      'unknown_airport': 'Unbekannter Flughafen',
      'ar_native_required': 'AR-Modus erfordert nativen Mobile-Build',
      'operated_by': 'Betrieben von',
      'loading': 'Laden...',
      'airport_word': 'Flughafen',
      'international_word': 'International',
      'active_flights': 'AKTIVE FLÜGE',
      'no_flights': 'Keine Flüge gefunden',
      'routes': 'ROUTEN',
    },
    'fr': {
      'airports': 'AÉROPORTS',
      'favorites': 'FAVORIS',
      'all': 'TOUT',
      'live': 'LIVE',
      'airlines': 'COMPAGNIES',
      'countries': 'PAYS',
      'flights_upper': 'VOLS',
      'airports_upper': 'AÉROPORTS',
      'search_airport_hint': 'Rechercher un aéroport (FRA, Tunis, CDG...)',
      'search_flights_hint': 'Vol, compagnie, immatriculation...',
      'search_map_hint': 'Rechercher un vol, une compagnie, un aéroport...',
      'search_flights_prompt': 'Rechercher des vols, compagnies ou avions',
      'search_examples': 'Exemples : TU, LH, DLH123, Ryanair...',
      'no_results': 'Aucun résultat',
      'no_flights_found': 'Aucun vol trouvé',
      'unable_to_load_data': 'Impossible de charger les données',
      'popular_airports': 'AÉROPORTS POPULAIRES',
      'recent_departures': 'DÉPARTS RÉCENTS',
      'cruising_flights': 'VOLS EN CROISIÈRE',
      'airborne': 'EN VOL',
      'on_ground': 'AU SOL',
      'total': 'TOTAL',
      'flights_count': 'Vols',
      'airlines_count': 'Compagnies',
      'airports_count': 'Aéroports',
      'no_favorites_help': 'Touchez l’étoile sur un vol,\nune compagnie ou un aéroport pour l’enregistrer ici.',
      'dark_radar': 'Radar sombre',
      'neon_theme': 'Thème néon',
      'light_aviation': 'Aviation claire',
      'clean_theme': 'Thème épuré',
      'system': 'Système',
      'follow_os': 'Suivre le système',
      'satellite': 'Satellite',
      'cartodb_dark': 'CartoDB sombre',
      'cartodb_light': 'CartoDB clair',
      'arcgis_imagery': 'Imagerie ArcGIS',
      'altitude_short': 'Altitude',
      'speed_short': 'Vitesse',
      'feet': 'Pieds',
      'meters': 'Mètres',
      'knots': 'Nœuds',
      'refresh': 'Actualiser',
      'aircraft_trails': 'Traînées avion',
      'flight_path': 'Trajectoire',
      'aircraft_labels': 'Étiquettes avion',
      'callsign_label': 'Indicatif',
      'airport_labels': 'Étiquettes aéroport',
      'iata_codes': 'Codes IATA',
      'density_heatmap': 'Carte de densité',
      'overlay': 'Surimpression',
      'provider': 'Fournisseur',
      'search_flights': 'Rechercher des vols...',
      'weather_clear': 'Dégagé',
      'weather_partly_cloudy': 'Partiellement nuageux',
      'weather_fog': 'Brouillard',
      'weather_drizzle': 'Bruine',
      'weather_rain': 'Pluie',
      'weather_snow': 'Neige',
      'weather_rain_showers': 'Averses',
      'weather_snow_showers': 'Averses de neige',
      'weather_thunderstorm': 'Orage',
      'weather_cloudy': 'Nuageux',
      'loading_route': 'Chargement de la route...',
      'track': 'SUIVRE',
      'replay': 'REJOUER',
      'history': 'HISTORIQUE',
      'favorite': 'FAVORI',
      'ground': 'Sol',
      'flight_replay': 'RELECTURE DU VOL',
      'searching': 'Recherche...',
      'found': 'trouvé(s)',
      'time_windows': 'fenêtres temporelles',
      'search_callsign_hint': 'Indicatif (ex. TAR744)',
      'search_callsign_prompt': 'Recherchez un indicatif de vol\npour voir l’historique sur 7 jours',
      'on_time': 'À l’heure',
      'delayed': 'Retardé',
      'avg_delay': 'Retard moy.',
      'departure': 'DÉPART',
      'arrival': 'ARRIVÉE',
      'scheduled_short': 'Prévu',
      'actual': 'Réel',
      'late': 'de retard',
      'early': 'd’avance',
      'dep': 'Dép',
      'arr': 'Arr',
      'cancelled_short': 'ANNULÉ',
      'scheduled_badge': 'PRÉVU',
      'landed_badge': 'ATTERRI',
      'ground_badge': 'SOL',
      'live_badge': 'LIVE',
      'initializing': 'Initialisation des systèmes de vol...',
      'airwatch_tagline': 'SUIVEZ LE CIEL EN TEMPS RÉEL',
      'no_track_data': 'Aucune donnée de suivi disponible',
      'failed_to_load_track': 'Échec du chargement du suivi',
      'unknown': 'Inconnu',
      'unknown_airport': 'Aéroport inconnu',
      'ar_native_required': 'Le mode AR nécessite une version mobile native',
      'operated_by': 'Opéré par',
      'loading': 'Chargement...',
      'airport_word': 'Aéroport',
      'international_word': 'International',
      'active_flights': 'VOLS ACTIFS',
      'no_flights': 'Aucun vol trouvé',
      'routes': 'ROUTES',
    },
  };

  static String statusLabel(BuildContext context, String? status, {bool compact = false}) {
    return switch (status?.toLowerCase()) {
      'en-route' || 'active' => context.tr(compact ? 'live_badge' : 'live'),
      'landed' => context.tr(compact ? 'landed_badge' : 'landed_badge'),
      'scheduled' => context.tr(compact ? 'scheduled_badge' : 'scheduled_badge'),
      'on ground' => context.tr(compact ? 'ground_badge' : 'on_ground'),
      'cancelled' => context.tr('cancelled_short'),
      _ => status?.toUpperCase() ?? '',
    };
  }

  static String weatherLabel(BuildContext context, int? code) {
    if (code == null) return '';
    if (code == 0) return context.tr('weather_clear');
    if (code <= 3) return context.tr('weather_partly_cloudy');
    if (code <= 49) return context.tr('weather_fog');
    if (code <= 59) return context.tr('weather_drizzle');
    if (code <= 69) return context.tr('weather_rain');
    if (code <= 79) return context.tr('weather_snow');
    if (code <= 82) return context.tr('weather_rain_showers');
    if (code <= 86) return context.tr('weather_snow_showers');
    if (code >= 95) return context.tr('weather_thunderstorm');
    return context.tr('weather_cloudy');
  }

  static String formatAltitude(
    BuildContext context,
    SettingsState settings,
    double? meters,
  ) {
    if (meters == null) return '--';
    switch (settings.altitudeUnit) {
      case AltitudeUnit.feet:
        final feet = meters * ConversionConstants.metersToFeet;
        if (feet < 1000) return '${feet.round()} ft';
        return '${(feet / 1000).toStringAsFixed(1)}k ft';
      case AltitudeUnit.meters:
        if (meters < 1000) return '${meters.round()} m';
        return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String formatSpeed(
    BuildContext context,
    SettingsState settings,
    double? metersPerSec,
  ) {
    // Treat 0 speed as missing data (ADS-B gap) — aircraft in flight always have speed
    if (metersPerSec == null || metersPerSec == 0) return '--';
    switch (settings.speedUnit) {
      case SpeedUnit.knots:
        return '${(metersPerSec * ConversionConstants.msToKnots).round()} kts';
      case SpeedUnit.kmh:
        return '${(metersPerSec * ConversionConstants.msToKmh).round()} km/h';
      case SpeedUnit.mph:
        return '${(metersPerSec * ConversionConstants.msToMph).round()} mph';
    }
  }

  static String formatVerticalRate(
    BuildContext context,
    SettingsState settings,
    double? metersPerSec,
  ) {
    if (metersPerSec == null) return '--';
    final sign = metersPerSec > 0 ? '+' : '';
    switch (settings.altitudeUnit) {
      case AltitudeUnit.feet:
        return '$sign${(metersPerSec * ConversionConstants.msToFtPerMin).round()} ft/m';
      case AltitudeUnit.meters:
        return '$sign${(metersPerSec * ConversionConstants.msToMPerMin).round()} m/m';
    }
  }

  static String formatRelative(BuildContext context, DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) {
      return switch (Localizations.localeOf(context).languageCode) {
        'de' => 'Gerade eben',
        'fr' => 'À l’instant',
        _ => 'Just now',
      };
    }
    if (diff.inMinutes < 60) {
      return switch (Localizations.localeOf(context).languageCode) {
        'de' => 'vor ${diff.inMinutes} Min.',
        'fr' => 'il y a ${diff.inMinutes} min',
        _ => '${diff.inMinutes}m ago',
      };
    }
    if (diff.inHours < 24) {
      return switch (Localizations.localeOf(context).languageCode) {
        'de' => 'vor ${diff.inHours} Std.',
        'fr' => 'il y a ${diff.inHours} h',
        _ => '${diff.inHours}h ago',
      };
    }
    return switch (Localizations.localeOf(context).languageCode) {
      'de' => 'vor ${diff.inDays} Tg.',
      'fr' => 'il y a ${diff.inDays} j',
      _ => '${diff.inDays}d ago',
    };
  }

  static DateFormat dateFormat(BuildContext context, String pattern) {
    return DateFormat(pattern, Localizations.localeOf(context).toLanguageTag());
  }
}
