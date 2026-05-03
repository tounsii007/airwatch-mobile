import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../features/map/data/models/aircraft_state.dart';

/// Heatmap overlay showing flight density
class HeatmapOverlay extends StatelessWidget {
  final List<AircraftState> aircraft;
  final double opacity;

  const HeatmapOverlay({super.key, required this.aircraft, this.opacity = 0.4});

  @override
  Widget build(BuildContext context) {
    if (aircraft.isEmpty) return const SizedBox.shrink();

    // Compute density grid
    final points = aircraft
        .where((a) => a.hasPosition)
        .map((a) => a.position!)
        .toList();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HeatmapPainter(points: points, opacity: opacity),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<LatLng> points;
  final double opacity;

  _HeatmapPainter({required this.points, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Cluster nearby points to compute density centers
    final clusters = _clusterPoints(points, gridSize: 40);

    for (final cluster in clusters) {
      final count = cluster.count;
      if (count < 2) continue;

      final intensity = (count / 20).clamp(0.1, 1.0);
      final radius = 20.0 + (count * 2).clamp(0.0, 60.0);

      final gradient = RadialGradient(
        colors: [
          Color.lerp(
            const Color(0xFF00E5FF),
            const Color(0xFFFF0080),
            intensity,
          )!.withValues(alpha: opacity * intensity),
          Colors.transparent,
        ],
      );

      final rect = Rect.fromCircle(
        center: Offset(cluster.x, cluster.y),
        radius: radius,
      );

      canvas.drawCircle(
        Offset(cluster.x, cluster.y),
        radius,
        Paint()..shader = gradient.createShader(rect),
      );
    }
  }

  List<_Cluster> _clusterPoints(
    List<LatLng> points, {
    required double gridSize,
  }) {
    final Map<String, _Cluster> grid = {};

    for (final point in points) {
      // Simple grid-based clustering using lat/lng scaled to screen space
      final gx = (point.longitude * 10 / gridSize).floor();
      final gy = (point.latitude * 10 / gridSize).floor();
      final key = '$gx,$gy';

      if (grid.containsKey(key)) {
        grid[key]!.count++;
      } else {
        grid[key] = _Cluster(
          x: point.longitude * 10,
          y: point.latitude * 10,
          count: 1,
        );
      }
    }

    return grid.values.toList();
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

class _Cluster {
  final double x;
  final double y;
  int count;

  _Cluster({required this.x, required this.y, required this.count});
}
