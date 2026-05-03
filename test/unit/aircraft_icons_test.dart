import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/utils/aircraft_icons.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';

void main() {
  group('AircraftIconPainter', () {
    group('getAltitudeColor', () {
      test('returns grey for on-ground aircraft', () {
        final color = AircraftIconPainter.getAltitudeColor(100, onGround: true);
        expect(color.toARGB32(), 0xFF6B7280);
      });

      test('returns bright white-blue for selected aircraft', () {
        final color = AircraftIconPainter.getAltitudeColor(
          10000,
          isSelected: true,
        );
        expect(color.toARGB32(), 0xFFE0F0FF);
      });

      test('selected overrides on-ground', () {
        final color = AircraftIconPainter.getAltitudeColor(
          0,
          onGround: true,
          isSelected: true,
        );
        expect(color.toARGB32(), 0xFFE0F0FF);
      });

      test('returns green for low altitude (<10k ft)', () {
        // 2000m ≈ 6562 ft
        final color = AircraftIconPainter.getAltitudeColor(2000);
        expect(color, AppColors.altitudeLow);
      });

      test('returns amber for medium altitude (10k-30k ft)', () {
        // 6000m ≈ 19685 ft
        final color = AircraftIconPainter.getAltitudeColor(6000);
        expect(color, AppColors.altitudeMedium);
      });

      test('returns rose for high altitude (>30k ft)', () {
        // 11000m ≈ 36089 ft
        final color = AircraftIconPainter.getAltitudeColor(11000);
        expect(color, AppColors.altitudeHigh);
      });

      test('returns grey for very low altitude (<100ft)', () {
        final color = AircraftIconPainter.getAltitudeColor(20);
        expect(color.toARGB32(), 0xFF6B7280);
      });

      test('returns muted for null altitude', () {
        final color = AircraftIconPainter.getAltitudeColor(null);
        expect(color, AppColors.textMuted);
      });
    });

    group('getType', () {
      test('category 8 returns helicopter', () {
        expect(AircraftIconPainter.getType(8), AircraftType.helicopter);
      });

      test('category 6 returns cargo', () {
        expect(AircraftIconPainter.getType(6), AircraftType.cargo);
      });

      test('category 4 returns jet', () {
        expect(AircraftIconPainter.getType(4), AircraftType.jet);
      });

      test('category 2 returns lightAircraft', () {
        expect(AircraftIconPainter.getType(2), AircraftType.lightAircraft);
      });

      test('category 3 returns turboprop', () {
        expect(AircraftIconPainter.getType(3), AircraftType.turboprop);
      });

      test('unknown category defaults to jet', () {
        expect(AircraftIconPainter.getType(0), AircraftType.jet);
        expect(AircraftIconPainter.getType(99), AircraftType.jet);
      });
    });
  });
}
