import 'package:airwatch_mobile/features/airport/data/services/atc_feeds_service.dart';
import 'package:airwatch_mobile/features/airport/data/services/aviation_weather_service.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/atc_audio_panel.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/metar_panel.dart';
import 'package:airwatch_mobile/features/airport/presentation/widgets/notam_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test stubs — extend the real services and override the single
/// public method each one needs. Avoids pulling in a mock framework
/// for what is essentially "return this Future".
class _StubAviation extends AviationWeatherService {
  _StubAviation({this.metarTaf, this.notams});
  final MetarTafResult? metarTaf;
  final NotamResult? notams;

  @override
  Future<MetarTafResult> loadMetarTaf(String icao) async =>
      metarTaf ?? const MetarTafResult();

  @override
  Future<NotamResult> loadNotams(String icao) async =>
      notams ?? const NotamResult();
}

class _StubAtc extends AtcFeedsService {
  _StubAtc({this.result});
  final AtcFeedsResult? result;

  @override
  Future<AtcFeedsResult?> load(String icao) async => result;
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MetarPanel', () {
    testWidgets('renders nothing when icao is null', (tester) async {
      await tester.pumpWidget(_wrap(const MetarPanel(icao: null)));
      await tester.pump();
      expect(find.text('METAR / TAF'), findsNothing);
    });

    testWidgets('renders nothing for malformed icao', (tester) async {
      await tester.pumpWidget(_wrap(const MetarPanel(icao: 'ED')));
      await tester.pump();
      expect(find.text('METAR / TAF'), findsNothing);
    });

    testWidgets('renders header + decoded fields on a happy METAR',
        (tester) async {
      await tester.pumpWidget(_wrap(MetarPanel(
        icao: 'EDDF',
        service: _StubAviation(
          metarTaf: const MetarTafResult(
            metarRaw: 'EDDF 101220Z 27010KT 9999 FEW040 23/12 Q1018',
          ),
        ),
      )));
      // Wait for the async load future to complete.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('METAR / TAF'), findsOneWidget);
      expect(find.text('EDDF'), findsOneWidget);
      // Decoded grid labels.
      expect(find.text('WIND'), findsOneWidget);
      expect(find.text('CLOUDS'), findsOneWidget);
    });

    testWidgets('shows unavailable line when both raws are missing',
        (tester) async {
      await tester.pumpWidget(_wrap(MetarPanel(
        icao: 'KSFO',
        service: _StubAviation(
          metarTaf: const MetarTafResult(upstreamUnavailable: true),
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('METAR / TAF unavailable'), findsOneWidget);
    });
  });

  group('NotamPanel', () {
    testWidgets('shows "no NOTAMs reported" on an empty list',
        (tester) async {
      await tester.pumpWidget(_wrap(NotamPanel(
        icao: 'EDDF',
        service: _StubAviation(notams: const NotamResult()),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('No NOTAMs reported'), findsOneWidget);
    });

    testWidgets('renders ID + classification + preview on a populated list',
        (tester) async {
      await tester.pumpWidget(_wrap(NotamPanel(
        icao: 'EDDF',
        service: _StubAviation(
          notams: const NotamResult(items: [
            NotamRecord(
              id: 'A1234/26',
              text: 'Runway 25R closed for resurfacing',
              classification: 'RWY',
              start: '2026-05-10T08:00:00Z',
              end: '2026-05-10T18:00:00Z',
            ),
          ]),
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('A1234/26'), findsOneWidget);
      expect(find.text('RWY'), findsOneWidget);
      expect(
        find.textContaining('Runway 25R closed for resurfacing'),
        findsOneWidget,
      );
    });

    testWidgets('shows "unavailable" when the upstream is open',
        (tester) async {
      await tester.pumpWidget(_wrap(NotamPanel(
        icao: 'EDDF',
        service: _StubAviation(
          notams: const NotamResult(upstreamUnavailable: true),
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('NOTAMs unavailable'), findsOneWidget);
    });
  });

  group('AtcAudioPanel', () {
    testWidgets('falls back to "Search on LiveATC" when no feeds',
        (tester) async {
      await tester.pumpWidget(_wrap(AtcAudioPanel(
        icao: 'EDDF',
        service: _StubAtc(
          result: const AtcFeedsResult(icao: 'EDDF', feeds: []),
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Search on LiveATC.net'), findsOneWidget);
    });

    testWidgets('renders chip per feed on populated catalog',
        (tester) async {
      await tester.pumpWidget(_wrap(AtcAudioPanel(
        icao: 'EDDF',
        service: _StubAtc(
          result: const AtcFeedsResult(
            icao: 'EDDF',
            feeds: [
              AtcFeed(
                label: 'Tower',
                mount: 'eddf_twr',
                streamUrl: 'https://example/stream.mp3',
                externalUrl: 'https://example/player',
              ),
              AtcFeed(
                label: 'Ground',
                mount: 'eddf_gnd',
                streamUrl: 'https://example/stream2.mp3',
                externalUrl: 'https://example/player2',
              ),
            ],
            attribution: 'Audio courtesy of LiveATC.net',
          ),
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Tower'), findsOneWidget);
      expect(find.text('Ground'), findsOneWidget);
      expect(find.text('Audio courtesy of LiveATC.net'), findsOneWidget);
    });
  });
}
