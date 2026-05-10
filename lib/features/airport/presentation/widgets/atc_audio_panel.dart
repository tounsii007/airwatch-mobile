import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/airport/data/services/atc_feeds_service.dart';

/// Live ATC audio panel for the airport detail INFO tab.
///
/// Mirrors airwatch-web's commit c8c53b5 with one mobile-specific
/// trade-off: instead of an inline `<audio>` element, every feed
/// row taps out to LiveATC.net via `url_launcher`. We deliberately
/// don't ship an in-app audio player — it would pull in `just_audio`
/// + per-platform background-audio entitlements (iOS Info.plist
/// background-mode, Android foreground service) and that's a
/// non-trivial dep and review surface for what the system browser
/// already does correctly. The UX is one extra tap; the user gets
/// the full LiveATC web player with chat + spectrogram + comments.
///
/// <h3>Render contract</h3>
/// Same as the web panel:
///   * icao=null → renders nothing.
///   * loading → small "Loading…" line.
///   * fetch error / empty catalog → "no feeds catalogued" line plus a
///     deeplink "Search on LiveATC.net?icao=…" so the user always has
///     somewhere to go.
///   * feeds present → chip picker; tapping a chip launches the
///     LiveATC web player for that feed.
class AtcAudioPanel extends StatefulWidget {
  /// 4-letter ICAO. Empty/wrong-length → no render, no fetch.
  final String? icao;

  /// Optional service override — production callers don't pass this;
  /// widget tests inject a fake to exercise the loading / fallback /
  /// chips render paths without hitting LiveATC's real API.
  final AtcFeedsService? service;

  const AtcAudioPanel({super.key, required this.icao, this.service});

  @override
  State<AtcAudioPanel> createState() => _AtcAudioPanelState();
}

class _AtcAudioPanelState extends State<AtcAudioPanel> {
  late final AtcFeedsService _service = widget.service ?? AtcFeedsService();

  bool _loading = true;
  AtcFeedsResult? _result;

  @override
  void initState() {
    super.initState();
    final icao = widget.icao;
    if (icao != null && icao.length == 4) _load(icao);
  }

  @override
  void didUpdateWidget(covariant AtcAudioPanel old) {
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

  Future<void> _load(String icao) async {
    final result = await _service.load(icao);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // Use external mode so the system browser handles audio
    // playback — the platform-default Chrome/Safari has the right
    // codec support for LiveATC's streaming MP3 format.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final icao = widget.icao;
    if (icao == null || icao.length != 4) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header.
            Row(
              children: [
                const Icon(
                  Icons.headset_mic_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  s.atcLiveTitle,
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
              ],
            ),
            const SizedBox(height: 8),
            _buildBody(context, isDark, icao, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    String icao,
    AppStrings s,
  ) {
    if (_loading) {
      return Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: isDark
                  ? AppColors.textMuted
                  : UiConstants.lightTextMuted,
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
    if (result == null || result.isEmpty) {
      // Fallback: deep-link to LiveATC's web search even when our
      // catalog has nothing. The user always has somewhere to go.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.atcUnavailable,
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: 11,
              color: isDark
                  ? AppColors.textMuted
                  : UiConstants.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _launch(
              'https://www.liveatc.net/search/?icao=$icao',
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  s.atcSearchFallback,
                  style: const TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: result.feeds
              .map((f) => _FeedChip(
                    feed: f,
                    onTap: () =>
                        _launch(f.externalUrl.isNotEmpty ? f.externalUrl : f.streamUrl),
                  ))
              .toList(growable: false),
        ),
        const SizedBox(height: 6),
        Text(
          result.attribution.isEmpty ? s.atcAttribution : result.attribution,
          style: TextStyle(
            fontFamily: UiConstants.bodyFont,
            fontSize: 9,
            fontStyle: FontStyle.italic,
            color: isDark
                ? AppColors.textMuted
                : UiConstants.lightTextMuted,
          ),
        ),
      ],
    );
  }
}

class _FeedChip extends StatelessWidget {
  final AtcFeed feed;
  final VoidCallback onTap;

  const _FeedChip({required this.feed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Text(
              feed.label.isNotEmpty ? feed.label : feed.mount,
              style: const TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
