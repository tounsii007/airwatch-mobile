import 'package:airwatch_mobile/core/constants/api_json_keys.dart';

class AirlabsFlightSnapshot {
  final String icao24;
  final int departureTimestamp;
  final int arrivalTimestamp;
  final String? departureIcao;
  final String? arrivalIcao;
  final String? callsign;
  final String? flightIcao;
  final String? flightIata;
  final String? depIata;
  final String? arrIata;
  final String? depTime;
  final String? arrTime;
  final String? depTerminal;
  final String? arrTerminal;
  final String? status;
  final int? depDelayMinutes;
  final int? arrDelayMinutes;
  final int? durationMinutes;

  const AirlabsFlightSnapshot({
    required this.icao24,
    required this.departureTimestamp,
    required this.arrivalTimestamp,
    this.departureIcao,
    this.arrivalIcao,
    this.callsign,
    this.flightIcao,
    this.flightIata,
    this.depIata,
    this.arrIata,
    this.depTime,
    this.arrTime,
    this.depTerminal,
    this.arrTerminal,
    this.status,
    this.depDelayMinutes,
    this.arrDelayMinutes,
    this.durationMinutes,
  });

  factory AirlabsFlightSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return AirlabsFlightSnapshot(
      icao24: map['hex']?.toString() ?? '',
      departureTimestamp: map['dep_time_ts'] as int? ?? 0,
      arrivalTimestamp: map['arr_time_ts'] as int? ?? 0,
      departureIcao: map['dep_icao']?.toString(),
      arrivalIcao: map['arr_icao']?.toString(),
      callsign: map['flight_icao']?.toString().trim(),
      flightIcao: map['flight_icao']?.toString(),
      flightIata: map['flight_iata']?.toString(),
      depIata: map['dep_iata']?.toString(),
      arrIata: map['arr_iata']?.toString(),
      depTime: map['dep_time']?.toString(),
      arrTime: map['arr_time']?.toString(),
      depTerminal: map['dep_terminal']?.toString(),
      arrTerminal: map['arr_terminal']?.toString(),
      status: map[ApiJsonKeys.status]?.toString(),
      depDelayMinutes: map['dep_delayed'] as int?,
      arrDelayMinutes: map['arr_delayed'] as int?,
      durationMinutes: map['duration'] as int?,
    );
  }
}

class AirlabsRouteSnapshot {
  final String? departureIcao;
  final String? arrivalIcao;
  final String? callsign;
  final String? flightIcao;
  final String? flightIata;
  final String? depIata;
  final String? arrIata;
  final String? depTime;
  final String? arrTime;
  final int? durationMinutes;

  const AirlabsRouteSnapshot({
    this.departureIcao,
    this.arrivalIcao,
    this.callsign,
    this.flightIcao,
    this.flightIata,
    this.depIata,
    this.arrIata,
    this.depTime,
    this.arrTime,
    this.durationMinutes,
  });

  factory AirlabsRouteSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return AirlabsRouteSnapshot(
      departureIcao: map['dep_icao']?.toString(),
      arrivalIcao: map['arr_icao']?.toString(),
      callsign: map['flight_icao']?.toString(),
      flightIcao: map['flight_icao']?.toString(),
      flightIata: map['flight_iata']?.toString(),
      depIata: map['dep_iata']?.toString(),
      arrIata: map['arr_iata']?.toString(),
      depTime: map['dep_time']?.toString(),
      arrTime: map['arr_time']?.toString(),
      durationMinutes: map['duration'] as int?,
    );
  }
}
