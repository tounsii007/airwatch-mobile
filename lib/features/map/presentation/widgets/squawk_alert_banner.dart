import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/squawk_alerts_provider.dart';

/// Banner that appears at the top of the map whenever any tracked
/// aircraft is on an emergency squawk (7500 / 7600 / 7700).
///
/// <p>Mirrors the web frontend's `SquawkAlertBanner.tsx`. Each affected
/// aircraft is rendered as a tap-able pill — tapping selects it on the
/// map (via [selectedAircraftProvider]) so the user can immediately see
/// where it is + its details panel.
///
/// <p>Hidden when there are no active emergency squawks — it's not a
/// permanent UI element, just a transient alert strip.
class SquawkAlertBanner extends ConsumerStatefulWidget {
  const SquawkAlertBanner({super.key});

  @override
  ConsumerState<SquawkAlertBanner> createState() => _SquawkAlertBannerState();
}

class _SquawkAlertBannerState extends ConsumerState<SquawkAlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    // Defer `.repeat()` to the next frame so we don't trip the
    // `elapsedInSeconds >= 0.0` assertion under flutter_test's FakeAsync
    // clock (same root cause as `_PulsingDot` / `RadarOverlay`).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(squawkAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();
    final s = S.of(ref.watch(languageProvider));

    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.of(context).padding.top + 56,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 12,
        borderColor: AppColors.error.withValues(alpha: 0.45),
        child: Row(
          children: [
            // Pulsing warning icon — uses an animation controller so the
            // pulse runs at a consistent ~1 Hz regardless of the
            // surrounding rebuild cadence.
            FadeTransition(
              opacity: Tween<double>(begin: 0.55, end: 1.0).animate(_pulse),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.squawkEmergencyTitle.toUpperCase(),
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final ac in alerts)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _SquawkPill(
                          callsign: ac.callsign?.trim().isNotEmpty == true
                              ? ac.callsign!
                              : ac.icao24.toUpperCase(),
                          squawk: ac.squawk!,
                          onTap: () => ref
                              .read(selectedAircraftProvider.notifier)
                              .set(ac),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquawkPill extends StatelessWidget {
  const _SquawkPill({
    required this.callsign,
    required this.squawk,
    required this.onTap,
  });

  final String callsign;
  final String squawk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = squawkColor(squawk);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              callsign,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              squawkLabel(squawk),
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
