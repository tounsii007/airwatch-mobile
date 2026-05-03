import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/cargo/domain/cargo_filter.dart';
import 'package:airwatch_mobile/features/cargo/domain/cargo_stats.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Verifies the [isCargoCallsign] predicate that powers the
/// /cargo screen's filtering. Pure logic — no Flutter, no network.
void main() {
  group('isCargoCallsign', () {
    test('classic cargo callsigns hit', () {
      expect(isCargoCallsign('FDX1234'), isTrue, reason: 'FedEx');
      expect(isCargoCallsign('UPS5'), isTrue, reason: 'UPS Airlines');
      expect(isCargoCallsign('GEC123A'), isTrue, reason: 'Lufthansa Cargo');
      expect(isCargoCallsign('DHK99'), isTrue);
      expect(isCargoCallsign('CLX07'), isTrue);
      expect(isCargoCallsign('GTI90'), isTrue);
    });

    test('passenger carriers do not match', () {
      expect(isCargoCallsign('DLH400'), isFalse, reason: 'Lufthansa pax');
      expect(isCargoCallsign('BAW100'), isFalse, reason: 'British Airways');
      expect(isCargoCallsign('AFR1'), isFalse, reason: 'Air France');
      expect(isCargoCallsign('UAL5'), isFalse, reason: 'United');
      expect(isCargoCallsign('AAL3'), isFalse, reason: 'American');
    });

    test('null / blank / too-short input yields false', () {
      expect(isCargoCallsign(null), isFalse);
      expect(isCargoCallsign(''), isFalse);
      expect(isCargoCallsign('A'), isFalse);
      expect(isCargoCallsign('AB'), isFalse);
    });

    test('whitespace around the callsign is tolerated', () {
      expect(isCargoCallsign('  FDX12  '), isTrue);
      expect(isCargoCallsign('\tUPS09\n'), isTrue);
    });

    test('case-sensitivity reflects the source data', () {
      // Real-world callsigns from the upstream feed are uppercase ICAO codes.
      // The predicate intentionally does NOT lowercase — a "fdx12" entry would
      // be treated as suspect and fall through.
      expect(isCargoCallsign('fdx12'), isFalse);
      expect(isCargoCallsign('Fdx12'), isFalse);
    });
  });

  group('cargoAirlineIcaoCodes', () {
    test('every entry is a 3-letter ICAO code', () {
      for (final code in cargoAirlineIcaoCodes) {
        expect(code.length, 3, reason: 'bad code: $code');
        expect(
          RegExp(r'^[A-Z]{3}$').hasMatch(code),
          isTrue,
          reason: 'non-uppercase letters in: $code',
        );
      }
    });

    test('contains the household-name carriers', () {
      expect(cargoAirlineIcaoCodes, contains('FDX'));
      expect(cargoAirlineIcaoCodes, contains('UPS'));
      expect(cargoAirlineIcaoCodes, contains('DHL'));
      expect(cargoAirlineIcaoCodes, contains('CLX'));
    });

    test('is non-empty', () {
      expect(cargoAirlineIcaoCodes, isNotEmpty);
    });
  });

  group('filterCargo', () {
    AircraftState ac(String cs, {bool onGround = false, String? country}) =>
        AircraftState(
          icao24: 'AABBCC',
          callsign: cs,
          onGround: onGround,
          originCountry: country,
        );

    test('all-status filter is a no-op on the search-empty path', () {
      final flights = [ac('FDX1'), ac('UPS5', onGround: true)];
      expect(filterCargo(flights, '', CargoStatusFilter.all), hasLength(2));
    });

    test('airborne filter drops on-ground entries', () {
      final flights = [ac('FDX1'), ac('UPS5', onGround: true)];
      final filtered = filterCargo(flights, '', CargoStatusFilter.airborne);
      expect(filtered, hasLength(1));
      expect(filtered.first.callsign, 'FDX1');
    });

    test('ground filter keeps only on-ground entries', () {
      final flights = [ac('FDX1'), ac('UPS5', onGround: true)];
      final filtered = filterCargo(flights, '', CargoStatusFilter.ground);
      expect(filtered, hasLength(1));
      expect(filtered.first.callsign, 'UPS5');
    });

    test('search matches callsign substring', () {
      final flights = [ac('FDX1234'), ac('UPS5')];
      expect(filterCargo(flights, 'fdx', CargoStatusFilter.all), hasLength(1));
      expect(filterCargo(flights, 'UPS', CargoStatusFilter.all), hasLength(1));
    });

    test('search matches origin country', () {
      final flights = [
        ac('FDX1', country: 'United States'),
        ac('GEC2', country: 'Germany'),
      ];
      final byCountry = filterCargo(flights, 'germany', CargoStatusFilter.all);
      expect(byCountry, hasLength(1));
      expect(byCountry.first.callsign, 'GEC2');
    });
  });

  group('computeCargoStats', () {
    test('counts airborne / ground / operators correctly', () {
      final flights = [
        AircraftState(icao24: 'A1', callsign: 'FDX1234'),
        AircraftState(icao24: 'A2', callsign: 'FDX5678'),
        AircraftState(icao24: 'A3', callsign: 'UPS999', onGround: true),
      ];
      final stats = computeCargoStats(flights);
      expect(stats.total, 3);
      expect(stats.airborne, 2);
      expect(stats.ground, 1);
      expect(stats.operators, 2); // FDX + UPS
    });

    test('empty input gives zero everywhere', () {
      final stats = computeCargoStats(const []);
      expect(stats.total, 0);
      expect(stats.airborne, 0);
      expect(stats.ground, 0);
      expect(stats.operators, 0);
    });
  });
}
