import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/widgets/count_up.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('CountUp widget', () {
    testWidgets('renders the initial value formatted with thousands separator',
        (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(value: 1234)));
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('renders zero correctly', (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(value: 0)));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders negative numbers with the minus sign', (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(value: -1234)));
      expect(find.text('-1,234'), findsOneWidget);
    });

    testWidgets('decimals=2 keeps two trailing fraction digits', (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(value: 12.5, decimals: 2)));
      expect(find.text('12.50'), findsOneWidget);
    });

    testWidgets('value change tweens — final frame matches new value',
        (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(
        value: 100,
        duration: Duration(milliseconds: 100),
      )));
      // Update to a new value — should animate over 100 ms.
      await tester.pumpWidget(_wrap(const CountUp(
        value: 200,
        duration: Duration(milliseconds: 100),
      )));
      // Mid-tween — value sits somewhere between 100 and 200.
      await tester.pump(const Duration(milliseconds: 50));
      // After tween completes, final value is rendered.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('custom thousands + decimal separators apply', (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(
        value: 12345.6,
        decimals: 1,
        thousandsSeparator: '.',
        decimalSeparator: ',',
      )));
      expect(find.text('12.345,6'), findsOneWidget);
    });

    testWidgets('survives rapid value changes without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const CountUp(value: 0)));
      for (var i = 1; i <= 5; i++) {
        await tester.pumpWidget(_wrap(CountUp(value: i * 100)));
        await tester.pump(const Duration(milliseconds: 10));
      }
      // Some value > 0 is on screen, no exceptions.
      expect(tester.takeException(), isNull);
    });
  });
}
