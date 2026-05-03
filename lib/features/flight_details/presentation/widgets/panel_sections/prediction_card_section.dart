import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/flight_details/domain/delay_predictor.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Compact AI-style "prediction card" with delay-probability gauge.
///
/// <p>Mirrors the web frontend's `PredictionCard.tsx`:
/// <ul>
///   <li>donut gauge of delay probability (success/warning/error tinted by
///       severity);</li>
///   <li>one-sentence explanation;</li>
///   <li>optional "~XX min delay" sub-line;</li>
///   <li>factor pills (Emergency squawk, Long-haul, etc.);</li>
///   <li>"Powered by …" footer for honesty about the heuristic.</li>
/// </ul>
///
/// <p>The actual prediction is done by [predictDelay] in the domain
/// layer — this widget is purely presentational and the parent (the
/// flight-details panel) wires it up.
class PanelPredictionCard extends StatelessWidget {
  final AircraftState aircraft;
  final FlightRouteInfo? route;
  final bool isDark;

  const PanelPredictionCard({
    super.key,
    required this.aircraft,
    required this.route,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pred = predictDelay(aircraft: aircraft, route: route);
    // Hide if the predictor returned nothing useful — matches the web
    // behaviour where the card collapses for unknown flights.
    if (pred.explanation.isEmpty) return const SizedBox.shrink();

    final delayColor = pred.delayProbability > 60
        ? AppColors.error
        : pred.delayProbability > 30
        ? AppColors.warning
        : AppColors.success;
    final confColor = switch (pred.confidence) {
      PredictionConfidence.high => AppColors.success,
      PredictionConfidence.medium => AppColors.warning,
      PredictionConfidence.low => AppColors.textMuted,
    };
    final confLabel = switch (pred.confidence) {
      PredictionConfidence.high => 'HIGH',
      PredictionConfidence.medium => 'MED',
      PredictionConfidence.low => 'LOW',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                size: 14,
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              const Text(
                'PREDICTION',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: confColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  confLabel,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: confColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: _DelayDonutPainter(
                    progress: pred.delayProbability / 100,
                    color: delayColor,
                    trackColor: isDark
                        ? AppColors.glassBorder
                        : UiConstants.lightBorder,
                  ),
                  child: Center(
                    child: Text(
                      '${pred.delayProbability}%',
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: delayColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pred.explanation,
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textPrimary
                            : UiConstants.lightTextPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (pred.estimatedDelayMinutes > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '~${pred.estimatedDelayMinutes} min',
                        style: TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: delayColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (pred.factors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final f in pred.factors)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'On-device heuristic — not airline-grade.',
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 8,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut-shaped progress arc, used for the delay-probability indicator.
class _DelayDonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _DelayDonutPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    final sweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _DelayDonutPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
