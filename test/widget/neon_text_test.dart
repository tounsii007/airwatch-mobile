import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
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

List<Text> _texts(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(NeonText), matching: find.byType(Text)),
    )
    .toList();

void main() {
  group('NeonText widget', () {
    testWidgets('dark theme paints the text twice (glow + sharp layer)', (
      tester,
    ) async {
      await tester.pumpWidget(_dark(const NeonText(text: 'SCANNING')));
      expect(find.text('SCANNING'), findsNWidgets(2));
    });

    testWidgets('dark theme stacks a transparent glow behind the sharp text', (
      tester,
    ) async {
      await tester.pumpWidget(_dark(const NeonText(text: 'RADAR')));
      expect(
        find.descendant(
          of: find.byType(NeonText),
          matching: find.byType(Stack),
        ),
        findsOneWidget,
      );

      final texts = _texts(tester);
      expect(texts, hasLength(2));
      // One layer is transparent but carries the blur shadows…
      expect(
        texts.any(
          (t) =>
              t.style?.color == Colors.transparent &&
              (t.style?.shadows?.isNotEmpty ?? false),
        ),
        isTrue,
      );
      // …the other is the crisp, fully-coloured text.
      expect(texts.any((t) => t.style?.color == AppColors.primary), isTrue);
    });

    testWidgets('light theme renders a single flat Text with no glow', (
      tester,
    ) async {
      await tester.pumpWidget(_light(const NeonText(text: 'RADAR')));
      expect(
        find.descendant(
          of: find.byType(NeonText),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );

      final texts = _texts(tester);
      expect(texts, hasLength(1));
      expect(texts.single.style?.shadows, isNull);
      expect(texts.single.style?.color, AppColors.primary);
    });

    testWidgets('applies a custom colour to the sharp layer', (tester) async {
      await tester.pumpWidget(
        _dark(const NeonText(text: 'X', color: Colors.red)),
      );
      expect(_texts(tester).any((t) => t.style?.color == Colors.red), isTrue);
    });

    testWidgets('forwards textAlign and fontSize to every layer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _dark(
          const NeonText(text: 'X', fontSize: 32, textAlign: TextAlign.center),
        ),
      );
      final texts = _texts(tester);
      expect(texts, hasLength(2));
      expect(texts.every((t) => t.textAlign == TextAlign.center), isTrue);
      expect(texts.every((t) => t.style?.fontSize == 32), isTrue);
    });

    testWidgets('defaults to the Orbitron font with wide letter spacing', (
      tester,
    ) async {
      await tester.pumpWidget(_dark(const NeonText(text: 'X')));
      final texts = _texts(tester);
      expect(texts.every((t) => t.style?.fontFamily == 'Orbitron'), isTrue);
      expect(texts.every((t) => t.style?.letterSpacing == 1.5), isTrue);
    });
  });
}
