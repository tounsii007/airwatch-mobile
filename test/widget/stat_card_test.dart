import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/widgets/stat_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(8), child: child),
  ),
);

void main() {
  group('StatCard widget', () {
    testWidgets('renders label + numeric value', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'ACTIVE FLIGHTS', value: 1_234)),
      );
      expect(find.text('ACTIVE FLIGHTS'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('null value shows the shimmer placeholder, no number', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'LOADING', value: null)),
      );
      // No CountUp value rendered while loading.
      expect(find.text('0'), findsNothing);
      expect(find.text('LOADING'), findsOneWidget);
    });

    testWidgets('hint line appears when supplied', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'AVG', value: 42, hint: 'last hour')),
      );
      expect(find.text('last hour'), findsOneWidget);
    });

    testWidgets('icon halo renders when icon is supplied', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'X', value: 1, icon: Icons.flight_rounded)),
      );
      expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    });

    testWidgets('trend triangle renders for up/down/flat', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'X', value: 1, trend: StatCardTrend.up)),
      );
      expect(find.text('▲'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(const StatCard(label: 'X', value: 1, trend: StatCardTrend.down)),
      );
      expect(find.text('▼'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(const StatCard(label: 'X', value: 1, trend: StatCardTrend.flat)),
      );
      expect(find.text('–'), findsOneWidget);
    });

    testWidgets('zero value renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(label: 'EMPTY', value: 0)));
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unit suffix renders next to the value', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'CO₂', value: 320, unit: 'kg')),
      );
      expect(find.text('320'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });
  });
}
