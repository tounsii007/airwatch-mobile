import 'package:airwatch_mobile/core/constants/api_json_keys.dart';

class AirportInfo {
  final String name;
  final String timezone;
  final double? lat;
  final double? lng;

  /// 4-letter ICAO code. Required for the METAR / TAF / NOTAM panels —
  /// the aviation-weather upstreams key on ICAO, not IATA. May be empty
  /// if the upstream payload didn't carry one (rare); the panels then
  /// hide rather than render an unfetchable request.
  final String icao;

  const AirportInfo({
    required this.name,
    required this.timezone,
    this.lat,
    this.lng,
    this.icao = '',
  });

  factory AirportInfo.fromMap(Map<dynamic, dynamic> map) {
    return AirportInfo(
      name: map['name']?.toString() ?? '',
      timezone: map['timezone']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      icao: map['icao_code']?.toString() ?? map['icao']?.toString() ?? '',
    );
  }
}

class WeatherInfo {
  final double? temperatureC;
  final double? windSpeedKmh;
  final int? weatherCode;
  final bool isDay;
  final int? humidity;

  const WeatherInfo({
    this.temperatureC,
    this.windSpeedKmh,
    this.weatherCode,
    this.isDay = true,
    this.humidity,
  });

  factory WeatherInfo.fromMap(Map<dynamic, dynamic> map) {
    final current = map['current'];
    if (current is! Map) {
      return const WeatherInfo();
    }

    return WeatherInfo(
      temperatureC: (current['temperature_2m'] as num?)?.toDouble(),
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
      weatherCode: current['weather_code'] as int?,
      isDay: current['is_day'] == 1,
      humidity: current['relative_humidity_2m'] as int?,
    );
  }
}

class AirportScheduleFlight {
  final String flightIcao;
  final String flightIata;
  final String airlineIata;
  final String depIata;
  final String arrIata;
  final String? status;
  final String? depTime;
  final String? arrTime;
  final int? depDelayed;
  final int? arrDelayed;
  final String? depTerminal;
  final String? arrTerminal;
  final String? depGate;
  final String? arrGate;

  /// Codeshare partner airline IATA (e.g. "AF" when a Lufthansa-operated
  /// flight is sold by Air France). Null when the row isn't a codeshare.
  /// Mirrors airwatch-web's `csAirlineIata` (commit 76fdfa0).
  final String? csAirlineIata;

  /// Codeshare partner's flight number (e.g. "AF1241"). Null when not
  /// applicable. The tile only shows this when it differs from the
  /// operating [flightIata] — Airlabs occasionally echoes the same
  /// number on both sides which is upstream noise, not a real
  /// codeshare.
  final String? csFlightIata;

  const AirportScheduleFlight({
    required this.flightIcao,
    required this.flightIata,
    required this.airlineIata,
    required this.depIata,
    required this.arrIata,
    this.status,
    this.depTime,
    this.arrTime,
    this.depDelayed,
    this.arrDelayed,
    this.depTerminal,
    this.arrTerminal,
    this.depGate,
    this.arrGate,
    this.csAirlineIata,
    this.csFlightIata,
  });

  factory AirportScheduleFlight.fromMap(Map<dynamic, dynamic> map) {
    final csAirline = map['cs_airline_iata']?.toString();
    final csFlight = map['cs_flight_iata']?.toString();
    return AirportScheduleFlight(
      flightIcao: map['flight_icao']?.toString() ?? '',
      flightIata: map['flight_iata']?.toString() ?? '',
      airlineIata: map['airline_iata']?.toString() ?? '',
      depIata: map['dep_iata']?.toString() ?? '',
      arrIata: map['arr_iata']?.toString() ?? '',
      status: map[ApiJsonKeys.status]?.toString(),
      depTime: map['dep_time']?.toString(),
      arrTime: map['arr_time']?.toString(),
      depDelayed: map['dep_delayed'] as int?,
      arrDelayed: map['arr_delayed'] as int?,
      depTerminal: map['dep_terminal']?.toString(),
      arrTerminal: map['arr_terminal']?.toString(),
      depGate: map['dep_gate']?.toString(),
      arrGate: map['arr_gate']?.toString(),
      csAirlineIata: (csAirline != null && csAirline.isNotEmpty)
          ? csAirline
          : null,
      csFlightIata: (csFlight != null && csFlight.isNotEmpty) ? csFlight : null,
    );
  }

  String get displayCode => flightIata.isNotEmpty ? flightIata : flightIcao;
  String get searchCode => displayCode.toUpperCase();

  /// True when a codeshare partner flight number actually differs from
  /// the operating flight number. Airlabs sometimes returns the same
  /// number on both sides — that's an upstream artefact, not real
  /// codeshare info, so we suppress the badge in that case.
  bool get hasMeaningfulCodeshare {
    final cs = csFlightIata;
    if (cs == null || cs.isEmpty) return false;
    return cs.toUpperCase() != flightIata.toUpperCase();
  }
}
