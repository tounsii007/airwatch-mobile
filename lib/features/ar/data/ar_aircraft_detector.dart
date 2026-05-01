import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../map/data/models/aircraft_state.dart';

/// Detects which aircraft are visible from a given position and viewing direction.
/// Used by AR mode to overlay flight info on the camera feed.
class ARAircraftDetector {
  /// Find aircraft that are approximately in the user's line of sight.
  ///
  /// [userPos] — GPS position of the user
  /// [compassHeading] — compass heading in degrees (0=North)
  /// [tiltAngle] — device tilt angle (0=horizontal, 90=straight up)
  /// [aircraft] — list of all known aircraft
  /// [fovDegrees] — field of view width (typically 60-90°)
  /// [maxDistance] — max detection distance in km
  static List<DetectedAircraft> detect({
    required LatLng userPos,
    required double compassHeading,
    required double tiltAngle,
    required List<AircraftState> aircraft,
    double fovDegrees = 60,
    double maxDistanceKm = 200,
  }) {
    final results = <DetectedAircraft>[];

    for (final ac in aircraft) {
      if (!ac.hasPosition || ac.onGround) continue;

      // Calculate bearing from user to aircraft
      final bearing = _bearingTo(userPos, ac.position!);

      // Calculate angular difference from compass heading
      var angleDiff = (bearing - compassHeading + 360) % 360;
      if (angleDiff > 180) angleDiff -= 360;

      // Check if within field of view
      if (angleDiff.abs() > fovDegrees / 2) continue;

      // Calculate distance
      final distKm = _distanceKm(userPos, ac.position!);
      if (distKm > maxDistanceKm) continue;

      // Calculate elevation angle to aircraft
      final altM = ac.altitude ?? 10000;
      final elevAngle = math.atan2(altM, distKm * 1000) * 180 / math.pi;

      // Check if elevation roughly matches tilt
      if ((elevAngle - tiltAngle).abs() > 30) continue;

      results.add(DetectedAircraft(
        aircraft: ac,
        bearingDeg: bearing,
        distanceKm: distKm,
        elevationDeg: elevAngle,
        screenXFraction: 0.5 + (angleDiff / fovDegrees),
        screenYFraction: 0.5 - ((elevAngle - tiltAngle) / 60),
      ));
    }

    // Sort by distance (closest first)
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results.take(10).toList();
  }

  static double _bearingTo(LatLng from, LatLng to) {
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) * math.cos(b.latitude * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
}

class DetectedAircraft {
  final AircraftState aircraft;
  final double bearingDeg;
  final double distanceKm;
  final double elevationDeg;
  final double screenXFraction; // 0.0=left, 1.0=right
  final double screenYFraction; // 0.0=top, 1.0=bottom

  DetectedAircraft({
    required this.aircraft,
    required this.bearingDeg,
    required this.distanceKm,
    required this.elevationDeg,
    required this.screenXFraction,
    required this.screenYFraction,
  });
}
