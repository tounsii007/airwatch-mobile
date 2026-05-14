import 'package:airwatch_mobile/core/constants/airline_database.dart';

/// Pure formatting helpers for the geofence alert panel.
///
/// <p>Lives in a separate file so the heavy [AlertsPanel] widget code
/// doesn't have to bundle test setup, and so the formatters can be
/// unit-tested at function-level without Flutter bindings overhead.
///
/// <p>Mirrors airwatch-web's `src/app/(public)/geofences/alertFormat.ts`
/// commit 01d0841 — keeping the breakpoints identical so identical
/// inputs produce identical labels on both platforms.

/// Time-since formatter that produces compact human-readable spans:
///
///   < 5 s    → "just now"
///   < 60 s   → "12s"
///   < 60 m   → "5m"
///   < 24 h   → "3h"
///   ≥ 24 h   → "2d"
///
/// [nowMs] is injected so tests are deterministic — pass
/// `DateTime.now().millisecondsSinceEpoch` at call site; never let the
/// formatter read the clock itself.
String timeAgo(DateTime timestamp, int nowMs) {
  final t = timestamp.millisecondsSinceEpoch;
  final diffMs = nowMs - t;
  if (diffMs < 0) return 'just now'; // future timestamp (clock skew)
  final sec = diffMs ~/ 1000;
  if (sec < 5) return 'just now';
  if (sec < 60) return '${sec}s';
  final min = sec ~/ 60;
  if (min < 60) return '${min}m';
  final hr = min ~/ 60;
  if (hr < 24) return '${hr}h';
  final day = hr ~/ 24;
  return '${day}d';
}

/// Look up an airline name from either an ICAO code or a callsign whose
/// first three letters are the ICAO. Returns null when the code is
/// unknown so the caller can fall back to the raw code.
///
/// The existing [resolveAirline] in `airline_database.dart` is callsign-
/// only; this wrapper accepts the airline ICAO directly as well so an
/// alert without a parsed callsign still resolves.
String? resolveAirlineName(String? code) {
  if (code == null) return null;
  final trimmed = code.trim();
  if (trimmed.length < 3) return null;
  // resolveAirline strips off the first 3 chars and uppercases — so
  // passing either "DLH" or "DLH123" works.
  return resolveAirline(trimmed)?.name;
}

/// Format altitude as a flight-level + metres string:
///   - 11280 m → "FL370 (11280 m)"
///   -  1500 m → "1500 m (4921 ft)"
///
/// Aircraft.baroAltitude in the mobile payload is metres (Airlabs
/// delivers metres). FL = pressure altitude / 100 ft so FL370 = 37000 ft
/// ≈ 11280 m. We pick FL notation only above the standard transition
/// altitude (typically 18000 ft / 5500 m); below that we show
/// metres + feet because that's how local ATC talks.
String formatAltitude(double? meters) {
  if (meters == null || meters.isNaN) return '—';
  final ft = (meters * 3.28084).round();
  if (ft >= 18000) {
    final fl = (ft / 100).round();
    return 'FL$fl (${meters.round()} m)';
  }
  return '${meters.round()} m ($ft ft)';
}
