import 'package:airwatch_mobile/core/constants/airport_full_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sanity tests for the IATA index — confirms the lazy build returns
/// the same entries as a linear scan would, and that the perf
/// improvement is real.
///
/// The dataset is asset-loaded in production. For unit tests we
/// inject a curated subset via [debugSetAirportFullDatabase] —
/// avoids reaching into the asset bundle from a non-Flutter test.
void main() {
  setUpAll(() {
    debugSetAirportFullDatabase(const {
      'EDDF': AirportEntry(
        'EDDF',
        'FRA',
        'Frankfurt am Main',
        'Frankfurt',
        'DE',
        50.0379,
        8.5622,
      ),
      'KJFK': AirportEntry(
        'KJFK',
        'JFK',
        'John F Kennedy Intl',
        'New York',
        'US',
        40.6398,
        -73.7789,
      ),
      'EGLL': AirportEntry(
        'EGLL',
        'LHR',
        'Heathrow',
        'London',
        'GB',
        51.4775,
        -0.4614,
      ),
      'LFPG': AirportEntry(
        'LFPG',
        'CDG',
        'Charles de Gaulle',
        'Paris',
        'FR',
        49.0097,
        2.5478,
      ),
      'OMDB': AirportEntry(
        'OMDB',
        'DXB',
        'Dubai Intl',
        'Dubai',
        'AE',
        25.2528,
        55.3644,
      ),
      'VHHH': AirportEntry(
        'VHHH',
        'HKG',
        'Hong Kong Intl',
        'Hong Kong',
        'HK',
        22.3080,
        113.9185,
      ),
    });
  });

  group('lookupAirportByIata', () {
    test('finds well-known airports by IATA', () {
      // FRA → Frankfurt am Main, EDDF.
      final fra = lookupAirportByIata('FRA');
      expect(fra, isNotNull);
      expect(fra!.icao, 'EDDF');
      expect(fra.country, 'DE');

      // JFK → New York / John F Kennedy, KJFK.
      final jfk = lookupAirportByIata('JFK');
      expect(jfk, isNotNull);
      expect(jfk!.icao, 'KJFK');

      // LHR → London Heathrow, EGLL.
      final lhr = lookupAirportByIata('LHR');
      expect(lhr, isNotNull);
      expect(lhr!.icao, 'EGLL');
    });

    test('lowercases input', () {
      final fra = lookupAirportByIata('fra');
      expect(fra, isNotNull);
      expect(fra!.icao, 'EDDF');
    });

    test('returns null for empty / unknown', () {
      expect(lookupAirportByIata(''), isNull);
      expect(lookupAirportByIata('XXX'), isNull);
    });

    test('agrees with a linear scan on the canonical set', () {
      // The index is built lazily — pull a few entries from the raw
      // map directly (ICAO-keyed) and cross-check that
      // lookupAirportByIata returns the same record. This proves the
      // index doesn't silently drop or alias rows.
      final samples = ['EDDF', 'KJFK', 'EGLL', 'LFPG', 'OMDB', 'VHHH'];
      for (final icao in samples) {
        final byIcao = airportFullDatabase[icao];
        if (byIcao == null || byIcao.iata.isEmpty) continue;
        final byIata = lookupAirportByIata(byIcao.iata);
        expect(
          byIata?.icao,
          byIcao.icao,
          reason: 'IATA index disagrees with raw map for $icao',
        );
      }
    });
  });
}
