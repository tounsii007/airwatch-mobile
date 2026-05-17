import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/geofences/data/fence_io.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';

/// Mirrors airwatch-web's `fenceIO.test.ts` (commit 982c6d2): round-trip
/// fidelity, version-literal enforcement, validation errors, partial
/// rejection paths.
void main() {
  GeoFence buildCircle() => GeoFence(
    id: 'f1',
    name: 'Frankfurt 50km',
    type: GeoFenceType.circle,
    centerLat: 50.0379,
    centerLon: 8.5622,
    radiusKm: 50,
    minAltitudeFt: 1000,
    maxAltitudeFt: 38000,
    airlineFilter: 'DLH',
  );

  GeoFence buildRect() => GeoFence(
    id: 'f2',
    name: 'Mediterranean box',
    type: GeoFenceType.rectangle,
    northLat: 45,
    southLat: 35,
    eastLon: 20,
    westLon: 5,
  );

  group('buildExportJson', () {
    test('produces an envelope with version + ISO timestamp + fences', () {
      final fence = buildCircle();
      final json = buildExportJson([fence], now: DateTime.utc(2026, 5, 14, 12));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['version'], kExportFileVersion);
      expect(decoded['exportedAt'], '2026-05-14T12:00:00.000Z');
      expect((decoded['fences'] as List).length, 1);
    });

    test('strips id + createdAt from every fence', () {
      final json = buildExportJson([buildCircle()]);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final fence = (decoded['fences'] as List).first as Map<String, dynamic>;
      expect(fence.containsKey('id'), isFalse);
      expect(fence.containsKey('createdAt'), isFalse);
      expect(fence['name'], 'Frankfurt 50km');
    });
  });

  group('parseImportJson — happy path', () {
    test('round-trips a single circle', () {
      final original = buildCircle();
      final json = buildExportJson([original]);
      final result = parseImportJson(json);
      expect(result, isA<FenceImportOk>());
      final out = (result as FenceImportOk).fences;
      expect(out.length, 1);
      expect(out.first.name, original.name);
      expect(out.first.centerLat, original.centerLat);
      expect(out.first.radiusKm, original.radiusKm);
      expect(out.first.airlineFilter, 'DLH');
      // Local-instance fields get fresh values, not the original.
      expect(out.first.id, isNot(original.id));
    });

    test('round-trips a rectangle', () {
      final json = buildExportJson([buildRect()]);
      final result = parseImportJson(json);
      expect(result, isA<FenceImportOk>());
      final out = (result as FenceImportOk).fences.first;
      expect(out.type, GeoFenceType.rectangle);
      expect(out.northLat, 45);
      expect(out.southLat, 35);
    });

    test('round-trips a mixed batch', () {
      final json = buildExportJson([buildCircle(), buildRect()]);
      final result = parseImportJson(json);
      expect(result, isA<FenceImportOk>());
      final out = (result as FenceImportOk).fences;
      expect(out.length, 2);
    });
  });

  group('parseImportJson — rejection paths', () {
    test('rejects invalid JSON syntax', () {
      final result = parseImportJson('not-json');
      expect(result, isA<FenceImportErr>());
      expect((result as FenceImportErr).message, contains('Invalid JSON'));
    });

    test('rejects a top-level array (envelope expected)', () {
      final result = parseImportJson('[]');
      expect(result, isA<FenceImportErr>());
    });

    test('rejects unsupported version', () {
      final result = parseImportJson(
        '{"version": 99, "exportedAt": "x", "fences": []}',
      );
      expect(result, isA<FenceImportErr>());
      expect((result as FenceImportErr).path, 'version');
    });

    test('rejects an out-of-range latitude', () {
      final raw = jsonEncode({
        'version': kExportFileVersion,
        'exportedAt': '2026-05-14T12:00:00Z',
        'fences': [
          {
            'name': 'bad',
            'type': 'circle',
            'centerLat': 200, // > 90
            'centerLon': 0,
            'radiusKm': 10,
            'active': true,
            'createdAt': '2026-05-14T12:00:00Z',
          },
        ],
      });
      final result = parseImportJson(raw);
      expect(result, isA<FenceImportErr>());
      expect((result as FenceImportErr).path, 'fences.0');
    });

    test('rejects a rectangle with north <= south', () {
      final raw = jsonEncode({
        'version': kExportFileVersion,
        'exportedAt': '2026-05-14T12:00:00Z',
        'fences': [
          {
            'name': 'bad',
            'type': 'rectangle',
            'northLat': 30,
            'southLat': 40,
            'eastLon': 20,
            'westLon': 5,
            'active': true,
            'createdAt': '2026-05-14T12:00:00Z',
          },
        ],
      });
      final result = parseImportJson(raw);
      expect(result, isA<FenceImportErr>());
    });
  });
}
