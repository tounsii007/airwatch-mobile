import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'conversion_constants.dart';

// ═══════════════════ UNIT PREFERENCES ═══════════════════

enum AltitudeUnit { feet, meters }

enum SpeedUnit { knots, kmh, mph }

/// Visual style of the base-map tiles. Kept identical to the web app's
/// `mapStyle` setting so a user's choice survives app-to-web / web-to-app
/// transitions conceptually (not physically — they're different stores).
///
/// Ordered by visual lightness: dark radar → dark baselayer → satellite
/// imagery → light street map → light terrain. The order matters for
/// `SharedPreferences` persistence via `.index`.
enum MapTheme {
  /// Dark Carto tiles — default, best contrast for in-flight markers.
  darkRadar,

  /// Light Carto tiles — softer, better for daytime / high-contrast need.
  lightAviation,

  /// ESRI World Imagery satellite photos.
  satellite,

  /// OpenStreetMap standard street layer.
  streets,

  /// Stadia Stamen Terrain — topographic with hillshading.
  terrain,
}

class SettingsState {
  final AltitudeUnit altitudeUnit;
  final SpeedUnit speedUnit;
  final MapTheme mapTheme;
  final bool showAircraftTrails;
  final bool showRadarSweep;
  final bool showHeatmap;
  final bool showAirportLabels;
  final bool showAircraftLabels;
  final int updateIntervalSec;

  const SettingsState({
    this.altitudeUnit = AltitudeUnit.feet,
    this.speedUnit = SpeedUnit.knots,
    this.mapTheme = MapTheme.darkRadar,
    this.showAircraftTrails = true,
    this.showRadarSweep = true,
    this.showHeatmap = false,
    this.showAirportLabels = true,
    this.showAircraftLabels = true,
    this.updateIntervalSec = 60,
  });

  SettingsState copyWith({
    AltitudeUnit? altitudeUnit,
    SpeedUnit? speedUnit,
    MapTheme? mapTheme,
    bool? showAircraftTrails,
    bool? showRadarSweep,
    bool? showHeatmap,
    bool? showAirportLabels,
    bool? showAircraftLabels,
    int? updateIntervalSec,
  }) {
    return SettingsState(
      altitudeUnit: altitudeUnit ?? this.altitudeUnit,
      speedUnit: speedUnit ?? this.speedUnit,
      mapTheme: mapTheme ?? this.mapTheme,
      showAircraftTrails: showAircraftTrails ?? this.showAircraftTrails,
      showRadarSweep: showRadarSweep ?? this.showRadarSweep,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      showAirportLabels: showAirportLabels ?? this.showAirportLabels,
      showAircraftLabels: showAircraftLabels ?? this.showAircraftLabels,
      updateIntervalSec: updateIntervalSec ?? this.updateIntervalSec,
    );
  }

  /// Format altitude value with proper unit
  String formatAltitude(double? meters) {
    if (meters == null) return '--';
    switch (altitudeUnit) {
      case AltitudeUnit.feet:
        final ft = meters * ConversionConstants.metersToFeet;
        if (ft < 1000) return '${ft.round()} ft';
        return '${(ft / 1000).toStringAsFixed(1)}k ft';
      case AltitudeUnit.meters:
        if (meters < 1000) return '${meters.round()} m';
        return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format speed value with proper unit
  String formatSpeed(double? metersPerSec) {
    if (metersPerSec == null) return '--';
    switch (speedUnit) {
      case SpeedUnit.knots:
        return '${(metersPerSec * ConversionConstants.msToKnots).round()} kts';
      case SpeedUnit.kmh:
        return '${(metersPerSec * ConversionConstants.msToKmh).round()} km/h';
      case SpeedUnit.mph:
        return '${(metersPerSec * ConversionConstants.msToMph).round()} mph';
    }
  }

  /// Format vertical rate
  String formatVerticalRate(double? metersPerSec) {
    if (metersPerSec == null) return '--';
    final sign = metersPerSec > 0 ? '+' : '';
    switch (altitudeUnit) {
      case AltitudeUnit.feet:
        return '$sign${(metersPerSec * ConversionConstants.msToFtPerMin).round()} ft/m';
      case AltitudeUnit.meters:
        return '$sign${(metersPerSec * ConversionConstants.msToMPerMin).round()} m/m';
    }
  }

  /// Map tile URL for the active theme.
  ///
  /// <p>Keep these URLs in lock-step with
  /// `airwatch-web/src/app/flights/...` so a user browsing the same
  /// area on web and mobile sees identical tiles — no visual jump between
  /// platforms.
  String get tileUrl {
    switch (mapTheme) {
      case MapTheme.darkRadar:
        return 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
      case MapTheme.lightAviation:
        return 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
      case MapTheme.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTheme.streets:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTheme.terrain:
        return 'https://tiles.stadiamaps.com/tiles/stamen_terrain/'
            '{z}/{x}/{y}@2x.png';
    }
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      altitudeUnit: AltitudeUnit.values[prefs.getInt('alt_unit') ?? 0],
      speedUnit: SpeedUnit.values[prefs.getInt('speed_unit') ?? 0],
      mapTheme: MapTheme.values[prefs.getInt('map_theme') ?? 0],
      showAircraftTrails: prefs.getBool('show_trails') ?? true,
      showRadarSweep: prefs.getBool('show_radar') ?? true,
      showHeatmap: prefs.getBool('show_heatmap') ?? false,
      showAirportLabels: prefs.getBool('show_apt_labels') ?? true,
      showAircraftLabels: prefs.getBool('show_ac_labels') ?? true,
      updateIntervalSec: prefs.getInt('update_interval') ?? 60,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alt_unit', state.altitudeUnit.index);
    await prefs.setInt('speed_unit', state.speedUnit.index);
    await prefs.setInt('map_theme', state.mapTheme.index);
    await prefs.setBool('show_trails', state.showAircraftTrails);
    await prefs.setBool('show_radar', state.showRadarSweep);
    await prefs.setBool('show_heatmap', state.showHeatmap);
    await prefs.setBool('show_apt_labels', state.showAirportLabels);
    await prefs.setBool('show_ac_labels', state.showAircraftLabels);
    await prefs.setInt('update_interval', state.updateIntervalSec);
  }

  void update(SettingsState Function(SettingsState s) updater) {
    state = updater(state);
    _save();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
