import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/responsive.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_style_picker.dart';
import 'package:airwatch_mobile/features/notifications/presentation/widgets/alert_bell.dart';
import 'package:airwatch_mobile/features/voice/presentation/voice_button.dart';

class MapControls extends ConsumerWidget {
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onToggleSearch;

  const MapControls({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
    required this.onMyLocation,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final right = Responsive.mapControlsRight(context);
    final currentStyle = ref.watch(mapStyleProvider);

    return Positioned(
      right: right,
      top: MediaQuery.of(context).padding.top + 80,
      child: Column(
        children: [
          _ControlButton(
            icon: Icons.search_rounded,
            onTap: onToggleSearch,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _ControlButton(
            icon: Icons.add_rounded,
            onTap: onZoomIn,
            isDark: isDark,
          ),
          const SizedBox(height: 4),
          _ControlButton(
            icon: Icons.remove_rounded,
            onTap: onZoomOut,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _ControlButton(
            icon: Icons.my_location_rounded,
            onTap: onMyLocation,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          // Basemap-style switcher. Web's MapStylePicker port: one tap opens
          // a popover listing every available style, one more selects it.
          // Replaces the older cycle-on-tap pattern. State lives in
          // mapStyleProvider so the choice survives screen rebuilds.
          MapStylePicker(
            current: currentStyle,
            onChanged: (next) =>
                ref.read(mapStyleProvider.notifier).set(next),
          ),
          const SizedBox(height: 8),
          // Alert bell — opens the central alerts panel (squawk +
          // geofence intrusions). Mirrors the web frontend's
          // top-right `AlertBell` from the layout.
          const AlertBell(),
          const SizedBox(height: 8),
          // Voice command button — mirrors the web frontend's
          // VoiceButton. Speech recognition runs natively via
          // `speech_to_text`; the parser is the same regex set used
          // on the web.
          const VoiceButton(),
          const SizedBox(height: 12),
          _AltitudeFilterChips(isDark: isDark),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: GlassPanel(
        padding: const EdgeInsets.all(10),
        borderRadius: 12,
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.primary : UiConstants.lightPrimary,
        ),
      ),
      ),
    );
  }
}

class _AltitudeFilterChips extends ConsumerWidget {
  final bool isDark;

  const _AltitudeFilterChips({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(altitudeFilterProvider);
    final primaryColor = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return GlassPanel(
      padding: const EdgeInsets.all(8),
      borderRadius: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip(context, ref, 'ALL', AltitudeFilter.all, current, primaryColor),
          const SizedBox(height: 3),
          _buildChip(context, ref, 'LOW', AltitudeFilter.low, current, AppColors.altitudeLow),
          const SizedBox(height: 3),
          _buildChip(context, ref, 'MED', AltitudeFilter.medium, current, AppColors.altitudeMedium),
          const SizedBox(height: 3),
          _buildChip(context, ref, 'HI', AltitudeFilter.high, current, AppColors.altitudeHigh),
          const SizedBox(height: 3),
          _buildChip(context, ref, 'GND', AltitudeFilter.ground, current, UiConstants.lightTextSecondary),
          const SizedBox(height: 6),
          // Category filters
          _CatFilter(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    AltitudeFilter filter,
    AltitudeFilter current,
    Color color,
  ) {
    final isActive = current == filter;

    return GestureDetector(
      onTap: () => ref.read(altitudeFilterProvider.notifier).set(filter),
      child: Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: isActive ? color : color.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CatFilter extends ConsumerWidget {
  final bool isDark;
  const _CatFilter({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(categoryFilterProvider);
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    Widget chip(CategoryFilter filter, IconData icon) {
      final active = current == filter;
      return GestureDetector(
        onTap: () => ref.read(categoryFilterProvider.notifier).set(
            active ? CategoryFilter.all : filter),
        child: Container(
          width: 36,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: active ? primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: active ? Border.all(color: primary.withValues(alpha: 0.4)) : null,
          ),
          child: Icon(icon, size: 14,
              color: active ? primary : primary.withValues(alpha: 0.4)),
        ),
      );
    }

    // Cargo-only callsign-prefix filter — orthogonal to the
    // category dropdown above. Same provider the voice command toggles,
    // so flipping the chip and saying "cargo" stay in sync.
    final cargoOnly = ref.watch(showCargoOnlyProvider);
    Widget cargoOnlyChip() {
      return GestureDetector(
        onTap: () => ref.read(showCargoOnlyProvider.notifier).toggle(),
        child: Container(
          width: 36,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: cargoOnly
                ? AppColors.warning.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: cargoOnly
                ? Border.all(color: AppColors.warning.withValues(alpha: 0.5))
                : null,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: cargoOnly
                ? AppColors.warning
                : primary.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      chip(CategoryFilter.jets, Icons.flight_rounded),
      const SizedBox(height: 3),
      chip(CategoryFilter.helicopters, Icons.air_rounded),
      const SizedBox(height: 3),
      chip(CategoryFilter.cargo, Icons.local_shipping_rounded),
      const SizedBox(height: 3),
      chip(CategoryFilter.light, Icons.paragliding_rounded),
      const SizedBox(height: 3),
      cargoOnlyChip(),
    ]);
  }
}
