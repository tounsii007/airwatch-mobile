import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/ar/domain/ar_math.dart';

/// Compass HUD strip across the top of the AR view.
///
/// <p>Mirrors the web frontend's `CompassHud.tsx`:
/// <ul>
///   <li>A horizontal strip with tick marks every 15° between
///       `heading - hfov/2` and `heading + hfov/2`.</li>
///   <li>Major ticks (N / E / S / W) labelled; minor ticks every 15°
///       with a half-height line.</li>
///   <li>The centre of the strip = the direction the camera is
///       pointing. Ticks that fall outside the FOV are clipped.</li>
/// </ul>
class CompassHud extends StatelessWidget {
  /// Compass heading in degrees [0, 360), clockwise from true north.
  final double headingDeg;

  /// Horizontal field of view of the camera in degrees. Default 60°
  /// matches a typical phone camera's wide-angle FOV.
  final double horizontalFovDeg;

  /// Whether the strip should sit on a translucent dark backdrop
  /// (true for a camera feed, false for a flat preview).
  final bool darkBacking;

  const CompassHud({
    super.key,
    required this.headingDeg,
    this.horizontalFovDeg = 60,
    this.darkBacking = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Container(
        decoration: darkBacking
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              )
            : null,
        child: ClipRect(
          child: CustomPaint(
            painter: _CompassPainter(
              headingDeg: headingDeg,
              horizontalFovDeg: horizontalFovDeg,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double headingDeg;
  final double horizontalFovDeg;

  _CompassPainter({required this.headingDeg, required this.horizontalFovDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2;
    final cx = half;

    final tickPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final majorPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final centerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5;

    // Centre indicator — the heading line.
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height * 0.55), centerPaint);

    // Cardinal labels live at exact 0/90/180/270; minor ticks at
    // every 15° in between. We iterate the visible window only:
    // [heading - fov/2, heading + fov/2] in 1°-grain to find ticks.
    final start = headingDeg - horizontalFovDeg / 2;
    final end = headingDeg + horizontalFovDeg / 2;

    for (
      var deg = (start.floor() ~/ 15) * 15;
      deg.toDouble() <= end;
      deg += 15
    ) {
      final normalized = normalizeDeg(deg.toDouble());
      final dx = shortestAngleDiff(headingDeg, normalized);
      if (dx.abs() > horizontalFovDeg / 2) continue;

      final px = cx + (dx / (horizontalFovDeg / 2)) * half;
      final isCardinal = normalized % 90 == 0;
      canvas.drawLine(
        Offset(px, isCardinal ? 0 : size.height * 0.30),
        Offset(px, isCardinal ? size.height * 0.55 : size.height * 0.50),
        isCardinal ? majorPaint : tickPaint,
      );

      if (isCardinal) {
        final label = _cardinalLabel(normalized);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(px - tp.width / 2, size.height * 0.62));
      }
    }
  }

  static String _cardinalLabel(double deg) {
    switch (deg.round()) {
      case 0:
        return 'N';
      case 90:
        return 'E';
      case 180:
        return 'S';
      case 270:
        return 'W';
      default:
        return '';
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.headingDeg != headingDeg || old.horizontalFovDeg != horizontalFovDeg;
}
