import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/app.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AirwatchMobileApp()));
    await tester.pump(const Duration(milliseconds: 100));
    // App should render without throwing
    expect(find.byType(AirwatchMobileApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
