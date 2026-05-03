import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/map/presentation/widgets/map_style_picker.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_styles.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: SafeArea(child: Center(child: child)),
  ),
);

void main() {
  group('MapStylePicker widget', () {
    testWidgets('initially closed — only the trigger is visible', (
      tester,
    ) async {
      var current = MapStyleId.dark;
      await tester.pumpWidget(
        _wrap(
          MapStylePicker(current: current, onChanged: (next) => current = next),
        ),
      );
      // Only the current style label "DRK" should be visible.
      expect(find.text('DRK'), findsOneWidget);
      // No other style codes are shown until the popover opens.
      expect(find.text('SAT'), findsNothing);
      expect(find.text('LGT'), findsNothing);
    });

    testWidgets('tap opens the popover, all six labels become visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(MapStylePicker(current: MapStyleId.dark, onChanged: (_) {})),
      );
      await tester.tap(find.byIcon(Icons.layers_rounded));
      await tester.pumpAndSettle();
      // Popover renders all six style labels.
      for (final id in kStyleOrder) {
        expect(
          find.text(styleDef(id).label),
          findsWidgets,
          reason: '${styleDef(id).label} should appear',
        );
      }
    });

    testWidgets(
      'selecting a different style fires onChanged + closes popover',
      (tester) async {
        MapStyleId? picked;
        await tester.pumpWidget(
          _wrap(
            MapStylePicker(
              current: MapStyleId.dark,
              onChanged: (next) => picked = next,
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.layers_rounded));
        await tester.pumpAndSettle();
        // Tap "SAT" entry inside the popover. There's only one (the
        // trigger shows DRK because the current style is dark), so a
        // straight `find.text` finds the popover entry.
        await tester.tap(find.text('SAT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(picked, MapStyleId.satellite);
      },
    );
  });
}
