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
}) => AircraftState(
  icao24: 'AABBCC',
  callsign: callsign,
  squawk: squawk,
  onGround: onGround,
  baroAltitude: baroAltitude,
  velocity: velocity,
);

FlightRouteInfo _route(String dep, String arr) => FlightRouteInfo(
  callsign: 'DLH400',
  departureAirport: dep,
  arrivalAirport: arr,
  source: 'test',
);

void main() {
  group('predictDelay — score capping', () {
    test('emergency squawk + every other factor stays at 95 (cap)', () {
      // Pile every risk factor on a single flight.
      final p = predictDelay(
        aircraft: _ac(
          squawk: '7700',
          onGround: true,
          baroAltitude: 1000, // approach phase
          velocity: 80, // slow
        ),
        route: _route('LHR', 'JFK'), // both delay-prone hubs + intl
      );
      expect(p.delayProbability, lessThanOrEqualTo(95));
    });

    test('estimatedDelayMinutes capped at 60', () {
      // Even with maxed-out risk, the minutes stay clamped.
      final p = predictDelay(
        aircraft: _ac(
          squawk: '7700',
          onGround: true,
          baroAltitude: 1000,
          velocity: 80,
        ),
        route: _route('LHR', 'JFK'),
      );
      expect(p.estimatedDelayMinutes, lessThanOrEqualTo(60));
    });
  });

  group('squawk variants', () {
    test('7500 (hijack) triggers same severity as 7700 / 7600', () {
      for (final sq in ['7500', '7600', '7700']) {
        final p = predictDelay(aircraft: _ac(squawk: sq), route: null);
        expect(
          p.delayProbability,
          greaterThanOrEqualTo(80),
          reason: 'squawk $sq did not produce expected risk',
        );
        expect(p.factors, contains('Emergency squawk'));
      }
    });

    test('non-emergency squawk (e.g. 1200) does NOT add risk', () {
      final p = predictDelay(aircraft: _ac(squawk: '1200'), route: null);
      expect(p.factors, isNot(contains('Emergency squawk')));
    });

    test('null squawk (unread by ADS-B) ignored', () {
      final p = predictDelay(aircraft: _ac(), route: null);
      expect(p.factors, isNot(contains('Emergency squawk')));
    });
  });

  group('international route detection', () {
    test('FRA → MUC (both German) is NOT international', () {
      // Both ICAOs start with 'L' (FRA → EDDF starts with E? — but we
      // only get IATA here). Looking at impl: it grabs IATA's first
      // char. IATA FRA + MUC both start 'F' / 'M' — different leading
      // letters → flagged as international by the heuristic. The
      // factor name is "International route".
      //
      // This documents a known limitation: the heuristic is char-based,
      // not actual-country-based.
      final p = predictDelay(aircraft: _ac(), route: _route('FRA', 'MUC'));
      // FRA starts with 'F', MUC with 'M' → flagged international.
      // Real-world FRA-MUC is domestic, so this is a known FP.
      expect(p.factors, contains('International route'));
    });

    test('FRA → FCO (both start "F") — heuristic says NOT international', () {
      // Both start with 'F' even though it's intl in reality.
      final p = predictDelay(aircraft: _ac(), route: _route('FRA', 'FCO'));
      expect(p.factors, isNot(contains('International route')));
    });

    test('empty endpoints — no international flag', () {
      final p = predictDelay(aircraft: _ac(), route: _route('', ''));
      expect(p.factors, isNot(contains('International route')));
    });
  });

  group('confidence transitions', () {
    test('0 factors → low', () {
      final p = predictDelay(aircraft: _ac(), route: null);
      expect(p.confidence, PredictionConfidence.low);
    });

    test('1 factor → low', () {
      final p = predictDelay(aircraft: _ac(), route: _route('FRA', 'JFK'));
      // FRA-JFK: international + delay-prone hub = 2 factors. Already
      // medium. Let's force exactly 1 factor.
      final p1 = predictDelay(aircraft: _ac(squawk: '7700'), route: null);
      expect(p1.factors, hasLength(1));
      expect(p1.confidence, PredictionConfidence.low);
      expect(p, isNotNull);
    });

    test('2-3 factors → medium', () {
      final p = predictDelay(
        aircraft: _ac(),
        route: _route('FRA', 'JFK'), // intl + delay-prone hub
      );
      expect(p.factors.length, greaterThanOrEqualTo(2));
      expect(p.factors.length, lessThanOrEqualTo(3));
      expect(p.confidence, PredictionConfidence.medium);
    });

    test('4+ factors → high', () {
      // Squawk + intl + hub + approach + ground + slow-cruise > 4.
      final p = predictDelay(
        aircraft: _ac(squawk: '7700', onGround: true, baroAltitude: 1000),
        route: _route('LHR', 'JFK'),
      );
      expect(p.factors.length, greaterThanOrEqualTo(4));
      expect(p.confidence, PredictionConfidence.high);
    });
  });

  group('delay-prone hub coverage', () {
    test('all known hubs trigger the factor', () {
      const hubs = [
        'JFK',
        'EWR',
        'LGA',
        'SFO',
        'LAX',
        'LHR',
        'LGW',
        'STN',
        'CDG',
        'ORY',
        'FCO',
        'MXP',
        'LIN',
        'IST',
        'SAW',
        'PEK',
        'PVG',
        'CAN',
        'DEL',
        'BOM',
      ];
      for (final h in hubs) {
        final p = predictDelay(aircraft: _ac(), route: _route('XYZ', h));
        expect(
          p.factors,
          contains('Heavy traffic hub'),
          reason: '$h should trigger the hub factor',
        );
      }
    });

    test('FRA / MUC are NOT in the list (Germany handled fine on-time)', () {
      final p = predictDelay(aircraft: _ac(), route: _route('XYZ', 'FRA'));
      expect(p.factors, isNot(contains('Heavy traffic hub')));
    });
  });

  group('explanation copy — risk tier branches', () {
    test('high-risk (≥70) explanation contains "high"', () {
      final p = predictDelay(
        aircraft: _ac(squawk: '7700', baroAltitude: 1000),
        route: _route('LHR', 'JFK'),
      );
      expect(p.explanation.toLowerCase(), contains('high'));
    });

    test('moderate-risk (45–69) explanation contains "moderate"', () {
      // Pile factors so we land in the 45–69 band:
      //   baseline 15 + intl 8 + hub 14 + approach 6 + ground 4 = 47.
      // ("approach" and "slow cruise" are mutually exclusive — they
      // hinge on altitude </> 6000m vs >9000m. So we use the
      // approach + on-ground combo to clear 45.)
      final p = predictDelay(
        aircraft: _ac(baroAltitude: 1000, onGround: true),
        route: _route('LHR', 'JFK'),
      );
      expect(p.delayProbability, greaterThanOrEqualTo(45));
      expect(p.delayProbability, lessThan(70));
      expect(p.explanation.toLowerCase(), contains('moderate'));
    });

    test('low-risk (25–44) explanation is "Slight risk"', () {
      // baseline 15 + intl 8 + hub 14 = 37, in [25,44].
      final p = predictDelay(aircraft: _ac(), route: _route('FRA', 'JFK'));
      expect(p.delayProbability, greaterThanOrEqualTo(25));
      expect(p.delayProbability, lessThan(45));
      expect(p.explanation.toLowerCase(), contains('slight'));
    });

    test('clear-skies (< 25) explanation is "On-time arrival likely"', () {
      // No factors → 15 baseline.
      final p = predictDelay(aircraft: _ac(), route: null);
      expect(p.delayProbability, lessThan(25));
      expect(p.explanation, contains('On-time'));
    });
  });
}
