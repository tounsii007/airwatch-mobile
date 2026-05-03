import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/cargo/domain/cargo_filter.dart';

void main() {
  group('isCargoCallsign — known carrier list', () {
    test('all listed carriers match', () {
      for (final code in cargoAirlineIcaoCodes) {
        expect(
          isCargoCallsign('${code}001'),
          isTrue,
          reason: '$code should be cargo',
        );
      }
    });

    test('Lufthansa Cargo (GEC) — listed', () {
      expect(isCargoCallsign('GEC401'), isTrue);
    });

    test('FedEx (FDX) — listed', () {
      expect(isCargoCallsign('FDX1234'), isTrue);
    });

    test('passenger Lufthansa (DLH) — NOT listed', () {
      expect(isCargoCallsign('DLH400'), isFalse);
    });

    test('Air France passenger (AFR) — NOT listed', () {
      expect(isCargoCallsign('AFR123'), isFalse);
    });
  });

  group('isCargoCallsign — input handling', () {
    test('null callsign rejects', () {
      expect(isCargoCallsign(null), isFalse);
    });

    test('empty / whitespace-only callsign rejects', () {
      expect(isCargoCallsign(''), isFalse);
      expect(isCargoCallsign('   '), isFalse);
    });

    test('callsign shorter than 3 chars rejects', () {
      expect(isCargoCallsign('FD'), isFalse);
    });

    test('whitespace around callsign is trimmed', () {
      expect(isCargoCallsign('  FDX1234  '), isTrue);
    });

    test('lowercase callsign — strict reject (real-world ADS-B is upper)', () {
      // The implementation is intentionally case-sensitive — the
      // upstream feed only ever sends uppercase ICAO codes, so a
      // lower-case "fdx" is suspicious data we don't want to tag as
      // cargo on a mistake.
      expect(isCargoCallsign('fdx1234'), isFalse);
    });

    test('callsign with leading non-letter chars is rejected', () {
      // '1FD' — '1'.toUpperCase() is '1', so the upper-case check
      // passes, but the prefix '1FD' isn't in the cargo set →
      // rejected via the prefix lookup.
      expect(isCargoCallsign('1FDX234'), isFalse);
    });
  });

  group('isCargoCallsign — exact 3-char callsign edge', () {
    test('callsign exactly 3 chars matches if it IS a cargo prefix', () {
      expect(isCargoCallsign('FDX'), isTrue);
      expect(isCargoCallsign('UPS'), isTrue);
    });
  });
}
