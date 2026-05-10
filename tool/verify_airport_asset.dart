// Asset health check — reads `assets/airports.json` and validates the
// shape every row should satisfy. Run as part of CI to catch a corrupt
// or hand-edited asset before it ships.
//
// <h3>Background</h3>
// The 21 k airport dataset used to live as a `const Map<String,
// AirportEntry>` in lib/core/constants/airport_full_database.dart —
// 184 k Dart source lines the compiler had to parse on every build.
// We migrated it to a JSON asset (commit 4dde088). Since the original
// const map is gone, the asset is now its own source of truth — this
// validator is the regression net.
//
// <h3>How to run</h3>
//
//     dart run tool/verify_airport_asset.dart
//
// Exit code 0 on success, 1 on any structural problem.
// CI (`.github/workflows/ci.yml`) wires this in as a hard gate.

import 'dart:convert';
import 'dart:io';

void main() {
  const path = 'assets/airports.json';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('FAIL: $path not found');
    exit(1);
  }

  late dynamic decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } catch (e) {
    stderr.writeln('FAIL: invalid JSON in $path: $e');
    exit(1);
  }

  if (decoded is! List) {
    stderr.writeln('FAIL: top-level value must be a JSON array');
    exit(1);
  }

  final problems = <String>[];
  final icaoSet = <String>{};
  for (var i = 0; i < decoded.length; i++) {
    final row = decoded[i];
    if (row is! List) {
      problems.add('row $i: not an array');
      continue;
    }
    if (row.length < 7) {
      problems.add('row $i: ${row.length} fields, expected 7');
      continue;
    }
    final icao = row[0];
    final iata = row[1];
    final name = row[2];
    final city = row[3];
    final country = row[4];
    final lat = row[5];
    final lon = row[6];

    if (icao is! String || icao.isEmpty) {
      problems.add('row $i: invalid icao "$icao"');
      continue;
    }
    if (icao.length != 4) {
      problems.add('row $i ($icao): icao must be 4 chars');
    }
    if (!icaoSet.add(icao)) {
      problems.add('row $i: duplicate icao $icao');
    }
    if (iata is! String) problems.add('row $i ($icao): iata not a string');
    if (name is! String) problems.add('row $i ($icao): name not a string');
    if (city is! String) problems.add('row $i ($icao): city not a string');
    if (country is! String) {
      problems.add('row $i ($icao): country not a string');
    }
    if (lat is! num || lat < -90 || lat > 90) {
      problems.add('row $i ($icao): lat out of range: $lat');
    }
    if (lon is! num || lon < -180 || lon > 180) {
      problems.add('row $i ($icao): lon out of range: $lon');
    }

    if (problems.length > 20) {
      problems.add('… more issues; truncated at 20');
      break;
    }
  }

  if (problems.isNotEmpty) {
    stderr.writeln('FAIL: $path has ${problems.length} structural issues:');
    for (final p in problems) {
      stderr.writeln('  - $p');
    }
    exit(1);
  }

  // Sanity: a real-world dataset should have at least 5 k airports
  // and at least 3 k IATA-coded ones. Anything below means the asset
  // was truncated or a regen pipeline broke.
  if (decoded.length < 5000) {
    stderr.writeln('FAIL: only ${decoded.length} airports; expected ≥ 5 000');
    exit(1);
  }
  final iataCount = decoded
      .whereType<List>()
      .where((row) => row.length >= 2 && row[1] is String && row[1] != '')
      .length;
  if (iataCount < 3000) {
    stderr.writeln('FAIL: only $iataCount IATA-coded; expected ≥ 3 000');
    exit(1);
  }

  // ignore: avoid_print
  print('OK: ${decoded.length} airports ($iataCount with IATA), '
      '${(file.lengthSync() / 1024).toStringAsFixed(1)} kB');
}
