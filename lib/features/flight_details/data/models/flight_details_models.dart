import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

class FlightDetailsData {
  final AirlineInfo? airline;
  final FlightRouteInfo? route;
  final AircraftMetadata? metadata;
  final String? aircraftPhotoUrl;

  const FlightDetailsData({
    this.airline,
    this.route,
    this.metadata,
    this.aircraftPhotoUrl,
  });
}
