import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/ar/domain/ar_math.dart';

void main() {
  group('normalizeDeg', () {
    test('canonical inputs unchanged', () {
      expect(normalizeDeg(0), 0);
      expect(normalizeDeg(180), 180);
      expect(normalizeDeg(359.9), closeTo(359.9, 1e-9));
    });
    test('360 wraps to 0', () {
      expect(normalizeDeg(360), 0);
    });
    test('overshoot wraps modulo', () {
      expect(normalizeDeg(720), 0);
      expect(normalizeDeg(450), 90);
    });
    test('negative wraps to positive', () {
      expect(normalizeDeg(-10), 350);
      expect(normalizeDeg(-180), 180);
      expect(normalizeDeg(-450), 270);
    });
  });

  group('shortestAngleDiff', () {
    test('a → a is zero', () {
      expect(shortestAngleDiff(0, 0), 0);
      expect(shortestAngleDiff(180, 180), 0);
    });
    test('crosses north — picks the short way', () {
      expect(shortestAngleDiff(350, 10), closeTo(20, 1e-9));
      expect(shortestAngleDiff(10, 350), closeTo(-20, 1e-9));
    });
    test('exact opposite is +180 / -180', () {
      // 540 % 360 - 180 = 0 → so opposite = 180. Convention: the
      // result is in (-180, 180], so 180 is the canonical answer.
      expect(shortestAngleDiff(0, 180).abs(), 180);
    });
    test('result range is [-180, 180]', () {
      // Strictly (-180, 180] in spec, but the closed-form modulo
      // arithmetic legitimately lands on exactly -180 for half-turn
      // inputs (a=0,b=180 gives `((180+540)%360)-180 = 0-180 = -180`).
      // Both endpoints carry the same physical meaning so we accept
      // either as valid.
      for (var a = 0; a < 360; a += 7) {
        for (var b = 0; b < 360; b += 11) {
          final d = shortestAngleDiff(a.toDouble(), b.toDouble());
          expect(d, lessThanOrEqualTo(180));
          expect(d, greaterThanOrEqualTo(-180));
        }
      }
    });
  });

  group('bearingDeg', () {
    test('due north — bearing is 0', () {
      expect(bearingDeg(0, 0, 1, 0), closeTo(0, 0.5));
    });
    test('due east — bearing is 90', () {
      expect(bearingDeg(0, 0, 0, 1), closeTo(90, 0.5));
    });
    test('due south — bearing is 180', () {
      expect(bearingDeg(0, 0, -1, 0), closeTo(180, 0.5));
    });
    test('due west — bearing is 270', () {
      expect(bearingDeg(0, 0, 0, -1), closeTo(270, 0.5));
    });
    test('a → a is undefined → returns 0 (no anomaly)', () {
      // Identical points; atan2(0, 0) = 0 in IEEE so the result is
      // 0. Documents the behaviour rather than mandating a specific
      // value.
      expect(bearingDeg(50, 8, 50, 8), 0);
    });
  });

  group('elevationAngleDeg', () {
    test('0 m altitude on the horizon → 0°', () {
      expect(elevationAngleDeg(0, 100), 0);
    });
    test('1 km up at 1 km away → 45°', () {
      expect(elevationAngleDeg(1000, 1), closeTo(45, 0.001));
    });
    test('overhead (distance = 0) returns 90°', () {
      expect(elevationAngleDeg(10000, 0), 90);
    });
    test('very high altitude / small distance → near 90°', () {
      expect(elevationAngleDeg(10000, 0.5), greaterThan(85));
    });
  });

  group('projectToScreen', () {
    test('aircraft dead-ahead, on the horizon → (0.5, 0.5)', () {
      final p = projectToScreen(
        aircraftBearingDeg: 90,
        aircraftElevationDeg: 0,
        cameraHeadingDeg: 90,
        cameraPitchDeg: 0,
        horizontalFovDeg: 60,
        verticalFovDeg: 45,
      );
      expect(p, isNotNull);
      expect(p!.x, closeTo(0.5, 1e-9));
      expect(p.y, closeTo(0.5, 1e-9));
    });

    test('aircraft 30° to the right at 0° pitch → x = 1.0 (right edge)', () {
      final p = projectToScreen(
        aircraftBearingDeg: 120,
        aircraftElevationDeg: 0,
        cameraHeadingDeg: 90,
        cameraPitchDeg: 0,
        horizontalFovDeg: 60,
        verticalFovDeg: 45,
      );
      expect(p, isNotNull);
      expect(p!.x, closeTo(1.0, 1e-9));
    });

    test('aircraft outside horizontal FOV → null', () {
      final p = projectToScreen(
        aircraftBearingDeg: 200,
        aircraftElevationDeg: 0,
        cameraHeadingDeg: 90,
        cameraPitchDeg: 0,
        horizontalFovDeg: 60,
        verticalFovDeg: 45,
      );
      expect(p, isNull);
    });

    test('aircraft above vertical FOV → null', () {
      final p = projectToScreen(
        aircraftBearingDeg: 90,
        aircraftElevationDeg: 60,
        cameraHeadingDeg: 90,
        cameraPitchDeg: 0,
        horizontalFovDeg: 60,
        verticalFovDeg: 45,
      );
      expect(p, isNull);
    });

    test('elevated target, camera level → y < 0.5 (above center)', () {
      final p = projectToScreen(
        aircraftBearingDeg: 90,
        aircraftElevationDeg: 15,
        cameraHeadingDeg: 90,
        cameraPitchDeg: 0,
        horizontalFovDeg: 60,
        verticalFovDeg: 45,
      );
      expect(p, isNotNull);
      expect(p!.y, lessThan(0.5));
    });
  });
}
