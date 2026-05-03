import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/airport/data/recent_airports_repository.dart';

void main() {
  group('RecentAirport', () {
    test('toJson / fromJson roundtrip preserves all fields', () {
      final r = RecentAirport(
        iata: 'CDG',
        city: 'Paris',
        country: 'France',
        visitedAt: DateTime.utc(2025, 1, 1, 12),
      );
      final back = RecentAirport.fromJson(r.toJson());
      expect(back.iata, 'CDG');
      expect(back.city, 'Paris');
      expect(back.country, 'France');
      expect(back.visitedAt, DateTime.utc(2025, 1, 1, 12));
    });

    test('visitedAt defaults to now when not given', () {
      final r = RecentAirport(iata: 'CDG');
      expect(
        r.visitedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('legacy v1 payload (missing visitedAt) parses to now', () {
      final r = RecentAirport.fromJson({
        'iata': 'CDG',
        'city': null,
        'country': null,
        // visitedAt key missing
      });
      expect(r.iata, 'CDG');
      expect(
        r.visitedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });
  });
}
