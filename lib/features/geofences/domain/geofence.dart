import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/core/utils/geo_utils.dart';
import 'package:latlong2/latlong.dart';

/// Geofence shape — circle or rectangle. Mirrors the web frontend's
/// `GeoFence` type so the two clients can share a future server payload.
enum GeoFenceType { circle, rectangle }

/// Self-contained client-side geofence definition.
///
/// <p>The web stores fences server-side via REST; mobile keeps them on
/// device under `SharedPreferences`. The shape on disk is identical
/// to the REST payload so a future migration ("upload my fences to
/// the backend") just iterates the local list and POSTs each one.
class GeoFence {
  /// Local identifier — always set on mobile; on the web this comes
  /// from the backend's auto-increment column.
  final String id;
  final String name;
  final GeoFenceType type;

  /// Circle parameters (only meaningful when [type] == circle).
  final double? centerLat;
  final double? centerLon;
  final double? radiusKm;

  /// Rectangle bounds (only meaningful when [type] == rectangle).
  final double? northLat;
  final double? southLat;
  final double? eastLon;
  final double? westLon;

  /// Optional aircraft-state filters — restrict alerts to flights
  /// inside the relevant altitude band / airline.
  final double? minAltitudeFt;
  final double? maxAltitudeFt;
  final String? airlineFilter;

  /// `false` silences the fence without deleting it.
  final bool active;

  final DateTime createdAt;

  GeoFence({
    required this.id,
    required this.name,
    required this.type,
    this.centerLat,
    this.centerLon,
    this.radiusKm,
    this.northLat,
    this.southLat,
    this.eastLon,
    this.westLon,
    this.minAltitudeFt,
    this.maxAltitudeFt,
    this.airlineFilter,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GeoFence copyWith({bool? active, String? name}) => GeoFence(
        id: id,
        name: name ?? this.name,
        type: type,
        centerLat: centerLat,
        centerLon: centerLon,
        radiusKm: radiusKm,
        northLat: northLat,
        southLat: southLat,
        eastLon: eastLon,
        westLon: westLon,
        minAltitudeFt: minAltitudeFt,
        maxAltitudeFt: maxAltitudeFt,
        airlineFilter: airlineFilter,
        active: active ?? this.active,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'centerLat': centerLat,
        'centerLon': centerLon,
        'radiusKm': radiusKm,
        'northLat': northLat,
        'southLat': southLat,
        'eastLon': eastLon,
        'westLon': westLon,
        'minAltitudeFt': minAltitudeFt,
        'maxAltitudeFt': maxAltitudeFt,
        'airlineFilter': airlineFilter,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeoFence.fromJson(Map<String, dynamic> j) => GeoFence(
        id: j['id'] as String,
        name: j['name'] as String,
        type: GeoFenceType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => GeoFenceType.circle,
        ),
        centerLat: (j['centerLat'] as num?)?.toDouble(),
        centerLon: (j['centerLon'] as num?)?.toDouble(),
        radiusKm: (j['radiusKm'] as num?)?.toDouble(),
        northLat: (j['northLat'] as num?)?.toDouble(),
        southLat: (j['southLat'] as num?)?.toDouble(),
        eastLon: (j['eastLon'] as num?)?.toDouble(),
        westLon: (j['westLon'] as num?)?.toDouble(),
        minAltitudeFt: (j['minAltitudeFt'] as num?)?.toDouble(),
        maxAltitudeFt: (j['maxAltitudeFt'] as num?)?.toDouble(),
        airlineFilter: j['airlineFilter'] as String?,
        active: (j['active'] as bool?) ?? true,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// True when the aircraft's current position satisfies every active
/// constraint of the fence — geometry + altitude + airline.
///
/// <p>Used by the alert provider on every flight tick. The web frontend
/// runs the same predicate server-side (in `GeoFenceMatcher.kt`); we
/// keep the formula in pure Dart so the mobile client doesn't need a
/// network round-trip per tick.
bool aircraftIsInsideFence(AircraftState ac, GeoFence f) {
  if (!f.active) return false;
  final pos = ac.position;
  if (pos == null) return false;

  // Geometry check.
  bool inside;
  if (f.type == GeoFenceType.circle) {
    if (f.centerLat == null || f.centerLon == null || f.radiusKm == null) {
      return false;
    }
    final dist = GeoUtils.distanceKm(
      LatLng(f.centerLat!, f.centerLon!),
      pos,
    );
    inside = dist <= f.radiusKm!;
  } else {
    if (f.northLat == null ||
        f.southLat == null ||
        f.eastLon == null ||
        f.westLon == null) {
      return false;
    }
    inside = pos.latitude <= f.northLat! &&
        pos.latitude >= f.southLat! &&
        pos.longitude <= f.eastLon! &&
        pos.longitude >= f.westLon!;
  }
  if (!inside) return false;

  // Altitude band — feet.
  final altFt = ac.baroAltitude == null ? null : ac.baroAltitude! * 3.28084;
  if (f.minAltitudeFt != null && (altFt == null || altFt < f.minAltitudeFt!)) {
    return false;
  }
  if (f.maxAltitudeFt != null && (altFt == null || altFt > f.maxAltitudeFt!)) {
    return false;
  }

  // Airline filter — case-insensitive prefix match against the
  // callsign's leading 3 chars (the airline ICAO).
  if (f.airlineFilter != null && f.airlineFilter!.isNotEmpty) {
    final cs = (ac.callsign ?? '').toUpperCase();
    if (cs.length < 3) return false;
    if (cs.substring(0, 3) != f.airlineFilter!.toUpperCase()) {
      return false;
    }
  }

  return true;
}
