import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

enum SearchResultType { liveAircraft, airline, apiResult, airlineFlight, country }

enum SearchFilter { all, live, airlines, flights, countries }

class SearchResultItem {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String? status;
  final double? altitude;
  final AircraftState? aircraft;
  final String? airlineIcao;
  final String? airlineIata;
  final String? flightIcao;
  final String? flightIata;
  final String? depIata;
  final String? arrIata;
  final String? countryCode;

  const SearchResultItem({
    required this.type,
    required this.title,
    this.subtitle = '',
    this.status,
    this.altitude,
    this.aircraft,
    this.airlineIcao,
    this.airlineIata,
    this.flightIcao,
    this.flightIata,
    this.depIata,
    this.arrIata,
    this.countryCode,
  });
}
