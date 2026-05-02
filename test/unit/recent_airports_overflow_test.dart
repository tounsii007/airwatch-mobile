import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/airport/data/recent_airports_repository.dart';

void main() {
  // SharedPreferences plugin needs an in-memory mock for unit tests.
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('RecentAirportsNotifier — overflow + dedup', () {
    test('cap kicks in at 20 — oldest entry falls off', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      for (var i = 0; i < 25; i++) {
        notifier.record(iata: 'A${i.toString().padLeft(2, '0')}');
      }
      final list = container.read(recentAirportsProvider);
      expect(list, hasLength(20));
      // Most recent (A24) should be on top.
      expect(list.first.iata, 'A24');
      // Oldest survivor should be A05 (A00..A04 dropped).
      expect(list.last.iata, 'A05');
    });

    test('re-recording the same IATA dedupes (no growth)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      notifier.record(iata: 'CDG');
      notifier.record(iata: 'JFK');
      notifier.record(iata: 'CDG'); // re-record CDG
      final list = container.read(recentAirportsProvider);
      expect(list, hasLength(2));
      // CDG moved to the top, JFK dropped to second.
      expect(list.first.iata, 'CDG');
      expect(list[1].iata, 'JFK');
    });

    test('lowercase IATA is normalised on record', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      notifier.record(iata: 'cdg');
      notifier.record(iata: 'CDG'); // should dedupe (same after upcasing)
      expect(container.read(recentAirportsProvider), hasLength(1));
      expect(container.read(recentAirportsProvider).first.iata, 'CDG');
    });

    test('whitespace-padded IATA is trimmed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      notifier.record(iata: '   CDG  ');
      expect(container.read(recentAirportsProvider).first.iata, 'CDG');
    });

    test('empty IATA is silently ignored (no zombie entries)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      notifier.record(iata: '');
      notifier.record(iata: '   ');
      expect(container.read(recentAirportsProvider), isEmpty);
    });

    test('clear() empties the list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      notifier.record(iata: 'CDG');
      notifier.record(iata: 'JFK');
      notifier.clear();
      expect(container.read(recentAirportsProvider), isEmpty);
    });

    test('city + country attach to the new entry on dedup-promotion', () async {
      // The current impl doesn't merge new metadata onto an existing
      // entry — it just creates a fresh entry with the latest values.
      // This test documents that behaviour.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(recentAirportsProvider.notifier);

      notifier.record(iata: 'CDG'); // no city
      notifier.record(iata: 'CDG', city: 'Paris', country: 'FR');
      final list = container.read(recentAirportsProvider);
      expect(list, hasLength(1));
      expect(list.first.city, 'Paris');
      expect(list.first.country, 'FR');
    });
  });
}
