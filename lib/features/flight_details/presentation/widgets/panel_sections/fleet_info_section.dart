import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/flight_details/data/services/fleet_info_service.dart';

/// Fleet info card on the flight detail panel — registry data merged
/// with AirWatch's own first/last-seen sighting history.
///
/// Mirrors airwatch-web's commit f8fff87. The base aircraft section
/// already shows manufacturer / type / registration, but doesn't
/// answer "how old is this airframe?" or "how often have we seen it?".
/// This tile sits beneath that section and surfaces both.
///
/// <h3>Render strategy</h3>
/// Same as the web frontend — silent unless we have something useful
/// to show. The service returns null on a total miss; on a partial
/// (registry-only or sightings-only) we hide the empty subsection
/// rather than render a "Unknown" placeholder.
class FleetInfoSection extends StatefulWidget {
  /// ICAO 24-bit hex of the aircraft. When null/wrong-length the
  /// section doesn't render — no fetch.
  final String? icao24;

  final bool isDark;
  final Color primary;

  const FleetInfoSection({
    super.key,
    required this.icao24,
    required this.isDark,
    required this.primary,
  });

  @override
  State<FleetInfoSection> createState() => _FleetInfoSectionState();
}

class _FleetInfoSectionState extends State<FleetInfoSection> {
  final FleetInfoService _service = FleetInfoService();

  bool _loading = true;
  FleetInfo? _info;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant FleetInfoSection old) {
    super.didUpdateWidget(old);
    if (old.icao24 != widget.icao24) {
      setState(() {
        _loading = true;
        _info = null;
      });
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    final hex = widget.icao24;
    if (hex == null || hex.length != 6) {
      setState(() => _loading = false);
      return;
    }
    final result = await _service.load(hex);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _info = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading + miss → render nothing. The base aircraft section above
    // already filled the "primary metadata" slot; we don't want a
    // layout pop above the prediction card on every panel open.
    if (_loading || _info == null) return const SizedBox.shrink();

    final s = context.s;
    final muted = widget.isDark
        ? AppColors.textMuted
        : UiConstants.lightTextMuted;
    final body = widget.isDark
        ? AppColors.textPrimary
        : UiConstants.lightTextPrimary;

    final registry = _info!.registry;
    final sightings = _info!.sightings;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isDark
                ? AppColors.glassBorder
                : UiConstants.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: widget.primary),
              const SizedBox(width: 6),
              Text(
                s.fleetInfoTitle,
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (registry != null) _registryRow(registry, body, muted, s),
          if (registry != null && sightings != null)
            const SizedBox(height: 4),
          if (sightings != null) _sightingsRow(sightings, body, muted, s),
        ],
      ),
    );
  }

  Widget _registryRow(
    FleetRegistry r,
    Color body,
    Color muted,
    AppStrings s,
  ) {
    final parts = <String>[];
    if (r.manufacturer != null) parts.add(r.manufacturer!);
    if (r.type != null) parts.add(r.type!);
    if (r.builtYear != null) {
      final age = DateTime.now().year - r.builtYear!;
      // Sanity: registry year passed parsing, so age ≥ 0.
      parts.add(s.fleetAge.replaceFirst('{0}', '$age').replaceFirst('{1}', '${r.builtYear}'));
    }
    if (r.owner != null) parts.add(r.owner!);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 11,
        color: body,
      ),
    );
  }

  Widget _sightingsRow(
    FleetSightings s,
    Color body,
    Color muted,
    AppStrings strings,
  ) {
    final fmt = NumberFormat.decimalPattern();
    final parts = <String>[];
    if (s.count > 0) {
      parts.add(strings.fleetSightings.replaceFirst('{0}', fmt.format(s.count)));
    }
    final firstSeen =
        _formatRelative(s.firstSeenAt, strings.fleetFirstSeen, strings);
    if (firstSeen != null) parts.add(firstSeen);
    final lastSeen =
        _formatRelative(s.lastSeenAt, strings.fleetLastSeen, strings);
    if (lastSeen != null) parts.add(lastSeen);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontFamily: UiConstants.bodyFont,
        fontSize: 10,
        color: muted,
      ),
    );
  }

  /// Cheap relative-time formatter — picks a granularity based on age,
  /// returns a localized "X minutes ago" / "X days ago" / "just now"
  /// string and substitutes it into the caller's template (e.g.
  /// "first seen {0}"). Returns null when the timestamp is missing.
  String? _formatRelative(DateTime? ts, String template, AppStrings strings) {
    if (ts == null) return null;
    final now = DateTime.now();
    final diff = now.difference(ts);
    String label;
    if (diff.inMinutes.abs() < 60) {
      label = diff.inMinutes <= 1
          ? strings.relTimeNow
          : strings.relTimeMinutes.replaceFirst('{0}', '${diff.inMinutes}');
    } else if (diff.inHours.abs() < 24) {
      label = strings.relTimeHours.replaceFirst('{0}', '${diff.inHours}');
    } else if (diff.inDays.abs() < 30) {
      label = strings.relTimeDays.replaceFirst('{0}', '${diff.inDays}');
    } else if (diff.inDays.abs() < 365) {
      label = strings.relTimeMonths
          .replaceFirst('{0}', '${(diff.inDays / 30).round()}');
    } else {
      label = strings.relTimeYears
          .replaceFirst('{0}', '${(diff.inDays / 365).round()}');
    }
    return template.replaceFirst('{0}', label);
  }
}
