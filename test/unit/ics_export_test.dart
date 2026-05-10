import 'package:airwatch_mobile/core/utils/ics_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('escapeText', () {
    test('escapes backslash, semicolon, comma, newline', () {
      expect(escapeText(r'a\b'), r'a\\b');
      expect(escapeText('a;b'), r'a\;b');
      expect(escapeText('a,b'), r'a\,b');
      expect(escapeText('line1\nline2'), r'line1\nline2');
    });

    test('drops carriage returns', () {
      expect(escapeText('a\r\nb'), r'a\nb');
    });
  });

  group('foldLine', () {
    test('returns input unchanged when ≤ 75 chars', () {
      const line = 'short';
      expect(foldLine(line), line);
    });

    test('splits long lines with CRLF + space continuations', () {
      final long = 'A' * 200;
      final folded = foldLine(long);
      // First chunk is 75 chars, then "\r\n " + 74 chars repeated.
      final lines = folded.split('\r\n');
      expect(lines.first.length, 75);
      // Continuation lines start with a single space.
      for (final cont in lines.skip(1)) {
        expect(cont[0], ' ');
        // Each continuation chunk is " " + up to 74 content chars.
        expect(cont.length, lessThanOrEqualTo(75));
      }
      // Reassembling without the leading space markers yields the
      // original string.
      final reassembled =
          lines.first + lines.skip(1).map((l) => l.substring(1)).join();
      expect(reassembled, long);
    });
  });

  group('buildIcs', () {
    test('emits a valid VCALENDAR envelope with one VEVENT per input', () {
      final ics = buildIcs([
        IcsEvent(
          id: 'flight-DLH400',
          start: DateTime.utc(2026, 5, 15, 10, 30),
          end: DateTime.utc(2026, 5, 15, 12, 0),
          title: 'DLH400 FRA → JFK',
          location: 'Frankfurt am Main',
          description: 'Lufthansa A340-600',
          url: 'https://airwatch.app/flight/DLH400',
        ),
      ]);

      // Skeleton.
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('END:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:-//AirWatch//Mobile//EN'));

      // Properties.
      expect(ics, contains('UID:flight-DLH400@airwatch.app'));
      expect(ics, contains('DTSTART:20260515T103000Z'));
      expect(ics, contains('DTEND:20260515T120000Z'));
      expect(ics, contains('SUMMARY:DLH400 FRA → JFK'));
      expect(ics, contains('LOCATION:Frankfurt am Main'));
      expect(ics, contains('DESCRIPTION:Lufthansa A340-600'));
      expect(ics, contains('URL:https://airwatch.app/flight/DLH400'));

      // RFC 5545: CRLF line endings, trailing CRLF.
      expect(ics.endsWith('\r\n'), isTrue);
      expect(ics.contains('\r\n'), isTrue);
    });

    test('defaults DTEND to start + 1h when not provided', () {
      final ics = buildIcs([
        IcsEvent(
          id: 'a',
          start: DateTime.utc(2026, 5, 15, 10, 0),
          title: 'thing',
        ),
      ]);
      expect(ics, contains('DTSTART:20260515T100000Z'));
      expect(ics, contains('DTEND:20260515T110000Z'));
    });

    test('escapes special chars in SUMMARY/LOCATION/DESCRIPTION', () {
      final ics = buildIcs([
        IcsEvent(
          id: 'a',
          start: DateTime.utc(2026, 5, 15),
          title: 'one; two, three',
          location: r'path\with\slashes',
          description: 'line1\nline2',
        ),
      ]);
      expect(ics, contains(r'SUMMARY:one\; two\, three'));
      expect(ics, contains(r'LOCATION:path\\with\\slashes'));
      expect(ics, contains(r'DESCRIPTION:line1\nline2'));
    });

    test('multiple events all get rendered', () {
      final ics = buildIcs([
        IcsEvent(
          id: 'a',
          start: DateTime.utc(2026, 5, 15),
          title: 'event A',
        ),
        IcsEvent(
          id: 'b',
          start: DateTime.utc(2026, 5, 16),
          title: 'event B',
        ),
      ]);
      // Two BEGIN:VEVENT and END:VEVENT pairs.
      expect('BEGIN:VEVENT'.allMatches(ics).length, 2);
      expect('END:VEVENT'.allMatches(ics).length, 2);
      expect(ics, contains('UID:a@airwatch.app'));
      expect(ics, contains('UID:b@airwatch.app'));
    });
  });
}

extension on String {
  Iterable<Match> allMatches(String input) =>
      RegExp(RegExp.escape(this)).allMatches(input);
}
