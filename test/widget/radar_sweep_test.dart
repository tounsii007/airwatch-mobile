import 'package:airwatch_mobile/core/widgets/radar_sweep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// Wraps [child] in a MediaQuery that reports the OS "reduce motion"
/// toggle as on, so the freeze branch is exercised.
Widget _reduced(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child,
      ),
    ),
  ),
);

Iterable<CustomPaint> _paints(WidgetTester tester, Type host) =>
    tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(host),
        matching: find.byType(CustomPaint),
      ),
    );

void main() {
  group('RadarSweep widget', () {
    testWidgets('paints a CustomPaint at the requested size', (tester) async {
      await tester.pumpWidget(_app(const RadarSweep(size: 120)));
      expect(_paints(tester, RadarSweep).first.size, const Size(120, 120));
      await tester.pumpWidget(const SizedBox.shrink()); // dispose the ticker
    });

    testWidgets('animates via an AnimatedBuilder when motion is allowed', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const RadarSweep()));
      expect(
        find.descendant(
          of: find.byType(RadarSweep),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('freezes to a static frame under reduce-motion', (
      tester,
    ) async {
      await tester.pumpWidget(_reduced(const RadarSweep()));
      expect(
        find.descendant(
          of: find.byType(RadarSweep),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      expect(_paints(tester, RadarSweep), isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('keeps repainting over time without throwing', (tester) async {
      await tester.pumpWidget(
        _app(const RadarSweep(duration: Duration(milliseconds: 200))),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('honours a custom size', (tester) async {
      await tester.pumpWidget(_app(const RadarSweep(size: 64)));
      expect(_paints(tester, RadarSweep).first.size, const Size(64, 64));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('PulsingRings widget', () {
    testWidgets('paints sized to maxRadius * 2', (tester) async {
      await tester.pumpWidget(_app(const PulsingRings(maxRadius: 30)));
      expect(_paints(tester, PulsingRings).first.size, const Size(60, 60));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('renders a static frame under reduce-motion', (tester) async {
      await tester.pumpWidget(_reduced(const PulsingRings()));
      expect(
        find.descendant(
          of: find.byType(PulsingRings),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      expect(_paints(tester, PulsingRings), isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('accepts a custom ringCount without throwing', (tester) async {
      await tester.pumpWidget(
        _app(const PulsingRings(maxRadius: 50, ringCount: 5)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
