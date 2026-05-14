import 'package:airwatch_mobile/features/geofences/domain/alert_format.dart';
import 'package:airwatch_mobile/features/geofences/presentation/providers/geofence_alerts_provider.dart';

/// Aggregated per-fence rollup. Mirrors airwatch-web's `fenceStats.ts`
/// (commit 982c6d2) — kept naming + semantics identical so a future
/// shared-schema export reads cleanly across both platforms.
class FenceStats {
  /// Total alerts recorded for this fence in the live history window.
  final int total;

  /// Most-frequent airline pair (ICAO + resolved name + count). null
  /// when callsigns are absent or the dedup map sees no winners.
  final FenceStatsTopAirline? topAirline;

  /// Unique aircraft (by icao24) that triggered this fence.
  final int uniqueAircraft;

  /// Timestamp of the newest alert in the history window. null when
  /// no alerts.
  final DateTime? latestAt;

  /// Average altitude across all alerts (metres). null when no alerts.
  final int? avgAltitudeMeters;

  const FenceStats({
    required this.total,
    required this.topAirline,
    required this.uniqueAircraft,
    required this.latestAt,
    required this.avgAltitudeMeters,
  });

  static const empty = FenceStats(
    total: 0,
    topAirline: null,
    uniqueAircraft: 0,
    latestAt: null,
    avgAltitudeMeters: null,
  );
}

class FenceStatsTopAirline {
  final String code;
  final String? name;
  final int count;
  const FenceStatsTopAirline({
    required this.code,
    required this.name,
    required this.count,
  });
}

/// Compute the per-fence rollup. O(n) over the hits list; mirrors the
/// pure aggregation contract of the web's computeFenceStats — alerts
/// outside [fenceId] contribute nothing.
///
/// <p>The mobile alerts feed is a list of [GeoFenceHit] — `(aircraft,
/// fence)` pairs computed live on every tick. There's no history store
/// like the web's geofenceStore yet; this still gives a useful "right
/// now" rollup of currently-inside-the-zone traffic.
FenceStats computeFenceStats(
  List<GeoFenceHit> hits,
  String fenceId, {
  DateTime? now,
}) {
  final subset = hits.where((h) => h.fence.id == fenceId).toList();
  if (subset.isEmpty) return FenceStats.empty;

  // Top airline: prefer the first 3 callsign chars (the airline ICAO).
  // Live mobile alerts don't carry an explicit airlineIcao; the
  // callsign prefix is the canonical source.
  final airlineCounts = <String, int>{};
  double altSum = 0;
  int altSamples = 0;
  final seenAircraft = <String>{};
  DateTime? latestAt;

  for (final h in subset) {
    seenAircraft.add(h.aircraft.icao24);
    final baro = h.aircraft.baroAltitude;
    if (baro != null) {
      altSum += baro;
      altSamples++;
    }
    // No per-hit timestamp on mobile — every live hit is "now".
    latestAt = now ?? DateTime.now();
    final cs = (h.aircraft.callsign ?? '').trim().toUpperCase();
    if (cs.length >= 3) {
      final code = cs.substring(0, 3);
      airlineCounts[code] = (airlineCounts[code] ?? 0) + 1;
    }
  }

  FenceStatsTopAirline? topAirline;
  if (airlineCounts.isNotEmpty) {
    var bestCode = '';
    var bestCount = 0;
    airlineCounts.forEach((code, count) {
      if (count > bestCount) {
        bestCode = code;
        bestCount = count;
      }
    });
    topAirline = FenceStatsTopAirline(
      code: bestCode,
      name: resolveAirlineName(bestCode),
      count: bestCount,
    );
  }

  return FenceStats(
    total: subset.length,
    topAirline: topAirline,
    uniqueAircraft: seenAircraft.length,
    latestAt: latestAt,
    avgAltitudeMeters: altSamples == 0 ? null : (altSum / altSamples).round(),
  );
}
