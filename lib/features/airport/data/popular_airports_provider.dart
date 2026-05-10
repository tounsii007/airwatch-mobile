import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:airwatch_mobile/core/constants/airport_database.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';

/// Dynamic popular airports based on user location or language preference.
final popularAirportsProvider =
    FutureProvider<List<({String iata, String city})>>((ref) async {
      final language = ref.watch(languageProvider);

      // Try geolocation (skip on web — unreliable)
      if (!kIsWeb) {
        final position = await _tryGetPosition();
        if (position != null) {
          return _nearestAirports(position.latitude, position.longitude);
        }
      }

      // Fallback: language-based selection
      return _airportsForLanguage(language);
    });

/// Country priorities per language.
/// Primary countries shown first, then nearby countries fill the rest.
const _languageCountries = <AppLanguage, List<List<String>>>{
  AppLanguage.de: [
    ['Germany', 'Austria', 'Switzerland'],
    [
      'Netherlands',
      'Belgium',
      'France',
      'Czechia',
      'Poland',
      'Denmark',
      'Italy',
      'Spain',
      'UK',
    ],
  ],
  AppLanguage.fr: [
    ['France'],
    [
      'Belgium',
      'Switzerland',
      'Spain',
      'Italy',
      'Morocco',
      'Tunisia',
      'Algeria',
      'Germany',
      'Netherlands',
      'UK',
    ],
  ],
  AppLanguage.en: [
    ['USA', 'UK', 'Canada', 'Australia'],
    [
      'UAE',
      'Singapore',
      'Germany',
      'France',
      'Netherlands',
      'Japan',
      'South Korea',
      'Turkey',
      'Qatar',
    ],
  ],
  AppLanguage.es: [
    ['Spain'],
    [
      'Mexico',
      'Argentina',
      'Colombia',
      'Chile',
      'Peru',
      'Portugal',
      'France',
      'Italy',
      'Germany',
      'UK',
    ],
  ],
  AppLanguage.it: [
    ['Italy'],
    [
      'Switzerland',
      'France',
      'Spain',
      'Germany',
      'Austria',
      'Greece',
      'Croatia',
      'Malta',
      'UK',
      'Netherlands',
    ],
  ],
};

const _maxPopularAirports = 18;

/// Try to get user position without prompting for permission.
Future<Position?> _tryGetPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    // Use last known first (instant), then current with timeout
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)),
    );
  } catch (_) {
    return null;
  }
}

/// Return nearest major airports sorted by distance from user.
List<({String iata, String city})> _nearestAirports(double lat, double lon) {
  final majors = AirportDatabase.getMajorAirports();

  majors.sort((a, b) {
    final distA = _haversine(lat, lon, a.lat, a.lon);
    final distB = _haversine(lat, lon, b.lat, b.lon);
    return distA.compareTo(distB);
  });

  return majors
      .take(_maxPopularAirports)
      .map((a) => (iata: a.iata, city: a.city))
      .toList();
}

/// Return airports based on selected language.
List<({String iata, String city})> _airportsForLanguage(AppLanguage lang) {
  final countryGroups =
      _languageCountries[lang] ?? _languageCountries[AppLanguage.en]!;
  final primaryCountries = countryGroups[0].toSet();
  final nearbyCountries = countryGroups.length > 1
      ? countryGroups[1].toSet()
      : <String>{};

  final allAirports = AirportDatabase.getMajorAirports();

  // Split into primary (home countries) and nearby
  final primary = allAirports
      .where((a) => primaryCountries.contains(a.country))
      .toList();
  final nearby = allAirports
      .where((a) => nearbyCountries.contains(a.country))
      .toList();
  final rest = allAirports
      .where(
        (a) =>
            !primaryCountries.contains(a.country) &&
            !nearbyCountries.contains(a.country),
      )
      .toList();

  // Combine: primary first, then nearby, then global fill
  final result = <({String iata, String city})>[];
  for (final airport in [...primary, ...nearby, ...rest]) {
    if (result.length >= _maxPopularAirports) break;
    final entry = (iata: airport.iata, city: airport.city);
    if (!result.any((r) => r.iata == entry.iata)) {
      result.add(entry);
    }
  }

  return result;
}

/// Haversine distance in km between two lat/lon points.
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180;
