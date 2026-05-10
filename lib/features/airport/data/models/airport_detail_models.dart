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
  });

  factory AirportScheduleFlight.fromMap(Map<dynamic, dynamic> map) {
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
    );
  }

  String get displayCode => flightIata.isNotEmpty ? flightIata : flightIcao;
  String get searchCode => displayCode.toUpperCase();
}
