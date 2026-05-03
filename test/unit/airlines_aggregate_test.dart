import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/airlines/presentation/screens/airlines_screen.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Helper — build a minimal AircraftState with just a callsign. Every other
/// field is irrelevant to the aggregation logic.
AircraftState _ac(String callsign) =>
    AircraftState(icao24: 'AABBCC', callsign: callsign);

/// Custom matcher for `MapEntry<String, int>`.
///
/// `MapEntry` deliberately does NOT override `==` / `hashCode` (the Dart
/// SDK leaves it as identity equality so it stays a cheap value-type),
/// so the natural `expect(result, [MapEntry(...)])` form fails even when
/// every key+value is identical. We compare by `key`/`value` instead.
Matcher _entry(String key, int value) => isA<MapEntry<String, int>>()
    .having((e) => e.key, 'key', key)
    .having((e) => e.value, 'value', value);

/// Convenience: assert a list of MapEntry results matches `[(key, value), ...]`
/// — keeps the call-site readable even with many entries.
void _expectEntries(
  List<MapEntry<String, int>> actual,
  List<(String, int)> expected,
) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i].key, expected[i].$1, reason: 'key at index $i');
    expect(actual[i].value, expected[i].$2, reason: 'value at index $i');
  }
}

void main() {
  group('aggregateByAirlineIcao', () {
    test('returns empty for empty input', () {
      expect(aggregateByAirlineIcao(const []), isEmpty);
    });

    test('groups callsigns by their first three chars (ICAO airline code)', () {
      final result = aggregateByAirlineIcao([
        _ac('DLH400'),
        _ac('DLH401'),
        _ac('AFR123'),
      ]);
      _expectEntries(result, [('DLH', 2), ('AFR', 1)]);
    });

    test('skips callsigns shorter than 3 chars', () {
      final result = aggregateByAirlineIcao([
        _ac('AB'),
        _ac('A'),
        _ac(''),
        _ac('DLH400'),
      ]);
      expect(result.length, 1);
      expect(result.first.key, 'DLH');
    });

    test(
      'skips callsigns whose prefix is not exactly three uppercase letters',
      () {
        final result = aggregateByAirlineIcao([
          _ac('1234'), // numeric
          _ac('dlh400'), // lowercase
          _ac('DL1400'), // letter-letter-digit
          _ac('DLH400'), // valid
        ]);
        expect(result.length, 1);
        expect(result.first.key, 'DLH');
      },
    );

    test('null callsign is silently dropped', () {
      final result = aggregateByAirlineIcao([
        AircraftState(icao24: 'AABB01'), // null callsign
        AircraftState(icao24: 'AABB02', callsign: 'DLH400'),
      ]);
      _expectEntries(result, [('DLH', 1)]);
    });

    test('whitespace around callsign is trimmed before slicing', () {
      final result = aggregateByAirlineIcao([
        _ac('   DLH400   '),
        _ac('\tDLH401\n'),
      ]);
      _expectEntries(result, [('DLH', 2)]);
    });

    test('sort is stable: ties broken alphabetically by ICAO ascending', () {
      // AAL, BAW, CCA all with count 1 → expect alphabetical order so the UI
      // doesn't flap between renders.
      final result = aggregateByAirlineIcao([
        _ac('CCA001'),
        _ac('AAL999'),
        _ac('BAW123'),
      ]);
      expect(result.map((e) => e.key).toList(), ['AAL', 'BAW', 'CCA']);
    });

    test('descending count beats alphabetical', () {
      final result = aggregateByAirlineIcao([
        _ac('CCA001'),
        _ac('AAL999'),
        _ac('AAL998'),
        _ac('AAL997'),
        _ac('BAW123'),
        _ac('BAW124'),
      ]);
      _expectEntries(result, [('AAL', 3), ('BAW', 2), ('CCA', 1)]);
    });

    // Bonus assertion: pin _entry as a usable helper for any future test that
    // needs to single out one entry without writing out the full list.
    test('_entry matcher pins both key and value', () {
      final result = aggregateByAirlineIcao([_ac('DLH400'), _ac('DLH401')]);
      expect(result.first, _entry('DLH', 2));
    });
  });
}
