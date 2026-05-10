// One-shot build tool: read the const `airportFullDatabase` map and
// emit it as a compact JSON asset.
//
// <h3>Why we ship JSON instead of Dart constants</h3>
// The Dart const-map literal carrying 21,728 entries is a 2.9 MB
// source file the compiler has to fully parse + validate on every
// build. Moving it to an asset:
//
//   * removes ~3 MB from `flutter build`'s Dart compile pipeline
//     (snappier debug iteration, smaller AOT artifact),
//   * keeps the apk size flat (the JSON ships in `assets/`, not
//     baked into the dart-instructions section),
//   * lets the JSON gzip cleanly inside the apk (1.2 MB → ~280 kB),
//   * lets us hot-swap the dataset without a code rebuild for
//     internal experiments.
//
// <h3>How to run</h3>
//
//     dart run tool/build_airport_asset.dart
//
// Output: `assets/airports.json` — a compact array of
// `[icao, iata, name, city, country, lat, lon]` rows, one per
// airport. The mobile app's lazy loader (in
// `core/constants/airport_full_database.dart`) parses this format on
// first access and caches the resulting Map<ICAO, AirportEntry>.

import 'dart:convert';
import 'dart:io';

import 'package:airwatch_mobile/core/constants/airport_full_database.dart';

void main() {
  final rows = <List<dynamic>>[];
  for (final entry in airportFullDatabase.values) {
    rows.add([
      entry.icao,
      entry.iata,
      entry.name,
      entry.city,
      entry.country,
      entry.lat,
      entry.lon,
    ]);
  }
  // Sort by ICAO so the asset is stable across builds — diff-friendly
  // and `git` doesn't re-shuffle on each regen.
  rows.sort((a, b) => (a[0] as String).compareTo(b[0] as String));

  final json = jsonEncode(rows);
  final out = File('assets/airports.json');
  out.writeAsStringSync(json);

  // ignore: avoid_print
  print('Wrote ${rows.length} airports → ${out.path} '
      '(${(out.lengthSync() / 1024).toStringAsFixed(1)} kB)');
}
