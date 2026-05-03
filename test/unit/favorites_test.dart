import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/features/favorites/data/favorites_repository.dart';

void main() {
  group('FavoriteItem', () {
    test('toJson and fromJson roundtrip', () {
      final item = FavoriteItem(
        id: 'DLH123',
        type: FavoriteType.flight,
        label: 'DLH123',
        subtitle: 'Lufthansa',
      );

      final json = item.toJson();
      final restored = FavoriteItem.fromJson(json);

      expect(restored.id, 'DLH123');
      expect(restored.type, FavoriteType.flight);
      expect(restored.label, 'DLH123');
      expect(restored.subtitle, 'Lufthansa');
    });

    test('FavoriteType enum values', () {
      expect(FavoriteType.values.length, 3);
      expect(FavoriteType.flight.index, 0);
      expect(FavoriteType.airline.index, 1);
      expect(FavoriteType.airport.index, 2);
    });

    test('addedAt defaults to now', () {
      final item = FavoriteItem(
        id: 'test',
        type: FavoriteType.flight,
        label: 'test',
      );
      expect(
        item.addedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('pinned defaults to false', () {
      final item = FavoriteItem(id: 'x', type: FavoriteType.flight, label: 'x');
      expect(item.pinned, isFalse);
    });

    test('pinned roundtrips through toJson/fromJson', () {
      final pinned = FavoriteItem(
        id: 'DLH123',
        type: FavoriteType.flight,
        label: 'DLH123',
        pinned: true,
      );
      final restored = FavoriteItem.fromJson(pinned.toJson());
      expect(restored.pinned, isTrue);
    });

    test('legacy v1 payload (no pinned key) defaults pinned to false', () {
      final v1 = <String, dynamic>{
        'id': 'OLD',
        'type': 0,
        'label': 'OLD',
        'subtitle': null,
        'addedAt': '2024-01-01T00:00:00.000',
        // 'pinned' key missing — old schema
      };
      final restored = FavoriteItem.fromJson(v1);
      expect(restored.pinned, isFalse);
      expect(restored.id, 'OLD');
    });

    test('copyWith only flips pinned, leaves other fields untouched', () {
      final original = FavoriteItem(
        id: 'A',
        type: FavoriteType.airline,
        label: 'AAL',
        subtitle: 'American Airlines',
      );
      final pinned = original.copyWith(pinned: true);
      expect(pinned.id, original.id);
      expect(pinned.type, original.type);
      expect(pinned.label, original.label);
      expect(pinned.subtitle, original.subtitle);
      expect(pinned.addedAt, original.addedAt);
      expect(pinned.pinned, isTrue);
      // Original is unchanged.
      expect(original.pinned, isFalse);
    });
  });
}
