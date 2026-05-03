import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/airlines/presentation/screens/airlines_screen.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Widget-level smoke tests for [AirlinesScreen]. Each test stands up
/// a [ProviderScope] that overrides [aircraftStreamProvider]
/// with a deterministic [Stream], so the screen renders synchronously
/// and predictably — no real network, no real polling.
///
/// <p>We keep these tests intentionally shallow: render → pump → assert
/// that the right strings show up. Full visual regression / golden tests
/// are scoped to a separate suite.

AircraftState _ac(String icao24, String callsign) =>
    AircraftState(icao24: icao24, callsign: callsign);

/// Wraps the screen-under-test in just enough scaffolding (Material + a
/// [ProviderScope] with the supplied overrides) to render in a
/// [WidgetTester].
Widget _harness({
  required Widget child,
  required Map<String, AircraftState> seed,
}) {
  return ProviderScope(
    overrides: [aircraftStreamProvider.overrideWith((_) => Stream.value(seed))],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AirlinesScreen', () {
    testWidgets('renders the empty-state string when no airline matches', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AirlinesScreen(),
          seed: const {}, // empty flight feed
        ),
      );
      // First frame is the loading spinner; pumping again drains the override.
      await tester.pumpAndSettle();

      // The English locale-default copy is exposed via S.of('en').noAirlinesActive.
      expect(
        find.text('No airborne flights match an airline yet'),
        findsOneWidget,
      );
    });

    testWidgets('groups by ICAO code and shows the count badge', (
      tester,
    ) async {
      final seed = {
        'a1': _ac('a1', 'DLH400'),
        'a2': _ac('a2', 'DLH401'),
        'a3': _ac('a3', 'AFR123'),
      };
      await tester.pumpWidget(
        _harness(child: const AirlinesScreen(), seed: seed),
      );
      await tester.pumpAndSettle();

      // Lufthansa (DLH) has 2 flights, Air France (AFR) has 1 — both must be rendered.
      expect(find.text('DLH'), findsWidgets);
      expect(find.text('AFR'), findsWidgets);
      expect(find.text('2 flights'), findsOneWidget);
      expect(find.text('1 flight'), findsOneWidget);
    });

    testWidgets(
      'orders carriers by descending count (Lufthansa above Air France)',
      (tester) async {
        final seed = {
          'a1': _ac('a1', 'AFR123'),
          'a2': _ac('a2', 'DLH400'),
          'a3': _ac('a3', 'DLH401'),
        };
        await tester.pumpWidget(
          _harness(child: const AirlinesScreen(), seed: seed),
        );
        await tester.pumpAndSettle();

        // Find the y-positions of the two ICAO labels in the rendered list.
        final dlhCenter = tester.getCenter(find.text('DLH').first);
        final afrCenter = tester.getCenter(find.text('AFR').first);
        expect(
          dlhCenter.dy,
          lessThan(afrCenter.dy),
          reason: 'DLH (count 2) should render above AFR (count 1)',
        );
      },
    );
  });
}
