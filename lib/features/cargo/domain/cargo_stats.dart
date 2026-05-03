import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Aggregate stats shown on the cargo page header.
///
/// <p>Mirrors the web frontend's `CargoStats` shape so the four-tile
/// header row on each platform reports identical numbers.
class CargoStats {
  final int airborne;
  final int ground;
  final int total;
  final int operators;

  const CargoStats({
    required this.airborne,
    required this.ground,
    required this.total,
    required this.operators,
  });

  static const empty = CargoStats(
    airborne: 0,
    ground: 0,
    total: 0,
    operators: 0,
  );
}

/// Compute the per-page cargo stats from a flight list.
///
/// <p>Single pass — separate counts for airborne / ground plus a `Set`
/// for distinct operator (callsign-prefix) counting. The web version
/// keys the operator set off `aircraft.airlineIcao`; mobile's
/// [AircraftState] doesn't carry that dedicated field, so we derive the
/// ICAO from the first three callsign chars (same convention used by
/// [cargoAirlineIcaos] and the web's callsign-prefix fallback).
CargoStats computeCargoStats(Iterable<AircraftState> flights) {
  var airborne = 0;
  var ground = 0;
  var total = 0;
  final ops = <String>{};
  for (final ac in flights) {
    total++;
    if (ac.onGround) {
      ground++;
    } else {
      airborne++;
    }
    final cs = ac.callsign?.trim().toUpperCase() ?? '';
    if (cs.length >= 3) {
      ops.add(cs.substring(0, 3));
    }
  }
  return CargoStats(
    airborne: airborne,
    ground: ground,
    total: total,
    operators: ops.length,
  );
}
