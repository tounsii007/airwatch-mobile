import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RadarSweep extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const RadarSweep({
    super.key,
    this.size = 200,
    this.color = AppColors.primary,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<RadarSweep> createState() => _RadarSweepState();
}

class _RadarSweepState extends State<RadarSweep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadarSweepPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Draw crosshairs
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);

    // Draw sweep
    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Draw sweep line
    final lineEnd = Offset(
      center.dx + radius * math.cos(sweepAngle - math.pi / 2),
      center.dy + radius * math.sin(sweepAngle - math.pi / 2),
    );
    canvas.drawLine(
      center,
      lineEnd,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1.5,
    );

    // Center dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Pulsing radar rings for airports
class PulsingRings extends StatefulWidget {
  final double maxRadius;
  final Color color;
  final int ringCount;

  const PulsingRings({
    super.key,
    this.maxRadius = 40,
    this.color = AppColors.mapAirportGlow,
    this.ringCount = 3,
  });

  @override
  State<PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<PulsingRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.maxRadius * 2, widget.maxRadius * 2),
          painter: _PulsingRingsPainter(
            progress: _controller.value,
            color: widget.color,
            maxRadius: widget.maxRadius,
            ringCount: widget.ringCount,
          ),
        );
      },
    );
  }
}

class _PulsingRingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;
  final int ringCount;

  _PulsingRingsPainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
    required this.ringCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + i / ringCount) % 1.0;
      final radius = maxRadius * ringProgress;
      final opacity = (1.0 - ringProgress) * 0.5;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Center dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsingRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
