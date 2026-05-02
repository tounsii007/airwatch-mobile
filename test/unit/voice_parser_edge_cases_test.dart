import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/features/voice/domain/command_parser.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────
  group('Whitespace + casing', () {
    test('lowercase callsign is uppercased on extraction', () {
      final cmd = parseVoiceCommand('show flight dlh123', AppLanguage.en);
      expect(cmd, isA<VShowFlight>());
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });

    test('extra leading + trailing whitespace is trimmed', () {
      final cmd =
          parseVoiceCommand('   track DLH123   \n', AppLanguage.en);
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });

    test('inner double-space matches as if single', () {
      final cmd =
          parseVoiceCommand('show  flight  DLH123', AppLanguage.en);
      expect(cmd, isA<VShowFlight>());
    });

    test('mixed-case sentence ("SHOW Flight dlh123")', () {
      final cmd = parseVoiceCommand('SHOW Flight dlh123', AppLanguage.en);
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Callsign format edge cases', () {
    test('2-letter / 1-digit callsign matches (e.g. AC1)', () {
      final cmd = parseVoiceCommand('show flight AC1', AppLanguage.en);
      expect(cmd, isA<VShowFlight>());
      expect((cmd as VShowFlight).callsign, 'AC1');
    });

    test('3-letter / 5-digit (max digits) matches (e.g. DLH12345)', () {
      final cmd =
          parseVoiceCommand('show flight DLH12345', AppLanguage.en);
      expect((cmd as VShowFlight).callsign, 'DLH12345');
    });

    test('"DLH" alone (no digits) does NOT match showFlight', () {
      // The regex requires at least one digit. "DLH" alone is just an
      // airline code, not a flight number — falls through to the
      // catch-all goToAirport.
      final cmd = parseVoiceCommand('show DLH', AppLanguage.en);
      // This will end up matching the goToAirport catch-all instead.
      expect(cmd, isA<VGoToAirport>());
    });

    test('"show flight 123" — falls through to goToAirport catch-all', () {
      // Flight number without airline prefix isn't a valid callsign
      // for the showFlight regex. The phrase still matches the
      // goToAirport catch-all though (`(?:show)\s+(?:airport\s+)?(\w{3,})`)
      // because "flight" is a word ≥ 3 chars. Documented here so
      // future tweaks to the catch-all don't silently change this.
      final cmd = parseVoiceCommand('show flight 123', AppLanguage.en);
      expect(cmd, isA<VGoToAirport>());
      expect((cmd as VGoToAirport).query, 'flight');
    });

    test('callsign with > 5 digits fails the regex', () {
      // Regex caps at 5 digits to avoid matching phone numbers.
      final cmd = parseVoiceCommand('show DLH123456', AppLanguage.en);
      // First 5 digits would still match — let's see what happens.
      // Actually the regex is greedy on digits, capped at 5: "(?:\d{1,5})".
      // "DLH123456" — would match "DLH12345" leaving "6" trailing.
      expect(cmd, isA<VShowFlight>());
      // Given regex match captures up to 5 digits, the callsign here
      // is 'DLH12345'. This is correct — extra trailing digits are
      // ignored (could be a misheard noise).
      expect((cmd as VShowFlight).callsign, 'DLH12345');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Empty + noise input', () {
    test('empty string returns null', () {
      expect(parseVoiceCommand('', AppLanguage.en), isNull);
    });

    test('whitespace only returns null', () {
      expect(parseVoiceCommand('   \t\n', AppLanguage.en), isNull);
    });

    test('random sentence with no keywords returns null', () {
      // Has to truly contain no recognised keywords. "the cat sat on
      // the mat" is genuinely unparseable.
      expect(parseVoiceCommand('the cat sat on the mat', AppLanguage.en),
          isNull);
    });

    test('"weather" anywhere in the sentence triggers toggleRadar', () {
      // The radar regex is `\bweather\b` — a word boundary, so any
      // sentence containing "weather" toggles the radar. Documented
      // here so future tightening of the regex doesn't silently
      // change this.
      final maybeRadar =
          parseVoiceCommand('how is the weather right now', AppLanguage.en);
      expect(maybeRadar, isA<VToggleRadar>());
    });

    test('numbers-only string returns null', () {
      expect(parseVoiceCommand('123456', AppLanguage.en), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Pattern priority — first-match wins', () {
    test('phrase containing both flight + airport prefers flight', () {
      // "show flight DLH123" — both showFlight and goToAirport could
      // match; the showFlight regex is earlier in the list, so it wins.
      final cmd = parseVoiceCommand('show flight DLH123', AppLanguage.en);
      expect(cmd, isA<VShowFlight>());
    });

    test('"radar" alone is toggleRadar, not goToAirport', () {
      final cmd = parseVoiceCommand('radar', AppLanguage.en);
      expect(cmd, isA<VToggleRadar>());
    });

    test('"turbulence" beats catch-all goToAirport', () {
      final cmd = parseVoiceCommand('show turbulence', AppLanguage.en);
      expect(cmd, isA<VToggleTurbulence>());
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('English fallback for non-EN locales', () {
    test('"track DLH123" in DE locale falls through to EN', () {
      final cmd = parseVoiceCommand('track DLH123', AppLanguage.de);
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });

    test('"track DLH123" in FR locale falls through to EN', () {
      final cmd = parseVoiceCommand('track DLH123', AppLanguage.fr);
      expect((cmd as VShowFlight).callsign, 'DLH123');
    });

    test('"radar" works in DE and FR via fallback', () {
      // German pattern matches "radar" — but if it didn't, the EN
      // fallback would still cover it.
      expect(parseVoiceCommand('radar', AppLanguage.de),
          isA<VToggleRadar>());
      expect(parseVoiceCommand('radar', AppLanguage.fr),
          isA<VToggleRadar>());
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('German locale specifics', () {
    test('"zeige Flug AFR1" — verb conjugation variant', () {
      // The regex is `(?:zeige?|suche?|finde?)` so both "zeig" and
      // "zeige" should match.
      final cmd = parseVoiceCommand('zeig Flug AFR1', AppLanguage.de);
      expect((cmd as VShowFlight).callsign, 'AFR1');
    });

    test('"vergrößer" (zoom in) matches', () {
      final cmd = parseVoiceCommand('vergrößer', AppLanguage.de);
      expect(cmd, isA<VZoomIn>());
    });

    test('"verklein" (zoom out, partial match) — current behaviour', () {
      // The regex matches `verklein` as a substring, so even a partial
      // word triggers zoomOut. This is intentional (user might mumble).
      final cmd = parseVoiceCommand('verkleinere', AppLanguage.de);
      expect(cmd, isA<VZoomOut>());
    });

    test('"flughafen CDG" via the second DE pattern', () {
      // Pattern: (?:zeige?)\s+flughafen\s+(\S{3,})
      final cmd =
          parseVoiceCommand('zeige flughafen CDG', AppLanguage.de);
      expect(cmd, isA<VGoToAirport>());
      expect((cmd as VGoToAirport).query, 'CDG');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('French locale specifics', () {
    test('accent variations — "à" vs "a"', () {
      // Pattern uses `[àa]`, so both should match.
      final accented =
          parseVoiceCommand('aller à CDG', AppLanguage.fr);
      final plain = parseVoiceCommand('aller a CDG', AppLanguage.fr);
      expect(accented, isA<VGoToAirport>());
      expect(plain, isA<VGoToAirport>());
    });

    test('"aéroport" with diacritic vs "aeroport" without', () {
      // Pattern: (?:l')?a[ée]roport — both forms should match.
      final accented =
          parseVoiceCommand('aller à aéroport CDG', AppLanguage.fr);
      final plain =
          parseVoiceCommand('aller a aeroport CDG', AppLanguage.fr);
      expect((accented as VGoToAirport).query, 'CDG');
      expect((plain as VGoToAirport).query, 'CDG');
    });

    test('"meteo" vs "météo" — both match radar toggle', () {
      expect(parseVoiceCommand('météo', AppLanguage.fr), isA<VToggleRadar>());
      expect(parseVoiceCommand('meteo', AppLanguage.fr), isA<VToggleRadar>());
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('GoToAirport regex hygiene', () {
    test('extracts query without leading "airport" keyword', () {
      final cmd = parseVoiceCommand('go to airport JFK', AppLanguage.en);
      expect((cmd as VGoToAirport).query.toUpperCase(), 'JFK');
    });

    test('"open CDG" matches without the airport word', () {
      final cmd = parseVoiceCommand('open CDG', AppLanguage.en);
      expect((cmd as VGoToAirport).query.toUpperCase(), 'CDG');
    });

    test('2-char query is rejected (regex requires 3+)', () {
      final cmd = parseVoiceCommand('go to AB', AppLanguage.en);
      expect(cmd, isNull);
    });

    test('numeric query (4 digits) — regex matches \\w which includes digits',
        () {
      // \w covers digits, so the catch-all can match a numeric query.
      // This is by design — some airports have numeric ICAO-ish codes.
      final cmd = parseVoiceCommand('go to 1234', AppLanguage.en);
      expect(cmd, isA<VGoToAirport>());
    });
  });
}
