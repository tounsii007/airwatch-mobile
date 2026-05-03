import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/errors/exceptions.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Primary flight data source using Airlabs.co /flights endpoint.
/// Returns ALL flight data in one call: positions, routes, airline, status.
/// Uses bbox+zoom for viewport-optimized requests.
class AirlabsFlightsDatasource {
  final Dio _dio;
  Timer? _pollTimer;
  final StreamController<List<AircraftState>> _controller =
      StreamController<List<AircraftState>>.broadcast();

  Stream<List<AircraftState>> get stateStream => _controller.stream;

  AirlabsFlightsDatasource({Dio? dio})
    : _dio =
          dio ??
          AppHttpClient.create(
            connectTimeout: AppConfig.longTimeout,
            receiveTimeout: const Duration(seconds: 60),
          );

  /// Fetch all flights with essential fields
  Future<List<AircraftState>> getAllFlights() async {
    try {
      // Request only needed fields to reduce payload (~50% smaller)
      final fields = [
        'hex',
        'reg_number',
        'flag',
        'lat',
        'lng',
        'alt',
        'dir',
        'speed',
        'v_speed',
        'squawk',
        'flight_icao',
        'flight_iata',
        'flight_number',
        'airline_icao',
        'airline_iata',
        'aircraft_icao',
        'dep_icao',
        'dep_iata',
        'arr_icao',
        'arr_iata',
        'status',
        'updated',
      ].join(',');

      final url = AppConfig.flightsUrl('_fields=$fields');
      debugPrint('[Airlabs Flights] Fetching all...');

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final flights = data[ApiJsonKeys.response] as List?;
        if (flights == null) return [];

        // Memory protection: limit to 15,000 aircraft max
        final limited = flights.length > 15000 ? flights.take(15000) : flights;

        final result = limited
            .map((f) => _parseAirlabsFlight(f as Map))
            .where((a) => a.hasPosition)
            .toList();

        debugPrint(
          '[Airlabs Flights] Got ${result.length} aircraft (raw: ${flights.length})',
        );
        return result;
      }
      if (response.statusCode == 429) {
        debugPrint('[Airlabs Flights] Rate limited (429)');
        throw const RateLimitException(apiName: 'Airlabs');
      }
      if (response.statusCode == 401) {
        debugPrint('[Airlabs Flights] Unauthorized — check API key');
        throw const NetworkException(
          message: 'Invalid Airlabs API key',
          statusCode: 401,
        );
      }
      return [];
    } on AirWatchException {
      rethrow;
    } on DioException catch (e, stack) {
      final wrapped = wrapException(e, stack);
      debugPrint('[Airlabs Flights] ${wrapped.message}');
      return [];
    } catch (e, stack) {
      debugPrint('[Airlabs Flights] ${wrapException(e, stack)}');
      return [];
    }
  }

  /// Parse Airlabs flight JSON into AircraftState
  AircraftState _parseAirlabsFlight(Map f) {
    final lat = (f[ApiJsonKeys.lat] as num?)?.toDouble();
    final lng = (f[ApiJsonKeys.lng] as num?)?.toDouble();

    final status = f[ApiJsonKeys.status]?.toString();
    return AircraftState(
      icao24: f[ApiJsonKeys.hex]?.toString() ?? '',
      callsign:
          f[ApiJsonKeys.flightIcao]?.toString() ??
          f[ApiJsonKeys.flightIata]?.toString(),
      originCountry: f[ApiJsonKeys.flag]?.toString(),
      latitude: lat,
      longitude: lng,
      baroAltitude: (f[ApiJsonKeys.alt] as num?)?.toDouble(),
      onGround:
          (f[ApiJsonKeys.alt] as num?)?.toDouble() == 0 || status == 'landed',
      velocity: _kmhToMs((f[ApiJsonKeys.speed] as num?)?.toDouble()),
      trueTrack: (f[ApiJsonKeys.dir] as num?)?.toDouble(),
      verticalRate: _kmhToMs((f[ApiJsonKeys.vSpeed] as num?)?.toDouble()),
      squawk: f[ApiJsonKeys.squawk]?.toString(),
      category: _guessCategory(f[ApiJsonKeys.aircraftIcao]?.toString()),
      flightStatus: status,
    );
  }

  /// Convert km/h to m/s (Airlabs returns km/h, our model expects m/s)
  double? _kmhToMs(double? kmh) => kmh != null ? kmh / 3.6 : null;

  /// Guess aircraft category from ICAO type code.
  /// Categories: 0=unknown, 2=light, 3=turboprop, 4=narrowbody, 6=widebody, 8=helicopter
  int _guessCategory(String? typeCode) {
    if (typeCode == null) return 0;
    final t = typeCode.toUpperCase();

    // Heavy widebody (twin-aisle)
    if (t.startsWith('A38') || // A380
        t.startsWith('B74') || // B747
        t.startsWith('B77') || // B777, B777X
        t.startsWith('B78') || // B787 Dreamliner
        t.startsWith('A35') || // A350
        t.startsWith('A34') || // A340
        t.startsWith('A33') || // A330
        t.startsWith('B76') || // B767
        t.startsWith('IL9') || // IL-96
        t.startsWith('A30')) {
      // A300, A310
      return AppConfig.categoryHighPerf; // 6 = widebody
    }

    // Large narrowbody (single-aisle)
    if (t.startsWith('A32') || // A320 family
        t.startsWith('A31') || // A310 (also narrowbody variants)
        t.startsWith('A21') || // A220
        t.startsWith('A22') || // A220 (BCS1/BCS3)
        t.startsWith('B73') || // B737
        t.startsWith('B75') || // B757
        t.startsWith('E19') || // E190, E195
        t.startsWith('E17') || // E170, E175
        t.startsWith('BCS') || // A220 (Bombardier C Series)
        t.startsWith('CRJ') || // CRJ-200/700/900/1000
        t.startsWith('ERJ') || // ERJ-135/140/145
        t.startsWith('E14') || // E145
        t.startsWith('E13') || // E135
        t.startsWith('B71') || // B717
        t.startsWith('MD') || // MD-80/90
        t.startsWith('F10') || // Fokker 100
        t.startsWith('F70') || // Fokker 70
        t.startsWith('SU9') || // Sukhoi Superjet
        t.startsWith('ARJ')) {
      // ARJ21
      return AppConfig.categoryHighVortex; // 4 = narrowbody
    }

    // Turboprop
    if (t.startsWith('AT') || // ATR 42/72
        t.startsWith('DH') || // Dash 8 / DHC
        t.startsWith('SF3') || // Saab 340
        t.startsWith('D32') || // Dornier 328
        t.startsWith('D38') || // Dornier 328
        t.startsWith('L41') || // L-410
        t.startsWith('AN2') || // AN-24/26
        t.startsWith('JS4') || // Jetstream 41
        t.startsWith('SB2')) {
      // Saab 2000
      return AppConfig.categoryLarge; // 3 = turboprop
    }

    // Light aircraft
    if (t.startsWith('C1') || // Cessna 100-series
        t.startsWith('C2') || // Cessna 200-series
        t.startsWith('C3') || // Cessna 300-series
        t.startsWith('C5') || // Cessna Citation
        t.startsWith('C6') || // Cessna Citation
        t.startsWith('PA') || // Piper
        t.startsWith('BE') || // Beechcraft
        t.startsWith('DA') || // Diamond
        t.startsWith('P18') || // Piper PA-18
        t.startsWith('SR2') || // Cirrus SR22
        t.startsWith('M20') || // Mooney
        t.startsWith('PC1') || // Pilatus PC-12
        t.startsWith('TBM')) {
      // TBM 700/850/900
      return AppConfig.categorySmall; // 2 = light
    }

    // Helicopter
    if (t.startsWith('R22') ||
        t.startsWith('R44') ||
        t.startsWith('R66') || // Robinson
        t.startsWith('EC') || // Eurocopter/Airbus H-series
        t.startsWith('AS') || // Aerospatiale
        t.startsWith('B4') || // Bell 400-series
        t.startsWith('B2') || // Bell 200-series
        t.startsWith('H1') || // Airbus H145/H160
        t.startsWith('S76') || // Sikorsky S-76
        t.startsWith('S92') || // Sikorsky S-92
        t.startsWith('A10') || // AgustaWestland AW109/139
        t.startsWith('A13') || // AW139
        t.startsWith('A16') || // AW169
        t.startsWith('A18') || // AW189
        t.startsWith('MD5') || // MD500
        t.startsWith('UH')) {
      // Utility helicopters
      return AppConfig.categoryHelicopter; // 8 = helicopter
    }

    return AppConfig.categoryHighVortex; // Default: narrowbody (4)
  }

  /// Start polling
  void startPolling({Duration interval = AppConfig.flightUpdateInterval}) {
    stopPolling();

    Future<void> fetch() async {
      final states = await getAllFlights();
      if (states.isNotEmpty) {
        _controller.add(states);
      }
    }

    fetch();
    _pollTimer = Timer.periodic(interval, (_) => fetch());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stopPolling();
    _controller.close();
  }
}
