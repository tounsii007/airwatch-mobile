import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/settings_provider.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

import 'panel_widgets.dart';

/// Compact 2x2 colored data cards: Altitude, Heading, Speed, V/S, Lat, Lon.
class PanelDataGrid extends StatelessWidget {
  final AircraftState aircraft;
  final SettingsState settings;
  final Color altColor;
  final bool isDark;

  const PanelDataGrid({
    super.key,
    required this.aircraft,
    required this.settings,
    required this.altColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final vsValue = UiText.formatVerticalRate(context, settings, aircraft.verticalRate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: [
        // Row 1: Altitude+Heading | Speed+V/S
        Row(children: [
          Expanded(child: FlightDataCard(
            title1: context.s.altitude, value1: UiText.formatAltitude(context, settings, aircraft.altitude),
            title2: context.s.heading, value2: aircraft.heading.toStringAsFixed(0),
            borderColor: AppColors.altitudeHigh, // Magenta
            isDark: isDark,
          )),
          const SizedBox(width: 8),
          Expanded(child: FlightDataCard(
            title1: context.s.speed, value1: UiText.formatSpeed(context, settings, aircraft.velocity),
            title2: context.s.verticalSpeed, value2: vsValue,
            borderColor: AppColors.primary, // Cyan
            isDark: isDark,
          )),
        ]),
        const SizedBox(height: 8),
        // Row 2: LAT | LON
        Row(children: [
          Expanded(child: FlightDataCard(
            title1: 'LAT', value1: aircraft.latitude?.toStringAsFixed(4) ?? '--',
            borderColor: AppColors.altitudeLow, // Yellow
            isDark: isDark,
          )),
          const SizedBox(width: 8),
          Expanded(child: FlightDataCard(
            title1: 'LON', value1: aircraft.longitude?.toStringAsFixed(4) ?? '--',
            borderColor: AppColors.altitudeLow, // Yellow
            isDark: isDark,
          )),
        ]),
      ]),
    );
  }
}
