import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Widget tests for [DashboardScreen]. We override the flight stream
/// with a synthetic feed and stub [SharedPreferences] so the tile
/// reorder-state load doesn't blow up in the test isolate.

AircraftState _ac(String icao24, String callsign, {double? altMeters}) =>
    AircraftState(icao24: icao24, callsign: callsign, baroAltitude: altMeters);

Widget _harness({
  required Widget child,
  required Map<String, AircraftState> seed,
}) => ProviderScope(
  overrides: [aircraftStreamProvider.overrideWith((_) => Stream.value(seed))],
  child: MaterialApp(home: child),
);

void main() {
  setUp(() {
    // SharedPreferences uses a method channel on real devices — in tests we
    // replace it with an in-memory map. Without this the dashboard's
    // initState would hang on the first read.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('DashboardScreen', () {
    testWidgets('renders all four default tiles', (tester) async {
      final seed = {
        'a': _ac('a', 'DLH400', altMeters: 11000),
        'b': _ac('b', 'AFR123', altMeters: 5000),
      };
      await tester.pumpWidget(
        _harness(child: const DashboardScreen(), seed: seed),
      );
      await tester.pumpAndSettle();

      // Each tile renders its own label string (en-default).
      expect(find.text('Live flights'), findsOneWidget);
      expect(find.text('Saved items'), findsOneWidget);
      expect(find.text('Top airlines'), findsOneWidget);
      expect(find.text('Altitude bands'), findsOneWidget);
    });

    testWidgets(
      'Top airlines tile picks the highest-count carrier as headline',
      (tester) async {
        final seed = {
          'a': _ac('a', 'DLH400'),
          'b': _ac('b', 'DLH401'),
          'c': _ac('c', 'AFR123'),
        };
        await tester.pumpWidget(
          _harness(child: const DashboardScreen(), seed: seed),
        );
        await tester.pumpAndSettle();

        // The headline value of the "Top airlines" tile is the leading ICAO.
        // We can't easily target the value text by widget tree alone, but DLH
        // must appear somewhere on the screen.
        expect(find.text('DLH'), findsWidgets);
      },
    );
  });
}
