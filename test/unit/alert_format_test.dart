import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/geofences/domain/alert_format.dart';

/// Mirrors airwatch-web's `alertFormat.test.ts` (commit 01d0841). Same
/// breakpoints, same edge cases — if these drift the two clients would
/// render the same alert with different labels.
void main() {
  group('timeAgo', () {
    final ref = DateTime.utc(2026, 5, 14, 12);
    final refMs = ref.millisecondsSinceEpoch;

    test('returns "just now" for a future timestamp (clock skew)', () {
      final future = ref.add(const Duration(seconds: 30));
      expect(timeAgo(future, refMs), 'just now');
    });

    test('returns "just now" for diffs < 5 s', () {
      expect(timeAgo(ref.subtract(const Duration(seconds: 1)), refMs),
          'just now');
      expect(timeAgo(ref.subtract(const Duration(seconds: 4)), refMs),
          'just now');
    });

    test('returns seconds for diffs in [5, 60) s', () {
      expect(timeAgo(ref.subtract(const Duration(seconds: 12)), refMs), '12s');
      expect(timeAgo(ref.subtract(const Duration(seconds: 59)), refMs), '59s');
    });

    test('returns minutes for diffs in [1, 60) m', () {
      expect(timeAgo(ref.subtract(const Duration(minutes: 5)), refMs), '5m');
      expect(timeAgo(ref.subtract(const Duration(minutes: 59)), refMs), '59m');
    });

    test('returns hours for diffs in [1, 24) h', () {
      expect(timeAgo(ref.subtract(const Duration(hours: 3)), refMs), '3h');
      expect(timeAgo(ref.subtract(const Duration(hours: 23)), refMs), '23h');
    });

    test('returns days for diffs ≥ 24 h', () {
      expect(timeAgo(ref.subtract(const Duration(days: 2)), refMs), '2d');
      expect(timeAgo(ref.subtract(const Duration(days: 30)), refMs), '30d');
    });

    test('crosses each unit boundary cleanly', () {
      expect(timeAgo(ref.subtract(const Duration(seconds: 60)), refMs), '1m');
      expect(timeAgo(ref.subtract(const Duration(minutes: 60)), refMs), '1h');
      expect(timeAgo(ref.subtract(const Duration(hours: 24)), refMs), '1d');
    });
  });

  group('resolveAirlineName', () {
    test('returns null for null / empty / too-short input', () {
      expect(resolveAirlineName(null), isNull);
      expect(resolveAirlineName(''), isNull);
      expect(resolveAirlineName('DL'), isNull);
    });

    test('resolves a 3-letter ICAO code', () {
      // DLH is curated as Lufthansa in airline_database.dart.
      expect(resolveAirlineName('DLH'), isNotNull);
    });

    test('resolves a full callsign by first 3 chars', () {
      expect(resolveAirlineName('DLH123'), isNotNull);
    });

    test('is case-insensitive', () {
      expect(resolveAirlineName('dlh'), isNotNull);
      expect(resolveAirlineName('dLh100'), isNotNull);
    });

    test('returns null for unknown codes', () {
      // Picked a triplet that the auto-generated airline DB has no row
      // for — verified against airline_database.dart at write time.
      expect(resolveAirlineName('QQQ'), isNull);
    });
  });

  group('formatAltitude', () {
    test('returns the dash sentinel for null / NaN', () {
      expect(formatAltitude(null), '—');
      expect(formatAltitude(double.nan), '—');
    });

    test('shows metres + feet below FL180 transition', () {
      // 1500 m → 1500 m (4921 ft).
      final s = formatAltitude(1500);
      expect(s, contains('1500 m'));
      expect(s, contains('ft'));
    });

    test('shows flight level + metres at and above FL180', () {
      // 11280 m ≈ 37000 ft → FL370.
      final s = formatAltitude(11280);
      expect(s.startsWith('FL'), isTrue);
      expect(s, contains('m'));
    });

    test('handles the FL180 transition boundary', () {
      // 18000 ft = 5486.4 m exactly — anything ≥ 5487 m rounds to ≥
      // 18000 ft and switches the formatter to FL notation.
      expect(formatAltitude(5487).startsWith('FL'), isTrue);
      // Just below the transition stays in the metres + feet form.
      expect(formatAltitude(5485).startsWith('FL'), isFalse);
    });
  });
}
