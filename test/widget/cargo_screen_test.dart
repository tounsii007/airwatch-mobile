import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/cargo/presentation/screens/cargo_screen.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Widget tests for [CargoScreen]. The cargo filter logic itself is
/// covered exhaustively in `test/unit/cargo_filter_test.dart`; here
/// we just verify the screen wires the predicate up to the live stream
/// and renders the right UI states.

AircraftState _ac(String icao24, String? callsign) =>
    AircraftState(icao24: icao24, callsign: callsign);

Widget _harness({
  required Widget child,
  required Map<String, AircraftState> seed,
}) =>
    ProviderScope(
      overrides: [
        aircraftStreamProvider.overrideWith((_) => Stream.value(seed)),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  group('CargoScreen', () {
    testWidgets('shows empty-state when no cargo flight is in the air',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const CargoScreen(),
        // Only a passenger flight present — should not match the cargo filter.
        seed: {'p1': _ac('p1', 'DLH400')},
      ));
      await tester.pumpAndSettle();
      expect(find.text('No cargo flights airborne right now'), findsOneWidget);
    });

    testWidgets('renders only flights whose callsign matches a cargo airline',
        (tester) async {
      final seed = {
        'p1': _ac('p1', 'DLH400'),  // Lufthansa pax — must NOT appear
        'c1': _ac('c1', 'FDX9'),    // FedEx — must appear
        'c2': _ac('c2', 'UPS5'),    // UPS — must appear
        'p2': _ac('p2', 'AFR1'),    // Air France pax — must NOT appear
      };
      await tester.pumpWidget(_harness(child: const CargoScreen(), seed: seed));
      await tester.pumpAndSettle();

      expect(find.text('FDX9'),   findsOneWidget);
      expect(find.text('UPS5'),   findsOneWidget);
      expect(find.text('DLH400'), findsNothing);
      expect(find.text('AFR1'),   findsNothing);
    });
  });
}
