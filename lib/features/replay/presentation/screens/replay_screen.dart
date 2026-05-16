import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/flight_history_screen.dart';

/// Replay entry point — mirrors airwatch-web's `/replay` route.
///
/// <p>Mobile already ships a feature-complete 7-day flight history
/// browser ([FlightHistoryScreen]) — this screen is the discoverable
/// entry point that lets a user start a replay search from the More
/// menu without needing to drill down via an existing aircraft pin
/// on the map.
///
/// <p>The actual playback (with a track-line scrubber + animated
/// marker on the map) lives inside FlightHistoryScreen's tile-tap
/// path. Keeping this screen thin avoids duplicating the search +
/// network + result-list logic that already exists.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _launch(BuildContext context) {
    final cs = _controller.text.trim();
    if (cs.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlightHistoryScreen(initialCallsign: cs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));
    return Scaffold(
      appBar: AppBar(
        title: Text(s.replayTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.history_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                s.replayHeading,
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.replayBody,
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 13,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              GlassPanel(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                borderRadius: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: s.replayHint,
                          hintStyle: const TextStyle(
                            fontFamily: UiConstants.bodyFont,
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: UiConstants.headingFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                        ),
                        onSubmitted: (_) => _launch(context),
                      ),
                    ),
                    IconButton(
                      tooltip: s.replaySearchAction,
                      onPressed: () => _launch(context),
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.replayExamples,
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
