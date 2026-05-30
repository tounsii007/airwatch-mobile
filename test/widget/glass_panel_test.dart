import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _dark(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(body: Center(child: child)),
);

Widget _light(Widget child) => MaterialApp(
  theme: ThemeData.light(),
  home: Scaffold(body: Center(child: child)),
);

/// Outermost container — owns the optional glow shadow + margin.
Container _outer(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.byType(Container),
      ),
    )
    .first;

/// Innermost container — owns the frosted background, border and padding.
Container _inner(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.byType(Container),
      ),
    )
    .last;

void main() {
  group('GlassPanel widget', () {
    testWidgets('renders its child behind a blur + clip', (tester) async {
      await tester.pumpWidget(_dark(const GlassPanel(child: Text('inside'))));
      expect(find.text('inside'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlassPanel),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GlassPanel),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dark theme draws a 1px branded border', (tester) async {
      await tester.pumpWidget(_dark(const GlassPanel(child: Text('x'))));
      final deco = _inner(tester).decoration! as BoxDecoration;
      expect((deco.border! as Border).top.width, 1.0);
    });

    testWidgets('light theme uses a hairline 0.5px border', (tester) async {
      await tester.pumpWidget(_light(const GlassPanel(child: Text('x'))));
      final deco = _inner(tester).decoration! as BoxDecoration;
      expect((deco.border! as Border).top.width, 0.5);
    });

    testWidgets('glowBorder adds an outer glow shadow in dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _dark(const GlassPanel(glowBorder: true, child: Text('x'))),
      );
      final deco = _outer(tester).decoration! as BoxDecoration;
      expect(deco.boxShadow, isNotNull);
      expect(deco.boxShadow, isNotEmpty);
    });

    testWidgets('no outer glow decoration when glowBorder is off', (
      tester,
    ) async {
      await tester.pumpWidget(_dark(const GlassPanel(child: Text('x'))));
      expect(_outer(tester).decoration, isNull);
    });

    testWidgets('glowBorder is ignored in light mode', (tester) async {
      await tester.pumpWidget(
        _light(const GlassPanel(glowBorder: true, child: Text('x'))),
      );
      expect(_outer(tester).decoration, isNull);
    });

    testWidgets('applies a custom borderRadius to the clip', (tester) async {
      await tester.pumpWidget(
        _dark(const GlassPanel(borderRadius: 8, child: Text('x'))),
      );
      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(GlassPanel),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('applies custom padding to the inner surface', (tester) async {
      await tester.pumpWidget(
        _dark(const GlassPanel(padding: EdgeInsets.all(4), child: Text('x'))),
      );
      expect(_inner(tester).padding, const EdgeInsets.all(4));
    });

    testWidgets('GlowingBorder wraps its child in a layered glow', (
      tester,
    ) async {
      await tester.pumpWidget(_dark(const GlowingBorder(child: Text('halo'))));
      expect(find.text('halo'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GlowingBorder),
          matching: find.byType(Container),
        ),
      );
      final deco = container.decoration! as BoxDecoration;
      expect(deco.boxShadow, hasLength(2));
    });
  });
}
