/// Unified airline info model used throughout the app.
/// Single source of truth — previously duplicated in airline_database.dart
/// and flight_info_datasource.dart.
class AirlineInfo {
  final String icao;
  final String iata;
  final String name;
  final String country;

  const AirlineInfo({
    required this.icao,
    required this.iata,
    required this.name,
    required this.country,
  });
}
