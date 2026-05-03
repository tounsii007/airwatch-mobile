import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Status filter applied to the cargo list.
///
/// <p>Mirrors the web frontend's `CargoStatusFilter` so the two screens
/// behave consistently — tapping the AIRBORNE stat tile narrows to
/// airborne flights, tapping again returns to ALL.
enum CargoStatusFilter { all, airborne, ground }

/// Known pure-freight airline ICAO codes — kept in lock-step with the
/// web frontend's `CARGO_AIRLINE_ICAOS` set so a flight that lands on
/// the cargo page in the web app also shows up here.
///
/// <p>Exported under the longer `cargoAirlineIcaoCodes` name — preserved
/// from the previous mobile API so tests / external callers continue
/// to compile.
const Set<String> cargoAirlineIcaoCodes = {
  'FDX', // FedEx
  'UPS', // UPS Airlines
  'DHK', // DHL (Aero Expreso etc.)
  'DHL', // DHL Aviation
  'GTI', // Atlas Air
  'GEC', // Lufthansa Cargo
  'CLX', // Cargolux
  'BOX', // AirBridgeCargo
  'ABX', // ABX Air
  'TAY', // ASL Airlines (TNT)
  'NPT', // West Atlantic
  'WGN', // Western Global
  'ATG', // Aerotrans Cargo
  'SQC', // Singapore Airlines Cargo
  'ADB', // Air Atlanta Icelandic
  'CKS', // Kalitta Air
  'AEC', // ASECNA / cargo ops
  'GMI', // Germania (cargo runs)
  'FPO', // Europe Airpost
  'TGX', // Turkish Cargo
  'KFS', // Kalitta Charters
  'MSC', // Air Cargo Carriers
  'QAF', // QatAirways Cargo
  'ETD', // Etihad Cargo
  'UAE', // Emirates SkyCargo
  'CKK', // China Cargo Airlines
  'CAO', // Air China Cargo
  'CPA', // Cathay Pacific (cargo ops too)
  'MPH', // Martinair
  'NCA', // Nippon Cargo
  'CLE', // Chapman Freeborn (leased cargo)
  'ABW', // AirBridgeCargo
};

/// Callsign prefixes used when the airline ICAO field is missing on
/// the live feed. Subset of [cargoAirlineIcaos] — only the carriers that
/// reliably encode the ICAO into the callsign (e.g. "FDX1234").
const Set<String> _cargoCallsignPrefixes = {
  'FDX',
  'UPS',
  'GTI',
  'CLX',
  'BOX',
  'TAY',
  'GEC',
  'ABX',
  'WGN',
};

/// True when the callsign string most likely identifies a cargo flight.
///
/// <p>Pure-logic version — exposed independently of [AircraftState] so
/// unit tests can hit the predicate directly without constructing a
/// full state object. Case-sensitive: real-world callsigns from the
/// upstream feed are uppercase ICAO codes, and a lower-case "fdx12"
/// would be suspect data we don't want to misclassify.
bool isCargoCallsign(String? callsign) {
  if (callsign == null) return false;
  final cs = callsign.trim();
  if (cs.length < 3) return false;
  // Reject callsigns that aren't proper uppercase ICAO codes — keeps
  // the predicate strict so noisy lower-case data doesn't get tagged
  // as cargo on mistake.
  if (cs[0] != cs[0].toUpperCase() ||
      cs[1] != cs[1].toUpperCase() ||
      cs[2] != cs[2].toUpperCase()) {
    return false;
  }
  final prefix = cs.substring(0, 3);
  if (cargoAirlineIcaoCodes.contains(prefix)) return true;
  return _cargoCallsignPrefixes.contains(prefix);
}

/// True when the aircraft is most likely a cargo flight.
///
/// <p>Two-step heuristic, matching the web's `isCargoFlight`:
/// <ol>
///   <li>If `airlineIcao` is set on the aircraft state and is in the
///       known cargo set, return true.</li>
///   <li>Otherwise check whether the callsign starts with one of the
///       cargo-specific prefixes.</li>
/// </ol>
///
/// <p>Mobile's [AircraftState] model doesn't expose `airlineIcao` as a
/// dedicated field today — the prefix path effectively becomes the only
/// signal. That matches how the existing `cargo_screen.dart` worked
/// before this redesign, so no false positives sneak in via this port.
bool isCargoFlight(AircraftState ac) => isCargoCallsign(ac.callsign);

bool _matchesStatus(AircraftState ac, CargoStatusFilter filter) {
  return switch (filter) {
    CargoStatusFilter.all => true,
    CargoStatusFilter.airborne => !ac.onGround,
    CargoStatusFilter.ground => ac.onGround,
  };
}

bool _matchesSearch(AircraftState ac, String q) {
  if (q.isEmpty) return true;
  final query = q.toLowerCase();
  final cs = ac.callsign?.toLowerCase() ?? '';
  if (cs.contains(query)) return true;
  // Airline ICAO is the first three callsign chars.
  if (cs.length >= 3 && cs.substring(0, 3).contains(query)) return true;
  // ICAO24 hex.
  if (ac.icao24.toLowerCase().contains(query)) return true;
  // Origin country (English) — subtle but matches the web's substring
  // semantics when the user types e.g. "germany" / "ger".
  if ((ac.originCountry ?? '').toLowerCase().contains(query)) return true;
  return false;
}

/// Apply status + search filters to a cargo list.
///
/// <p>Stable: input order is preserved within each retained subset, so
/// the list doesn't visually flap between renders when the user narrows
/// or widens the filter.
List<AircraftState> filterCargo(
  Iterable<AircraftState> flights,
  String search,
  CargoStatusFilter status,
) {
  final q = search.trim();
  return flights
      .where((ac) => _matchesStatus(ac, status) && _matchesSearch(ac, q))
      .toList(growable: false);
}
