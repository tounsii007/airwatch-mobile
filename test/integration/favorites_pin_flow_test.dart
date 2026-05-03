import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/favorites/data/favorites_repository.dart';

/// End-to-end-ish flow: add favorites, pin one, verify ordering, then
/// unpin + remove. Uses an in-memory SharedPreferences mock so the
/// repository layer's persistence runs through the same code paths
/// as on a real device — only the storage backend differs.
void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Favorites flow', () {
    test('add → pin → unpin → remove preserves invariants', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);

      // ── Add three flights with explicit addedAt so the test
      // doesn't depend on `DateTime.now()` ms-level resolution
      // (rapid back-to-back calls land in the same millisecond and
      // make the sort tiebreaker unpredictable). ──
      final t0 = DateTime.utc(2025);
      notifier.toggle(
        FavoriteItem(
          id: 'DLH400',
          type: FavoriteType.flight,
          label: 'DLH400',
          addedAt: t0,
        ),
      );
      notifier.toggle(
        FavoriteItem(
          id: 'AFR123',
          type: FavoriteType.flight,
          label: 'AFR123',
          addedAt: t0.add(const Duration(seconds: 1)),
        ),
      );
      notifier.toggle(
        FavoriteItem(
          id: 'TU744',
          type: FavoriteType.flight,
          label: 'TU744',
          addedAt: t0.add(const Duration(seconds: 2)),
        ),
      );
      expect(container.read(favoritesProvider), hasLength(3));

      // ── Pin AFR123 → byType returns it FIRST despite being added second ──
      notifier.togglePin('AFR123');
      final pinnedFirst = notifier.byType(FavoriteType.flight);
      expect(pinnedFirst.first.id, 'AFR123');
      expect(pinnedFirst.first.pinned, isTrue);

      // ── Unpin AFR123 → most-recently-added (TU744) returns to top ──
      notifier.togglePin('AFR123');
      final afterUnpin = notifier.byType(FavoriteType.flight);
      expect(afterUnpin.first.id, 'TU744');
      expect(afterUnpin.every((f) => !f.pinned), isTrue);

      // ── Remove AFR123 entirely ──
      notifier.remove('AFR123');
      expect(
        container.read(favoritesProvider).any((f) => f.id == 'AFR123'),
        isFalse,
      );
      expect(container.read(favoritesProvider), hasLength(2));
    });

    test('togglePin on a non-existent id is a silent no-op', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);

      notifier.togglePin('does-not-exist');
      // No exception, no side-effect — list stays empty.
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('multiple pins coexist; sort is stable on equal pin state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);

      // Add three with deterministic timestamps so the byType
      // tiebreaker is predictable (see note in the previous test).
      final t0 = DateTime.utc(2025);
      notifier.toggle(
        FavoriteItem(
          id: 'A',
          type: FavoriteType.flight,
          label: 'A',
          addedAt: t0,
        ),
      );
      notifier.toggle(
        FavoriteItem(
          id: 'B',
          type: FavoriteType.flight,
          label: 'B',
          addedAt: t0.add(const Duration(seconds: 1)),
        ),
      );
      notifier.toggle(
        FavoriteItem(
          id: 'C',
          type: FavoriteType.flight,
          label: 'C',
          addedAt: t0.add(const Duration(seconds: 2)),
        ),
      );
      notifier.togglePin('A');
      notifier.togglePin('C');

      final list = notifier.byType(FavoriteType.flight);
      expect(
        list.where((f) => f.pinned).map((f) => f.id),
        containsAll(['A', 'C']),
      );
      // Pinned-first; within pinned, sort by addedAt desc → C is the
      // most-recently-added pinned entry, so it leads. Then A
      // (older pinned). Unpinned B sorts last.
      expect(list.first.id, 'C');
      expect(list[1].id, 'A');
      expect(list[2].id, 'B');
    });
  });
}
