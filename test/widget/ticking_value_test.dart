import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/ticking_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = TextStyle(fontSize: 20, color: AppColors.textPrimary);

Widget _host(Object value, {Color? flashColor}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: TickingValue(value: value, style: _style, flashColor: flashColor),
    ),
  ),
);

/// The colour the [AnimatedDefaultTextStyle] is currently animating
/// *towards* — flips synchronously with the flash flag, so it reflects
/// flash vs settled state without waiting for the implicit tween.
Color? _flashTarget(WidgetTester tester) {
  final animated = tester.widget<AnimatedDefaultTextStyle>(
    find.descendant(
      of: find.byType(TickingValue),
      matching: find.byType(AnimatedDefaultTextStyle),
    ),
  );
  return animated.style.color;
}

void main() {
  group('TickingValue widget', () {
    testWidgets('renders the value as text (string and num)', (tester) async {
      await tester.pumpWidget(_host('FL360'));
      expect(find.text('FL360'), findsOneWidget);

      await tester.pumpWidget(_host(42));
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('sits at the base style colour while idle', (tester) async {
      await tester.pumpWidget(_host('FL360'));
      expect(_flashTarget(tester), AppColors.textPrimary);
    });

    testWidgets('flashes the accent colour when the value changes', (
      tester,
    ) async {
      await tester.pumpWidget(_host('FL360'));
      await tester.pumpWidget(_host('FL370'));
      expect(_flashTarget(tester), AppColors.accent);
      await tester.pumpAndSettle();
    });

    testWidgets('settles back to the base colour after the flash window', (
      tester,
    ) async {
      await tester.pumpWidget(_host('FL360'));
      await tester.pumpWidget(_host('FL370'));
      expect(_flashTarget(tester), AppColors.accent);

      // flashFor defaults to 350 ms — advance past it.
      await tester.pump(const Duration(milliseconds: 400));
      expect(_flashTarget(tester), AppColors.textPrimary);
      await tester.pumpAndSettle();
    });

    testWidgets('does not flash when re-rendered with an equal value', (
      tester,
    ) async {
      await tester.pumpWidget(_host('FL360'));
      await tester.pumpWidget(_host('FL360'));
      expect(_flashTarget(tester), AppColors.textPrimary);
    });

    testWidgets('a numeric value change also triggers the flash', (
      tester,
    ) async {
      await tester.pumpWidget(_host(100));
      await tester.pumpWidget(_host(200));
      expect(_flashTarget(tester), AppColors.accent);
      await tester.pumpAndSettle();
    });

    testWidgets('uses a custom flashColor instead of the accent default', (
      tester,
    ) async {
      await tester.pumpWidget(_host('A', flashColor: Colors.red));
      await tester.pumpWidget(_host('B', flashColor: Colors.red));
      expect(_flashTarget(tester), Colors.red);
      await tester.pumpAndSettle();
    });

    testWidgets('tears down cleanly when unmounted mid-flash', (tester) async {
      await tester.pumpWidget(_host('A'));
      await tester.pumpWidget(_host('B')); // starts the flash + settle timer
      await tester.pump(const Duration(milliseconds: 50));
      // Unmount before the 350 ms timer fires — dispose must cancel it.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
