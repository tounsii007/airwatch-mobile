import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/utils/extensions.dart';

void main() {
  group('DoubleExtensions', () {
    test('metersToFeet conversion', () {
      expect(1000.0.metersToFeet, closeTo(3280.84, 0.1));
      expect(10000.0.metersToFeet, closeTo(32808.4, 1));
    });

    test('msToKnots conversion', () {
      expect(100.0.msToKnots, closeTo(194.384, 0.1));
    });

    test('formatAltitude for low values', () {
      expect(200.0.formatAltitude(), contains('ft'));
    });

    test('formatAltitude for high values', () {
      expect(10000.0.formatAltitude(), contains('k ft'));
    });

    test('formatSpeed', () {
      expect(250.0.formatSpeed(), contains('kts'));
    });

    test('formatHeading compass directions', () {
      expect(0.0.formatHeading(), contains('N'));
      expect(90.0.formatHeading(), contains('E'));
      expect(180.0.formatHeading(), contains('S'));
      expect(270.0.formatHeading(), contains('W'));
    });
  });

  group('StringExtensions', () {
    test('capitalize', () {
      expect('hello'.capitalize, 'Hello');
      expect(''.capitalize, '');
    });

    test('airlineIcao extracts first 3 chars', () {
      expect('DLH123'.airlineIcao, 'DLH');
      expect('AB'.airlineIcao, 'AB');
    });
  });
}
