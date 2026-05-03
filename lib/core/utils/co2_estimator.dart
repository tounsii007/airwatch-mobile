import 'package:latlong2/latlong.dart';
import 'package:airwatch_mobile/core/utils/geo_utils.dart';

/// Per-flight CO₂ emission estimate.
///
/// <p>Mirrors the web frontend's `useFlightDetailsViewModel.ts` CO₂ block.
/// The two clients deliberately use the SAME formula so a flight detail
/// in the mobile app shows the same number as the web — anything else
/// would erode user trust ("why does mobile say 1.4 t but web 2.1 t?").
///
/// <h3>Methodology</h3>
/// <ul>
///   <li>Distance via great-circle haversine between dep/arr coords.</li>
///   <li>Per-passenger emission factor in kg CO₂ / km, by ADS-B aircraft
///       category (1–14, see [AppConfig] for the map):
///       <ul>
///         <li><b>0.08</b> kg/km — heavy (cat 6: A380, B747, B777-300ER).
///             Lower per-pax thanks to higher load factor.</li>
///         <li><b>0.12</b> kg/km — large (cat 3: A320, B737).</li>
///         <li><b>0.15</b> kg/km — small (cat 2: regional jets / props).
///             Higher per-pax, fewer seats per kg of fuel.</li>
///         <li><b>0.10</b> kg/km — fallback for unknown / mixed.</li>
///       </ul>
///   </li>
/// </ul>
///
/// <p>The numbers come from the EU EEA inventory's average load-factor
/// adjusted figures — calibrated to match published per-flight CO₂
/// numbers from major airline sustainability reports (Lufthansa, AF/KL,
/// IAG group). Not airline-specific; we don't have aircraft-tail-level
/// fuel data so the per-category average is the best signal we have.
class Co2Estimate {
  /// Total CO₂ in kilograms (rounded to nearest int).
  final int co2Kg;

  /// Great-circle distance in kilometres (rounded).
  final int distKm;

  const Co2Estimate({required this.co2Kg, required this.distKm});
}

/// Estimate CO₂ emissions for a flight given its dep/arr airport coords
/// and the aircraft category.
///
/// <p>Returns `null` if either coordinate is missing — caller should
/// render a "no estimate available" footer in that case.
Co2Estimate? estimateCo2({
  required LatLng? departure,
  required LatLng? arrival,
  int? aircraftCategory,
}) {
  if (departure == null || arrival == null) return null;
  final distKm = GeoUtils.distanceKm(departure, arrival);
  if (!distKm.isFinite || distKm < 1) return null;

  final factor = co2FactorForCategory(aircraftCategory);
  return Co2Estimate(distKm: distKm.round(), co2Kg: (distKm * factor).round());
}

/// Per-km kg-CO₂ factor for a given ADS-B category.
///
/// Public so unit tests can verify the table directly without going
/// through the airport-lookup path.
double co2FactorForCategory(int? category) {
  return switch (category) {
    6 => 0.08, // heavy
    3 => 0.12, // large
    2 => 0.15, // small
    _ => 0.10, // unknown / mid
  };
}
