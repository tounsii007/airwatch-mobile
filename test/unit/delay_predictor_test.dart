import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/flight_details/domain/delay_predictor.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

AircraftState _ac({
  String? callsign = 'DLH400',
  String? squawk,
  bool onGround = false,
  double? baroAltitude,
  double? velocity,
}) {
  return AircraftState(
    icao24: 'AABBCC',
    callsign: callsign,
    squawk: squawk,
    onGround: onGround,
    baroAltitude: baroAltitude,
    velocity: velocity,
  );
}

FlightRouteInfo _route(String dep, String arr) => FlightRouteInfo(
      callsign: 'DLH400',
      departureAirport: dep,
      arrivalAirport: arr,
      source: 'test',
    );

void main() {
  group('predictDelay', () {
    test('returns empty for missing callsign', () {
      final p = predictDelay(aircraft: _ac(callsign: null), route: null);
      expect(p.explanation, isEmpty);
    });

    test('emergency squawk dominates the score', () {
      final p = predictDelay(aircraft: _ac(squawk: '7700'), route: null);
      expect(p.delayProbability, greaterThanOrEqualTo(80));
      expect(p.factors, contains('Emergency squawk'));
    });

    test('regular passenger flight gets a low risk score', () {
      // No emergency, no delay-prone hub, cruising altitude.
      final p = predictDelay(
        aircraft: _ac(baroAltitude: 11000, velocity: 240),
        route: _route('FRA', 'MUC'),
      );
      expect(p.delayProbability, lessThan(45));
    });

    test('long-haul to a delay-prone US east-coast hub bumps the score', () {
      final p = predictDelay(
        aircraft: _ac(baroAltitude: 11000, velocity: 240),
        route: _route('FRA', 'JFK'),
      );
      expect(p.delayProbability, greaterThan(25));
      expect(p.factors, contains('International route'));
      expect(p.factors, contains('Heavy traffic hub'));
    });

    test('approach phase (low altitude) adds a factor', () {
      final p = predictDelay(
        aircraft: _ac(baroAltitude: 1500, velocity: 100),
        route: _route('FRA', 'MUC'),
      );
      expect(p.factors, contains('In approach phase'));
    });

    test('confidence rises with the number of factors', () {
      // Many factors → high.
      final p = predictDelay(
        aircraft: _ac(squawk: '7700', baroAltitude: 1000, velocity: 80),
        route: _route('LHR', 'JFK'),
      );
      expect(p.confidence, PredictionConfidence.high);

      // Few factors → low / medium.
      final p2 = predictDelay(
        aircraft: _ac(baroAltitude: 11000, velocity: 240),
        route: _route('FRA', 'MUC'),
      );
      expect(
        p2.confidence,
        anyOf(PredictionConfidence.low, PredictionConfidence.medium),
      );
    });

    test('estimated minutes scales with risk above the threshold', () {
      final low = predictDelay(
        aircraft: _ac(baroAltitude: 11000, velocity: 240),
        route: _route('FRA', 'MUC'),
      );
      // Below the 30 % threshold → 0 minutes.
      expect(low.estimatedDelayMinutes, 0);

      final high = predictDelay(
        aircraft: _ac(squawk: '7700'),
        route: _route('LHR', 'JFK'),
      );
      expect(high.estimatedDelayMinutes, greaterThan(0));
    });

    test('explanation text references the dominant factor for high risk', () {
      final p = predictDelay(
        aircraft: _ac(squawk: '7700', baroAltitude: 1000),
        route: _route('LHR', 'JFK'),
      );
      expect(p.explanation.toLowerCase(), contains('high'));
    });
  });
}
