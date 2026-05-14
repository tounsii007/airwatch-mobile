import 'dart:convert';

import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';

/// Export / import a set of geofences as JSON.
///
/// <p>Round-trip rules mirror airwatch-web's `fenceIO.ts` (commit
/// 982c6d2) so a JSON file exported on one platform is readable on the
/// other:
/// <ul>
///   <li>Exported file omits `id` and `createdAt` — those are scoped to
///       the specific instance. The receiving side mints fresh ones.</li>
///   <li>`active` defaults to true on import.</li>
///   <li>The shape is validated by the same fields the [GeoFence.fromJson]
///       constructor expects; out-of-range inputs surface a
///       human-readable error rather than crash.</li>
///   <li>File format is a top-level object {version, exportedAt,
///       fences} rather than a bare array — leaves room for a future
///       migration without breaking existing exports.</li>
/// </ul>
const int kExportFileVersion = 1;

/// Result of a parse attempt — discriminated union.
sealed class FenceImportResult {
  const FenceImportResult();
}

class FenceImportOk extends FenceImportResult {
  final List<GeoFence> fences;
  const FenceImportOk(this.fences);
}

class FenceImportErr extends FenceImportResult {
  /// User-visible error path (e.g. "fences.0.radiusKm"). Empty string
  /// when the failure is at the top level (e.g. invalid JSON).
  final String path;
  final String message;
  const FenceImportErr(this.message, {this.path = ''});
}

/// Pretty-printed export envelope ready for download / share.
String buildExportJson(List<GeoFence> fences, {DateTime? now}) {
  final stamp = (now ?? DateTime.now()).toUtc().toIso8601String();
  final envelope = {
    'version': kExportFileVersion,
    'exportedAt': stamp,
    'fences': fences.map((f) {
      // Strip per-instance fields — id is scoped to this install, and
      // createdAt is meaningless on a receiving side that wants a
      // fresh entry. `active` is preserved so a "paused" fence stays
      // paused when round-tripped.
      final m = f.toJson();
      m.remove('id');
      m.remove('createdAt');
      return m;
    }).toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(envelope);
}

/// Parse + validate raw JSON text into a typed list of fences.
///
/// Returns a discriminated union so callers can show a friendly error
/// to the user rather than crashing on a malformed file.
FenceImportResult parseImportJson(String raw) {
  Object? json;
  try {
    json = jsonDecode(raw);
  } catch (e) {
    return FenceImportErr('Invalid JSON: ${e.toString()}');
  }

  if (json is! Map) {
    return const FenceImportErr(
      'Expected an object with version, exportedAt, fences',
    );
  }

  final v = json['version'];
  if (v != kExportFileVersion) {
    return FenceImportErr(
      'Unsupported export version: $v (expected $kExportFileVersion)',
      path: 'version',
    );
  }

  final raws = json['fences'];
  if (raws is! List) {
    return const FenceImportErr(
      'Expected fences array',
      path: 'fences',
    );
  }

  final out = <GeoFence>[];
  for (var i = 0; i < raws.length; i++) {
    final entry = raws[i];
    if (entry is! Map) {
      return FenceImportErr('Not an object', path: 'fences.$i');
    }
    // The export envelope strips `id` and `createdAt` (those are
    // local-instance fields). [GeoFence.fromJson] requires both, so
    // we inject neutral placeholders before deserialising — the
    // [_adoptForLocal] step below replaces them with fresh values.
    final patched = <String, dynamic>{
      'id': '_import_$i',
      'createdAt': DateTime.now().toIso8601String(),
      ...Map<String, dynamic>.from(entry),
    };
    try {
      final fence = _adoptForLocal(GeoFence.fromJson(patched));
      final err = _validate(fence);
      if (err != null) {
        return FenceImportErr(err, path: 'fences.$i');
      }
      out.add(fence);
    } catch (e) {
      return FenceImportErr(e.toString(), path: 'fences.$i');
    }
  }

  return FenceImportOk(out);
}

/// Stamp a freshly-imported fence with a local-instance id + createdAt.
GeoFence _adoptForLocal(GeoFence f) {
  return GeoFence(
    id: 'fence-${DateTime.now().millisecondsSinceEpoch}-${f.name.hashCode}',
    name: f.name,
    type: f.type,
    centerLat: f.centerLat,
    centerLon: f.centerLon,
    radiusKm: f.radiusKm,
    northLat: f.northLat,
    southLat: f.southLat,
    eastLon: f.eastLon,
    westLon: f.westLon,
    minAltitudeFt: f.minAltitudeFt,
    maxAltitudeFt: f.maxAltitudeFt,
    airlineFilter: f.airlineFilter,
    active: f.active,
  );
}

/// Range-check the imported fence — same rules as the form validator.
/// Returns a human-readable error path or null when ok.
String? _validate(GeoFence f) {
  if (f.name.trim().isEmpty) return 'name: required';
  if (f.type == GeoFenceType.circle) {
    final lat = f.centerLat;
    final lon = f.centerLon;
    final r = f.radiusKm;
    if (lat == null || lat < -90 || lat > 90) {
      return 'centerLat: out of range (-90..90)';
    }
    if (lon == null || lon < -180 || lon > 180) {
      return 'centerLon: out of range (-180..180)';
    }
    if (r == null || r <= 0) return 'radiusKm: must be > 0';
  } else {
    final n = f.northLat;
    final s = f.southLat;
    final e = f.eastLon;
    final w = f.westLon;
    if (n == null || s == null || e == null || w == null) {
      return 'bounds: all four required';
    }
    if (n <= s) return 'northLat: must be > southLat';
    if (e <= w) return 'eastLon: must be > westLon';
  }
  return null;
}
