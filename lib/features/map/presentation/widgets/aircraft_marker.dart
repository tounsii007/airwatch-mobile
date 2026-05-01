import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/aircraft_icons.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

class AircraftMarkerWidget extends StatelessWidget {
  final AircraftState aircraft;
  final bool isSelected;
  final double markerSize;
  final VoidCallback? onTap;

  const AircraftMarkerWidget({
    super.key,
    required this.aircraft,
    this.isSelected = false,
    this.markerSize = 32,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AircraftIconPainter.getAltitudeColor(
      aircraft.altitude,
      onGround: aircraft.onGround,
      flightStatus: aircraft.flightStatus,
    );
    final type = AircraftIconPainter.getType(aircraft.category);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: markerSize,
        height: markerSize,
        child: CustomPaint(
          painter: AircraftIconPainter(
            type: type,
            heading: aircraft.heading,
            color: color,
            altitude: aircraft.altitude ?? 0,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

/// Animated aircraft marker with smooth position interpolation
class AnimatedAircraftMarker extends StatefulWidget {
  final AircraftState aircraft;
  final bool isSelected;
  final double markerSize;
  final VoidCallback? onTap;

  const AnimatedAircraftMarker({
    super.key,
    required this.aircraft,
    this.isSelected = false,
    this.markerSize = 32,
    this.onTap,
  });

  @override
  State<AnimatedAircraftMarker> createState() => _AnimatedAircraftMarkerState();
}

class _AnimatedAircraftMarkerState extends State<AnimatedAircraftMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppConfig.markerPulseDuration,
    );
    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedAircraftMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AircraftIconPainter.getAltitudeColor(
      widget.aircraft.altitude,
      onGround: widget.aircraft.onGround,
      isSelected: widget.isSelected,
      flightStatus: widget.aircraft.flightStatus,
    );
    final type = AircraftIconPainter.getType(widget.aircraft.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseScale =
              widget.isSelected ? 1.0 + (_pulseController.value * AppConfig.markerPulseScale) : 1.0;

          return Transform.scale(
            scale: pulseScale,
            child: OverflowBox(
              maxHeight: AppConfig.markerOverflowMaxHeight,
              maxWidth: AppConfig.markerOverflowMaxWidth,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Callsign label
                if (widget.isSelected &&
                    widget.aircraft.callsign != null &&
                    widget.aircraft.callsign!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.aircraft.callsign!.trim(),
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                // Aircraft icon
                SizedBox(
                  width: widget.markerSize,
                  height: widget.markerSize,
                  child: CustomPaint(
                    painter: AircraftIconPainter(
                      type: type,
                      heading: widget.aircraft.heading,
                      color: color,
                      altitude: widget.aircraft.altitude ?? 0,
                      isSelected: widget.isSelected,
                      glowIntensity: isDark ? 0.6 : 0.3,
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
