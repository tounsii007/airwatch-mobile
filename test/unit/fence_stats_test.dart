import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/features/geofences/domain/fence_stats.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/geofences/presentation/providers/geofence_alerts_provider.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Mirrors airwatch-web's `fenceStats.test.ts` (commit 982c6d2).

AircraftState _ac({
  required String icao24,
  required String callsign,
  double altMeters = 10000,
  double lat = 50,
  double lon = 8,
}) {
  return AircraftState(
    icao24: icao24,
    callsign: callsign,
    latitude: lat,
    longitude: lon,
    baroAltitude: altMeters,
  );
}

GeoFence _fence(String id) => GeoFence(
      id: id,
      name: 'Test fence $id',
      type: GeoFenceType.circle,
      centerLat: 50,
      centerLon: 8,
      radiusKm: 100,
    );

void main() {
  group('computeFenceStats', () {
    test('returns the empty sentinel when no hits target this fence', () {
      final hits = <GeoFenceHit>[];
      final stats = computeFenceStats(hits, 'f1');
      expect(stats.total, 0);
      expect(stats.topAirline, isNull);
      expect(stats.uniqueAircraft, 0);
      expect(stats.latestAt, isNull);
      expect(stats.avgAltitudeMeters, isNull);
    });

    test('only counts hits whose fence id matches', () {
      final fA = _fence('a');
      final fB = _fence('b');
      final hits = [
        GeoFenceHit(_ac(icao24: '1', callsign: 'DLH1'), fA),
        GeoFenceHit(_ac(icao24: '2', callsign: 'DLH2'), fB),
      ];
      final s = computeFenceStats(hits, 'a');
      expect(s.total, 1);
      expect(s.uniqueAircraft, 1);
    });

    test('dedupes aircraft by icao24', () {
      final f = _fence('a');
      // Two hits, same icao24 — counts as one unique aircraft.
      final hits = [
        GeoFenceHit(_ac(icao24: '1', callsign: 'DLH1'), f),
        GeoFenceHit(_ac(icao24: '1', callsign: 'DLH2'), f),
      ];
      final s = computeFenceStats(hits, 'a');
      expect(s.total, 2);
      expect(s.uniqueAircraft, 1);
    });

    test('picks the most-frequent airline ICAO from callsign prefixes', () {
      final f = _fence('a');
      final hits = [
        GeoFenceHit(_ac(icao24: '1', callsign: 'DLH1'), f),
        GeoFenceHit(_ac(icao24: '2', callsign: 'DLH2'), f),
        GeoFenceHit(_ac(icao24: '3', callsign: 'BAW9'), f),
      ];
      final s = computeFenceStats(hits, 'a');
      expect(s.topAirline?.code, 'DLH');
      expect(s.topAirline?.count, 2);
    });

    test('returns null topAirline when no callsign has 3+ chars', () {
      final f = _fence('a');
      final hits = [
        GeoFenceHit(_ac(icao24: '1', callsign: 'AB'), f),
      ];
      final s = computeFenceStats(hits, 'a');
      expect(s.topAirline, isNull);
    });

    test('averages altitudes across the matching hits', () {
      final f = _fence('a');
      final hits = [
        GeoFenceHit(_ac(icao24: '1', callsign: 'DLH1'), f),
        GeoFenceHit(_ac(icao24: '2', callsign: 'DLH2', altMeters: 20000), f),
      ];
      final s = computeFenceStats(hits, 'a');
      expect(s.avgAltitudeMeters, 15000);
    });

    test('skips alt averaging when every hit lacks baroAltitude', () {
      final f = _fence('a');
      final hits = [
        GeoFenceHit(
          AircraftState(
            icao24: '1',
            callsign: 'DLH1',
            latitude: 50,
            longitude: 8,
            // baroAltitude omitted on purpose
          ),
          f,
        ),
      ];
      final s = computeFenceStats(hits, 'a');
      expect(s.avgAltitudeMeters, isNull);
    });

    test('latestAt is non-null whenever total > 0', () {
      final f = _fence('a');
      final hits = [
        GeoFenceHit(_ac(icao24: '1', callsign: 'DLH1'), f),
      ];
      final s = computeFenceStats(
        hits,
        'a',
        now: DateTime.utc(2026, 5, 14, 12),
      );
      expect(s.latestAt, DateTime.utc(2026, 5, 14, 12));
    });
  });

  // Sanity-check that the LatLng type chain still compiles — the
  // computeFenceStats imports leak transitively through the geofences
  // provider; if either side drifts (latlong2 major), the test
  // surfaces it.
  test('LatLng helper is still wire-compatible', () {
    const p = LatLng(50.0, 8.0);
    expect(p.latitude, 50.0);
  });
}
