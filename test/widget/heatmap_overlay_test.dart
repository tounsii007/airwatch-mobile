import 'package:airwatch_mobile/core/widgets/heatmap_overlay.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AircraftState _ac(String id, {double? lat, double? lon}) =>
    AircraftState(icao24: id, latitude: lat, longitude: lon);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, height: 300, child: child)),
  ),
);

Finder _painter() => find.descendant(
  of: find.byType(HeatmapOverlay),
  matching: find.byType(CustomPaint),
);

void main() {
  group('HeatmapOverlay widget', () {
    testWidgets('renders nothing when there are no aircraft', (tester) async {
      await tester.pumpWidget(_app(const HeatmapOverlay(aircraft: [])));
      // The empty-guard returns a bare SizedBox.shrink — neither the
      // IgnorePointer wrapper nor the painter is mounted.
      expect(_painter(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HeatmapOverlay),
          matching: find.byType(IgnorePointer),
        ),
        findsNothing,
      );
    });

    testWidgets('paints inside an IgnorePointer for positioned aircraft', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          HeatmapOverlay(
            aircraft: [
              _ac('a', lat: 50.1, lon: 8.6),
              _ac('b', lat: 50.1, lon: 8.6),
            ],
          ),
        ),
      );
      final ignore = find.descendant(
        of: find.byType(HeatmapOverlay),
        matching: find.byType(IgnorePointer),
      );
      expect(ignore, findsOneWidget);
      expect(
        find.descendant(of: ignore, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
    });

    testWidgets('the overlay is non-interactive (ignores pointer events)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(HeatmapOverlay(aircraft: [_ac('a', lat: 51.0, lon: 9.0)])),
      );
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(HeatmapOverlay),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('skips aircraft without a position and still paints', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          HeatmapOverlay(
            aircraft: [_ac('pos', lat: 48.1, lon: 11.6), _ac('nopos')],
          ),
        ),
      );
      expect(_painter(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mounts a painter even when no aircraft have a position', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(HeatmapOverlay(aircraft: [_ac('x'), _ac('y')])),
      );
      expect(_painter(), findsOneWidget);
    });

    testWidgets('paints an overlapping density cluster without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          HeatmapOverlay(
            aircraft: [
              _ac('a', lat: 50.0, lon: 8.0),
              _ac('b', lat: 50.0, lon: 8.0),
              _ac('c', lat: 50.0, lon: 8.0),
            ],
            opacity: 0.7,
          ),
        ),
      );
      expect(_painter(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('repaints when the aircraft list grows', (tester) async {
      await tester.pumpWidget(
        _app(HeatmapOverlay(aircraft: [_ac('a', lat: 50.0, lon: 8.0)])),
      );
      await tester.pumpWidget(
        _app(
          HeatmapOverlay(
            aircraft: [
              _ac('a', lat: 50.0, lon: 8.0),
              _ac('b', lat: 50.2, lon: 8.2),
            ],
          ),
        ),
      );
      expect(_painter(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
