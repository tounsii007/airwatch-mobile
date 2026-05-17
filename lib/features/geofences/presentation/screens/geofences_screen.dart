import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/airline_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/aw_page_scaffold.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';
import 'package:airwatch_mobile/features/geofences/presentation/screens/fence_form_screen.dart';
import 'package:airwatch_mobile/features/geofences/presentation/screens/geofence_draw_screen.dart';
import 'package:airwatch_mobile/features/geofences/presentation/widgets/alerts_panel.dart';
import 'package:airwatch_mobile/features/geofences/presentation/widgets/fence_io_toolbar.dart';
import 'package:airwatch_mobile/features/geofences/presentation/widgets/fence_stats_badge.dart';

/// List + create + delete + toggle for the user's geofences.
///
/// <p>Mirrors the web frontend's `/geofences` page (FencesList +
/// FenceForm + AlertsPanel + FenceIOToolbar). Mobile combines list +
/// add into a single scrollable screen with an FAB; the form gets
/// pushed as a separate route to keep the UI uncluttered on phones.
///
/// <p>Sections (top → bottom):
/// <ol>
///   <li>{@link AlertsPanel} — live intrusions, per-fence filter chips,
///       deep-link to map on tap. Hidden when no aircraft are inside
///       an active fence right now.</li>
///   <li>{@link FenceIOToolbar} — export / import buttons + status line.</li>
///   <li>List of {@link _FenceTile} — each with shape caption, filter
///       chips (airline / min / max alt), and a {@link FenceStatsBadge}
///       under the chips showing per-fence live rollups.</li>
/// </ol>
class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.s;
    final fences = ref.watch(geofencesProvider);

    return AwPageScaffold(
      title: s.geofences,
      // Show the active-fence count as a small badge under the title —
      // mirrors web's `<Subtitle>{n} active</Subtitle>` on /geofences.
      subtitle: fences.isNotEmpty
          ? AwPageBadge(
              label: '${fences.length} ACTIVE',
              color: AppColors.success,
            )
          : null,
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
                builder: (_) => const GeoFenceDrawScreen(),
              ),
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
      child: CustomScrollView(
          slivers: [
            // Live alerts — auto-hidden when no aircraft is inside an
            // active fence right now. Sits above the list so a new
            // intrusion is immediately visible.
            const SliverToBoxAdapter(child: AlertsPanel()),

            // Section header with total count + IO toolbar.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      s.fenceActiveHeading,
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    if (fences.isNotEmpty)
                      Text(
                        s.fenceTotalCount.replaceAll('{0}', '${fences.length}'),
                        style: const TextStyle(
                          fontFamily: UiConstants.bodyFont,
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Export / import toolbar — always visible so users discover
            // the JSON round-trip even with no fences (the empty-export
            // path renders an informative status message).
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: FenceIOToolbar(fences: fences),
              ),
            ),

            if (fences.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(isDark: isDark),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                sliver: SliverList.separated(
                  itemCount: fences.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _FenceTile(
                    fence: fences[i],
                    isDark: isDark,
                    onToggle: () => ref
                        .read(geofencesProvider.notifier)
                        .toggleActive(fences[i].id),
                    onRemove: () => ref
                        .read(geofencesProvider.notifier)
                        .remove(fences[i].id),
                  ),
                ),
              ),
          ],
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

  /// Format the geometry as a one-liner human can read at a glance.
  /// Mirrors the web's `shapeCaption` (FencesList.tsx) so users moving
  /// between the two see the same readout for the same fence.
  String _shapeCaption(BuildContext context) {
    final s = context.s;
    if (fence.type == GeoFenceType.circle) {
      return s.fenceShapeCircle
          .replaceAll(
            '{0}',
            (fence.centerLat ?? 0).toStringAsFixed(2),
          )
          .replaceAll(
            '{1}',
            (fence.centerLon ?? 0).toStringAsFixed(2),
          )
          .replaceAll(
            '{2}',
            (fence.radiusKm ?? 0).toStringAsFixed(1),
          );
    }
    return s.fenceShapeRect
        .replaceAll('{0}', (fence.southLat ?? 0).toStringAsFixed(1))
        .replaceAll('{1}', (fence.northLat ?? 0).toStringAsFixed(1))
        .replaceAll('{2}', (fence.westLon ?? 0).toStringAsFixed(1))
        .replaceAll('{3}', (fence.eastLon ?? 0).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final accent = fence.active ? AppColors.success : AppColors.textMuted;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      borderColor: accent.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _shapeCaption(context),
                            style: const TextStyle(
                              fontFamily: UiConstants.bodyFont,
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    _FilterChips(fence: fence),
                    FenceStatsBadge(fenceId: fence.id),
                  ],
                ),
              ),
              Column(
                children: [
                  // Toggle switch (active / paused).
                  Switch.adaptive(
                    value: fence.active,
                    activeThumbColor: AppColors.success,
                    onChanged: (_) => onToggle(),
                  ),
                  // Delete.
                  IconButton(
                    tooltip: s.fenceDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    onPressed: onRemove,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Coloured filter chips for the fence row — airline / min-alt /
/// max-alt. Mirrors web's `FilterChips` (FencesList.tsx commit e22ca75).
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.fence});
  final GeoFence fence;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chips = <Widget>[];
    final airlineCode = fence.airlineFilter?.trim();

    if (airlineCode != null && airlineCode.isNotEmpty) {
      final info = resolveAirline(airlineCode);
      final tooltip = info == null
          ? s.fenceAirlineTooltipNoName.replaceAll('{0}', airlineCode)
          : s.fenceAirlineTooltip
                .replaceAll('{0}', info.name)
                .replaceAll('{1}', airlineCode);
      chips.add(
        _Chip(
          icon: Icons.flight_rounded,
          label: airlineCode.toUpperCase(),
          tone: _ChipTone.info,
          tooltip: tooltip,
        ),
      );
    }
    if (fence.minAltitudeFt != null) {
      chips.add(
        _Chip(
          icon: Icons.arrow_upward_rounded,
          label: '≥${fence.minAltitudeFt!.toStringAsFixed(0)} ft',
          tone: _ChipTone.muted,
          tooltip: s.fenceMinAltTooltip,
        ),
      );
    }
    if (fence.maxAltitudeFt != null) {
      chips.add(
        _Chip(
          icon: Icons.arrow_downward_rounded,
          label: '≤${fence.maxAltitudeFt!.toStringAsFixed(0)} ft',
          tone: _ChipTone.warn,
          tooltip: s.fenceMaxAltTooltip,
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4),
      child: Wrap(spacing: 4, runSpacing: 4, children: chips),
    );
  }
}

enum _ChipTone { info, muted, warn }

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.tone,
    required this.tooltip,
  });
  final IconData icon;
  final String label;
  final _ChipTone tone;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _ChipTone.info => AppColors.info,
      _ChipTone.warn => AppColors.warning,
      _ChipTone.muted => AppColors.textMuted,
    };
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fence_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              s.fencesListEmpty,
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
