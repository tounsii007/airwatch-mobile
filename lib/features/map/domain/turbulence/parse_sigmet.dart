import 'package:flutter/painting.dart';

/// Severity level reported by the AWC SIGMET feed.
enum TurbulenceSeverity { light, moderate, severe }

/// Hex colour shown for each severity tier — matches the web frontend's
/// `getSeverityColor` palette so a yellow polygon on the web app and on
/// mobile mean the same thing.
Color severityColor(TurbulenceSeverity s) => switch (s) {
  TurbulenceSeverity.light => const Color(0xFFEAB308),
  TurbulenceSeverity.moderate => const Color(0xFFF97316),
  TurbulenceSeverity.severe => const Color(0xFFEF4444),
};

/// Parsed turbulence / convective zone polygon ready to render.
class TurbulenceZone {
  final String id;
  final String hazard;
  final TurbulenceSeverity severity;

  /// Lat / lon vertices of the affected area (closed polygon — last
  /// point may equal first, depending on source).
  final List<List<double>> polygon;

  final double? altitudeLowFt;
  final double? altitudeHighFt;
  final String validFrom;
  final String validTo;

  const TurbulenceZone({
    required this.id,
    required this.hazard,
    required this.severity,
    required this.polygon,
    this.altitudeLowFt,
    this.altitudeHighFt,
    this.validFrom = '',
    this.validTo = '',
  });
}

/// Parse the AWC `/api/data/airsigmet?format=json` response into a list
/// of turbulence + convective zones.
///
/// <p>Mirrors the web frontend's `parseSigmetResponse` — same severity
/// classifier, same coord-format tolerance, same hazard whitelist
/// (turbulence, convective, thunderstorm) so a polygon shown on the
/// web is also shown on mobile.
List<TurbulenceZone> parseSigmetResponse(dynamic raw) {
  if (raw is! List) return const [];
  final out = <TurbulenceZone>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final d = Map<String, dynamic>.from(item);

    final hazard =
        (d['hazard'] ?? d['airsigmetType'] ?? d['rawAirSigmet'] ?? '')
            .toString();
    final hazLow = hazard.toLowerCase();
    if (!hazLow.contains('turb') &&
        !hazLow.contains('convective') &&
        !hazLow.contains('ts')) {
      continue;
    }

    final severity =
        _severity(d['severity'] ?? d['intensity']) ??
        (hazLow.contains('convective') ? TurbulenceSeverity.moderate : null);
    if (severity == null) continue;

    final polygon = _parseCoords(d);
    if (polygon == null || polygon.length < 3) continue;

    out.add(
      TurbulenceZone(
        id: (d['airSigmetId'] ?? d['id'] ?? 'sigmet-${out.length}').toString(),
        hazard: hazard,
        severity: severity,
        polygon: polygon,
        altitudeLowFt: (d['altitudeLow1'] as num?)?.toDouble(),
        altitudeHighFt: (d['altitudeHi1'] as num?)?.toDouble(),
        validFrom: (d['validTimeFrom'] ?? d['issueTime'] ?? '').toString(),
        validTo: (d['validTimeTo'] ?? '').toString(),
      ),
    );
  }
  return out;
}

TurbulenceSeverity? _severity(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().toLowerCase();
  if (s.contains('sev') || s.contains('extreme'))
    return TurbulenceSeverity.severe;
  if (s.contains('mod')) return TurbulenceSeverity.moderate;
  if (s.contains('light') || s.contains('lgt')) return TurbulenceSeverity.light;
  return TurbulenceSeverity.moderate;
}

/// Parse coordinates out of any of the three shapes the AWC API uses:
/// <ul>
///   <li>`coords: [{lat, lon}, …]` — modern shape</li>
///   <li>`coords: "lat lon lat lon …"` — legacy space-separated</li>
///   <li>`area: [{lat, lon}, …]` — alternative key</li>
/// </ul>
List<List<double>>? _parseCoords(Map<String, dynamic> d) {
  final coords = d['coords'];
  if (coords is List) {
    final pts = coords
        .whereType<Map>()
        .where((p) => p['lat'] != null && p['lon'] != null)
        .map<List<double>>(
          (p) => [(p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()],
        )
        .toList();
    return pts.length >= 3 ? pts : null;
  }
  if (coords is String) {
    final nums = coords
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.tryParse)
        .toList();
    if (nums.length < 6 || nums.length.isOdd) return null;
    // Reject both `null` (unparseable token) AND `NaN` (parse-able as
    // double but useless as a coordinate). `double.tryParse('NaN')`
    // returns `double.nan` rather than null, so the null-check alone
    // lets a NaN polygon slip through and feed the renderer garbage.
    if (nums.any((n) => n == null || n.isNaN)) return null;
    final pts = <List<double>>[];
    for (var i = 0; i < nums.length; i += 2) {
      pts.add([nums[i]!, nums[i + 1]!]);
    }
    return pts.length >= 3 ? pts : null;
  }
  final area = d['area'];
  if (area is List) {
    final pts = area
        .whereType<Map>()
        .where((p) => p['lat'] != null && p['lon'] != null)
        .map<List<double>>(
          (p) => [(p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()],
        )
        .toList();
    return pts.length >= 3 ? pts : null;
  }
  return null;
}
