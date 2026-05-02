import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Horizon-line indicator for the AR view.
///
/// <p>Mirrors the web frontend's `HorizonLine.tsx` — a thin line that
/// translates vertically based on the device's pitch (and optionally
/// rotates with roll). The line marks "0° elevation" so the user can
/// tell which way is "level" relative to where the camera is pointing.
class HorizonLine extends StatelessWidget {
  /// Camera pitch in degrees: 0 = level (horizon dead-centre), +ve =
  /// looking up, -ve = looking down.
  final double pitchDeg;

  /// Camera roll in degrees: 0 = upright. Used to tilt the line so it
  /// stays visually-horizontal as the user rotates the device.
  final double rollDeg;

  /// Vertical field of view of the camera (default 45°). Used to
  /// translate pitch into a screen offset — at pitch = vfov/2 the
  /// horizon line is at the bottom of the screen, at pitch = -vfov/2
  /// it's at the top.
  final double verticalFovDeg;

  const HorizonLine({
    super.key,
    required this.pitchDeg,
    this.rollDeg = 0,
    this.verticalFovDeg = 45,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Translate pitch to fractional Y offset. Positive pitch =
        // looking up = horizon falls below the center.
        final fraction = (pitchDeg / verticalFovDeg).clamp(-0.5, 0.5);
        final yOffset = constraints.maxHeight * (0.5 + fraction);
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: yOffset - 1,
              child: Transform.rotate(
                angle: -rollDeg * 3.14159 / 180,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0),
                        AppColors.primary.withValues(alpha: 0.55),
                        AppColors.primary.withValues(alpha: 0.55),
                        AppColors.primary.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
