import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Outcome of a fleet-info fetch — either a populated [FleetInfo],
/// or null when both registry + sightings are missing (the UI hides
/// the entire card in that case rather than rendering "Unknown"
/// placeholders).
class FleetInfo {
  final String icao24;
  final FleetRegistry? registry;
  final FleetSightings? sightings;

  const FleetInfo({required this.icao24, this.registry, this.sightings});

  bool get isEmpty => registry == null && sightings == null;
}

/// Registry subsection — the merged hexdb fields the FleetInfoCard
/// surfaces. Year arithmetic is sanity-bounded by the caller (1950 ≤
/// year ≤ now+1) so junk strings from stale hexdb rows don't render
/// as "1984 yrs old".
class FleetRegistry {
  final String? registration;
  final String? manufacturer;
  final String? type;
  final int? builtYear;
  final String? owner;
  final String? country;

  const FleetRegistry({
    this.registration,
    this.manufacturer,
    this.type,
    this.builtYear,
    this.owner,
    this.country,
  });

  factory FleetRegistry.fromMap(Map<String, dynamic> map) {
    int? parseYear(Object? raw) {
      if (raw == null) return null;
      final s = raw.toString().trim();
      if (s.isEmpty) return null;
      final n = int.tryParse(s);
      if (n == null) return null;
      // Sanity bound — drops "0042" / "9999" placeholder rows.
      final now = DateTime.now().year + 1;
      if (n < 1950 || n > now) return null;
      return n;
    }

    String? readString(List<String> keys) {
      for (final k in keys) {
        final v = map[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    return FleetRegistry(
      registration: readString(['Registration', 'registration']),
      manufacturer: readString(['Manufacturer', 'manufacturer']),
      type: readString(['Type', 'ICAOTypeCode', 'type']),
      builtYear: parseYear(map['Built'] ?? map['built'] ?? map['BuiltYear']),
      owner: readString(['RegisteredOwners', 'OperatorFlagCode', 'owner']),
      country: readString(['Country', 'country']),
    );
  }

  bool get isEmpty =>
      registration == null &&
      manufacturer == null &&
      type == null &&
      builtYear == null;
}

/// Sighting subsection — AirWatch's own first/last-seen counts.
class FleetSightings {
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final int count;
  final String? registration;
  final String? typeCode;

  const FleetSightings({
    this.firstSeenAt,
    this.lastSeenAt,
    this.count = 0,
    this.registration,
    this.typeCode,
  });

  factory FleetSightings.fromMap(Map<String, dynamic> map) {
    DateTime? parseTs(Object? raw) {
      if (raw is! String || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return FleetSightings(
      firstSeenAt: parseTs(map['firstSeenAt']),
      lastSeenAt: parseTs(map['lastSeenAt']),
      count: (map['count'] as num?)?.toInt() ?? 0,
      registration: map['registration']?.toString(),
      typeCode: map['typeCode']?.toString(),
    );
  }

  bool get isEmpty => count == 0 && firstSeenAt == null && lastSeenAt == null;
}

/// Thin client for the `/api/proxy/aircraft/{hex}` endpoint (api commit
/// 015853c). Returns null on any error — the FleetInfoCard hides itself
/// rather than rendering an error placeholder.
class FleetInfoService {
  final Dio _dio;

  FleetInfoService({Dio? dio})
    : _dio =
          dio ?? AppHttpClient.create(receiveTimeout: AppConfig.shortTimeout);

  Future<FleetInfo?> load(String hex) async {
    final code = hex.trim().toLowerCase();
    if (code.length != 6) return null;
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.aircraftFleet(code),
      );
      if (response.statusCode != 200) return null;
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;

      final registryRaw = body['registry'];
      final sightingsRaw = body['sightings'];
      final registry = registryRaw is Map<String, dynamic>
          ? FleetRegistry.fromMap(registryRaw)
          : null;
      final sightings = sightingsRaw is Map<String, dynamic>
          ? FleetSightings.fromMap(sightingsRaw)
          : null;

      // Hide the card on a total miss instead of rendering empty rows.
      if ((registry == null || registry.isEmpty) &&
          (sightings == null || sightings.isEmpty)) {
        return null;
      }
      return FleetInfo(
        icao24: code,
        registry: registry?.isEmpty == true ? null : registry,
        sightings: sightings?.isEmpty == true ? null : sightings,
      );
    } catch (e, stack) {
      debugPrint('[FleetInfo] $code: $e\n$stack');
      return null;
    }
  }
}
