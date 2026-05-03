import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/map/domain/turbulence/parse_sigmet.dart';

/// Mirrors the web frontend's `parseSigmet.test.ts`. Pure JSON
/// transformer — no Flutter widgets, no network.
void main() {
  group('parseSigmetResponse', () {
    test('returns empty list for non-array input', () {
      expect(parseSigmetResponse(null), isEmpty);
      expect(parseSigmetResponse('not an array'), isEmpty);
      expect(parseSigmetResponse(<String, dynamic>{'wrong': 'shape'}), isEmpty);
    });

    test('parses a turbulence SIGMET with array coords', () {
      final response = [
        {
          'airSigmetId': 'sigmet-1',
          'hazard': 'TURB',
          'severity': 'moderate',
          'coords': [
            {'lat': 50.0, 'lon': 8.0},
            {'lat': 51.0, 'lon': 9.0},
            {'lat': 49.5, 'lon': 9.5},
          ],
          'altitudeLow1': 18000,
          'altitudeHi1': 35000,
        },
      ];
      final zones = parseSigmetResponse(response);
      expect(zones, hasLength(1));
      final z = zones.first;
      expect(z.id, 'sigmet-1');
      expect(z.severity, TurbulenceSeverity.moderate);
      expect(z.polygon, hasLength(3));
      expect(z.altitudeLowFt, 18000);
      expect(z.altitudeHighFt, 35000);
    });

    test('parses space-separated coord string', () {
      final response = [
        {
          'id': 'sigmet-2',
          'hazard': 'TURB',
          'severity': 'sev',
          'coords': '50 8 51 9 49 10',
        },
      ];
      final zones = parseSigmetResponse(response);
      expect(zones, hasLength(1));
      expect(zones.first.severity, TurbulenceSeverity.severe);
      expect(zones.first.polygon, hasLength(3));
    });

    test('skips non-turbulence / non-convective items', () {
      final response = [
        {'hazard': 'ICE', 'severity': 'moderate', 'coords': '0 0 1 1 2 2'},
        {'hazard': 'TURB', 'severity': 'light', 'coords': '0 0 1 1 2 2'},
      ];
      final zones = parseSigmetResponse(response);
      expect(zones, hasLength(1));
      expect(zones.first.severity, TurbulenceSeverity.light);
    });

    test('skips entries with too few coords', () {
      final response = [
        {'hazard': 'TURB', 'severity': 'mod', 'coords': '50 8 51 9'},
      ];
      expect(parseSigmetResponse(response), isEmpty);
    });

    test('convective hazard defaults to moderate severity', () {
      final response = [
        {'hazard': 'CONVECTIVE SIGMET', 'coords': '0 0 1 1 2 2'},
      ];
      final zones = parseSigmetResponse(response);
      expect(zones, hasLength(1));
      expect(zones.first.severity, TurbulenceSeverity.moderate);
    });
  });

  group('severityColor', () {
    test('light is yellow, moderate is orange, severe is red', () {
      expect(
        severityColor(TurbulenceSeverity.light).toARGB32().toRadixString(16),
        contains('eab308'),
      );
      expect(
        severityColor(TurbulenceSeverity.moderate).toARGB32().toRadixString(16),
        contains('f97316'),
      );
      expect(
        severityColor(TurbulenceSeverity.severe).toARGB32().toRadixString(16),
        contains('ef4444'),
      );
    });
  });
}
