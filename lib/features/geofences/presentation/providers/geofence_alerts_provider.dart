import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// One live geofence intrusion. The pair `(aircraft, fence)` is enough
/// to render a banner: the alert hub uses it to show "DLH400 entered
/// Frankfurt 50 km".
class GeoFenceHit {
  final AircraftState aircraft;
  final GeoFence fence;
  const GeoFenceHit(this.aircraft, this.fence);
}

/// Live list of every aircraft that's currently inside an active
/// geofence.
///
/// <p>Mirrors the web frontend's `useGeoFenceAlerts` hook — combines
/// the live flight feed with the user's saved fences and runs the
/// `aircraftIsInsideFence` predicate on every tick. Returns an empty
/// list when there are no fences or the live feed is loading; that's
/// all the consumers need to render their banners + bell badge.
final geofenceAlertsProvider = Provider<List<GeoFenceHit>>((ref) {
  final fences = ref.watch(geofencesProvider);
  if (fences.isEmpty) return const [];

  final asyncFlights = ref.watch(aircraftStreamProvider);
  final flights = asyncFlights.value ?? const <String, AircraftState>{};
  if (flights.isEmpty) return const [];

  final hits = <GeoFenceHit>[];
  for (final ac in flights.values) {
    if (ac.position == null) continue;
    for (final f in fences) {
      if (!f.active) continue;
      if (aircraftIsInsideFence(ac, f)) {
        hits.add(GeoFenceHit(ac, f));
      }
    }
  }
  return hits;
});
