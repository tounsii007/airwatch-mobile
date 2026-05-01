import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import 'package:airwatch_mobile/core/constants/airport_full_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/co2_estimator.dart';
import 'package:airwatch_mobile/core/utils/share_utils.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// CO₂ + Share footer at the bottom of the flight-details panel.
///
/// <p>Mirrors the web frontend's `Co2Footer.tsx`. Two halves:
/// <ul>
///   <li><b>CO₂ estimate</b> — kg-CO₂ for the dep→arr great circle, plus
///       distance in km. Hidden when we don't have both airport IATAs
///       (live-only flights with no Airlabs route data).</li>
///   <li><b>Share button</b> — fires the native share sheet via
///       `share_plus`; on platforms without one (desktop / linux without
///       a share daemon), falls back to copying flight info to the
///       clipboard and flashing a "copied" pill for 2 seconds.</li>
/// </ul>
class PanelCo2Footer extends StatefulWidget {
  final AircraftState aircraft;
  final FlightRouteInfo? route;
  final AirlineInfo? airline;
  final AircraftMetadata? metadata;
  final bool isDark;

  const PanelCo2Footer({
    super.key,
    required this.aircraft,
    required this.route,
    required this.airline,
    required this.metadata,
    required this.isDark,
  });

  @override
  State<PanelCo2Footer> createState() => _PanelCo2FooterState();
}

class _PanelCo2FooterState extends State<PanelCo2Footer> {
  bool _copied = false;

  Co2Estimate? _estimate() {
    final dep = widget.route?.departureAirport;
    final arr = widget.route?.arrivalAirport;
    if (dep == null || arr == null || dep.isEmpty || arr.isEmpty) return null;
    final depAirport = lookupAirport(dep);
    final arrAirport = lookupAirport(arr);
    if (depAirport == null || arrAirport == null) return null;

    return estimateCo2(
      departure: LatLng(depAirport.lat, depAirport.lon),
      arrival: LatLng(arrAirport.lat, arrAirport.lon),
      aircraftCategory: widget.aircraft.category,
    );
  }

  Future<void> _onShare() async {
    final cs = widget.aircraft.callsign?.trim() ?? widget.aircraft.icao24;
    final text = ShareUtils.buildFlightShareText(
      callsign: cs,
      airline: widget.airline?.name,
      depIata: widget.route?.departureAirport,
      arrIata: widget.route?.arrivalAirport,
      aircraftType: widget.metadata?.model,
      altitude: widget.aircraft.baroAltitude,
      speed: widget.aircraft.velocity,
    );

    try {
      // share_plus: on iOS / Android this opens the system share sheet.
      // On desktop (Windows, macOS, Linux) it falls back to clipboard.
      final result = await SharePlus.instance.share(ShareParams(text: text));
      if (!mounted) return;
      // Show "copied" feedback whenever the platform reported success but
      // didn't actually surface a sheet — desktop fallback path.
      if (result.status == ShareResultStatus.unavailable) {
        await _fallbackToClipboard(text);
      }
    } catch (_) {
      // Last-resort clipboard copy so the user is never silently denied
      // the action when the share sheet is unavailable.
      await _fallbackToClipboard(text);
    }
  }

  Future<void> _fallbackToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final est = _estimate();
    final hasEstimate = est != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: widget.isDark ? AppColors.glassBorder : UiConstants.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Left: CO₂ estimate (or muted "no data" state) ──
          Expanded(child: _Co2Pill(estimate: est, label: s)),
          const SizedBox(width: 8),
          // ── Right: Share button ──
          _ShareButton(
            copied: _copied,
            onTap: _onShare,
            shareLabel: s.share.toUpperCase(),
            copiedLabel: hasEstimate ? 'COPIED' : 'COPIED',
          ),
        ],
      ),
    );
  }
}

class _Co2Pill extends StatelessWidget {
  const _Co2Pill({required this.estimate, required this.label});
  final Co2Estimate? estimate;
  final AppStrings label;

  @override
  Widget build(BuildContext context) {
    if (estimate == null) {
      return Row(
        children: [
          Icon(Icons.eco_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label.co2EstimateLabel,
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.eco_rounded, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '~${_formatKg(estimate!.co2Kg)} CO₂',
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              Text(
                '${estimate!.distKm} km · ${label.co2PerPaxLabel}',
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Group-of-thousands formatting for the CO₂ value.
  ///
  /// 1234 → "1,234"  · 567  → "567"  ·  150 000 → "150,000"
  String _formatKg(int kg) {
    if (kg < 1000) return '${kg.toString()} kg';
    final str = kg.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return '$buf kg';
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.copied,
    required this.onTap,
    required this.shareLabel,
    required this.copiedLabel,
  });
  final bool copied;
  final VoidCallback onTap;
  final String shareLabel;
  final String copiedLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              copied ? Icons.check_rounded : Icons.share_outlined,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              copied ? copiedLabel : shareLabel,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
