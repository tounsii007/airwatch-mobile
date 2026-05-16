import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/widgets/ticking_value.dart';
import '../../../../../core/theme/app_colors.dart';

/// Colored data card with 1 or 2 values
class FlightDataCard extends StatelessWidget {
  final String title1, value1;
  final String? title2, value2;
  final Color borderColor;
  final bool isDark;
  const FlightDataCard({
    super.key,
    required this.title1,
    required this.value1,
    this.title2,
    this.value2,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title1,
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
            ),
          ),
          const SizedBox(height: 2),
          // Wrapped in TickingValue so a WS push that actually changes
          // the number (alt / speed / heading / V/S / lat / lon) gives
          // a visible cue instead of looking identical to "the panel
          // is idle". Mirrors airwatch-web's TickingValue primitive
          // (commit 6eeb5b8).
          TickingValue(
            value: value1,
            style: TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: borderColor,
            ),
          ),
          if (title2 != null) ...[
            const SizedBox(height: 4),
            Text(
              title2!,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
                color: isDark
                    ? AppColors.textMuted
                    : UiConstants.lightTextMuted,
              ),
            ),
            const SizedBox(height: 2),
            TickingValue(
              value: value2!,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimary
                    : UiConstants.lightTextPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Metadata tag chip
class FlightTag extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const FlightTag({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 9,
              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Altitude color legend dot
class AltitudeLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const AltitudeLegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Solid action button (TRACK, REPLAY, HISTORY, FAVORITE)
class FlightActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  /// Optional long-press handler. Currently used by the REPLAY button
  /// to open the 3-D globe variant instead of the 2-D map replay —
  /// mirrors the web frontend's `/replay/3d` shortcut without burning
  /// a separate slot on the action row.
  final VoidCallback? onLongPress;

  const FlightActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small detail chip for aircraft info
class DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const DetailChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Route line painter between DEP and ARR
class RouteLinePainter extends CustomPainter {
  final Color color;
  RouteLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final dash = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
      x += 9;
    }
    final cx = size.width / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx + 7, y)
        ..lineTo(cx + 2, y - 2)
        ..lineTo(cx - 3, y - 2)
        ..lineTo(cx, y - 5)
        ..lineTo(cx - 2, y - 5)
        ..lineTo(cx - 6, y - 2)
        ..lineTo(cx - 7, y)
        ..lineTo(cx - 6, y + 2)
        ..lineTo(cx - 2, y + 5)
        ..lineTo(cx, y + 5)
        ..lineTo(cx - 3, y + 2)
        ..lineTo(cx + 2, y + 2)
        ..close(),
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(2, y),
      2.5,
      Paint()..color = const Color(0xFF4ADE80),
    );
    canvas.drawCircle(
      Offset(size.width - 2, y),
      2.5,
      Paint()..color = const Color(0xFFD4A574),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
