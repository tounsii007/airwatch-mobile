import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/geofences/domain/alert_format.dart';
import 'package:airwatch_mobile/features/geofences/domain/fence_stats.dart';
import 'package:airwatch_mobile/features/geofences/presentation/providers/geofence_alerts_provider.dart';

/// Per-fence compact stats badge — shows nothing when the fence has
/// zero live hits so the empty-state list stays clean.
///
/// <p>Mirrors airwatch-web's `FenceStatsBadge.tsx` (commit 982c6d2).
/// Refreshes the "last X ago" caption every 30 s without recomputing
/// stats — the wallclock ticker is decoupled from the alert subscription.
class FenceStatsBadge extends ConsumerStatefulWidget {
  const FenceStatsBadge({super.key, required this.fenceId});
  final String fenceId;

  @override
  ConsumerState<FenceStatsBadge> createState() => _FenceStatsBadgeState();
}

class _FenceStatsBadgeState extends ConsumerState<FenceStatsBadge> {
  Timer? _wallclock;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _wallclock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  @override
  void dispose() {
    _wallclock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hits = ref.watch(geofenceAlertsProvider);
    final stats = computeFenceStats(hits, widget.fenceId);
    if (stats.total == 0) return const SizedBox.shrink();

    final s = S.of(ref.watch(languageProvider));
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        children: [
          _Pill(
            icon: Icons.bolt_rounded,
            text: stats.total == 1
                ? s.fenceStatsHitsOne.replaceAll('{0}', '${stats.total}')
                : s.fenceStatsHitsMany.replaceAll('{0}', '${stats.total}'),
          ),
          _Pill(
            icon: Icons.flight_rounded,
            text: s.fenceStatsAircraft.replaceAll(
              '{0}',
              '${stats.uniqueAircraft}',
            ),
          ),
          if (stats.topAirline != null)
            _AirlinePill(
              prefix: s.fenceStatsTopLabel,
              code: stats.topAirline!.code,
              count: stats.topAirline!.count,
              tooltip: stats.topAirline!.name == null
                  ? s.fenceStatsTopAirline.replaceAll(
                      '{0}',
                      stats.topAirline!.code,
                    )
                  : s.fenceStatsTopAirlineWithName
                        .replaceAll('{0}', stats.topAirline!.name!)
                        .replaceAll('{1}', '${stats.topAirline!.count}'),
            ),
          if (stats.latestAt != null)
            Tooltip(
              message: stats.latestAt!.toLocal().toString(),
              child: Text(
                s.fenceStatsLast.replaceAll(
                  '{0}',
                  timeAgo(stats.latestAt!, _nowMs),
                ),
                style: const TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AirlinePill extends StatelessWidget {
  const _AirlinePill({
    required this.prefix,
    required this.code,
    required this.count,
    required this.tooltip,
  });
  final String prefix;
  final String code;
  final int count;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: const TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            code,
            style: const TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '×$count',
            style: const TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
