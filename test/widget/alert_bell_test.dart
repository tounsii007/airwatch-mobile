import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/notifications/domain/alert.dart';
import 'package:airwatch_mobile/features/notifications/presentation/providers/alerts_provider.dart';
import 'package:airwatch_mobile/features/notifications/presentation/widgets/alert_bell.dart';

Widget _wrap({required List<AppAlert> alerts}) {
  return ProviderScope(
    overrides: [
      alertsProvider.overrideWith((ref) => alerts),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: const AlertBell(),
          ),
        ),
      ),
    ),
  );
}

AppAlert _alert({required AlertKind kind, String id = 'x', String title = 'Test'}) =>
    AppAlert(id: id, kind: kind, title: title, firedAt: DateTime.now());

void main() {
  group('AlertBell widget', () {
    testWidgets('zero alerts — outline bell, no badge', (tester) async {
      await tester.pumpWidget(_wrap(alerts: const []));
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      // Badge text should not be present.
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('one alert — filled bell + "1" badge', (tester) async {
      await tester.pumpWidget(_wrap(alerts: [_alert(kind: AlertKind.squawk)]));
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('badge caps at "9+" for ten or more alerts', (tester) async {
      final alerts = [
        for (var i = 0; i < 12; i++)
          _alert(kind: AlertKind.geofence, id: 'g$i'),
      ];
      await tester.pumpWidget(_wrap(alerts: alerts));
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('tap opens the alerts bottom-sheet', (tester) async {
      await tester.pumpWidget(_wrap(alerts: [
        _alert(
          kind: AlertKind.squawk,
          id: 'sq-1',
          title: 'Emergency squawk',
        ),
      ]));
      await tester.tap(find.byIcon(Icons.notifications_active_rounded));
      await tester.pumpAndSettle();
      expect(find.text('ALERTS · 1'), findsOneWidget);
      expect(find.text('Emergency squawk'), findsOneWidget);
    });

    testWidgets('empty bottom-sheet shows the empty state', (tester) async {
      await tester.pumpWidget(_wrap(alerts: const []));
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(find.text('No active alerts'), findsOneWidget);
    });
  });
}
