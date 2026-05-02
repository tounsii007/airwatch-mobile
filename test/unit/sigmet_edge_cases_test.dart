import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/map/domain/turbulence/parse_sigmet.dart';

void main() {
  group('parseSigmetResponse — malformed input handling', () {
    test('non-list inputs all return empty list (defensive)', () {
      expect(parseSigmetResponse(null), isEmpty);
      expect(parseSigmetResponse('a string'), isEmpty);
      expect(parseSigmetResponse(42), isEmpty);
      expect(parseSigmetResponse(<String, dynamic>{'wrong': 'shape'}),
          isEmpty);
    });

    test('list with non-map entries skips them silently', () {
      final r = [
        'a string entry',
        42,
        null,
        {'hazard': 'TURB', 'severity': 'mod', 'coords': '0 0 1 1 2 2'},
      ];
      // Only the well-formed map should produce a zone.
      expect(parseSigmetResponse(r), hasLength(1));
    });

    test('coord string with NaN values is skipped', () {
      final r = [
        {
          'hazard': 'TURB',
          'severity': 'mod',
          // "NaN" parses to NaN — implementation rejects.
          'coords': '0 0 NaN NaN 2 2',
        },
      ];
      expect(parseSigmetResponse(r), isEmpty);
    });

    test('coord string with odd number of values (incomplete pair) skipped',
        () {
      final r = [
        {
          'hazard': 'TURB',
          'severity': 'mod',
          'coords': '0 0 1 1 2', // missing trailing lon
        },
      ];
      expect(parseSigmetResponse(r), isEmpty);
    });

    test('polygon with exactly 3 vertices is the boundary — accepted', () {
      // Exactly 3 = minimum to form a triangle.
      final r = [
        {
          'hazard': 'TURB',
          'severity': 'mod',
          'coords': '50 8 51 9 49 10',
        },
      ];
      expect(parseSigmetResponse(r), hasLength(1));
      expect(parseSigmetResponse(r).first.polygon, hasLength(3));
    });

    test('polygon with 2 vertices is rejected (line, not polygon)', () {
      final r = [
        {
          'hazard': 'TURB',
          'severity': 'mod',
          'coords': '50 8 51 9',
        },
      ];
      expect(parseSigmetResponse(r), isEmpty);
    });

    test('"area" alternate key works', () {
      final r = [
        {
          'hazard': 'CONVECTIVE',
          'severity': 'mod',
          'area': [
            {'lat': 0, 'lon': 0},
            {'lat': 1, 'lon': 1},
            {'lat': 2, 'lon': 2},
          ],
        },
      ];
      expect(parseSigmetResponse(r), hasLength(1));
    });

    test('mixed entries — some hazards turb/conv, others irrelevant', () {
      final r = [
        {'hazard': 'ICE', 'severity': 'mod', 'coords': '0 0 1 1 2 2'},
        {'hazard': 'TURB', 'severity': 'mod', 'coords': '0 0 1 1 2 2'},
        {'hazard': 'CONVECTIVE', 'coords': '0 0 1 1 2 2'},
        {'hazard': 'VOLCANO', 'severity': 'severe', 'coords': '0 0 1 1 2 2'},
      ];
      // ICE and VOLCANO are rejected; TURB and CONVECTIVE pass.
      final out = parseSigmetResponse(r);
      expect(out, hasLength(2));
    });
  });

  group('parseSigmetResponse — severity classifier', () {
    test('"sev"/"severe"/"extreme" → severe', () {
      for (final s in ['sev', 'severe', 'extreme', 'EXTREME']) {
        final r = [
          {'hazard': 'TURB', 'severity': s, 'coords': '0 0 1 1 2 2'},
        ];
        expect(parseSigmetResponse(r).first.severity,
            TurbulenceSeverity.severe);
      }
    });

    test('"mod"/"moderate" → moderate', () {
      for (final s in ['mod', 'moderate', 'MODERATE']) {
        final r = [
          {'hazard': 'TURB', 'severity': s, 'coords': '0 0 1 1 2 2'},
        ];
        expect(parseSigmetResponse(r).first.severity,
            TurbulenceSeverity.moderate);
      }
    });

    test('"light"/"lgt" → light', () {
      for (final s in ['light', 'lgt', 'LIGHT']) {
        final r = [
          {'hazard': 'TURB', 'severity': s, 'coords': '0 0 1 1 2 2'},
        ];
        expect(parseSigmetResponse(r).first.severity,
            TurbulenceSeverity.light);
      }
    });

    test('unknown severity defaults to moderate', () {
      final r = [
        {'hazard': 'TURB', 'severity': 'unknown weird text', 'coords': '0 0 1 1 2 2'},
      ];
      expect(parseSigmetResponse(r).first.severity, TurbulenceSeverity.moderate);
    });

    test('missing severity but convective hazard → moderate fallback', () {
      final r = [
        {'hazard': 'CONVECTIVE', 'coords': '0 0 1 1 2 2'},
      ];
      expect(parseSigmetResponse(r).first.severity, TurbulenceSeverity.moderate);
    });

    test('missing severity AND non-convective turb → entry skipped', () {
      // The implementation uses _severity(...) which never returns null
      // for non-empty input; missing field is the only path to null
      // and the convective fallback covers that. Result: a TURB entry
      // with no `severity` key still parses (default-moderate from the
      // _severity fallback path).
      final r = [
        {'hazard': 'TURB', 'coords': '0 0 1 1 2 2'},
      ];
      // Per the impl: `_severity(null)` → null, but the convective
      // fallback only kicks in for `convective` hazard. So a turb
      // without severity is dropped.
      expect(parseSigmetResponse(r), isEmpty);
    });
  });

  group('id fallback', () {
    test('uses airSigmetId when present', () {
      final r = [
        {
          'airSigmetId': 'awc-123',
          'hazard': 'TURB',
          'severity': 'mod',
          'coords': '0 0 1 1 2 2',
        },
      ];
      expect(parseSigmetResponse(r).first.id, 'awc-123');
    });

    test('falls back to "id" key', () {
      final r = [
        {
          'id': 'fallback-1',
          'hazard': 'TURB',
          'severity': 'mod',
          'coords': '0 0 1 1 2 2',
        },
      ];
      expect(parseSigmetResponse(r).first.id, 'fallback-1');
    });

    test('synthesises sigmet-N when both id keys are missing', () {
      final r = [
        {'hazard': 'TURB', 'severity': 'mod', 'coords': '0 0 1 1 2 2'},
        {'hazard': 'TURB', 'severity': 'mod', 'coords': '3 3 4 4 5 5'},
      ];
      final out = parseSigmetResponse(r);
      expect(out[0].id, 'sigmet-0');
      expect(out[1].id, 'sigmet-1');
    });
  });
}
