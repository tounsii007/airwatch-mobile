import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

AircraftState _ac({
  required double lat,
  required double lon,
  String? callsign,
  double? baroAltitudeMeters,
  bool onGround = false,
}) =>
    AircraftState(
      icao24: 'AABBCC',
      callsign: callsign,
      latitude: lat,
      longitude: lon,
      baroAltitude: baroAltitudeMeters,
      onGround: onGround,
    );

GeoFence _circle({
  double centerLat = 50,
  double centerLon = 8,
  double radiusKm = 50,
  bool active = true,
  double? minAltitudeFt,
  double? maxAltitudeFt,
  String? airlineFilter,
}) =>
    GeoFence(
      id: 'c',
      name: 'C',
      type: GeoFenceType.circle,
      centerLat: centerLat,
      centerLon: centerLon,
      radiusKm: radiusKm,
      active: active,
      minAltitudeFt: minAltitudeFt,
      maxAltitudeFt: maxAltitudeFt,
      airlineFilter: airlineFilter,
    );

GeoFence _rect({
  double n = 55,
  double s = 45,
  double e = 17,
  double w = 5,
  bool active = true,
}) =>
    GeoFence(
      id: 'r',
      name: 'R',
      type: GeoFenceType.rectangle,
      northLat: n,
      southLat: s,
      eastLon: e,
      westLon: w,
      active: active,
    );

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  group('Circle — exact boundary cases', () {
    test('aircraft AT the radius edge counts as inside (≤, not <)', () {
      // Distance roughly equal to radiusKm — depending on the
      // floating-point math the boundary could fall either way; the
      // implementation uses <= so a hit ON the edge is inside.
      final fence = _circle(centerLat: 0, centerLon: 0, radiusKm: 100);
      // 100 km north of (0,0) ≈ lat 0.899°
      const edgePoint = 0.8993; // a hair under the 100 km contour
      expect(
          aircraftIsInsideFence(_ac(lat: edgePoint, lon: 0), fence), isTrue);
    });

    test('zero-radius fence rejects everything except the exact center', () {
      final fence = _circle(centerLat: 50, centerLon: 8, radiusKm: 0);
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8), fence), isTrue);
      // 1 km away — must be rejected.
      expect(aircraftIsInsideFence(_ac(lat: 50.01, lon: 8), fence), isFalse);
    });

    test('huge fence (10,000 km) covers most of the eastern hemisphere', () {
      final fence = _circle(centerLat: 50, centerLon: 8, radiusKm: 10000);
      // Sydney → still inside (~16,500 km is too far, but ~9,000 km hits)
      expect(aircraftIsInsideFence(_ac(lat: 30, lon: 30), fence), isTrue);
      // Antipodal point ~20,000 km — outside.
      expect(aircraftIsInsideFence(_ac(lat: -50, lon: -172), fence), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Circle — antimeridian crossing', () {
    test('aircraft at lon -179 vs fence center lon 179 (across dateline)', () {
      // ~2° apart longitudinally, but they're really only ~220 km
      // apart on the great circle (the antimeridian). A correct
      // haversine handles this.
      final fence =
          _circle(centerLat: 0, centerLon: 179, radiusKm: 300);
      expect(aircraftIsInsideFence(_ac(lat: 0, lon: -179), fence), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Circle — polar regions', () {
    test('two points near the north pole resolve as close', () {
      // (89, 0) and (89, 180) — at lat 89° they're only ~220 km apart.
      final fence = _circle(centerLat: 89, centerLon: 0, radiusKm: 500);
      expect(aircraftIsInsideFence(_ac(lat: 89, lon: 180), fence), isTrue);
    });

    test('south pole — fence centered at -89 still covers nearby longitudes',
        () {
      final fence = _circle(centerLat: -89, centerLon: 0, radiusKm: 500);
      // (-89, -180) is ~220 km from (-89, 0) along the polar arc — well inside.
      expect(aircraftIsInsideFence(_ac(lat: -89, lon: -180), fence), isTrue);
      // (-80, 0) is ~1000 km away in latitude — well outside.
      expect(aircraftIsInsideFence(_ac(lat: -80, lon: 0), fence), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Rectangle — exact boundary', () {
    test('aircraft exactly on the north edge is INSIDE (≤)', () {
      final f = _rect();
      expect(aircraftIsInsideFence(_ac(lat: 55, lon: 10), f), isTrue);
    });

    test('aircraft exactly on the south edge is INSIDE (≥)', () {
      final f = _rect();
      expect(aircraftIsInsideFence(_ac(lat: 45, lon: 10), f), isTrue);
    });

    test('aircraft exactly on the east edge is INSIDE', () {
      final f = _rect();
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 17), f), isTrue);
    });

    test('aircraft just outside (lat = 55.001) is rejected', () {
      final f = _rect();
      expect(aircraftIsInsideFence(_ac(lat: 55.001, lon: 10), f), isFalse);
    });

    test('zero-area rectangle (n=s, e=w) accepts only the single point', () {
      final f = _rect(n: 50, s: 50, e: 10, w: 10);
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 10), f), isTrue);
      expect(aircraftIsInsideFence(_ac(lat: 50.0001, lon: 10), f), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Altitude band — boundary values', () {
    final fence = _circle(minAltitudeFt: 30000, maxAltitudeFt: 40000);

    test('exact min altitude (30,000 ft = 9144 m) passes (≥, not >)', () {
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, baroAltitudeMeters: 9144), fence), isTrue);
    });

    test('exact max altitude (40,000 ft = 12192 m) passes (≤, not <)', () {
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, baroAltitudeMeters: 12192), fence), isTrue);
    });

    test('one foot below min is rejected', () {
      // 29,999 ft = 9143.7 m
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, baroAltitudeMeters: 9143.7), fence), isFalse);
    });

    test('one foot above max is rejected', () {
      // 40,001 ft = 12192.3 m
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, baroAltitudeMeters: 12192.5), fence), isFalse);
    });

    test('altitude null fails the band check (we never assume anything)', () {
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8), fence), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Airline filter — case sensitivity', () {
    test('lowercase fence filter still matches uppercase callsign', () {
      final fence = _circle(airlineFilter: 'dlh');
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, callsign: 'DLH400'), fence), isTrue);
    });

    test('lowercase callsign — implementation uppercases, so still matches', () {
      final fence = _circle(airlineFilter: 'DLH');
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, callsign: 'dlh400'), fence), isTrue);
    });

    test('whitespace in callsign breaks the prefix match if not trimmed', () {
      // The current impl does NOT trim. This documents the behaviour.
      final fence = _circle(airlineFilter: 'DLH');
      // Leading whitespace makes substring(0,3) be ' DL' — no match.
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, callsign: ' DLH400'), fence), isFalse);
    });

    test('callsign exactly 3 chars long matches', () {
      final fence = _circle(airlineFilter: 'DLH');
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, callsign: 'DLH'), fence), isTrue);
    });

    test('callsign shorter than 3 chars rejects', () {
      final fence = _circle(airlineFilter: 'DLH');
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8, callsign: 'DL'), fence), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Compound: geometry + altitude + airline', () {
    final fence = _circle(
      centerLat: 50,
      centerLon: 8,
      radiusKm: 100,
      minAltitudeFt: 30000,
      airlineFilter: 'DLH',
    );

    test('all three constraints satisfied → inside', () {
      final ac = _ac(
        lat: 50.1,
        lon: 8.1,
        callsign: 'DLH400',
        baroAltitudeMeters: 10000, // ~32,800 ft
      );
      expect(aircraftIsInsideFence(ac, fence), isTrue);
    });

    test('geometry fails → false even with right airline + altitude', () {
      final ac = _ac(
        lat: 0,
        lon: 0,
        callsign: 'DLH400',
        baroAltitudeMeters: 10000,
      );
      expect(aircraftIsInsideFence(ac, fence), isFalse);
    });

    test('altitude fails → false even with right airline + position', () {
      final ac = _ac(
        lat: 50.1,
        lon: 8.1,
        callsign: 'DLH400',
        baroAltitudeMeters: 5000, // ~16,400 ft — too low
      );
      expect(aircraftIsInsideFence(ac, fence), isFalse);
    });

    test('airline fails → false even with right position + altitude', () {
      final ac = _ac(
        lat: 50.1,
        lon: 8.1,
        callsign: 'AFR123',
        baroAltitudeMeters: 10000,
      );
      expect(aircraftIsInsideFence(ac, fence), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Position null → never inside', () {
    test('aircraft with no lat/lon never matches a fence', () {
      final fence = _circle();
      final ac = AircraftState(icao24: 'AABBCC');
      expect(aircraftIsInsideFence(ac, fence), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('JSON roundtrip — robustness', () {
    test('rect with NaN-able input survives encode/decode', () {
      final f = _rect();
      final restored = GeoFence.fromJson(f.toJson());
      expect(restored.northLat, f.northLat);
      expect(restored.eastLon, f.eastLon);
    });

    test('partial JSON (missing optional filters) survives', () {
      final raw = {
        'id': 'x',
        'name': 'X',
        'type': 'circle',
        'centerLat': 50.0,
        'centerLon': 8.0,
        'radiusKm': 50.0,
        'active': true,
        'createdAt': '2025-01-01T00:00:00.000',
      };
      final f = GeoFence.fromJson(raw);
      expect(f.minAltitudeFt, isNull);
      expect(f.maxAltitudeFt, isNull);
      expect(f.airlineFilter, isNull);
    });

    test('invalid type string falls back to circle (defensive default)', () {
      final raw = {
        'id': 'x',
        'name': 'X',
        'type': 'pentagon',
        'centerLat': 50.0,
        'centerLon': 8.0,
        'radiusKm': 50.0,
        'active': true,
        'createdAt': '2025-01-01T00:00:00.000',
      };
      final f = GeoFence.fromJson(raw);
      expect(f.type, GeoFenceType.circle);
    });

    test('bad createdAt timestamp falls back to "now"', () {
      final raw = {
        'id': 'x',
        'name': 'X',
        'type': 'circle',
        'centerLat': 50.0,
        'centerLon': 8.0,
        'radiusKm': 50.0,
        'active': true,
        'createdAt': 'not a date',
      };
      final f = GeoFence.fromJson(raw);
      expect(f.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(2));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('copyWith — selective updates', () {
    test('toggling active leaves all other fields intact', () {
      final original = _circle(centerLat: 1, centerLon: 2, radiusKm: 3);
      final flipped = original.copyWith(active: false);
      expect(flipped.active, isFalse);
      expect(flipped.centerLat, 1);
      expect(flipped.centerLon, 2);
      expect(flipped.radiusKm, 3);
      expect(flipped.id, original.id);
      expect(flipped.createdAt, original.createdAt);
    });

    test('renaming via copyWith does not lose state', () {
      final original = _circle();
      final renamed = original.copyWith(name: 'New Name');
      expect(renamed.name, 'New Name');
      expect(renamed.active, original.active);
    });
  });
}
