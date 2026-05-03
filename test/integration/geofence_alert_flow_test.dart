import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/geofences/presentation/providers/geofence_alerts_provider.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Geofence alert end-to-end', () {
    test(
      'aircraft inside an active fence appears in geofenceAlertsProvider',
      () async {
        final inside = AircraftState(
          icao24: 'DLH400',
          callsign: 'DLH400',
          latitude: 50.04,
          longitude: 8.56, // 0.3 km from FRA
          baroAltitude: 10000, // ~32,800 ft
        );
        final outside = AircraftState(
          icao24: 'AFR1',
          callsign: 'AFR1',
          latitude: 0,
          longitude: 0,
          baroAltitude: 11000,
        );
        // Override aircraftStreamProvider directly with a stream that
        // emits immediately. Bypasses the datasource layer entirely so
        // the test doesn't depend on Riverpod's listen / emit ordering.
        final container = ProviderContainer(
          overrides: [
            aircraftStreamProvider.overrideWith((ref) {
              return Stream.value({
                inside.icao24: inside,
                outside.icao24: outside,
              });
            }),
          ],
        );
        addTearDown(container.dispose);

        // Add a fence at FRA.
        container
            .read(geofencesProvider.notifier)
            .add(
              GeoFence(
                id: 'fra-50',
                name: 'FRA 50 km',
                type: GeoFenceType.circle,
                centerLat: 50.0379,
                centerLon: 8.5622,
                radiusKm: 50,
              ),
            );

        // Drive the stream to emit by listening + waiting for first
        // non-loading state. Spin the event loop a few times so the
        // synchronous Stream.value emit propagates through Riverpod's
        // internal pipeline.
        container.listen(aircraftStreamProvider, (_, _) {});
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        final hits = container.read(geofenceAlertsProvider);
        expect(hits, hasLength(1));
        expect(hits.first.aircraft.icao24, 'DLH400');
        expect(hits.first.fence.name, 'FRA 50 km');
      },
    );

    test(
      'disabled fence produces no hits even when aircraft is inside',
      () async {
        final inside = AircraftState(
          icao24: 'DLH400',
          callsign: 'DLH400',
          latitude: 50.04,
          longitude: 8.56,
        );
        final container = ProviderContainer(
          overrides: [
            aircraftStreamProvider.overrideWith((ref) {
              return Stream.value({inside.icao24: inside});
            }),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(geofencesProvider.notifier)
            .add(
              GeoFence(
                id: 'fra-paused',
                name: 'FRA paused',
                type: GeoFenceType.circle,
                centerLat: 50.0379,
                centerLon: 8.5622,
                radiusKm: 50,
                active: false,
              ),
            );

        container.listen(aircraftStreamProvider, (_, _) {});
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        expect(container.read(geofenceAlertsProvider), isEmpty);
      },
    );

    test('toggling fence active flips alerts on / off', () async {
      final inside = AircraftState(
        icao24: 'DLH400',
        callsign: 'DLH400',
        latitude: 50.04,
        longitude: 8.56,
      );
      final container = ProviderContainer(
        overrides: [
          aircraftStreamProvider.overrideWith((ref) {
            return Stream.value({inside.icao24: inside});
          }),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(geofencesProvider.notifier)
          .add(
            GeoFence(
              id: 'toggle-test',
              name: 'X',
              type: GeoFenceType.circle,
              centerLat: 50.0379,
              centerLon: 8.5622,
              radiusKm: 50,
            ),
          );
      container.listen(aircraftStreamProvider, (_, _) {});
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(container.read(geofenceAlertsProvider), hasLength(1));

      container.read(geofencesProvider.notifier).toggleActive('toggle-test');
      expect(container.read(geofenceAlertsProvider), isEmpty);

      container.read(geofencesProvider.notifier).toggleActive('toggle-test');
      expect(container.read(geofenceAlertsProvider), hasLength(1));
    });
  });

  // Sanity check that a LatLng helper still works in the test env.
  test('LatLng pair is constructible', () {
    expect(const LatLng(0, 0).latitude, 0);
  });
}
