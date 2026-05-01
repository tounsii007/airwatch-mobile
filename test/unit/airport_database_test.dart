import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/constants/airport_database.dart';

void main() {
  group('AirportDatabase', () {
    test('getName returns full name for known airport', () {
      expect(AirportDatabase.getName('EDDF'), 'Frankfurt Airport');
      expect(AirportDatabase.getName('LFPG'), 'Charles de Gaulle');
    });

    test('getName returns ICAO code for unknown airport', () {
      expect(AirportDatabase.getName('XXXX'), 'XXXX');
    });

    test('getCity returns city name', () {
      expect(AirportDatabase.getCity('EDDF'), 'Frankfurt');
      expect(AirportDatabase.getCity('DTTA'), 'Tunis');
    });

    test('getIata returns IATA code', () {
      expect(AirportDatabase.getIata('EDDF'), 'FRA');
      expect(AirportDatabase.getIata('EGLL'), 'LHR');
    });

    test('displayCode returns IATA for known airports', () {
      expect(AirportDatabase.displayCode('EDDF'), 'FRA');
      expect(AirportDatabase.displayCode('DTTA'), 'TUN');
    });

    test('displayCode returns ICAO for unknown airports', () {
      expect(AirportDatabase.displayCode('XXXX'), 'XXXX');
    });

    test('displayCode handles null', () {
      expect(AirportDatabase.displayCode(null), '???');
      expect(AirportDatabase.displayCode(''), '???');
    });

    test('fullDisplay returns city with IATA', () {
      expect(AirportDatabase.fullDisplay('EDDF'), 'Frankfurt (FRA)');
      expect(AirportDatabase.fullDisplay('DTTA'), 'Tunis (TUN)');
    });

    test('getMajorAirports returns non-empty list', () {
      final airports = AirportDatabase.getMajorAirports();
      expect(airports, isNotEmpty);
      expect(airports.length, greaterThan(10));
    });

    test('getMajorAirports have valid coordinates', () {
      final airports = AirportDatabase.getMajorAirports();
      for (final apt in airports) {
        expect(apt.lat, inInclusiveRange(-90, 90));
        expect(apt.lon, inInclusiveRange(-180, 180));
        expect(apt.iata, isNotEmpty);
      }
    });

    test('all Tunisian airports are in database', () {
      expect(AirportDatabase.getIata('DTTA'), 'TUN');
      expect(AirportDatabase.getIata('DTMB'), 'MIR');
      expect(AirportDatabase.getIata('DTNH'), 'NBE');
      expect(AirportDatabase.getIata('DTTJ'), 'DJE');
      expect(AirportDatabase.getIata('DTKA'), 'TOE');
      expect(AirportDatabase.getIata('DTTS'), 'SFA');
    });

    test('all Moroccan airports are in database', () {
      expect(AirportDatabase.getIata('GMMN'), 'CMN');
      expect(AirportDatabase.getIata('GMMX'), 'RAK');
      expect(AirportDatabase.getIata('GMFF'), 'FEZ');
      expect(AirportDatabase.getIata('GMAD'), 'AGA');
    });
  });
}
