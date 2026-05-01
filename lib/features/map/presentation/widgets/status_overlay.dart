import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

class StatusOverlay extends ConsumerWidget {
  const StatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(aircraftCountProvider);
    final filter = ref.watch(altitudeFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderRadius: 14,
            blur: 16,
            opacity: isDark ? 0.3 : 0.85,
            child: Row(
              children: [
                NeonText(text: 'AIRWATCH', fontSize: 13, color: primary,
                    glowRadius: isDark ? 10 : 0),
                const SizedBox(width: 10),
                _PulsingDot(color: AppColors.success),
                const SizedBox(width: 5),
                Text(context.tr('live'), style: TextStyle(
                  fontFamily: UiConstants.headingFont, fontSize: 9, fontWeight: FontWeight.w700,
                  color: AppColors.success, letterSpacing: 1,
                  shadows: isDark ? [Shadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 6)] : null,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.flight_rounded, size: 12, color: primary),
                    const SizedBox(width: 4),
                    Text('$count', style: TextStyle(
                      fontFamily: UiConstants.headingFont, fontSize: 12, fontWeight: FontWeight.w700,
                      color: primary,
                      shadows: isDark ? [Shadow(color: primary.withValues(alpha: 0.4), blurRadius: 4)] : null,
                    )),
                  ]),
                ),
                if (filter != AltitudeFilter.all) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _fColor(filter).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _fColor(filter).withValues(alpha: 0.3)),
                    ),
                    child: Text(_fLabel(filter), style: TextStyle(
                      fontFamily: UiConstants.headingFont, fontSize: 7, fontWeight: FontWeight.w700,
                      color: _fColor(filter),
                    )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _fColor(AltitudeFilter f) => switch (f) {
        AltitudeFilter.low => AppColors.altitudeLow,
        AltitudeFilter.medium => AppColors.altitudeMedium,
        AltitudeFilter.high => AppColors.altitudeHigh,
        AltitudeFilter.ground => Color(UiConstants.lightTextSecondary.toARGB32()),
        AltitudeFilter.all => AppColors.primary,
      };

  String _fLabel(AltitudeFilter f) => switch (f) {
        AltitudeFilter.low => '< 10K',
        AltitudeFilter.medium => '10-30K',
        AltitudeFilter.high => '> 30K',
        AltitudeFilter.ground => 'GND',
        AltitudeFilter.all => 'ALL',
      };
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    // Defer `.repeat()` to the next frame. Calling it synchronously inside
    // `initState` triggers an `elapsedInSeconds >= 0.0` assertion under
    // `flutter_test`'s FakeAsync clock — the controller records its start
    // time before the test's clock is moved into the right window, so the
    // first tick can compute a negative elapsed. Scheduling the start via
    // `addPostFrameCallback` puts the start AFTER the test framework has
    // pumped at least one frame, which sidesteps the issue without changing
    // the visible behaviour at runtime.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.repeat(reverse: true);
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: widget.color,
          boxShadow: [BoxShadow(
            color: widget.color.withValues(alpha: 0.5 * _c.value),
            blurRadius: 8 * _c.value, spreadRadius: 2 * _c.value,
          )],
        ),
      ),
    );
  }
}
