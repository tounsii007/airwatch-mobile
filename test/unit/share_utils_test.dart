import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/utils/share_utils.dart';

void main() {
  group('ShareUtils', () {
    test('buildFlightShareText prefers user-friendly flight code', () {
      final text = ShareUtils.buildFlightShareText(callsign: 'DLH123');
      expect(text, contains('LH123'));
      expect(text, contains('AirWatch'));
    });

    test('buildFlightShareText includes route', () {
      final text = ShareUtils.buildFlightShareText(
        callsign: 'LX39',
        airline: 'Swiss',
        depIata: 'SFO',
        arrIata: 'ZRH',
      );
      expect(text, contains('SFO'));
      expect(text, contains('ZRH'));
      expect(text, contains('Swiss'));
    });

    test('buildFlightShareText includes aircraft', () {
      final text = ShareUtils.buildFlightShareText(
        callsign: 'BA123',
        aircraftType: 'Boeing 777',
        status: 'en-route',
      );
      expect(text, contains('Boeing 777'));
      expect(text, contains('en-route'));
    });

    test('buildFlightShareText converts altitude to feet', () {
      final text = ShareUtils.buildFlightShareText(
        callsign: 'TEST',
        altitude: 10000, // meters
      );
      expect(text, contains('32808')); // ~32808 ft
    });
  });
}
