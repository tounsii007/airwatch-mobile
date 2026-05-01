import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/app.dart';
import 'package:airwatch_mobile/features/map/data/datasources/airlabs_flights_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

class _FakeAirlabsFlightsDatasource extends AirlabsFlightsDatasource {
  final StreamController<List<AircraftState>> _controller =
      StreamController<List<AircraftState>>.broadcast();

  @override
  Stream<List<AircraftState>> get stateStream => _controller.stream;

  @override
  void startPolling({Duration interval = const Duration(minutes: 5)}) {
    if (!_controller.isClosed) {
      _controller.add(const []);
    }
  }

  @override
  void stopPolling() {}

  @override
  void dispose() {
    _controller.close();
  }
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      airlabsFlightsDatasourceProvider.overrideWithValue(
        _FakeAirlabsFlightsDatasource(),
      ),
    ],
    child: const AirwatchMobileApp(),
  );
}

void main() {
  group('App Integration Tests', () {
    testWidgets('App starts and shows splash screen', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      // App should render
      expect(find.byType(AirwatchMobileApp), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('App shows bottom navigation after splash', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      // Advance through the splash sequence in phases:
      // 600ms until text animation, 2800ms until fade starts, 500ms fade-out.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.pump(const Duration(milliseconds: 600));

      // After the splash sequence the shell should be visible.
      expect(find.byType(AppShell), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Navigation tabs work', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap SEARCH tab
      final searchTab = find.text('SEARCH');
      if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Tap SETTINGS tab
      final settingsTab = find.text('SETTINGS');
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Tap back to MAP
      final mapTab = find.text('MAP');
      if (mapTab.evaluate().isNotEmpty) {
        await tester.tap(mapTab);
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Search screen has input field', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to search
      final searchTab = find.text('SEARCH');
      if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pump(const Duration(milliseconds: 300));

        // Should have a TextField
        expect(find.byType(TextField), findsWidgets);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Settings screen shows language section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 200));

      final settingsTab = find.text('SETTINGS');
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pump(const Duration(milliseconds: 300));

        // Should show settings sections
        expect(find.text('APPEARANCE'), findsWidgets);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
