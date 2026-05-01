import 'package:latlong2/latlong.dart';

/// Represents a single aircraft state from OpenSky Network API
class AircraftState {
  final String icao24;
  final String? callsign;
  final String? originCountry;
  final int? timePosition;
  final int? lastContact;
  final double? longitude;
  final double? latitude;
  final double? baroAltitude;
  final bool onGround;
  final double? velocity;
  final double? trueTrack;
  final double? verticalRate;
  final List<int>? sensors;
  final double? geoAltitude;
  final String? squawk;
  final bool spiFlag;
  final int positionSource;
  final int category;
  /// Flight status from Airlabs: 'en-route', 'landed', 'scheduled', 'cancelled'
  final String? flightStatus;

  // Computed fields for animation
  final LatLng? position;
  final LatLng? previousPosition;
  final DateTime lastUpdate;
  final List<LatLng> trail;

  AircraftState({
    required this.icao24,
    this.callsign,
    this.originCountry,
    this.timePosition,
    this.lastContact,
    this.longitude,
    this.latitude,
    this.baroAltitude,
    this.onGround = false,
    this.velocity,
    this.trueTrack,
    this.verticalRate,
    this.sensors,
    this.geoAltitude,
    this.squawk,
    this.spiFlag = false,
    this.positionSource = 0,
    this.category = 0,
    this.flightStatus,
    this.previousPosition,
    DateTime? lastUpdate,
    List<LatLng>? trail,
  })  : position = (latitude != null && longitude != null)
            ? LatLng(latitude, longitude)
            : null,
        lastUpdate = lastUpdate ?? DateTime.now(),
        trail = trail ?? [];

  @Deprecated('OpenSky data source is disabled. Use Airlabs parser instead.')
  factory AircraftState.fromOpenSkyList(List<dynamic> data) {
    return AircraftState(
      icao24: data[0]?.toString() ?? '',
      callsign: data[1]?.toString().trim(),
      originCountry: data[2]?.toString(),
      timePosition: data[3] as int?,
      lastContact: data[4] as int?,
      longitude: (data[5] as num?)?.toDouble(),
      latitude: (data[6] as num?)?.toDouble(),
      baroAltitude: (data[7] as num?)?.toDouble(),
      onGround: data[8] as bool? ?? false,
      velocity: (data[9] as num?)?.toDouble(),
      trueTrack: (data[10] as num?)?.toDouble(),
      verticalRate: (data[11] as num?)?.toDouble(),
      sensors: (data[12] as List?)?.cast<int>(),
      geoAltitude: (data[13] as num?)?.toDouble(),
      squawk: data[14]?.toString(),
      spiFlag: data[15] as bool? ?? false,
      positionSource: data[16] as int? ?? 0,
      category: data.length > 17 ? (data[17] as int? ?? 0) : 0,
    );
  }

  AircraftState copyWith({
    String? callsign,
    double? longitude,
    double? latitude,
    double? baroAltitude,
    bool? onGround,
    double? velocity,
    double? trueTrack,
    double? verticalRate,
    double? geoAltitude,
    int? category,
    String? flightStatus,
    LatLng? previousPosition,
    DateTime? lastUpdate,
    List<LatLng>? trail,
  }) {
    return AircraftState(
      icao24: icao24,
      callsign: callsign ?? this.callsign,
      originCountry: originCountry,
      timePosition: timePosition,
      lastContact: lastContact,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      baroAltitude: baroAltitude ?? this.baroAltitude,
      onGround: onGround ?? this.onGround,
      velocity: velocity ?? this.velocity,
      trueTrack: trueTrack ?? this.trueTrack,
      verticalRate: verticalRate ?? this.verticalRate,
      sensors: sensors,
      geoAltitude: geoAltitude ?? this.geoAltitude,
      squawk: squawk,
      spiFlag: spiFlag,
      positionSource: positionSource,
      category: category ?? this.category,
      flightStatus: flightStatus ?? this.flightStatus,
      previousPosition: previousPosition ?? this.previousPosition,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      trail: trail ?? this.trail,
    );
  }

  /// Get the effective altitude (prefer baro, fallback to geo)
  double? get altitude => baroAltitude ?? geoAltitude;

  /// Get heading or default to 0
  double get heading => trueTrack ?? 0;

  /// Check if aircraft has valid position
  bool get hasPosition => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'icao24': icao24,
        'callsign': callsign,
        'origin_country': originCountry,
        'latitude': latitude,
        'longitude': longitude,
        'baro_altitude': baroAltitude,
        'on_ground': onGround,
        'velocity': velocity,
        'true_track': trueTrack,
        'vertical_rate': verticalRate,
        'geo_altitude': geoAltitude,
        'category': category,
        'flight_status': flightStatus,
      };
}
