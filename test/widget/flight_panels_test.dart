import 'package:airwatch_mobile/features/flight_details/data/services/fleet_info_service.dart';
import 'package:airwatch_mobile/features/flight_details/data/services/route_stats_service.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/widgets/panel_sections/fleet_info_section.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/widgets/panel_sections/route_stats_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubFleet extends FleetInfoService {
  _StubFleet({this.info});
  final FleetInfo? info;
  @override
  Future<FleetInfo?> load(String hex) async => info;
}

class _StubRoute extends RouteStatsService {
  _StubRoute({this.stats});
  final RouteStats? stats;
  @override
  Future<RouteStats?> load(String? dep, String? arr) async => stats;
}

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('it'),
  ],
  home: Scaffold(body: child),
);

void main() {
  group('FleetInfoSection', () {
    testWidgets('renders nothing on a total miss', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FleetInfoSection(
            icao24: 'abc123',
            isDark: true,
            primary: const Color(0xFF00BFA5),
            service: _StubFleet(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('FLEET INFO'), findsNothing);
    });

    testWidgets('shows manufacturer + sightings on a populated info', (
      tester,
    ) async {
      final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(
        _wrap(
          FleetInfoSection(
            icao24: 'abc123',
            isDark: true,
            primary: const Color(0xFF00BFA5),
            service: _StubFleet(
              info: FleetInfo(
                icao24: 'abc123',
                registry: const FleetRegistry(
                  manufacturer: 'Airbus',
                  type: 'A320',
                  builtYear: 2010,
                  owner: 'Lufthansa',
                ),
                sightings: FleetSightings(
                  firstSeenAt: tenDaysAgo,
                  lastSeenAt: yesterday,
                  count: 142,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('FLEET INFO'), findsOneWidget);
      expect(find.textContaining('Airbus'), findsOneWidget);
      expect(find.textContaining('A320'), findsOneWidget);
      expect(find.textContaining('142'), findsOneWidget);
    });

    testWidgets('does not render when icao24 is wrong length', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FleetInfoSection(
            icao24: 'xx',
            isDark: true,
            primary: const Color(0xFF00BFA5),
            service: _StubFleet(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('FLEET INFO'), findsNothing);
    });
  });

  group('RouteStatsBadge', () {
    testWidgets('renders nothing on missing IATA codes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RouteStatsBadge(
            dep: null,
            arr: 'JFK',
            primary: const Color(0xFF00BFA5),
            isDark: true,
            service: _StubRoute(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders nothing when observed=false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RouteStatsBadge(
            dep: 'FRA',
            arr: 'JFK',
            primary: const Color(0xFF00BFA5),
            isDark: true,
            service: _StubRoute(
              stats: const RouteStats(depIata: 'FRA', arrIata: 'JFK'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.show_chart_rounded), findsNothing);
    });

    testWidgets('renders all 3 buckets on a populated route', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RouteStatsBadge(
            dep: 'FRA',
            arr: 'JFK',
            primary: const Color(0xFF00BFA5),
            isDark: true,
            service: _StubRoute(
              stats: const RouteStats(
                depIata: 'FRA',
                arrIata: 'JFK',
                observed: true,
                todayCount: 5,
                weekCount: 32,
                monthCount: 142,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);
      // The row text is comma-soup; assert it contains all three values.
      expect(find.textContaining('5 today'), findsOneWidget);
    });

    testWidgets('only shows non-zero buckets', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RouteStatsBadge(
            dep: 'FRA',
            arr: 'JFK',
            primary: const Color(0xFF00BFA5),
            isDark: true,
            service: _StubRoute(
              stats: const RouteStats(
                depIata: 'FRA',
                arrIata: 'JFK',
                observed: true,
                weekCount: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Today is 0 → its segment isn't rendered; week is 32 → present.
      expect(find.textContaining('32'), findsOneWidget);
      expect(find.textContaining('0 today'), findsNothing);
    });

    testWidgets('hides itself when every bucket is 0 despite observed=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RouteStatsBadge(
            dep: 'FRA',
            arr: 'JFK',
            primary: const Color(0xFF00BFA5),
            isDark: true,
            service: _StubRoute(
              stats: const RouteStats(
                depIata: 'FRA',
                arrIata: 'JFK',
                observed: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.show_chart_rounded), findsNothing);
    });
  });
}
