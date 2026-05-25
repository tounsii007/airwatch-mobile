import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/airlines/presentation/screens/airlines_screen.dart';
import 'package:airwatch_mobile/features/cargo/presentation/screens/cargo_screen.dart';
import 'package:airwatch_mobile/features/compare/presentation/screens/compare_screen.dart';
import 'package:airwatch_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:airwatch_mobile/features/geofences/presentation/screens/geofences_screen.dart';
import 'package:airwatch_mobile/features/globe/presentation/screens/globe_screen.dart';
import 'package:airwatch_mobile/features/replay/presentation/screens/replay_screen.dart';
import 'package:airwatch_mobile/features/spotting/presentation/screens/spotting_screen.dart';
import 'package:airwatch_mobile/features/stats/presentation/screens/stats_screen.dart';

/// "More" overflow sheet — the mobile equivalent of airwatch-web's
/// `MoreMenuSheet` triggered from BottomNav.tsx. Surfaces the 8
/// secondary routes that don't fit in the always-visible bottom-nav
/// (which is capped at 5 + More for one-handed reach).
///
/// <p>Each row navigates via `Navigator.push` rather than swapping the
/// IndexedStack inside `_AppShell`, so:
///   - the secondary screen gets its own back-stack (swipe-back works),
///   - bottom-nav state on the primary tabs is preserved underneath,
///   - the user lands back exactly where they started after `pop()`.
///
/// <p>Replay is intentionally absent — the mobile app doesn't ship a
/// `/replay` screen yet (only the data layer + `replay` i18n key). It
/// will be added here once `ReplayScreen` exists.
class MoreMenuSheet extends ConsumerWidget {
  const MoreMenuSheet({super.key});

  /// Convenience launcher — call from anywhere with a `BuildContext`.
  /// Returns when the sheet closes (which is independent of the chosen
  /// destination's own navigation lifecycle).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Tap-outside-to-dismiss is the default; we just want the sheet
      // to feel modal without a full opaque scrim, which would clash
      // with the glass aesthetic on the primary screens behind it.
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const MoreMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref.watch(languageProvider));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Each entry: (icon, label, subtitle, screen builder).
    // Order mirrors airwatch-web's SECONDARY_ITEMS list so users moving
    // between platforms find features in the same place.
    final entries = <_MoreEntry>[
      _MoreEntry(
        icon: Icons.dashboard_rounded,
        // Renamed to "Overview" — see DashboardScreen's AppBar for the
        // rationale (parity-clear naming vs web's airport-monitoring
        // dashboard).
        label: s.overview,
        subtitle: s.dashboardSubtitle,
        builder: (_) => const DashboardScreen(),
      ),
      _MoreEntry(
        icon: Icons.local_shipping_rounded,
        label: s.cargo,
        subtitle: s.cargoSubtitle,
        builder: (_) => const CargoScreen(),
      ),
      _MoreEntry(
        icon: Icons.bar_chart_rounded,
        label: s.stats,
        subtitle: s.statsSubtitle,
        builder: (_) => const StatsScreen(),
      ),
      _MoreEntry(
        icon: Icons.compare_arrows_rounded,
        label: s.compare,
        subtitle: s.compareSubtitle,
        builder: (_) => const CompareScreen(),
      ),
      _MoreEntry(
        icon: Icons.public_rounded,
        label: s.globe,
        subtitle: s.globeSubtitle,
        builder: (_) => const GlobeScreen(),
      ),
      _MoreEntry(
        icon: Icons.camera_alt_rounded,
        label: s.spotting,
        subtitle: s.spottingShortSubtitle,
        builder: (_) => const SpottingScreen(),
      ),
      _MoreEntry(
        icon: Icons.history_rounded,
        label: s.replay,
        subtitle: s.replayBody,
        builder: (_) => const ReplayScreen(),
      ),
      _MoreEntry(
        icon: Icons.hexagon_outlined,
        label: s.geofences,
        subtitle: s.geofencesSubtitle,
        builder: (_) => const GeofencesScreen(),
      ),
      _MoreEntry(
        icon: Icons.flight_rounded,
        label: s.airlines,
        subtitle: s.airlinesSubtitle,
        builder: (_) => const AirlinesScreen(),
      ),
    ];

    // 90 % of viewport — leaves a hint of the primary screen behind so
    // the user knows they can swipe down to dismiss without losing
    // their map context.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: GlassPanel(
          borderRadius: 0, // outer ClipRRect handles the radius
          padding: EdgeInsets.zero,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle — purely visual, the sheet listens to the
                // drag on the whole surface area.
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.moreFeatures,
                          style: TextStyle(
                            fontFamily: UiConstants.headingFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                // Grid — 2 columns on phones, expands on landscape.
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      0,
                      12,
                      16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 480 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.35,
                              ),
                          itemCount: entries.length,
                          itemBuilder: (_, i) =>
                              _MoreCard(entry: entries[i], isDark: isDark),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreEntry {
  const _MoreEntry({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.builder,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final WidgetBuilder builder;
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.entry, required this.isDark});
  final _MoreEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${entry.label}. ${entry.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Close the sheet first so the back-button on the pushed
            // screen returns to the underlying primary tab, not to a
            // ghost sheet that's already gone.
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: entry.builder));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.glassBorder.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(entry.icon, color: AppColors.primary, size: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 10,
                        color: AppColors.textMuted,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
