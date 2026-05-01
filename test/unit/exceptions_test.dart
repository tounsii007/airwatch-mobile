import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/errors/exceptions.dart';
import 'package:airwatch_mobile/core/errors/result.dart';

void main() {
  group('Exceptions', () {
    test('NetworkException has statusCode', () {
      const e = NetworkException(message: 'Failed', statusCode: 500);
      expect(e.isServerError, true);
      expect(e.isRateLimited, false);
      expect(e.toString(), contains('NetworkException'));
    });

    test('RateLimitException', () {
      const e = RateLimitException(apiName: 'Airlabs');
      expect(e.apiName, 'Airlabs');
      expect(e.code, 'rate_limited');
    });

    test('AircraftNotFoundException', () {
      const e = AircraftNotFoundException(icao24: 'abc123');
      expect(e.icao24, 'abc123');
      expect(e.message, 'Aircraft not found');
    });

    test('AirportNotFoundException', () {
      const e = AirportNotFoundException(iataCode: 'XXX');
      expect(e.iataCode, 'XXX');
    });

    test('RouteNotFoundException', () {
      const e = RouteNotFoundException(callsign: 'DLH123');
      expect(e.callsign, 'DLH123');
    });

    test('wrapException handles SocketException', () {
      final e = wrapException(Exception('SocketException: Connection refused'));
      expect(e, isA<NetworkException>());
      expect((e as NetworkException).isNoInternet, true);
    });

    test('wrapException handles timeout', () {
      final e = wrapException(Exception('TimeoutException after 0:00:15'));
      expect(e, isA<NetworkException>());
      expect((e as NetworkException).isTimeout, true);
    });

    test('wrapException handles rate limit', () {
      final e = wrapException(Exception('429 Too many requests'));
      expect(e, isA<RateLimitException>());
    });

    test('wrapException passes through AirWatchException', () {
      const original = AircraftNotFoundException(icao24: 'test');
      final result = wrapException(original);
      expect(identical(result, original), true);
    });

    test('wrapException handles FormatException', () {
      final e = wrapException(const FormatException('bad format'));
      expect(e, isA<ApiParseException>());
    });

    test('wrapException truncates long messages', () {
      final longMsg = 'x' * 300;
      final e = wrapException(Exception(longMsg));
      expect(e.message.length, lessThanOrEqualTo(204)); // 200 + "..."
    });
  });

  group('Result', () {
    test('Success holds data', () {
      final r = Result.success(42);
      expect(r.isSuccess, true);
      expect(r.isFailure, false);
      expect(r.dataOrNull, 42);
      expect(r.errorOrNull, isNull);
    });

    test('Failure holds error', () {
      final r = Result<int>.failure(
          const NetworkException(message: 'fail'));
      expect(r.isSuccess, false);
      expect(r.isFailure, true);
      expect(r.dataOrNull, isNull);
      expect(r.errorOrNull, isA<NetworkException>());
    });

    test('when dispatches correctly', () {
      final success = Result.success(10);
      final failure = Result<int>.failure(
          const NetworkException(message: 'x'));

      expect(success.when(success: (d) => d * 2, failure: (_) => -1), 20);
      expect(failure.when(success: (d) => d * 2, failure: (_) => -1), -1);
    });

    test('map transforms success', () {
      final r = Result.success(5).map((d) => d * 3);
      expect(r.dataOrNull, 15);
    });

    test('map passes through failure', () {
      final r = Result<int>.failure(
          const NetworkException(message: 'x')).map((d) => d * 3);
      expect(r.isFailure, true);
    });

    test('runCatching catches errors', () async {
      final r = await runCatching(() async {
        throw Exception('boom');
      });
      expect(r.isFailure, true);
    });

    test('runCatching returns success', () async {
      final r = await runCatching(() async => 42);
      expect(r.dataOrNull, 42);
    });
  });
}
