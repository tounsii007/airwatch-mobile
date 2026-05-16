import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/airport/data/services/airport_wiki_service.dart';

/// Inline Wikipedia summary card for the airport detail screen.
///
/// <p>Mirrors airwatch-web's `WikiPanel.tsx` (commit d99d3c2). Backend
/// has a 7-day cache, so the fetch on mount is cheap on repeat views.
///
/// <p>Failure modes degrade silently: on rate-limit / quota / upstream
/// outage / empty payload the panel hides entirely — wiki is
/// decorative, not load-critical. If the operator hasn't shipped the
/// backend proxy endpoint yet, the user just doesn't see anything;
/// the rest of the airport detail screen keeps working.
class WikiPanel extends ConsumerStatefulWidget {
  final String airportIata;
  const WikiPanel({super.key, required this.airportIata});

  @override
  ConsumerState<WikiPanel> createState() => _WikiPanelState();
}

class _WikiPanelState extends ConsumerState<WikiPanel> {
  final _service = AirportWikiService();
  WikiInfo? _wiki;
  bool _loading = true;
  String? _lastIata;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WikiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.airportIata != widget.airportIata) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_lastIata == widget.airportIata) return;
    _lastIata = widget.airportIata;
    setState(() {
      _wiki = null;
      _loading = true;
    });
    final result = await _service.fetchForAirport(widget.airportIata);
    if (!mounted || _lastIata != widget.airportIata) return;
    setState(() {
      _wiki = result;
      _loading = false;
    });
  }

  Future<void> _openWiki() async {
    final url = _wiki?.wikiUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Fail-soft: while loading or on error / empty, render nothing so
    // the rest of the airport detail screen doesn't shift to make
    // room for a card that may never arrive.
    if (_loading || _wiki == null) return const SizedBox.shrink();

    final s = S.of(ref.watch(languageProvider));
    final wiki = _wiki!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wiki.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: wiki.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  // No placeholder + on-error invisible box — wiki
                  // images are decorative, a broken-img icon would be
                  // worse than a missing column.
                  errorWidget: (_, _, _) => const SizedBox(width: 0, height: 0),
                  placeholder: (_, _) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.surface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            if (wiki.imageUrl != null) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.wikiAbout,
                    style: const TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (wiki.summary != null)
                    Text(
                      wiki.summary!,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: UiConstants.bodyFont,
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (wiki.wikiUrl != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openWiki,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          '${s.wikiReadMore} →',
                          style: const TextStyle(
                            fontFamily: UiConstants.headingFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
