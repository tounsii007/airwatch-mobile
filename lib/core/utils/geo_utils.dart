import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  /// Calculate distance between two points in km
  static double distanceKm(LatLng from, LatLng to) {
    final dLat = _toRad(to.latitude - from.latitude);
    final dLon = _toRad(to.longitude - from.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(from.latitude)) *
            math.cos(_toRad(to.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Interpolate position between two points
  static LatLng interpolate(LatLng from, LatLng to, double fraction) {
    final lat = from.latitude + (to.latitude - from.latitude) * fraction;
    final lng = from.longitude + (to.longitude - from.longitude) * fraction;
    return LatLng(lat, lng);
  }

  /// Calculate bearing from one point to another in degrees
  static double bearing(LatLng from, LatLng to) {
    final dLon = _toRad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(_toRad(to.latitude));
    final x =
        math.cos(_toRad(from.latitude)) * math.sin(_toRad(to.latitude)) -
        math.sin(_toRad(from.latitude)) *
            math.cos(_toRad(to.latitude)) *
            math.cos(dLon);
    return (_toDeg(math.atan2(y, x)) + 360) % 360;
  }

  /// Get destination point given bearing and distance
  static LatLng destinationPoint(
    LatLng from,
    double bearingDeg,
    double distanceKm,
  ) {
    final d = distanceKm / earthRadiusKm;
    final bearing = _toRad(bearingDeg);
    final lat1 = _toRad(from.latitude);
    final lng1 = _toRad(from.longitude);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(d) +
          math.cos(lat1) * math.sin(d) * math.cos(bearing),
    );
    final lng2 =
        lng1 +
        math.atan2(
          math.sin(bearing) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_toDeg(lat2), _toDeg(lng2));
  }

  /// Check if point is within visible bounds with margin
  static bool isInBounds(
    LatLng point,
    LatLng sw,
    LatLng ne, {
    double margin = 1.0,
  }) {
    return point.latitude >= sw.latitude - margin &&
        point.latitude <= ne.latitude + margin &&
        point.longitude >= sw.longitude - margin &&
        point.longitude <= ne.longitude + margin;
  }

  static double _toRad(double deg) => deg * (math.pi / 180.0);
  static double _toDeg(double rad) => rad * (180.0 / math.pi);
}
