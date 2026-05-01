import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

AircraftState _ac({
  required double lat,
  required double lon,
  String? callsign,
  double? baroAltitudeMeters,
}) {
  return AircraftState(
    icao24: 'AABBCC',
    callsign: callsign,
    latitude: lat,
    longitude: lon,
    baroAltitude: baroAltitudeMeters,
  );
}

void main() {
  group('aircraftIsInsideFence — circle', () {
    final fence = GeoFence(
      id: 'f1',
      name: 'Frankfurt 50km',
      type: GeoFenceType.circle,
      centerLat: 50.0379,
      centerLon: 8.5622,
      radiusKm: 50,
    );

    test('aircraft inside the radius matches', () {
      // ~30 km north of FRA — well inside 50 km.
      expect(aircraftIsInsideFence(_ac(lat: 50.30, lon: 8.5622), fence), isTrue);
    });

    test('aircraft outside the radius does not match', () {
      // ~150 km away.
      expect(aircraftIsInsideFence(_ac(lat: 51.4, lon: 9.5), fence), isFalse);
    });

    test('disabled fence never matches', () {
      final disabled = fence.copyWith(active: false);
      expect(aircraftIsInsideFence(_ac(lat: 50.04, lon: 8.56), disabled), isFalse);
    });
  });

  group('aircraftIsInsideFence — rectangle', () {
    final box = GeoFence(
      id: 'f2',
      name: 'DACH box',
      type: GeoFenceType.rectangle,
      northLat: 55.0,
      southLat: 45.0,
      eastLon: 17.0,
      westLon: 5.0,
    );

    test('inside box matches', () {
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 10), box), isTrue);
    });

    test('outside box does not match', () {
      expect(aircraftIsInsideFence(_ac(lat: 60, lon: 10), box), isFalse);
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 20), box), isFalse);
    });
  });

  group('altitude band filter', () {
    final fence = GeoFence(
      id: 'f3',
      name: 'High-altitude only',
      type: GeoFenceType.circle,
      centerLat: 50,
      centerLon: 8,
      radiusKm: 100,
      minAltitudeFt: 30000,
    );

    test('aircraft above the floor matches', () {
      // 35,000 ft = ~10,668 m
      final ac = _ac(lat: 50, lon: 8, baroAltitudeMeters: 10668);
      expect(aircraftIsInsideFence(ac, fence), isTrue);
    });

    test('aircraft below the floor is rejected', () {
      // 20,000 ft = ~6,096 m
      final ac = _ac(lat: 50, lon: 8, baroAltitudeMeters: 6096);
      expect(aircraftIsInsideFence(ac, fence), isFalse);
    });

    test('aircraft with no altitude data fails the band check', () {
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8), fence), isFalse);
    });
  });

  group('airline filter', () {
    final fence = GeoFence(
      id: 'f4',
      name: 'Lufthansa only',
      type: GeoFenceType.circle,
      centerLat: 50,
      centerLon: 8,
      radiusKm: 200,
      airlineFilter: 'DLH',
    );

    test('matching callsign passes', () {
      final ac = _ac(lat: 50, lon: 8, callsign: 'DLH400');
      expect(aircraftIsInsideFence(ac, fence), isTrue);
    });

    test('non-matching callsign fails', () {
      final ac = _ac(lat: 50, lon: 8, callsign: 'AFR123');
      expect(aircraftIsInsideFence(ac, fence), isFalse);
    });

    test('missing callsign fails the airline check', () {
      expect(aircraftIsInsideFence(_ac(lat: 50, lon: 8), fence), isFalse);
    });
  });

  group('GeoFence.toJson / fromJson roundtrip', () {
    test('circle survives encode + decode', () {
      final f = GeoFence(
        id: 'f5',
        name: 'Test',
        type: GeoFenceType.circle,
        centerLat: 1.0,
        centerLon: 2.0,
        radiusKm: 50.0,
        minAltitudeFt: 10000,
        airlineFilter: 'DLH',
      );
      final back = GeoFence.fromJson(f.toJson());
      expect(back.id, f.id);
      expect(back.type, f.type);
      expect(back.centerLat, 1.0);
      expect(back.centerLon, 2.0);
      expect(back.radiusKm, 50.0);
      expect(back.airlineFilter, 'DLH');
      expect(back.active, isTrue);
    });

    test('rectangle survives encode + decode', () {
      final f = GeoFence(
        id: 'f6',
        name: 'Box',
        type: GeoFenceType.rectangle,
        northLat: 55,
        southLat: 45,
        eastLon: 17,
        westLon: 5,
      );
      final back = GeoFence.fromJson(f.toJson());
      expect(back.type, GeoFenceType.rectangle);
      expect(back.northLat, 55);
      expect(back.westLon, 5);
    });
  });

  // Sanity check that LatLng + position bind together; ensures the
  // helper's nullability handling matches the AircraftState API.
  test('AircraftState.position returns LatLng when both fields set', () {
    final ac = _ac(lat: 1.0, lon: 2.0);
    expect(ac.position, isA<LatLng>());
    expect(ac.position!.latitude, 1.0);
  });
}
