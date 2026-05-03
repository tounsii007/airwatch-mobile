import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/config.dart';
import '../constants/conversion_constants.dart';
import '../theme/app_colors.dart';

enum AircraftType {
  jet,
  turboprop,
  helicopter,
  lightAircraft,
  cargo,
  military,
  unknown,
}

class AircraftIconPainter extends CustomPainter {
  final AircraftType type;
  final double heading;
  final Color color;
  final double altitude;
  final bool isSelected;
  final double glowIntensity;

  AircraftIconPainter({
    required this.type,
    required this.heading,
    required this.color,
    this.altitude = 0,
    this.isSelected = false,
    this.glowIntensity = 0.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    // heading 0=North, rotate so nose points in heading direction
    canvas.rotate(heading * math.pi / 180);

    final s = size.width / 32; // scale factor

    // Outer glow effect — stronger, more visible
    if (isSelected) {
      // Selected: double glow ring
      canvas.drawCircle(
        Offset.zero,
        18 * s,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(
        Offset.zero,
        12 * s,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    } else if (glowIntensity > 0.2) {
      // Unselected: subtle neon glow
      canvas.drawCircle(
        Offset.zero,
        10 * s,
        Paint()
          ..color = color.withValues(alpha: glowIntensity * 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowIntensity),
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case AircraftType.jet:
        _drawJetTopDown(canvas, s, paint);
      case AircraftType.cargo:
        _drawCargoTopDown(canvas, s, paint);
      case AircraftType.turboprop:
        _drawTurbopropTopDown(canvas, s, paint);
      case AircraftType.helicopter:
        _drawHelicopterTopDown(canvas, s, paint);
      case AircraftType.lightAircraft:
        _drawLightTopDown(canvas, s, paint);
      default:
        _drawJetTopDown(canvas, s, paint);
    }

    canvas.restore();
  }

  /// Realistic top-down jet silhouette (like A320/B737)
  void _drawJetTopDown(Canvas canvas, double s, Paint paint) {
    // Fuselage — slim elongated body
    final fuselage = Path()
      ..moveTo(0, -13 * s) // nose tip
      ..cubicTo(
        1.5 * s,
        -11 * s, // nose right curve
        1.8 * s,
        -6 * s,
        1.8 * s,
        0,
      )
      ..lineTo(1.5 * s, 8 * s) // body right
      ..lineTo(0.8 * s, 12 * s) // tail right
      ..lineTo(-0.8 * s, 12 * s) // tail left
      ..lineTo(-1.5 * s, 8 * s) // body left
      ..lineTo(-1.8 * s, 0)
      ..cubicTo(-1.8 * s, -6 * s, -1.5 * s, -11 * s, 0, -13 * s)
      ..close();
    canvas.drawPath(fuselage, paint);

    // Main wings — swept back
    final wings = Path()
      ..moveTo(-1.5 * s, -1 * s) // left wing root
      ..lineTo(-11 * s, 4 * s) // left wingtip
      ..lineTo(-11 * s, 5 * s) // left tip thickness
      ..lineTo(-1.5 * s, 2 * s) // left trailing edge
      ..close();
    canvas.drawPath(wings, paint);

    final wingsR = Path()
      ..moveTo(1.5 * s, -1 * s)
      ..lineTo(11 * s, 4 * s)
      ..lineTo(11 * s, 5 * s)
      ..lineTo(1.5 * s, 2 * s)
      ..close();
    canvas.drawPath(wingsR, paint);

    // Horizontal stabilizer (tail wings)
    final tailL = Path()
      ..moveTo(-0.8 * s, 10 * s)
      ..lineTo(-5 * s, 12 * s)
      ..lineTo(-5 * s, 12.5 * s)
      ..lineTo(-0.8 * s, 11 * s)
      ..close();
    canvas.drawPath(tailL, paint);

    final tailR = Path()
      ..moveTo(0.8 * s, 10 * s)
      ..lineTo(5 * s, 12 * s)
      ..lineTo(5 * s, 12.5 * s)
      ..lineTo(0.8 * s, 11 * s)
      ..close();
    canvas.drawPath(tailR, paint);

    // Engines (small bumps on wings)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-4.5 * s, 2.5 * s),
        width: 1.5 * s,
        height: 3 * s,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(4.5 * s, 2.5 * s),
        width: 1.5 * s,
        height: 3 * s,
      ),
      paint,
    );
  }

  /// Cargo / widebody (like B747/B777) — wider body, longer wings
  void _drawCargoTopDown(Canvas canvas, double s, Paint paint) {
    // Wider fuselage
    final fuselage = Path()
      ..moveTo(0, -14 * s)
      ..cubicTo(2 * s, -12 * s, 2.5 * s, -6 * s, 2.5 * s, 0)
      ..lineTo(2 * s, 9 * s)
      ..lineTo(1 * s, 13 * s)
      ..lineTo(-1 * s, 13 * s)
      ..lineTo(-2 * s, 9 * s)
      ..lineTo(-2.5 * s, 0)
      ..cubicTo(-2.5 * s, -6 * s, -2 * s, -12 * s, 0, -14 * s)
      ..close();
    canvas.drawPath(fuselage, paint);

    // Longer swept wings
    final wL = Path()
      ..moveTo(-2 * s, -2 * s)
      ..lineTo(-13 * s, 4 * s)
      ..lineTo(-13 * s, 5.5 * s)
      ..lineTo(-2 * s, 2 * s)
      ..close();
    canvas.drawPath(wL, paint);

    final wR = Path()
      ..moveTo(2 * s, -2 * s)
      ..lineTo(13 * s, 4 * s)
      ..lineTo(13 * s, 5.5 * s)
      ..lineTo(2 * s, 2 * s)
      ..close();
    canvas.drawPath(wR, paint);

    // Tail
    final tL = Path()
      ..moveTo(-1 * s, 11 * s)
      ..lineTo(-5.5 * s, 13 * s)
      ..lineTo(-5.5 * s, 13.5 * s)
      ..lineTo(-1 * s, 12 * s)
      ..close();
    canvas.drawPath(tL, paint);
    final tR = Path()
      ..moveTo(1 * s, 11 * s)
      ..lineTo(5.5 * s, 13 * s)
      ..lineTo(5.5 * s, 13.5 * s)
      ..lineTo(1 * s, 12 * s)
      ..close();
    canvas.drawPath(tR, paint);

    // 4 engines
    for (final ex in [-4.0, -8.0, 4.0, 8.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex * s, 2.5 * s),
          width: 1.2 * s,
          height: 2.8 * s,
        ),
        paint,
      );
    }
  }

  /// Turboprop — straight wings, no sweep
  void _drawTurbopropTopDown(Canvas canvas, double s, Paint paint) {
    // Slimmer fuselage
    final fuselage = Path()
      ..moveTo(0, -11 * s)
      ..cubicTo(1.2 * s, -9 * s, 1.5 * s, -4 * s, 1.5 * s, 0)
      ..lineTo(1.2 * s, 8 * s)
      ..lineTo(0, 11 * s)
      ..lineTo(-1.2 * s, 8 * s)
      ..lineTo(-1.5 * s, 0)
      ..cubicTo(-1.5 * s, -4 * s, -1.2 * s, -9 * s, 0, -11 * s)
      ..close();
    canvas.drawPath(fuselage, paint);

    // Straight wings (no sweep)
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, 1 * s), width: 22 * s, height: 2 * s),
      paint,
    );

    // Tail wings
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, 10 * s),
        width: 10 * s,
        height: 1.5 * s,
      ),
      paint,
    );
  }

  /// Helicopter top-down
  void _drawHelicopterTopDown(Canvas canvas, double s, Paint paint) {
    // Teardrop body
    final body = Path()
      ..moveTo(0, -5 * s)
      ..cubicTo(3 * s, -4 * s, 3.5 * s, 0, 3 * s, 3 * s)
      ..lineTo(1 * s, 8 * s)
      ..lineTo(-1 * s, 8 * s)
      ..lineTo(-3 * s, 3 * s)
      ..cubicTo(-3.5 * s, 0, -3 * s, -4 * s, 0, -5 * s)
      ..close();
    canvas.drawPath(body, paint);

    // Main rotor disc
    final rotorPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * s;
    canvas.drawCircle(Offset(0, -1 * s), 10 * s, rotorPaint);
    // Rotor blades
    canvas.drawLine(
      Offset(-10 * s, -1 * s),
      Offset(10 * s, -1 * s),
      rotorPaint,
    );
    canvas.drawLine(Offset(0, -11 * s), Offset(0, 9 * s), rotorPaint);

    // Tail boom
    canvas.drawLine(
      Offset(0, 8 * s),
      Offset(0, 13 * s),
      Paint()
        ..color = color
        ..strokeWidth = 1 * s
        ..strokeCap = StrokeCap.round,
    );
    // Tail rotor
    canvas.drawLine(
      Offset(-3 * s, 13 * s),
      Offset(3 * s, 13 * s),
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 0.6 * s,
    );
  }

  /// Light aircraft — simple, short wings
  void _drawLightTopDown(Canvas canvas, double s, Paint paint) {
    // Small fuselage
    final fuselage = Path()
      ..moveTo(0, -8 * s)
      ..cubicTo(1 * s, -6 * s, 1.2 * s, -2 * s, 1.2 * s, 0)
      ..lineTo(1 * s, 6 * s)
      ..lineTo(0, 8 * s)
      ..lineTo(-1 * s, 6 * s)
      ..lineTo(-1.2 * s, 0)
      ..cubicTo(-1.2 * s, -2 * s, -1 * s, -6 * s, 0, -8 * s)
      ..close();
    canvas.drawPath(fuselage, paint);

    // Short straight wings
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: 16 * s,
        height: 1.5 * s,
      ),
      paint,
    );

    // Tail
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, 7 * s), width: 7 * s, height: 1.2 * s),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant AircraftIconPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.color != color ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.type != type;
  }

  static Color getAltitudeColor(
    double? altitudeMeters, {
    bool onGround = false,
    bool isSelected = false,
    String? flightStatus,
  }) {
    // Selected aircraft gets a distinct bright white-blue color
    if (isSelected) return const Color(0xFFE0F0FF);
    if (onGround) {
      // Scheduled (about to depart) → amber
      if (flightStatus == 'scheduled') return const Color(0xFFF59E0B);
      // Landed (just arrived) → blue-gray
      return const Color(0xFF6B7280);
    }
    if (altitudeMeters == null) return AppColors.textMuted;
    final feet = altitudeMeters * ConversionConstants.metersToFeet;
    if (feet < AppConfig.altitudeGroundMax)
      return const Color(AppConfig.groundColor);
    if (feet < AppConfig.altitudeLowMax) return AppColors.altitudeLow;
    if (feet < AppConfig.altitudeMedMax) return AppColors.altitudeMedium;
    return AppColors.altitudeHigh;
  }

  static AircraftType getType(int category) {
    return switch (category) {
      8 => AircraftType.helicopter,
      6 => AircraftType.cargo,
      2 => AircraftType.lightAircraft,
      9 || 10 || 11 || 12 => AircraftType.lightAircraft,
      3 => AircraftType.turboprop,
      4 || 5 || 7 => AircraftType.jet,
      _ => AircraftType.jet,
    };
  }
}
