import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/aircraft_icons.dart';
import '../../data/models/aircraft_state.dart';

/// Shows trail + projected route ONLY for the selected aircraft.
/// If no destination is known, draws a heading-based projection line.
class FlightTrailLayer extends StatelessWidget {
  final List<AircraftState> aircraft;
  final String? selectedIcao;
  final LatLng? destinationPosition;

  const FlightTrailLayer({
    super.key,
    required this.aircraft,
    this.selectedIcao,
    this.destinationPosition,
  });

  @override
  Widget build(BuildContext context) {
    final trails = <Polyline>[];

    for (final ac in aircraft) {
      final isSelected = ac.icao24 == selectedIcao;
      if (!isSelected) continue;

      final color = AircraftIconPainter.getAltitudeColor(ac.altitude);

      // 1) Traveled trail — thick gradient line
      if (ac.trail.isNotEmpty) {
        final trailPoints = [...ac.trail];
        if (ac.position != null) trailPoints.add(ac.position!);

        trails.add(
          Polyline(
            points: trailPoints,
            strokeWidth: 4.0,
            color: color,
            gradientColors: [
              color.withValues(alpha: 0.05),
              color.withValues(alpha: 0.3),
              color,
            ],
          ),
        );
      }

      // 2) Projected route ahead
      if (ac.position != null) {
        if (destinationPosition != null) {
          // Known destination — dashed line to it
          trails.add(
            Polyline(
              points: [ac.position!, destinationPosition!],
              strokeWidth: 2.0,
              color: color.withValues(alpha: 0.35),
              pattern: const StrokePattern.dotted(spacingFactor: 2.5),
            ),
          );
        } else if (ac.velocity != null && ac.velocity! > 10 && !ac.onGround) {
          // Unknown destination — project line in heading direction
          // Estimate ~1 hour ahead based on current speed
          final distKm = ac.velocity! * 3.6; // m/s -> km/h, * 1h = km
          final projectedPoint = _projectPoint(
            ac.position!,
            ac.heading,
            distKm.clamp(100, 2000),
          );
          trails.add(
            Polyline(
              points: [ac.position!, projectedPoint],
              strokeWidth: 1.5,
              color: color.withValues(alpha: 0.2),
              pattern: const StrokePattern.dotted(spacingFactor: 3.0),
            ),
          );
        }
      }
    }

    return PolylineLayer(polylines: trails);
  }

  /// Project a point forward from a given position along a bearing for a given distance in km.
  static LatLng _projectPoint(
    LatLng from,
    double bearingDeg,
    double distanceKm,
  ) {
    const earthRadiusKm = 6371.0;
    final d = distanceKm / earthRadiusKm;
    final bearing = bearingDeg * math.pi / 180;
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(d) +
          math.cos(lat1) * math.sin(d) * math.cos(bearing),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }
}
