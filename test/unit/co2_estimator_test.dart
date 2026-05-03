import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/core/utils/co2_estimator.dart';

/// Verifies the CO₂ estimation formula matches the web frontend's
/// `useFlightDetailsViewModel.ts` so the two clients show the same
/// numbers for the same flight. Pure math — no Flutter, no network.
void main() {
  group('co2FactorForCategory', () {
    test('heavy aircraft (cat 6) gets 0.08 kg/km', () {
      expect(co2FactorForCategory(6), 0.08);
    });

    test('large aircraft (cat 3) gets 0.12 kg/km', () {
      expect(co2FactorForCategory(3), 0.12);
    });

    test('small aircraft (cat 2) gets 0.15 kg/km', () {
      expect(co2FactorForCategory(2), 0.15);
    });

    test('unknown / null falls back to 0.10 kg/km', () {
      expect(co2FactorForCategory(null), 0.10);
      expect(co2FactorForCategory(0), 0.10);
      expect(co2FactorForCategory(1), 0.10);
      expect(co2FactorForCategory(4), 0.10);
      expect(co2FactorForCategory(7), 0.10);
    });
  });

  group('estimateCo2', () {
    // Frankfurt — Munich (real airports, real coords). Great-circle ~ 305 km.
    const fra = LatLng(50.0379, 8.5622);
    const muc = LatLng(48.354, 11.786);

    test('returns null when departure is missing', () {
      expect(
        estimateCo2(departure: null, arrival: muc, aircraftCategory: 3),
        isNull,
      );
    });

    test('returns null when arrival is missing', () {
      expect(
        estimateCo2(departure: fra, arrival: null, aircraftCategory: 3),
        isNull,
      );
    });

    test('returns null when both endpoints are the same point (<1 km)', () {
      expect(
        estimateCo2(departure: fra, arrival: fra, aircraftCategory: 3),
        isNull,
      );
    });

    test('FRA → MUC large-jet (cat 3) gives ~37 kg CO₂', () {
      // ~305 km × 0.12 kg/km ≈ 37 kg.
      final est = estimateCo2(
        departure: fra,
        arrival: muc,
        aircraftCategory: 3,
      );
      expect(est, isNotNull);
      expect(est!.distKm, closeTo(305, 5));
      expect(est.co2Kg, closeTo(37, 3));
    });

    test(
      'Heavy widebody (cat 6) emits less per km than a small jet (cat 2)',
      () {
        // Same route, two different categories → category 6 should give a
        // smaller kg figure (better load factor) than category 2.
        final heavy = estimateCo2(
          departure: fra,
          arrival: muc,
          aircraftCategory: 6,
        );
        final small = estimateCo2(
          departure: fra,
          arrival: muc,
          aircraftCategory: 2,
        );
        expect(heavy, isNotNull);
        expect(small, isNotNull);
        expect(heavy!.co2Kg, lessThan(small!.co2Kg));
      },
    );

    test('Long-haul scaling — JFK → LHR gives ~5500 km × 0.12 = ~660 kg', () {
      const jfk = LatLng(40.6413, -73.7781);
      const lhr = LatLng(51.4700, -0.4543);
      final est = estimateCo2(
        departure: jfk,
        arrival: lhr,
        aircraftCategory: 3,
      );
      expect(est, isNotNull);
      // Real great-circle distance ≈ 5547 km; tolerate ±50 km for
      // haversine vs. WGS-84 differences.
      expect(est!.distKm, closeTo(5547, 50));
      expect(est.co2Kg, closeTo(665, 8));
    });

    test('result fields are integer-rounded', () {
      final est = estimateCo2(
        departure: fra,
        arrival: muc,
        aircraftCategory: 3,
      );
      expect(est, isNotNull);
      expect(est!.distKm, isA<int>());
      expect(est.co2Kg, isA<int>());
    });
  });
}
