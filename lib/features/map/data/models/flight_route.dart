import 'package:latlong2/latlong.dart';

class FlightRoute {
  final String flightNumber;
  final String? airline;
  final String? airlineLogo;
  final Airport? departure;
  final Airport? arrival;
  final String? aircraftType;
  final String? aircraftRegistration;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final DateTime? estimatedArrival;
  final String? status;
  final List<LatLng> routePoints;

  FlightRoute({
    required this.flightNumber,
    this.airline,
    this.airlineLogo,
    this.departure,
    this.arrival,
    this.aircraftType,
    this.aircraftRegistration,
    this.departureTime,
    this.arrivalTime,
    this.estimatedArrival,
    this.status,
    this.routePoints = const [],
  });

  double? get progress {
    if (departureTime == null || estimatedArrival == null) return null;
    final total = estimatedArrival!.difference(departureTime!).inMinutes;
    final elapsed = DateTime.now().difference(departureTime!).inMinutes;
    if (total <= 0) return null;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class Airport {
  final String code;
  final String name;
  final String city;
  final LatLng position;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.position,
  });
}
