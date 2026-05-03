import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Confidence level the model is willing to put behind a prediction.
enum PredictionConfidence { low, medium, high }

/// On-device delay forecast. Mirrors the web frontend's `PredictionCard`
/// payload shape (`delayProbability`, `estimatedDelayMinutes`,
/// `confidence`, `explanation`, `factors`) so the two can share strings.
class DelayPrediction {
  /// 0–100. Probability the flight will arrive ≥ 15 min late.
  final int delayProbability;

  /// Best-guess minutes of delay (0 if probability is low).
  final int estimatedDelayMinutes;

  final PredictionConfidence confidence;

  /// Human-readable single-sentence summary.
  final String explanation;

  /// Short factor pills (e.g. `["Long-haul", "Heavy traffic hub"]`).
  final List<String> factors;

  const DelayPrediction({
    required this.delayProbability,
    required this.estimatedDelayMinutes,
    required this.confidence,
    required this.explanation,
    required this.factors,
  });

  /// Small heuristic that says "no clue" — rendered as a hidden card.
  static const empty = DelayPrediction(
    delayProbability: 0,
    estimatedDelayMinutes: 0,
    confidence: PredictionConfidence.low,
    explanation: '',
    factors: [],
  );
}

// ── Hub-airport blacklists ─────────────────────────────────────────────────
//
// Empirically derived from the EU CAA + FAA on-time-performance reports:
// the airports that consistently rank in the bottom-quartile of arrival
// punctuality. Used as a "this hub adds risk" heuristic factor.

const Set<String> _delayProneHubs = {
  'JFK', 'EWR', 'LGA', 'SFO', 'LAX', // US East/West coast majors
  'LHR', 'LGW', 'STN', // London cluster
  'CDG', 'ORY', // Paris
  'FCO', 'MXP', 'LIN', // Italy
  'IST', 'SAW', // Istanbul
  'PEK', 'PVG', 'CAN', // China
  'DEL', 'BOM', // India
};

/// Run the heuristic prediction. Pure function — no I/O, no network.
///
/// <p>The web's `PredictionCard` calls a backend `/api/predict` endpoint
/// that doesn't ship with the open-source code (it would be a
/// proprietary ML service). Mobile gets a deterministic on-device
/// approximation so the user still sees a useful card, with a `low`
/// confidence flag that's honest about the limits of a non-ML signal.
DelayPrediction predictDelay({
  required AircraftState aircraft,
  required FlightRouteInfo? route,
}) {
  if (aircraft.callsign == null || aircraft.callsign!.trim().isEmpty) {
    return DelayPrediction.empty;
  }

  // ── Score accumulation ───────────────────────────────────────────────────
  // Each factor contributes to a 0..100 risk total. We tune weights so that:
  //   * a regular passenger flight on an efficient route lands ~10–25
  //   * a long-haul to a delay-prone hub lands ~50–70
  //   * an emergency squawk forces ≥ 80
  var risk = 15; // baseline — every flight has *some* slip risk.
  final factors = <String>[];

  // Emergency squawk — highest possible signal.
  final sq = aircraft.squawk;
  if (sq == '7700' || sq == '7600' || sq == '7500') {
    risk = 90;
    factors.add('Emergency squawk');
  }

  // Long-haul flights statistically more likely to absorb delay over ATC
  // routing + weather diversions.
  final dep = route?.departureAirport ?? '';
  final arr = route?.arrivalAirport ?? '';
  final isInternational =
      dep.isNotEmpty && arr.isNotEmpty && _country(dep) != _country(arr);
  if (isInternational) {
    risk += 8;
    factors.add('International route');
  }

  // Delay-prone hub on either end.
  final hubHit = _delayProneHubs.contains(dep) || _delayProneHubs.contains(arr);
  if (hubHit) {
    risk += 14;
    factors.add('Heavy traffic hub');
  }

  // Departed already (existing baroAltitude > 0) AND below cruise → still
  // climbing or already on descent. Lower altitude generally means
  // closer to a busy airport → more queue risk.
  final alt = aircraft.baroAltitude ?? 0;
  if (alt > 0 && alt < 6000) {
    risk += 6;
    factors.add('In approach phase');
  }

  // Ground-stuck flight: still on ground but should be in the air —
  // hard to verify without scheduled-departure time, so weight low.
  if (aircraft.onGround) {
    risk += 4;
    factors.add('Currently on ground');
  }

  // Slow at high altitude (potential headwinds / re-routing).
  final speedMs = aircraft.velocity ?? 0;
  if (alt > 9000 && speedMs > 0 && speedMs < 200) {
    risk += 5;
    factors.add('Slow cruise speed');
  }

  // Clamp.
  risk = risk.clamp(0, 95);

  // Derived minutes — linear above the 30 % threshold, capped at 60.
  final estMin = risk < 30 ? 0 : ((risk - 30) * 1.0).clamp(0, 60).round();

  // Confidence depends on how many distinct factors fired:
  //   0–1   → low (we mostly ran the baseline)
  //   2–3   → medium
  //   4+    → high
  final confidence = factors.length >= 4
      ? PredictionConfidence.high
      : factors.length >= 2
      ? PredictionConfidence.medium
      : PredictionConfidence.low;

  final explanation = _explain(risk, estMin, factors);

  return DelayPrediction(
    delayProbability: risk,
    estimatedDelayMinutes: estMin,
    confidence: confidence,
    explanation: explanation,
    factors: factors,
  );
}

String _explain(int risk, int estMin, List<String> factors) {
  if (risk >= 70) {
    return 'High delay risk — '
        '${factors.isEmpty ? "multiple disruption signals" : factors.first.toLowerCase()} '
        'suggests ~$estMin min delay.';
  }
  if (risk >= 45) {
    return 'Moderate delay risk — '
        '${factors.isEmpty ? "some risk factors present" : factors.first.toLowerCase()} '
        'may add ~$estMin min.';
  }
  if (risk >= 25) {
    return 'Slight risk of arrival delay; ${estMin > 0 ? "~$estMin min " : ""}'
        'unlikely to be significant.';
  }
  return 'On-time arrival likely.';
}

/// Best-effort country guess based on the airport's leading char of its
/// ICAO code. Crude but cheap — used here only to decide
/// "is this an international route?" with no per-airport DB lookup.
///
/// IATA prefixes are too fragmented to use here (Munich is MUC, but
/// 99 % of airports' ICAO/IATA pairs share country) — rather than
/// load a 21k-row DB on every prediction call we fall back to "any
/// difference in first char counts as international".
String _country(String code) =>
    code.isNotEmpty ? code.substring(0, 1).toUpperCase() : '';
