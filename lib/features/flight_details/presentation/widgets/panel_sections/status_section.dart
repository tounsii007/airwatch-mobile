import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_status_utils.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

/// Status + Delay info from Airlabs.
class PanelStatusSection extends StatelessWidget {
  final FlightRouteInfo route;
  final bool isDark;
  final Color primary;

  const PanelStatusSection({
    super.key,
    required this.route,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final r = route;
    final statusColor = FlightStatusUtils.statusColor(r.status, primary: AppColors.primary);
    final statusText = FlightStatusUtils.statusLabel(context, r.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
        )),
      ),
      child: Row(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(statusText, style: TextStyle(fontFamily: 'Orbitron',
                fontSize: 8, fontWeight: FontWeight.w700, color: statusColor)),
          ),
          const SizedBox(width: 8),
          // Scheduled times
          if (r.scheduledDep != null)
            Expanded(child: Text(
              '${context.tr('dep')} ${_formatTime(r.scheduledDep)}${r.actualDep != null ? " \u2192 ${_formatTime(r.actualDep)}" : ""}',
              style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11,
                  color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
            )),
          // Delay badges
          if (r.hasDepDelay)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('+${r.depDelay}m', style: TextStyle(fontFamily: 'Orbitron',
                  fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.error)),
            ),
          if (r.hasArrDelay) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${context.tr('arr')} +${r.arrDelay}m', style: TextStyle(fontFamily: 'Orbitron',
                  fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.warning)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--';
    // Airlabs format: "2026-04-07 14:30" or "14:30"
    // ISO format: "2026-04-07T14:30:00"
    if (timeStr.contains(' ')) {
      final parts = timeStr.split(' ');
      if (parts.length > 1) return parts.last.length >= 5 ? parts.last.substring(0, 5) : parts.last;
    }
    if (timeStr.contains('T')) {
      final parts = timeStr.split('T');
      if (parts.length > 1) return parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
    }
    // Already HH:mm format
    if (timeStr.length == 5 && timeStr.contains(':')) return timeStr;
    return timeStr;
  }
}
