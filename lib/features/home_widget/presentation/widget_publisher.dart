import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/features/home_widget/data/home_widget_service.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Watches the live aircraft feed and republishes a compact summary
/// to the home-screen widget every ~30 s while the app is running.
///
/// <p>Wrapped at the app's top level via [installHomeWidgetPublisher].
/// When the app is backgrounded, Android keeps the last-published
/// values around in SharedPreferences and the widget continues
/// rendering them — so the user gets a useful at-a-glance readout
/// even without opening the app.
class HomeWidgetPublisher extends StatefulWidget {
  const HomeWidgetPublisher({super.key, required this.child});
  final Widget child;

  @override
  State<HomeWidgetPublisher> createState() => _HomeWidgetPublisherState();
}

class _HomeWidgetPublisherState extends State<HomeWidgetPublisher> {
  Timer? _publishTimer;

  @override
  void initState() {
    super.initState();
    // Throttle to every 30 s — Android widget refresh requests beyond
    // ~30 min/day get rate-limited by the system anyway, but a more
    // frequent in-app cadence means the widget is always fresh when
    // the user returns to the home screen.
    _publishTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _publish());
  }

  @override
  void dispose() {
    _publishTimer?.cancel();
    super.dispose();
  }

  void _publish() {
    final container = ProviderScope.containerOf(context);
    final asyncFlights = container.read(aircraftStreamProvider);
    final flights = asyncFlights.value;
    if (flights == null) return;

    final airlineCounts = <String, int>{};
    for (final ac in flights.values) {
      final cs = (ac.callsign ?? '').trim().toUpperCase();
      if (cs.length < 3) continue;
      final icao = cs.substring(0, 3);
      airlineCounts[icao] = (airlineCounts[icao] ?? 0) + 1;
    }

    final top = airlineCounts.entries.fold<MapEntry<String, int>?>(
      null,
      (acc, e) => (acc == null || e.value > acc.value) ? e : acc,
    );

    HomeWidgetService.instance.publish(HomeWidgetPayload(
      liveFlights: flights.length,
      topAirlineIcao: top?.key,
      topAirlineCount: top?.value ?? 0,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Convenience helper used in app.dart.
Widget installHomeWidgetPublisher({required Widget child}) =>
    HomeWidgetPublisher(child: child);

// keep the import graph honest — `AircraftState` is used transitively
// through aircraftStreamProvider but not directly here. Import is
// retained for future expansion (e.g. publishing the closest-to-user
// flight). Helper isn't called from outside.
// ignore: unused_element
void _typeAnchor(AircraftState _) {}
