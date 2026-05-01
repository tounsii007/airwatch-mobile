import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated radar overlay with concentric glowing rings and a sweep line.
/// Draws on top of the map to create the futuristic radar effect from the mockups.
class RadarOverlay extends StatefulWidget {
  final bool enabled;

  const RadarOverlay({super.key, this.enabled = true});

  @override
  State<RadarOverlay> createState() => _RadarOverlayState();
}

class _RadarOverlayState extends State<RadarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    // Defer `.repeat()` to the next frame — calling it synchronously in
    // `initState` triggers an `elapsedInSeconds >= 0.0` assertion under
    // `flutter_test`'s FakeAsync clock. See the comment in
    // status_overlay.dart's `_PulsingDot` for the full reasoning.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return const SizedBox.shrink(); // Only in dark mode

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _RadarOverlayPainter(
              progress: _controller.value,
              color: AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}

class _RadarOverlayPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarOverlayPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.45;

    // ── Concentric radar rings ──
    const ringCount = 4;
    for (int i = 1; i <= ringCount; i++) {
      final fraction = i / ringCount;
      final radius = maxRadius * fraction;
      // Outer rings are more transparent
      final opacity = (0.12 - (fraction * 0.08)).clamp(0.02, 0.12);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // ── Pulsing ring (animates outward) ──
    final pulseRadius = maxRadius * progress;
    final pulseOpacity = (1.0 - progress) * 0.15;
    canvas.drawCircle(
      center,
      pulseRadius,
      Paint()
        ..color = color.withValues(alpha: pulseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Sweep line ──
    final sweepAngle = progress * 2 * math.pi;
    final sweepEnd = Offset(
      center.dx + maxRadius * math.cos(sweepAngle - math.pi / 2),
      center.dy + maxRadius * math.sin(sweepAngle - math.pi / 2),
    );
    canvas.drawLine(
      center,
      sweepEnd,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );

    // ── Sweep gradient trail ──
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepAngle - 0.6,
        endAngle: sweepAngle,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.06),
        ],
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, sweepPaint);

    // ── Crosshairs (very subtle) ──
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    canvas.drawLine(
        Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius),
        crossPaint);
    canvas.drawLine(
        Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy),
        crossPaint);

    // ── Center dot ──
    canvas.drawCircle(
      center,
      3,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      center,
      1.5,
      Paint()..color = color.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
