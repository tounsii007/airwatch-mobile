import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/metar_decode.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/airport/data/services/aviation_weather_service.dart';

/// METAR + TAF panel for the airport detail screen.
///
/// Mirrors the web frontend's `MetarPanel.tsx` (commit d29081e). METAR
/// is "right now" (one observation, ≤ 1h old). TAF is "the next 24 h"
/// — a list of forecast windows. Both are rendered as tabs to keep
/// the surface uncluttered, with the active tab persisted in
/// SharedPreferences so an operator who always wants TAF first only
/// flips once.
///
/// Three states across both: loading / unavailable / decoded — none
/// silent. Loading + unavailable both still render the header so the
/// operator knows the section *did* load and isn't broken.
class MetarPanel extends StatefulWidget {
  /// ICAO code (4 letters, e.g. EDDF). When null/empty the panel
  /// doesn't render — the airport entry didn't carry one.
  final String? icao;

  /// Optional service override — production callers don't pass this;
  /// widget tests inject a fake to drive the loading / unavailable /
  /// decoded states without hitting the real api.
  final AviationWeatherService? service;

  const MetarPanel({super.key, required this.icao, this.service});

  @override
  State<MetarPanel> createState() => _MetarPanelState();
}

enum _Tab { metar, taf }

class _MetarPanelState extends State<MetarPanel> {
  static const _prefsKey = 'airwatch.metar.mode';

  late final AviationWeatherService _service =
      widget.service ?? AviationWeatherService();

  bool _loading = true;
  MetarTafResult? _result;
  _Tab _tab = _Tab.metar;
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    _loadStickyTab();
    if (widget.icao != null && widget.icao!.length == 4) {
      _load(widget.icao!);
    }
  }

  @override
  void didUpdateWidget(covariant MetarPanel old) {
    super.didUpdateWidget(old);
    if (old.icao != widget.icao &&
        widget.icao != null &&
        widget.icao!.length == 4) {
      setState(() {
        _loading = true;
        _result = null;
      });
      _load(widget.icao!);
    }
  }

  Future<void> _loadStickyTab() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (!mounted) return;
    if (raw == 'taf') setState(() => _tab = _Tab.taf);
  }

  Future<void> _selectTab(_Tab next) async {
    setState(() => _tab = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next == _Tab.taf ? 'taf' : 'metar');
  }

  Future<void> _load(String icao) async {
    final result = await _service.loadMetarTaf(icao);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final icao = widget.icao;
    if (icao == null || icao.length != 4) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — title + ICAO + tab strip.
            Row(
              children: [
                Icon(Icons.cloud_outlined, size: 14, color: primary),
                const SizedBox(width: 6),
                Text(
                  s.metarTafTitle,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: isDark
                        ? AppColors.textMuted
                        : UiConstants.lightTextMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  icao,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textMuted
                        : UiConstants.lightTextMuted,
                  ),
                ),
                const Spacer(),
                _ModeTab(
                  label: s.metarTab,
                  active: _tab == _Tab.metar,
                  primary: primary,
                  onTap: () => _selectTab(_Tab.metar),
                ),
                const SizedBox(width: 4),
                _ModeTab(
                  label: s.tafTab,
                  active: _tab == _Tab.taf,
                  primary: primary,
                  onTap: () => _selectTab(_Tab.taf),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBody(context, isDark, primary, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color primary,
    AppStrings s,
  ) {
    if (_loading) {
      return _LoadingLine(text: '${s.loadingShort}…', isDark: isDark);
    }
    final result = _result;
    if (result == null || !result.hasAnything) {
      return Text(
        s.metarUnavailable,
        style: TextStyle(
          fontFamily: UiConstants.bodyFont,
          fontSize: 11,
          color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
        ),
      );
    }
    if (_tab == _Tab.metar) {
      final raw = result.metarRaw;
      if (raw == null) {
        return Text(
          s.metarUnavailable,
          style: TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 11,
            color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
          ),
        );
      }
      return _MetarBody(
        decoded: decodeMetar(raw),
        isDark: isDark,
        primary: primary,
        showRaw: _showRaw,
        onToggleRaw: () => setState(() => _showRaw = !_showRaw),
      );
    }
    // TAF tab.
    final raw = result.tafRaw;
    if (raw == null) {
      return Text(
        s.metarUnavailable,
        style: TextStyle(
          fontFamily: UiConstants.bodyFont,
          fontSize: 11,
          color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
        ),
      );
    }
    return _TafBody(
      decoded: decodeTaf(raw),
      isDark: isDark,
      primary: primary,
      showRaw: _showRaw,
      onToggleRaw: () => setState(() => _showRaw = !_showRaw),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  final String text;
  final bool isDark;

  const _LoadingLine({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 11,
            color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
          ),
        ),
      ],
    );
  }
}

class _MetarBody extends StatelessWidget {
  final DecodedMetar decoded;
  final bool isDark;
  final Color primary;
  final bool showRaw;
  final VoidCallback onToggleRaw;

  const _MetarBody({
    required this.decoded,
    required this.isDark,
    required this.primary,
    required this.showRaw,
    required this.onToggleRaw,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final muted = isDark ? AppColors.textMuted : UiConstants.lightTextMuted;
    final body = isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decoded.observed != null)
          Text(
            decoded.observed!,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: muted,
            ),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            if (decoded.wind != null)
              _Field(
                label: s.metarLabelWind,
                value: _windText(decoded.wind!),
                body: body,
                muted: muted,
              ),
            if (decoded.visibility != null)
              _Field(
                label: s.metarLabelVisibility,
                value: _visText(decoded.visibility!),
                body: body,
                muted: muted,
              ),
            if (decoded.temperature.tempC != null)
              _Field(
                label: s.metarLabelTemp,
                value: _tempText(decoded.temperature),
                body: body,
                muted: muted,
              ),
            if (decoded.altimeter.hPa != null || decoded.altimeter.inHg != null)
              _Field(
                label: s.metarLabelAltimeter,
                value: _altText(decoded.altimeter),
                body: body,
                muted: muted,
              ),
            if (decoded.cloudLayers.isNotEmpty)
              _Field(
                label: s.metarLabelClouds,
                value: _cloudText(decoded.cloudLayers),
                body: body,
                muted: muted,
              ),
            if (decoded.phenomena.isNotEmpty)
              _Field(
                label: s.metarLabelWeather,
                value: decoded.phenomena.map(phenomenonText).join(', '),
                body: body,
                muted: muted,
              ),
          ],
        ),
        const SizedBox(height: 6),
        _RawToggle(
          showing: showRaw,
          raw: decoded.raw,
          isDark: isDark,
          onToggle: onToggleRaw,
        ),
      ],
    );
  }

  String _windText(DecodedWind w) {
    if (w.variable && w.speed == 0) return 'CALM';
    final dir = w.variable
        ? 'VRB'
        : '${w.direction!.toString().padLeft(3, '0')}°';
    final gust = w.gust != null ? 'G${w.gust}' : '';
    return '$dir ${w.speed}$gust ${w.unit}';
  }

  String _visText(DecodedVisibility v) {
    return switch (v.unit) {
      VisibilityUnit.cavok => 'CAVOK',
      VisibilityUnit.sm => '${v.value} SM',
      VisibilityUnit.m => '${v.value} m',
    };
  }

  String _tempText(DecodedTemperature t) {
    final temp = t.tempC != null ? '${t.tempC}°' : '—';
    final dew = t.dewC != null ? ' / ${t.dewC}°' : '';
    return '$temp$dew';
  }

  String _altText(DecodedAltimeter a) {
    if (a.hPa != null) return '${a.hPa} hPa';
    if (a.inHg != null) return '${a.inHg!.toStringAsFixed(2)} inHg';
    return '—';
  }

  String _cloudText(List<DecodedCloudLayer> layers) {
    return layers
        .map((l) {
          if (l.cover == 'CAVOK' || l.cover == 'SKC' || l.cover == 'CLR') {
            return l.cover;
          }
          final type = l.type != null ? ' ${l.type}' : '';
          return '${l.cover} ${l.baseFt} ft$type';
        })
        .join(' • ');
  }
}

class _TafBody extends StatelessWidget {
  final DecodedTaf decoded;
  final bool isDark;
  final Color primary;
  final bool showRaw;
  final VoidCallback onToggleRaw;

  const _TafBody({
    required this.decoded,
    required this.isDark,
    required this.primary,
    required this.showRaw,
    required this.onToggleRaw,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final muted = isDark ? AppColors.textMuted : UiConstants.lightTextMuted;
    final body = isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decoded.validFrom != null && decoded.validTo != null)
          Text(
            s.metarTafValidPrefix
                .replaceFirst('{0}', decoded.validFrom!)
                .replaceFirst('{1}', decoded.validTo!),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: muted,
            ),
          ),
        const SizedBox(height: 6),
        ...decoded.windows
            .take(6)
            .map(
              (w) => _TafWindowRow(
                window: w,
                body: body,
                muted: muted,
                primary: primary,
              ),
            ),
        const SizedBox(height: 6),
        _RawToggle(
          showing: showRaw,
          raw: decoded.raw,
          isDark: isDark,
          onToggle: onToggleRaw,
        ),
      ],
    );
  }
}

class _TafWindowRow extends StatelessWidget {
  final DecodedTafWindow window;
  final Color body;
  final Color muted;
  final Color primary;

  const _TafWindowRow({
    required this.window,
    required this.body,
    required this.muted,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final c = window.conditions;
    final summary = <String>[];
    if (c.wind != null) summary.add(_windShort(c.wind!));
    if (c.visibility != null) summary.add(_visShort(c.visibility!));
    if (c.cloudLayers.isNotEmpty) {
      summary.add(
        c.cloudLayers
            .where((l) => l.cover != 'CAVOK')
            .take(2)
            .map((l) => l.baseFt != null ? '${l.cover}${l.baseFt}' : l.cover)
            .join(' '),
      );
    }
    if (c.phenomena.isNotEmpty) {
      summary.add(c.phenomena.take(3).map((p) => p.code).join(','));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              window.label == 'INITIAL' ? context.s.metarTafNow : window.label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          if (window.when != null)
            SizedBox(
              width: 80,
              child: Text(
                window.when!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: muted,
                ),
              ),
            ),
          Expanded(
            child: Text(
              summary.join(' • '),
              style: TextStyle(
                fontFamily: UiConstants.bodyFont,
                fontSize: 10,
                color: body,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _windShort(DecodedWind w) {
    if (w.variable) return 'VRB${w.speed}';
    return '${w.direction!.toString().padLeft(3, '0')}/${w.speed}';
  }

  String _visShort(DecodedVisibility v) => switch (v.unit) {
    VisibilityUnit.cavok => 'CAVOK',
    VisibilityUnit.sm => '${v.value}SM',
    VisibilityUnit.m => '${v.value}m',
  };
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final Color body;
  final Color muted;

  const _Field({
    required this.label,
    required this.value,
    required this.body,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 11,
            color: body,
          ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final Color primary;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? primary.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: active ? primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _RawToggle extends StatelessWidget {
  final bool showing;
  final String raw;
  final bool isDark;
  final VoidCallback onToggle;

  const _RawToggle({
    required this.showing,
    required this.raw,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final muted = isDark ? AppColors.textMuted : UiConstants.lightTextMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showing
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: muted,
              ),
              Text(
                showing ? s.metarHideRaw : s.metarShowRaw,
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        if (showing) ...[
          const SizedBox(height: 4),
          SelectableText(
            raw,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondary
                  : UiConstants.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
