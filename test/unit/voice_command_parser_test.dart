import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/features/voice/domain/command_parser.dart';

/// Mirrors the web frontend's `commandParser.test.ts`. Pure regex
/// dispatch — no platform speech APIs, no Flutter widgets.
void main() {
  group('parseVoiceCommand — English', () {
    test('show flight DLH123 → showFlight', () {
      final cmd = parseVoiceCommand('show flight DLH123', AppLanguage.en);
      expect(cmd, isA<VShowFlight>());
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });

    test('"track AFR1" parses callsign', () {
      final cmd = parseVoiceCommand('track AFR1', AppLanguage.en);
      expect((cmd as VShowFlight).callsign, 'AFR1');
    });

    test('cargo / freight → filterCargo', () {
      expect(parseVoiceCommand('cargo', AppLanguage.en), isA<VFilterCargo>());
      expect(parseVoiceCommand('show cargo', AppLanguage.en), isA<VFilterCargo>());
      expect(parseVoiceCommand('freight', AppLanguage.en), isA<VFilterCargo>());
    });

    test('dark mode → setStyleDark', () {
      expect(parseVoiceCommand('dark mode', AppLanguage.en), isA<VSetStyleDark>());
    });

    test('zoom in / zoom out / closer / further', () {
      expect(parseVoiceCommand('zoom in', AppLanguage.en), isA<VZoomIn>());
      expect(parseVoiceCommand('closer', AppLanguage.en), isA<VZoomIn>());
      expect(parseVoiceCommand('zoom out', AppLanguage.en), isA<VZoomOut>());
      expect(parseVoiceCommand('further', AppLanguage.en), isA<VZoomOut>());
    });

    test('radar / weather → toggleRadar', () {
      expect(parseVoiceCommand('radar', AppLanguage.en), isA<VToggleRadar>());
      expect(parseVoiceCommand('weather', AppLanguage.en), isA<VToggleRadar>());
    });

    test('turbulence → toggleTurbulence', () {
      expect(parseVoiceCommand('turbulence', AppLanguage.en), isA<VToggleTurbulence>());
    });

    test('go to airport CDG → goToAirport', () {
      final cmd = parseVoiceCommand('go to airport CDG', AppLanguage.en);
      expect(cmd, isA<VGoToAirport>());
      expect((cmd as VGoToAirport).query.toUpperCase(), 'CDG');
    });

    test('empty / unknown → null', () {
      expect(parseVoiceCommand('', AppLanguage.en), isNull);
      expect(parseVoiceCommand('   ', AppLanguage.en), isNull);
      expect(parseVoiceCommand('hello world', AppLanguage.en), isNull);
    });
  });

  group('parseVoiceCommand — German', () {
    test('"zeige Flug DLH123" → showFlight', () {
      final cmd = parseVoiceCommand('zeige Flug DLH123', AppLanguage.de);
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });

    test('"fracht" → filterCargo', () {
      expect(parseVoiceCommand('fracht', AppLanguage.de), isA<VFilterCargo>());
    });

    test('"dunkler modus" → setStyleDark', () {
      expect(parseVoiceCommand('dunkler modus', AppLanguage.de), isA<VSetStyleDark>());
    });

    test('"hell" → setStyleLight', () {
      expect(parseVoiceCommand('hell', AppLanguage.de), isA<VSetStyleLight>());
    });

    test('"turbulenz" → toggleTurbulence', () {
      expect(parseVoiceCommand('turbulenz', AppLanguage.de),
          isA<VToggleTurbulence>());
    });
  });

  group('parseVoiceCommand — French', () {
    test('"montre le vol AFR1" → showFlight', () {
      final cmd = parseVoiceCommand('montre le vol AFR1', AppLanguage.fr);
      expect((cmd as VShowFlight).callsign, 'AFR1');
    });

    test('"fret" → filterCargo', () {
      expect(parseVoiceCommand('fret', AppLanguage.fr), isA<VFilterCargo>());
    });

    test('"mode sombre" → setStyleDark', () {
      expect(parseVoiceCommand('mode sombre', AppLanguage.fr), isA<VSetStyleDark>());
    });

    test('"zoom avant" → zoomIn', () {
      expect(parseVoiceCommand('zoom avant', AppLanguage.fr), isA<VZoomIn>());
    });

    test('"meteo" → toggleRadar', () {
      expect(parseVoiceCommand('meteo', AppLanguage.fr), isA<VToggleRadar>());
    });
  });

  group('English fallback for non-English locale', () {
    test('"track DLH123" works in DE locale via EN fallback', () {
      // In German the show-flight regex is `zeige|suche|finde`, so
      // "track" wouldn't match the DE patterns — but the fallback
      // path tries the EN patterns afterwards.
      final cmd = parseVoiceCommand('track DLH123', AppLanguage.de);
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });
  });
}
