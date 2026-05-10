import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/airport/data/services/aviation_weather_service.dart';

/// NOTAM (Notice to Airmen) panel for the airport detail screen.
///
/// Mirrors the web frontend's `NotamPanel.tsx` (commit 8fef4f3).
/// NOTAMs are issued by aviation authorities about anything affecting
/// flight ops — runway closures, navaid outages, obstacles, restricted
/// airspace. Each carries an issued/expires window, an ID, and an
/// optional Q-code classification.
///
/// We render up to 10 most-recent rows; each opens to the full text
/// on tap. The empty / unavailable / loading states all surface the
/// header so the operator knows the panel loaded.
class NotamPanel extends StatefulWidget {
  /// ICAO code (4 letters). When null/empty the panel doesn't render.
  final String? icao;

  /// Optional service override — production callers don't pass this;
  /// widget tests inject a fake to drive the loading / unavailable /
  /// empty / populated states without hitting the real api.
  final AviationWeatherService? service;

  const NotamPanel({super.key, required this.icao, this.service});

  @override
  State<NotamPanel> createState() => _NotamPanelState();
}

class _NotamPanelState extends State<NotamPanel> {
  late final AviationWeatherService _service =
      widget.service ?? AviationWeatherService();

  bool _loading = true;
  NotamResult? _result;
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    final icao = widget.icao;
    if (icao != null && icao.length == 4) _load(icao);
  }

  @override
  void didUpdateWidget(covariant NotamPanel old) {
    super.didUpdateWidget(old);
    if (old.icao != widget.icao &&
        widget.icao != null &&
        widget.icao!.length == 4) {
      setState(() {
        _loading = true;
        _result = null;
        _expanded.clear();
      });
      _load(widget.icao!);
    }
  }

  Future<void> _load(String icao) async {
    final result = await _service.loadNotams(icao);
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
    final s = context.s;
    final result = _result;
    final items = result?.items ?? const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — title + ICAO + count badge.
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  s.notamsTitle,
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
                if (items.isNotEmpty)
                  Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBody(isDark, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, AppStrings s) {
    if (_loading) {
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
            '${s.loadingShort}…',
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 11,
              color: isDark
                  ? AppColors.textMuted
                  : UiConstants.lightTextMuted,
            ),
          ),
        ],
      );
    }

    final result = _result;
    if (result == null ||
        result.upstreamUnavailable ||
        result.networkError) {
      return Text(
        s.notamsUnavailable,
        style: TextStyle(
          fontFamily: UiConstants.bodyFont,
          fontSize: 11,
          color: isDark
              ? AppColors.textMuted
              : UiConstants.lightTextMuted,
        ),
      );
    }

    if (result.isEmpty) {
      return Text(
        s.notamsNone,
        style: TextStyle(
          fontFamily: UiConstants.bodyFont,
          fontSize: 11,
          color: isDark
              ? AppColors.textMuted
              : UiConstants.lightTextMuted,
        ),
      );
    }

    final visible = result.items.take(10).toList(growable: false);
    final extra = result.items.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visible.map((n) => _NotamRow(
              item: n,
              expanded: _expanded.contains(n.id),
              isDark: isDark,
              onToggle: () => setState(() {
                if (!_expanded.add(n.id)) _expanded.remove(n.id);
              }),
            )),
        if (extra > 0) ...[
          const SizedBox(height: 4),
          Text(
            s.notamsMore.replaceFirst('{0}', '$extra'),
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 10,
              color: isDark
                  ? AppColors.textMuted
                  : UiConstants.lightTextMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _NotamRow extends StatelessWidget {
  final NotamRecord item;
  final bool expanded;
  final bool isDark;
  final VoidCallback onToggle;

  const _NotamRow({
    required this.item,
    required this.expanded,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark
        ? AppColors.textMuted
        : UiConstants.lightTextMuted;
    final body = isDark
        ? AppColors.textSecondary
        : UiConstants.lightTextSecondary;
    final preview = !expanded && item.text.length > 200
        ? '${item.text.substring(0, 200)}…'
        : item.text;
    final canExpand = item.text.length > 200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: canExpand ? onToggle : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsetsDirectional.only(start: 8),
          // Vertical accent bar on the leading edge — flips with the
          // panel for RTL via BorderDirectional.
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: AppColors.warning.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item.id,
                    style: const TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                  if (item.classification != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        item.classification!,
                        style: const TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  if (item.start != null)
                    Text(
                      _trimDate(item.start!),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: muted,
                      ),
                    ),
                  if (item.end != null && item.end != item.start)
                    Text(
                      '→ ${_trimDate(item.end!)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                preview,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact display of the upstream timestamp. Strips the ISO `T` and
  /// trims to 16 chars (`yyyy-MM-dd HH:mm`) when long enough; otherwise
  /// returns the source verbatim — some providers ship `DDhhmm` strings
  /// which we don't want to mangle.
  String _trimDate(String d) {
    final cleaned = d.replaceFirst('T', ' ');
    return cleaned.length >= 16 ? cleaned.substring(0, 16) : cleaned;
  }
}
