import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/notifications/domain/alert.dart';
import 'package:airwatch_mobile/features/notifications/presentation/providers/alerts_provider.dart';

/// Bell-icon button + badge + bottom-sheet alert panel.
///
/// <p>Mirrors the web frontend's `AlertBell` from the layout's
/// top-right corner. Tap to open a bottom sheet listing every active
/// alert (squawk + geofence) with their kind icon, title, subtitle,
/// timestamp. Tapping an alert focuses the relevant aircraft.
class AlertBell extends ConsumerWidget {
  const AlertBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final count = ref.watch(alertCountProvider);

    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            borderColor: count > 0
                ? AppColors.error.withValues(alpha: 0.55)
                : null,
            child: Icon(
              count > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 20,
              color: count > 0 ? AppColors.error : primary,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AlertsSheet(),
    );
  }
}

class _AlertsSheet extends ConsumerWidget {
  const _AlertsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (_, scrollCtl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.background : UiConstants.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        size: 18,
                        color: alerts.isEmpty
                            ? AppColors.textMuted
                            : AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'ALERTS · ${alerts.length}',
                      style: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: alerts.isEmpty
                            ? AppColors.textMuted
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: alerts.isEmpty
                    ? const _Empty()
                    : ListView.separated(
                        controller: scrollCtl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        itemCount: alerts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.alert});
  final AppAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _focus(context, ref),
      behavior: HitTestBehavior.opaque,
      child: GlassPanel(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderColor: alert.accent.withValues(alpha: 0.45),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: alert.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(alert.icon, color: alert.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: alert.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (alert.subtitle != null && alert.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      alert.subtitle!,
                      style: const TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  /// Focus the relevant aircraft when the user taps the alert. For
  /// squawk + geofence alerts, the [targetId] is the icao24 hex.
  void _focus(BuildContext context, WidgetRef ref) {
    final id = alert.targetId;
    if (id == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final live = ref.read(aircraftStreamProvider).value;
    final ac = live?[id];
    if (ac != null && ac.position != null) {
      ref.read(selectedAircraftProvider.notifier).set(ac);
      ref.read(mapFocusProvider.notifier).focusOn(ac.position!, zoom: 9);
    }
    Navigator.of(context).maybePop();
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 40,
                color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            const Text(
              'No active alerts',
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
