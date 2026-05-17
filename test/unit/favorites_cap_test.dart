import 'package:airwatch_mobile/features/favorites/data/favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';

FavoriteItem make(String id, {bool pinned = false, DateTime? addedAt}) =>
    FavoriteItem(
      id: id,
      type: FavoriteType.flight,
      label: id,
      pinned: pinned,
      addedAt: addedAt,
    );

void main() {
  group('FavoritesNotifier.appendWithCap', () {
    test('keeps the list growing under the cap', () {
      final items = <FavoriteItem>[];
      for (var i = 0; i < 10; i++) {
        final next = make('f$i');
        final updated = FavoritesNotifier.appendWithCap(items, next);
        items
          ..clear()
          ..addAll(updated);
      }
      expect(items.length, 10);
      expect(items.last.id, 'f9');
    });

    test('drops the oldest non-pinned when crossing the cap', () {
      final base = <FavoriteItem>[];
      for (var i = 0; i < FavoritesNotifier.maxItems; i++) {
        base.add(
          make('f$i', addedAt: DateTime(2026).add(Duration(seconds: i))),
        );
      }
      final result = FavoritesNotifier.appendWithCap(base, make('newest'));
      expect(result.length, FavoritesNotifier.maxItems);
      // f0 was the oldest non-pinned and should have been evicted.
      expect(result.any((f) => f.id == 'f0'), isFalse);
      expect(result.any((f) => f.id == 'newest'), isTrue);
    });

    test('pinned entries are never evicted', () {
      final base = <FavoriteItem>[];
      // f0 is pinned (oldest); f1..f499 are non-pinned.
      base.add(make('f0', pinned: true, addedAt: DateTime(2026)));
      for (var i = 1; i < FavoritesNotifier.maxItems; i++) {
        base.add(
          make('f$i', addedAt: DateTime(2026).add(Duration(seconds: i))),
        );
      }
      final result = FavoritesNotifier.appendWithCap(base, make('newest'));
      expect(result.length, FavoritesNotifier.maxItems);
      // The pinned entry survives; the next-oldest non-pinned (f1) is dropped.
      expect(result.any((f) => f.id == 'f0' && f.pinned), isTrue);
      expect(result.any((f) => f.id == 'f1'), isFalse);
      expect(result.any((f) => f.id == 'newest'), isTrue);
    });

    test('refuses to grow past the cap when every entry is pinned', () {
      final base = <FavoriteItem>[];
      for (var i = 0; i < FavoritesNotifier.maxItems; i++) {
        base.add(make('p$i', pinned: true));
      }
      final result = FavoritesNotifier.appendWithCap(base, make('newcomer'));
      expect(result.length, FavoritesNotifier.maxItems);
      expect(result.any((f) => f.id == 'newcomer'), isFalse);
    });
  });
}
