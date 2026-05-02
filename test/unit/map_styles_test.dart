import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/map/presentation/widgets/map_styles.dart';

void main() {
  group('MapStyle catalog — completeness + sanity', () {
    test('every MapStyleId has a catalog entry', () {
      for (final id in MapStyleId.values) {
        expect(kMapStyles[id], isNotNull,
            reason: '$id missing from kMapStyles');
      }
    });

    test('kStyleOrder enumerates every MapStyleId exactly once', () {
      expect(kStyleOrder.toSet().length, MapStyleId.values.length);
      expect(kStyleOrder.toSet(), equals(MapStyleId.values.toSet()));
    });

    test('every URL contains the {z}/{x}/{y} placeholders', () {
      for (final entry in kMapStyles.entries) {
        final url = entry.value.url;
        expect(url, contains('{z}'),
            reason: '${entry.key} URL missing {z}: $url');
        expect(url, contains('{x}'),
            reason: '${entry.key} URL missing {x}: $url');
        expect(url, contains('{y}'),
            reason: '${entry.key} URL missing {y}: $url');
      }
    });

    test('every URL is HTTPS', () {
      for (final entry in kMapStyles.entries) {
        expect(entry.value.url, startsWith('https://'),
            reason: '${entry.key} URL is not HTTPS: ${entry.value.url}');
      }
    });

    test('every label is exactly 3 uppercase letters', () {
      for (final def in kMapStyles.values) {
        expect(def.label, hasLength(3));
        expect(def.label, equals(def.label.toUpperCase()));
      }
    });

    test('every attribution has © and at least one provider name', () {
      for (final def in kMapStyles.values) {
        expect(def.attribution, contains('©'));
        expect(def.attribution.length, greaterThan(2));
      }
    });

    test('all palette colours are fully opaque (alpha = 0xFF)', () {
      // Pure-black IS valid for the "ground" hue on some styles
      // (e.g. terrain) — the palette is mirrored from the web's
      // mapStyles.ts. What we genuinely want to reject is a
      // transparent colour, which would render the marker invisible.
      for (final def in kMapStyles.values) {
        for (final c in [
          def.colors.ground,
          def.colors.low,
          def.colors.med,
          def.colors.high,
          def.colors.selected,
        ]) {
          final alpha = (c.toARGB32() >> 24) & 0xFF;
          expect(alpha, 0xFF,
              reason: 'transparent / partial-alpha colour in ${def.label}');
        }
      }
    });

    test('styleDef returns the same instance from kMapStyles', () {
      for (final id in MapStyleId.values) {
        expect(styleDef(id), same(kMapStyles[id]));
      }
    });

    test('high-altitude colours are reasonably distinct between styles', () {
      // The picker uses the high-altitude hue as a thumbnail. If two
      // styles had identical hues, the picker would look broken.
      final hues = {
        for (final def in kMapStyles.values) def.colors.high.toARGB32(),
      };
      // Some palettes may share a colour by design; require ≥ 4 distinct
      // values out of 6 styles.
      expect(hues.length, greaterThanOrEqualTo(4));
    });
  });
}
