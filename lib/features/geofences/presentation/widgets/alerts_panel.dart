import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/geofences/domain/alert_format.dart';
import 'package:airwatch_mobile/features/geofences/presentation/providers/geofence_alerts_provider.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

/// Live alerts panel — every aircraft currently inside an active
/// geofence. Mirrors airwatch-web's `AlertsPanel.tsx` (commit 01d0841):
/// per-fence filter chips, airline-name resolution, relative-time
/// captions, deep-link to map.
///
/// <p>Mobile's alerts feed is the live `geofenceAlertsProvider` — pure
/// derived state, no separate history store. So `Dismiss` is a
/// transient local-suppression set (cleared on tab switch or fence
/// change), and `Clear All` clears just that set.
class AlertsPanel extends ConsumerStatefulWidget {
  const AlertsPanel({super.key});

  @override
  ConsumerState<AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends ConsumerState<AlertsPanel> {
  /// Fence ids currently selected for the filter chips. `null` = ALL.
  Set<String>? _selectedFences;

  /// Transient "I've seen this" suppression — keyed `${fenceId}:${icao24}`.
  /// Cleared when the user reopens the screen (state lives on this State).
  final Set<String> _dismissed = <String>{};

  String _key(GeoFenceHit h) => '${h.fence.id}:${h.aircraft.icao24}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));
    final allHits = ref.watch(geofenceAlertsProvider);
    final hits = allHits.where((h) => !_dismissed.contains(_key(h))).toList();
    if (hits.isEmpty) return const SizedBox.shrink();

    // Per-fence aggregate for the filter bar.
    final fenceCounts = <String, _FenceCount>{};
    for (final h in hits) {
      final entry = fenceCounts[h.fence.id];
      if (entry != null) {
        entry.count++;
      } else {
        fenceCounts[h.fence.id] = _FenceCount(h.fence.id, h.fence.name, 1);
      }
    }
    final fenceList = fenceCounts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Drop stale ids from the selection so the UI doesn't get stuck
    // filtering against a fence that no longer has any active hits.
    if (_selectedFences != null) {
      final liveIds = fenceList.map((f) => f.id).toSet();
      final pruned = _selectedFences!.where(liveIds.contains).toSet();
      if (pruned.length != _selectedFences!.length) {
        // Schedule the prune for after this build to avoid a setState
        // during build. The build still proceeds with the stale set —
        // next frame will re-render with the pruned one.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedFences = pruned.isEmpty ? null : pruned;
            });
          }
        });
      }
    }

    final filtered = _selectedFences == null
        ? hits
        : hits.where((h) => _selectedFences!.contains(h.fence.id)).toList();

    final total = hits.length;
    final shown = filtered.length;
    final word = total == 1 ? s.alertsCountOne : s.alertsCountMany;
    final headerText = shown == total
        ? '$total $word'
        : '$shown / $total $word';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        borderColor: AppColors.warning.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  headerText,
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.warning,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: s.alertsClearAllTooltip,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _dismissed.addAll(hits.map(_key));
                      });
                    },
                    child: Text(
                      s.alertsClearAll,
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (fenceList.length > 1) ...[
              const SizedBox(height: 6),
              _FilterBar(
                fences: fenceList,
                selected: _selectedFences,
                allFilterLabel: s.alertsAllFilter,
                tooltipFmt: s.alertsFilterTooltip,
                onChange: (next) => setState(() => _selectedFences = next),
              ),
              const Divider(height: 12, color: AppColors.glassBorder),
            ] else
              const SizedBox(height: 6),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.alertsEmptyFilter,
                  style: const TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final hit = filtered[i];
                    return _AlertRow(
                      hit: hit,
                      onShowOnMap: () => _focusOnMap(hit),
                      onDismiss: () => setState(() {
                        _dismissed.add(_key(hit));
                      }),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _focusOnMap(GeoFenceHit hit) {
    final pos = hit.aircraft.position;
    if (pos == null) return;
    ref.read(selectedAircraftProvider.notifier).set(hit.aircraft);
    ref
        .read(mapFocusProvider.notifier)
        .focusOn(LatLng(pos.latitude, pos.longitude));
    // Pop back to the root (AppShell, which holds the map at index 0).
    // The map screen consumes `mapFocusProvider` via a `ref.listen` and
    // pans + selects on next build. Mirrors the web's `?icao24=…` deep
    // link — same intent ("jump to this flight"), expressed natively.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class _FenceCount {
  final String id;
  final String name;
  int count;
  _FenceCount(this.id, this.name, this.count);
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.fences,
    required this.selected,
    required this.allFilterLabel,
    required this.tooltipFmt,
    required this.onChange,
  });
  final List<_FenceCount> fences;
  final Set<String>? selected;
  final String allFilterLabel;
  final String tooltipFmt;
  final ValueChanged<Set<String>?> onChange;

  @override
  Widget build(BuildContext context) {
    final allActive = selected == null;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(
          Icons.filter_alt_outlined,
          size: 12,
          color: AppColors.textMuted,
        ),
        _FilterChip(
          label: allFilterLabel,
          active: allActive,
          onTap: () => onChange(null),
        ),
        for (final fc in fences)
          Tooltip(
            message: tooltipFmt.replaceAll('{0}', fc.name),
            child: _FilterChip(
              label: '${fc.name} (${fc.count})',
              active: selected?.contains(fc.id) ?? false,
              onTap: () {
                final next = Set<String>.from(selected ?? const <String>{});
                if (next.contains(fc.id)) {
                  next.remove(fc.id);
                } else {
                  next.add(fc.id);
                }
                onChange(next.isEmpty ? null : next);
              },
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.info : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppColors.info.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? AppColors.info.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.hit,
    required this.onShowOnMap,
    required this.onDismiss,
  });
  final GeoFenceHit hit;
  final VoidCallback onShowOnMap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ac = hit.aircraft;
    final airline = resolveAirlineName(ac.callsign);
    final callsign = (ac.callsign ?? '').trim().isEmpty
        ? ac.icao24
        : ac.callsign!.trim();
    final altText = formatAltitude(ac.baroAltitude);
    final speedKmh = ac.velocity == null ? null : (ac.velocity! * 3.6).round();

    return Tooltip(
      message: s.alertsShowOnMap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onShowOnMap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: AppColors.warning, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            callsign,
                            style: const TextStyle(
                              fontFamily: UiConstants.headingFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 10,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '→ ${hit.fence.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: UiConstants.bodyFont,
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          if (airline != null) _Sub(airline),
                          _Sub(altText),
                          if (speedKmh != null && speedKmh > 0)
                            _Sub('$speedKmh km/h'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: s.alertsDismissTooltip,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
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

class _Sub extends StatelessWidget {
  const _Sub(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 10,
        color: AppColors.textMuted,
      ),
    );
  }
}
