import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_status_utils.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/airport/data/models/airport_detail_models.dart';

class AirportScheduleTile extends StatelessWidget {
  final AirportScheduleFlight flight;
  final bool isDep;
  final bool isDark;
  final Color primary;

  const AirportScheduleTile({
    super.key,
    required this.flight,
    required this.isDep,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = flight.displayCode.isNotEmpty
        ? flight.displayCode
        : UiConstants.missingCode;
    final depIata = flight.depIata.isNotEmpty
        ? flight.depIata
        : UiConstants.missingCode;
    final arrIata = flight.arrIata.isNotEmpty
        ? flight.arrIata
        : UiConstants.missingCode;
    final status = flight.status;
    final scheduledTime = isDep ? flight.depTime : flight.arrTime;
    final delay = isDep ? flight.depDelayed : flight.arrDelayed;
    final terminal = isDep ? flight.depTerminal : flight.arrTerminal;
    final gate = isDep ? flight.depGate : flight.arrGate;

    final statusColor = FlightStatusUtils.statusColor(status, primary: primary);
    final statusText = FlightStatusUtils.statusLabel(context, status);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 10,
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                _formatTime(scheduledTime),
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: UiConstants.captionFontSize,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 40),
              decoration: BoxDecoration(
                color: (delay != null && delay > 0)
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (delay != null && delay > 0)
                    ? '+${delay}min'
                    : context.tr('on_time'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: (delay != null && delay > 0)
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                cs,
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: UiConstants.microFontSize,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : UiConstants.lightTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isDep ? '→ $arrIata' : '$depIata →',
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: UiConstants.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: isDep ? AppColors.accent : AppColors.success,
                ),
              ),
            ),
            if (terminal != null || gate != null)
              Text(
                [if (terminal != null) 'T$terminal', gate].join('/'),
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: UiConstants.microFontSize,
                  color: isDark
                      ? AppColors.textMuted
                      : UiConstants.lightTextMuted,
                ),
              ),
            const SizedBox(width: 6),
            if (statusText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    if (value.contains(' ')) {
      final last = value.split(' ').last;
      return last.length >= 5 ? last.substring(0, 5) : last;
    }
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}
