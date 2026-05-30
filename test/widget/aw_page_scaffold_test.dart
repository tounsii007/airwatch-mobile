import 'package:airwatch_mobile/core/widgets/aw_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  group('AwPageScaffold widget', () {
    testWidgets('renders the title and body inside a scaffold app bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const AwPageScaffold(title: 'FLIGHTS', child: Text('body'))),
      );
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('FLIGHTS'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('renders a subtitle line under the title when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AwPageScaffold(
            title: 'FLIGHTS',
            subtitle: Text('3 active'),
            child: Text('body'),
          ),
        ),
      );
      expect(find.text('FLIGHTS'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('3 active'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('forwards action buttons into the app bar', (tester) async {
      await tester.pumpWidget(
        _app(
          AwPageScaffold(
            title: 'X',
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
            ],
            child: const Text('body'),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );
    });

    testWidgets('wraps the body in a SafeArea by default', (tester) async {
      await tester.pumpWidget(
        _app(const AwPageScaffold(title: 'X', child: Text('body'))),
      );
      expect(
        find.ancestor(of: find.text('body'), matching: find.byType(SafeArea)),
        findsWidgets,
      );
    });

    testWidgets('extendBody true does not wrap the body in a SafeArea', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AwPageScaffold(
            title: 'X',
            extendBody: true,
            child: Text('body'),
          ),
        ),
      );
      expect(
        find.ancestor(of: find.text('body'), matching: find.byType(SafeArea)),
        findsNothing,
      );
    });

    testWidgets('passes a floatingActionButton through to the scaffold', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          AwPageScaffold(
            title: 'X',
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            child: const Text('body'),
          ),
        ),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('forwards a custom leading widget into the app bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          AwPageScaffold(
            title: 'X',
            leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
            child: const Text('body'),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.menu),
        ),
        findsOneWidget,
      );
    });

    testWidgets('forwards an app-bar bottom widget', (tester) async {
      await tester.pumpWidget(
        _app(
          const AwPageScaffold(
            title: 'X',
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(),
            ),
            child: Text('body'),
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('AwPageBadge renders its label text', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Center(child: AwPageBadge(label: '3 ACTIVE')),
          ),
        ),
      );
      expect(find.text('3 ACTIVE'), findsOneWidget);
    });
  });
}
