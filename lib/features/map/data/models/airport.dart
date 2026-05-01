import 'package:latlong2/latlong.dart';

class Airport {
  final String icao;
  final String? iata;
  final String name;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final double? elevation;
  final String? timezone;
  final int? departures;
  final int? arrivals;

  Airport({
    required this.icao,
    this.iata,
    required this.name,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.timezone,
    this.departures,
    this.arrivals,
  });

  LatLng get position => LatLng(latitude, longitude);

  String get displayCode => iata ?? icao;

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      icao: json['icao'] ?? json['icao_code'] ?? '',
      iata: json['iata'] ?? json['iata_code'],
      name: json['name'] ?? json['airport_name'] ?? '',
      city: json['city'] ?? json['city_iata_code'] ?? '',
      country: json['country'] ?? json['country_name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      elevation: (json['elevation'] as num?)?.toDouble(),
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'icao': icao,
        'iata': iata,
        'name': name,
        'city': city,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'elevation': elevation,
        'timezone': timezone,
      };
}
