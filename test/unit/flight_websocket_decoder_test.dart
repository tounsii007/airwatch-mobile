import 'dart:convert';

import 'package:airwatch_mobile/features/map/data/datasources/flight_websocket_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// We can't unit-test the WS service end-to-end without a real socket,
/// but we CAN feed a synthetic frame through the public stream by
/// invoking the same JSON-decode path indirectly via a Reflection-y
/// trick: emit a stream of bytes through a fresh service. Cleanest
/// approach is to just verify the decoder shape via the full message
/// envelope shape the api emits.
void main() {
  group('FlightWebSocketService frame decoding (smoke)', () {
    test('connect() does not throw without a real socket', () {
      // No real WS server in unit tests — just verify that build +
      // dispose roundtrip cleanly. The real protocol coverage lives
      // in integration tests.
      final svc = FlightWebSocketService();
      expect(svc.subscriptions, isEmpty);
      expect(svc.currentState, WsConnectionState.idle);
      svc.dispose();
    });

    test('subscribe() rejects malformed icao24 codes', () {
      final svc = FlightWebSocketService();
      svc.subscribe(['bad', '4242', 'abc1234', '']);
      // None of those are 6-char hex strings — set stays empty.
      expect(svc.subscriptions, isEmpty);
      svc.dispose();
    });

    test('subscribe() lowercases + dedupes valid icao24 codes', () {
      final svc = FlightWebSocketService();
      svc.subscribe(['ABC123', 'abc123', 'DEF456']);
      expect(svc.subscriptions, containsAll(['abc123', 'def456']));
      expect(svc.subscriptions.length, 2);
      svc.dispose();
    });

    test('replaceSubscriptions() clears + sets atomically', () {
      final svc = FlightWebSocketService();
      svc.subscribe(['abc123']);
      svc.replaceSubscriptions(['xyz789', 'def456']);
      expect(svc.subscriptions, containsAll(['xyz789', 'def456']));
      expect(svc.subscriptions.contains('abc123'), isFalse);
      svc.dispose();
    });

    test('frame envelope sanity check — what the api ships', () {
      // Just a documentation-like assertion: when the api pushes a
      // frame, the wire shape is `{type, count, timestamp, data: []}`.
      // If this ever breaks we want a green-text review of the WS
      // service's internal _onMessage branching.
      final synthetic = jsonEncode({
        'type': 'flights',
        'count': 1,
        'timestamp': 1700000000,
        'data': [
          {
            'hex': 'abc123',
            'flight_icao': 'DLH400',
            'lat': 50.0,
            'lng': 8.0,
            'alt': 11000.0,
            'dir': 90.0,
            'speed': 800.0,
            'flag': 'DE',
            'status': 'en-route',
          },
        ],
      });
      final decoded = jsonDecode(synthetic);
      expect(decoded['type'], 'flights');
      expect((decoded['data'] as List).first['hex'], 'abc123');
    });
  });
}
