import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

void main() {
  group('AircraftState', () {
    test('fromOpenSkyList parses correctly', () {
      final data = [
        'abc123', 'DLH123  ', 'Germany', 1700000000, 1700000001,
        8.571, 50.033, 10000.0, false, 250.0, 90.0, 0.0,
        null, 10500.0, '1234', false, 0, 4,
      ];

      final state = AircraftState.fromOpenSkyList(data);

      expect(state.icao24, 'abc123');
      expect(state.callsign, 'DLH123');
      expect(state.originCountry, 'Germany');
      expect(state.latitude, 50.033);
      expect(state.longitude, 8.571);
      expect(state.baroAltitude, 10000.0);
      expect(state.onGround, false);
      expect(state.velocity, 250.0);
      expect(state.trueTrack, 90.0);
      expect(state.hasPosition, true);
      expect(state.position, isNotNull);
      expect(state.heading, 90.0);
    });

    test('hasPosition is false without coordinates', () {
      final state = AircraftState(icao24: 'test');
      expect(state.hasPosition, false);
      expect(state.position, isNull);
    });

    test('altitude prefers baroAltitude over geoAltitude', () {
      final state = AircraftState(
        icao24: 'test',
        baroAltitude: 9000,
        geoAltitude: 9500,
      );
      expect(state.altitude, 9000);
    });

    test('altitude falls back to geoAltitude', () {
      final state = AircraftState(
        icao24: 'test',
        geoAltitude: 9500,
      );
      expect(state.altitude, 9500);
    });

    test('copyWith preserves fields', () {
      final original = AircraftState(
        icao24: 'abc',
        callsign: 'DLH1',
        originCountry: 'Germany',
        latitude: 50.0,
        longitude: 8.0,
      );

      final copy = original.copyWith(callsign: 'DLH2');
      expect(copy.icao24, 'abc');
      expect(copy.callsign, 'DLH2');
      expect(copy.originCountry, 'Germany');
    });

    test('heading defaults to 0 when trueTrack is null', () {
      final state = AircraftState(icao24: 'test');
      expect(state.heading, 0);
    });
  });
}
