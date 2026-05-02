import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/geofences/presentation/screens/fence_form_screen.dart';
import 'package:airwatch_mobile/features/geofences/presentation/screens/geofence_draw_screen.dart';

/// List + create + delete + toggle for the user's geofences.
///
/// <p>Mirrors the web frontend's `/geofences` page (FencesList +
/// FenceForm + AlertsPanel). Mobile combines list + add into a single
/// scrollable screen with an FAB; the form gets pushed as a separate
/// route to keep the UI uncluttered on phones.
class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.s;
    final fences = ref.watch(geofencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.geofences),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tap-to-draw on a real map — visual primary path. Mirrors
          // the web's `GeoFenceDrawMap` UX.
          FloatingActionButton.extended(
            heroTag: 'fence_draw',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const GeoFenceDrawScreen()),
            ),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.edit_location_alt_rounded),
            label: const Text('DRAW'),
          ),
          const SizedBox(height: 10),
          // Numeric form fallback for users who prefer typing exact
          // lat / lon / radius values.
          FloatingActionButton.small(
            heroTag: 'fence_form',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FenceFormScreen()),
            ),
            backgroundColor: AppColors.surface.withValues(alpha: 0.85),
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: fences.isEmpty
          ? _Empty(isDark: isDark)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: fences.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _FenceTile(
                fence: fences[i],
                isDark: isDark,
                onToggle: () =>
                    ref.read(geofencesProvider.notifier).toggleActive(fences[i].id),
                onRemove: () =>
                    ref.read(geofencesProvider.notifier).remove(fences[i].id),
              ),
            ),
    );
  }
}

class _FenceTile extends StatelessWidget {
  const _FenceTile({
    required this.fence,
    required this.isDark,
    required this.onToggle,
    required this.onRemove,
  });
  final GeoFence fence;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  String _shapeLine() {
    if (fence.type == GeoFenceType.circle) {
      final lat = fence.centerLat?.toStringAsFixed(2);
      final lon = fence.centerLon?.toStringAsFixed(2);
      final r = fence.radiusKm?.toStringAsFixed(0);
      return 'Circle · $r km @ ($lat, $lon)';
    }
    return 'Rect · '
        '(${fence.northLat?.toStringAsFixed(1)}, '
        '${fence.westLon?.toStringAsFixed(1)}) → '
        '(${fence.southLat?.toStringAsFixed(1)}, '
        '${fence.eastLon?.toStringAsFixed(1)})';
  }

  @override
  Widget build(BuildContext context) {
    final accent = fence.active ? AppColors.success : AppColors.textMuted;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      borderColor: accent.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              fence.type == GeoFenceType.circle
                  ? Icons.circle_outlined
                  : Icons.crop_square_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fence.name,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _shapeLine(),
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (fence.airlineFilter != null && fence.airlineFilter!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Airline: ${fence.airlineFilter}',
                      style: TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Toggle switch (active / paused).
          Switch.adaptive(
            value: fence.active,
            activeThumbColor: AppColors.success,
            onChanged: (_) => onToggle(),
          ),
          // Delete.
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fence_rounded,
                size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No geofences yet',
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to draw a circle or rectangle and get an alert when '
              'an aircraft enters it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
