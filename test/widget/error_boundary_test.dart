import 'package:airwatch_mobile/core/widgets/error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _Crashing extends StatelessWidget {
  const _Crashing();
  @override
  Widget build(BuildContext context) {
    throw StateError('boom');
  }
}

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('de'), Locale('fr')],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('catches a build-time exception and renders a fallback', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ErrorBoundary(child: _Crashing())));
    // ErrorWidget.builder swap catches the exception — but the framework
    // still records it on the test reporter. Drain via takeException so
    // the test passes while we assert the fallback rendered.
    final captured = tester.takeException();
    expect(captured, isStateError);
    await tester.pump();
    expect(find.text('SECTION UNAVAILABLE'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('retry button resets the boundary and rebuilds the child', (
    tester,
  ) async {
    var crashCount = 0;
    final child = Builder(
      builder: (ctx) {
        crashCount++;
        if (crashCount == 1) throw StateError('boom');
        return const Text('OK');
      },
    );
    await tester.pumpWidget(_wrap(ErrorBoundary(child: child)));
    expect(tester.takeException(), isStateError);
    await tester.pump();
    expect(find.text('SECTION UNAVAILABLE'), findsOneWidget);

    // Second build returns OK; tap retry, the host rebuilds the child.
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    expect(find.text('OK'), findsOneWidget);
  });
}
