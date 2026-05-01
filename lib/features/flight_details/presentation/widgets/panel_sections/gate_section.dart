import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

/// Gate / Terminal info section.
class PanelGateSection extends StatelessWidget {
  final FlightRouteInfo route;
  final bool isDark;
  final Color primary;

  const PanelGateSection({
    super.key,
    required this.route,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final r = route;
    final depInfo = <String>[];
    final arrInfo = <String>[];

    if (r.depTerminal != null) depInfo.add('T${r.depTerminal}');
    if (r.depGate != null) depInfo.add('Gate ${r.depGate}');
    if (r.arrTerminal != null) arrInfo.add('T${r.arrTerminal}');
    if (r.arrGate != null) arrInfo.add('Gate ${r.arrGate}');
    if (r.arrBaggage != null) arrInfo.add('Bag ${r.arrBaggage}');

    if (depInfo.isEmpty && arrInfo.isEmpty && r.duration == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
        )),
      ),
      child: Row(
        children: [
          // Departure gate info
          if (depInfo.isNotEmpty)
            Expanded(child: Row(children: [
              Icon(Icons.flight_takeoff_rounded, size: 12,
                  color: AppColors.success.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(depInfo.join(' / '), style: TextStyle(fontFamily: 'Rajdhani',
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
            ])),
          // Duration
          if (r.duration != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withValues(alpha: 0.15)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.timer_rounded, size: 11, color: primary),
                const SizedBox(width: 4),
                Text(
                  r.duration! >= 60
                      ? '${r.duration! ~/ 60}h ${r.duration! % 60}m'
                      : '${r.duration}m',
                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 10,
                      fontWeight: FontWeight.w700, color: primary),
                ),
              ]),
            ),
          // Arrival gate info
          if (arrInfo.isNotEmpty)
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(arrInfo.join(' / '), style: TextStyle(fontFamily: 'Rajdhani',
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                const SizedBox(width: 5),
                Icon(Icons.flight_land_rounded, size: 12,
                    color: AppColors.accent.withValues(alpha: 0.7)),
              ],
            )),
        ],
      ),
    );
  }
}
