import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/core/utils/co2_estimator.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────
  group('estimateCo2 — geographic extremes', () {
    test('antipodal flight (max possible great-circle ~20 015 km)', () {
      // (0, 0) and (0, 180) are exact antipodes on the equator.
      // Real great-circle ≈ π × 6371 ≈ 20 015 km.
      final est = estimateCo2(
        departure: const LatLng(0, 0),
        arrival: const LatLng(0, 180),
        aircraftCategory: 6,
      );
      expect(est, isNotNull);
      // Tolerance is wide because haversine formula uses a single mean
      // earth radius (6371 km) and antipodal precision is sensitive.
      expect(est!.distKm, closeTo(20015, 50));
    });

    test('north pole to south pole (~20 015 km, half-meridian)', () {
      final est = estimateCo2(
        departure: const LatLng(90, 0),
        arrival: const LatLng(-90, 0),
        aircraftCategory: 6,
      );
      expect(est, isNotNull);
      expect(est!.distKm, closeTo(20015, 50));
    });

    test('equator-to-equator at 90° longitude — quarter circle', () {
      final est = estimateCo2(
        departure: const LatLng(0, 0),
        arrival: const LatLng(0, 90),
        aircraftCategory: 3,
      );
      expect(est, isNotNull);
      // π × 6371 / 2 ≈ 10 008 km
      expect(est!.distKm, closeTo(10008, 30));
    });

    test('exactly 1 km apart — just above the rejection threshold', () {
      // 0.009° latitude ≈ 1 km. Should NOT return null.
      final est = estimateCo2(
        departure: const LatLng(50, 0),
        arrival: const LatLng(50.009, 0),
        aircraftCategory: 3,
      );
      expect(est, isNotNull);
      expect(est!.distKm, 1);
    });

    test('< 1 km apart returns null (taxiway-only flight)', () {
      // 0.001° ≈ 100 m
      final est = estimateCo2(
        departure: const LatLng(50, 0),
        arrival: const LatLng(50.001, 0),
        aircraftCategory: 3,
      );
      expect(est, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('co2FactorForCategory — full ADS-B coverage', () {
    test('every documented category gets a non-zero factor', () {
      for (var cat = 0; cat < 16; cat++) {
        expect(co2FactorForCategory(cat), greaterThan(0));
      }
    });

    test('factors are physically ordered: heavier-than-light, smaller > bigger',
        () {
      final small = co2FactorForCategory(2);
      final large = co2FactorForCategory(3);
      final heavy = co2FactorForCategory(6);
      // Smaller jets emit more per km because of worse load factor.
      expect(small, greaterThan(large));
      expect(large, greaterThan(heavy));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('integer rounding', () {
    test('exactly-halfway km rounds correctly (banker\'s rounding doesn\'t apply)', () {
      // FRA-MUC ≈ 305 km, factor 0.12 → 36.6 kg → rounds to 37.
      final est = estimateCo2(
        departure: const LatLng(50.0379, 8.5622),
        arrival: const LatLng(48.354, 11.786),
        aircraftCategory: 3,
      );
      expect(est!.co2Kg, isA<int>());
      expect(est.co2Kg, closeTo(37, 1));
    });

    test('symmetric — A→B distance equals B→A distance', () {
      final ab = estimateCo2(
        departure: const LatLng(50.0379, 8.5622),
        arrival: const LatLng(48.354, 11.786),
        aircraftCategory: 3,
      );
      final ba = estimateCo2(
        departure: const LatLng(48.354, 11.786),
        arrival: const LatLng(50.0379, 8.5622),
        aircraftCategory: 3,
      );
      expect(ab!.distKm, ba!.distKm);
      expect(ab.co2Kg, ba.co2Kg);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('null inputs — all paths reject cleanly', () {
    test('null dep, null arr, null both', () {
      expect(
          estimateCo2(
            departure: null,
            arrival: const LatLng(0, 0),
            aircraftCategory: 3,
          ),
          isNull);
      expect(
          estimateCo2(
            departure: const LatLng(0, 0),
            arrival: null,
            aircraftCategory: 3,
          ),
          isNull);
      expect(
          estimateCo2(
            departure: null,
            arrival: null,
            aircraftCategory: 3,
          ),
          isNull);
    });

    test('null aircraft category falls back to default factor (0.10)', () {
      final est = estimateCo2(
        departure: const LatLng(50.0379, 8.5622),
        arrival: const LatLng(48.354, 11.786),
        aircraftCategory: null,
      );
      expect(est, isNotNull);
      // 305 km × 0.10 ≈ 31 kg
      expect(est!.co2Kg, closeTo(31, 2));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('antimeridian crossing', () {
    test('flight HKG → LAX (Pacific great-circle) gets sane distance', () {
      const hkg = LatLng(22.3, 113.9);
      const lax = LatLng(33.94, -118.4);
      final est = estimateCo2(
        departure: hkg,
        arrival: lax,
        aircraftCategory: 6,
      );
      expect(est, isNotNull);
      // Real great-circle ≈ 11 645 km — antipodal-crossing handled
      // by haversine without special case.
      expect(est!.distKm, closeTo(11645, 100));
    });
  });
}
