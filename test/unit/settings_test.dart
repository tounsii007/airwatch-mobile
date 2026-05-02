import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/constants/settings_provider.dart';

void main() {
  group('SettingsState', () {
    test('default values', () {
      const s = SettingsState();
      expect(s.altitudeUnit, AltitudeUnit.feet);
      expect(s.speedUnit, SpeedUnit.knots);
      expect(s.mapTheme, MapTheme.darkRadar);
      expect(s.showAircraftTrails, true);
      expect(s.showRadarSweep, true);
      expect(s.showHeatmap, false);
      expect(s.updateIntervalSec, 60);
    });

    test('formatAltitude in feet', () {
      const s = SettingsState();
      expect(s.formatAltitude(10000), contains('k ft'));
      expect(s.formatAltitude(500), contains('ft'));
      expect(s.formatAltitude(null), '--');
    });

    test('formatAltitude in meters', () {
      const s = SettingsState(altitudeUnit: AltitudeUnit.meters);
      expect(s.formatAltitude(10000), contains('km'));
      expect(s.formatAltitude(500), contains('m'));
    });

    test('formatSpeed in knots', () {
      const s = SettingsState();
      expect(s.formatSpeed(250), contains('kts'));
      expect(s.formatSpeed(null), '--');
    });

    test('formatSpeed in km/h', () {
      const s = SettingsState(speedUnit: SpeedUnit.kmh);
      expect(s.formatSpeed(250), contains('km/h'));
    });

    test('formatSpeed in mph', () {
      const s = SettingsState(speedUnit: SpeedUnit.mph);
      expect(s.formatSpeed(250), contains('mph'));
    });

    test('formatVerticalRate', () {
      const s = SettingsState();
      expect(s.formatVerticalRate(5), contains('+'));
      expect(s.formatVerticalRate(-5), isNot(contains('+')));
      expect(s.formatVerticalRate(null), '--');
    });

    test('tileUrl varies by theme', () {
      expect(const SettingsState().tileUrl,
          contains('dark'));
      expect(const SettingsState(mapTheme: MapTheme.lightAviation).tileUrl,
          contains('light'));
      expect(const SettingsState(mapTheme: MapTheme.satellite).tileUrl,
          contains('arcgis'));
    });

    test('copyWith changes only specified fields', () {
      const original = SettingsState();
      final copy = original.copyWith(altitudeUnit: AltitudeUnit.meters);
      expect(copy.altitudeUnit, AltitudeUnit.meters);
      expect(copy.speedUnit, SpeedUnit.knots); // unchanged
      expect(copy.mapTheme, MapTheme.darkRadar); // unchanged
    });
  });
}
