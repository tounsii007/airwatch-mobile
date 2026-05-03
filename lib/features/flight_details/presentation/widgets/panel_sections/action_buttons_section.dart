import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/flight_history_screen.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/flight_replay_3d_screen.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/flight_replay_screen.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

import 'panel_widgets.dart';

/// Action buttons row: Track, Replay, History, Favorite.
class PanelActionButtons extends StatelessWidget {
  final AircraftState aircraft;
  final bool isDark;
  final VoidCallback onTrack;
  final VoidCallback onFavorite;

  const PanelActionButtons({
    super.key,
    required this.aircraft,
    required this.isDark,
    required this.onTrack,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: FlightActionButton(
              label: context.tr('track'),
              color: AppColors.primary,
              isDark: isDark,
              onTap: onTrack,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FlightActionButton(
              label: context.tr('replay'),
              color: AppColors.altitudeMedium,
              isDark: isDark,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FlightReplayScreen(
                      icao24: aircraft.icao24,
                      callsign: aircraft.callsign?.trim(),
                    ),
                  ),
                );
              },
              // Long-press swaps to the 3-D globe replay — mirrors the
              // web frontend's `/replay/3d` route. We use long-press
              // instead of a separate button to keep the action row at
              // 4 entries on phones where horizontal real estate is
              // already tight.
              onLongPress: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FlightReplay3DScreen(
                      icao24: aircraft.icao24,
                      callsign: aircraft.callsign?.trim(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FlightActionButton(
              label: context.tr('history'),
              color: AppColors.altitudeHigh,
              isDark: isDark,
              onTap: () {
                final cs = aircraft.callsign?.trim();
                if (cs != null && cs.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FlightHistoryScreen(initialCallsign: cs),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FlightActionButton(
              label: context.tr('favorite'),
              color: AppColors.error,
              isDark: isDark,
              onTap: onFavorite,
            ),
          ),
        ],
      ),
    );
  }
}
