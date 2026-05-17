// Auto-generated — replaces the historical 184 k-line const map.
// The dataset now lives in `assets/airports.json` and is loaded on
// app boot via `loadAirportFullDatabase()`. Lookups stay synchronous;
// they just hit the in-memory cache.
//
// <h3>Why moved off compile-time constants</h3>
// The previous shape — a `const Map<String, AirportEntry>` carrying
// 21 728 const constructor calls — was a 2.9 MB Dart source the
// compiler had to fully parse + validate on every build. Moving it
// to an asset:
//
//   * removes ~3 MB from `flutter build`'s Dart compile pipeline
//     (snappier debug iteration, smaller AOT artifact),
//   * keeps the apk size flat (the JSON ships in `assets/`, gzips
//     ~1.5 MB → ~280 kB),
//   * lets the dataset be regenerated without a code rebuild — see
//     `tool/build_airport_asset.dart` for the build script.
//
// To regen: `dart run tool/build_airport_asset.dart`
//
// <h3>Boot wiring</h3>
// `main.dart` awaits [loadAirportFullDatabase] before `runApp`, so by
// the time any UI builds the cache is primed and the synchronous
// lookups (`lookupAirport`, `lookupAirportByIata`, `airportCity`,
// `airportCountry`) work transparently.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class AirportEntry {
  final String icao, iata, name, city, country;
  final double lat, lon;
  const AirportEntry(
    this.icao,
    this.iata,
    this.name,
    this.city,
    this.country,
    this.lat,
    this.lon,
  );
}

/// In-memory cache, populated by [loadAirportFullDatabase]. Until the
/// loader has run we expose an empty map — sync lookups return null
/// and the UI falls back to the bundled `airport_database.dart` shorthand
/// for major hubs (already what every callsite does on a miss).
Map<String, AirportEntry> _icaoMap = const {};
Map<String, AirportEntry>? _iataIndex;

/// The full dataset keyed by ICAO. Returned as an unmodifiable view —
/// callers should never mutate it.
Map<String, AirportEntry> get airportFullDatabase => _icaoMap;

bool _loadStarted = false;
Future<void>? _loadFuture;

/// Load the airports asset into [_icaoMap]. Idempotent — concurrent
/// callers all await the same Future. Called once from `main.dart`
/// before `runApp`. Tests can populate the map directly via
/// [debugSetAirportFullDatabase] instead of touching the asset bundle.
Future<void> loadAirportFullDatabase() async {
  if (_loadStarted) return _loadFuture!;
  _loadStarted = true;
  _loadFuture = _doLoad();
  return _loadFuture!;
}

Future<void> _doLoad() async {
  final raw = await rootBundle.loadString('assets/airports.json');
  final list = jsonDecode(raw) as List<dynamic>;
  final out = <String, AirportEntry>{};
  for (final row in list) {
    if (row is! List || row.length < 7) continue;
    final entry = AirportEntry(
      row[0] as String,
      row[1] as String,
      row[2] as String,
      row[3] as String,
      row[4] as String,
      (row[5] as num).toDouble(),
      (row[6] as num).toDouble(),
    );
    if (entry.icao.isNotEmpty) out[entry.icao] = entry;
  }
  _icaoMap = Map.unmodifiable(out);
  _iataIndex = null; // rebuild lazily on next IATA lookup
}

/// Test hook — replace the in-memory dataset with a curated subset.
/// Production code should never call this; tests use it to avoid the
/// asset-bundle round-trip.
void debugSetAirportFullDatabase(Map<String, AirportEntry> map) {
  _icaoMap = Map.unmodifiable(map);
  _iataIndex = null;
  _loadStarted = true;
  _loadFuture = Future.value();
}

/// Lookup by ICAO code — O(1).
AirportEntry? lookupAirport(String icao) => _icaoMap[icao.toUpperCase()];

/// Build (or fetch the cached) IATA index. The dataset is keyed by
/// ICAO; the IATA index lets us avoid a 21 k linear scan on every
/// flight tile that wants the city / country for a dep / arr code.
Map<String, AirportEntry> _ensureIataIndex() {
  final cached = _iataIndex;
  if (cached != null) return cached;
  final fresh = <String, AirportEntry>{};
  for (final entry in _icaoMap.values) {
    if (entry.iata.isNotEmpty) fresh[entry.iata] = entry;
  }
  _iataIndex = fresh;
  return fresh;
}

/// Lookup by IATA code — O(1) after first access.
AirportEntry? lookupAirportByIata(String iata) {
  if (iata.isEmpty) return null;
  return _ensureIataIndex()[iata.toUpperCase()];
}

/// Get city name for an IATA code.
String airportCity(String? iata) {
  if (iata == null || iata.isEmpty) return '';
  final apt = lookupAirportByIata(iata);
  return apt?.city ?? '';
}

/// Get country code for an IATA code.
String airportCountry(String? iata) {
  if (iata == null || iata.isEmpty) return '';
  final apt = lookupAirportByIata(iata);
  return apt?.country ?? '';
}
