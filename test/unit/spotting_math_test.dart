import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/spotting/presentation/screens/spotting_screen.dart';

/// Verifies the great-circle helpers used by the spotting screen. Pure
/// math functions, no Flutter or network dependencies.
void main() {
  group('haversineKm', () {
    test('distance from a point to itself is zero', () {
      expect(haversineKm(48.8566, 2.3522, 48.8566, 2.3522), closeTo(0, 1e-6));
    });

    test('Paris-CDG ↔ Frankfurt-FRA is ~447 km (±2 km tolerance)', () {
      // Real-world reference: 447 km airport-to-airport on a great circle.
      // The previous version of this test mixed Paris CITY (48.8566) with
      // Frankfurt AIRPORT (50.0379) — those two coords are actually 468 km
      // apart, so the assertion never matched 447. Now both endpoints are
      // the airports themselves so the expected distance is consistent.
      const cdg = (49.0097, 2.5479);
      const fra = (50.0379, 8.5622);
      final d = haversineKm(cdg.$1, cdg.$2, fra.$1, fra.$2);
      expect(d, closeTo(447, 2));
    });

    test('London ↔ New York is ~5570 km (±15 km tolerance)', () {
      const london = (51.5074, -0.1278);
      const ny = (40.7128, -74.0060);
      final d = haversineKm(london.$1, london.$2, ny.$1, ny.$2);
      expect(d, closeTo(5570, 15));
    });

    test('symmetric — A→B equals B→A', () {
      final ab = haversineKm(48.8566, 2.3522, 51.5074, -0.1278);
      final ba = haversineKm(51.5074, -0.1278, 48.8566, 2.3522);
      expect(ab, closeTo(ba, 1e-6));
    });
  });

  group('bearingDeg', () {
    test('bearing from a point to a point due-north is ~0°', () {
      // Paris → due north (same longitude, +1° latitude).
      final b = bearingDeg(48.8566, 2.3522, 49.8566, 2.3522);
      expect(b, closeTo(0, 1));
    });

    test('bearing from Paris due-east is ~90°', () {
      final b = bearingDeg(48.8566, 2.3522, 48.8566, 3.3522);
      expect(b, closeTo(90, 1));
    });

    test('bearing from Paris due-south is ~180°', () {
      final b = bearingDeg(48.8566, 2.3522, 47.8566, 2.3522);
      expect(b, closeTo(180, 1));
    });

    test('bearing from Paris due-west is ~270°', () {
      final b = bearingDeg(48.8566, 2.3522, 48.8566, 1.3522);
      expect(b, closeTo(270, 1));
    });

    test('result is always in [0, 360)', () {
      for (final delta in const [-5.0, -1.0, 1.0, 5.0]) {
        final b = bearingDeg(0, 0, delta, delta);
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
      }
    });
  });
}
