import 'package:airwatch_mobile/core/constants/api_json_keys.dart';

/// A single flight operated by an airline, from Airlabs /flights endpoint.
class AirlineFlightInfo {
  final String flightIcao;
  final String flightIata;
  final String depIata;
  final String arrIata;
  final String? status;
  final String? aircraftIcao;
  final double? lat;
  final double? lng;
  final double? alt;
  final double? speed;
  final double? dir;

  const AirlineFlightInfo({
    required this.flightIcao,
    required this.flightIata,
    required this.depIata,
    required this.arrIata,
    this.status,
    this.aircraftIcao,
    this.lat,
    this.lng,
    this.alt,
    this.speed,
    this.dir,
  });

  factory AirlineFlightInfo.fromMap(Map f) {
    return AirlineFlightInfo(
      flightIcao: f[ApiJsonKeys.flightIcao]?.toString() ?? '',
      flightIata: f[ApiJsonKeys.flightIata]?.toString() ?? '',
      depIata: f[ApiJsonKeys.depIata]?.toString() ?? '',
      arrIata: f[ApiJsonKeys.arrIata]?.toString() ?? '',
      status: f[ApiJsonKeys.status]?.toString(),
      aircraftIcao: f[ApiJsonKeys.aircraftIcao]?.toString(),
      lat: (f[ApiJsonKeys.lat] as num?)?.toDouble(),
      lng: (f[ApiJsonKeys.lng] as num?)?.toDouble(),
      alt: (f[ApiJsonKeys.alt] as num?)?.toDouble(),
      speed: (f[ApiJsonKeys.speed] as num?)?.toDouble(),
      dir: (f[ApiJsonKeys.dir] as num?)?.toDouble(),
    );
  }

  String get displayCode => flightIata.isNotEmpty ? flightIata : flightIcao;

  String get route => '$depIata → $arrIata';

  bool get isAirborne => (alt ?? 0) > 0 && status != 'landed';
}
