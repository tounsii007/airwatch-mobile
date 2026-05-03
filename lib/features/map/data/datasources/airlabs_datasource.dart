import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Airlabs.co API — uses the /flight endpoint (singular) for maximum detail.
/// Free tier: 1,000 requests/month.
class AirlabsDatasource {
  final Dio _dio;
  static final Map<String, AirlabsFlight?> _cache = {};

  AirlabsDatasource({Dio? dio})
    : _dio = dio ?? AppHttpClient.create(receiveTimeout: AppConfig.apiTimeout);

  /// Look up flight by ICAO callsign using /flight endpoint (detailed)
  Future<AirlabsFlight?> getFlightByCallsign(String callsign) async {
    final cs = callsign.trim().toUpperCase();
    if (cs.isEmpty) return null;
    if (_cache.containsKey(cs)) return _cache[cs];

    try {
      // Use /flight (singular) for detailed response
      final url = AppConfig.flightUrl(flightIcao: cs);
      debugPrint('[Airlabs] Fetching: $cs');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final f = data[ApiJsonKeys.response] as Map?;

        if (f != null && f.isNotEmpty) {
          final result = _parseFlight(f);
          _cache[cs] = result;
          debugPrint(
            '[Airlabs] Found: ${result.depIata} -> ${result.arrIata} (${result.status})',
          );
          return result;
        }
      }

      _cache[cs] = null;
      debugPrint('[Airlabs] No data for $cs');
      return null;
    } catch (e) {
      debugPrint('[Airlabs] Error: $e');
      _cache[cs] = null;
      return null;
    }
  }

  /// Look up by IATA flight code using /flight endpoint
  Future<AirlabsFlight?> getFlightByIata(String iataCode) async {
    final code = iataCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    final cacheKey = 'iata_$code';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final url = AppConfig.flightUrl(flightIata: code);
      debugPrint('[Airlabs] Fetching IATA: $code');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final f = data[ApiJsonKeys.response] as Map?;
        if (f != null && f.isNotEmpty) {
          final result = _parseFlight(f);
          _cache[cacheKey] = result;
          return result;
        }
      }
      _cache[cacheKey] = null;
      return null;
    } catch (e) {
      _cache[cacheKey] = null;
      return null;
    }
  }

  AirlabsFlight _parseFlight(Map f) {
    return AirlabsFlight(
      // Flight identifiers
      flightIcao: f[ApiJsonKeys.flightIcao]?.toString(),
      flightIata: f[ApiJsonKeys.flightIata]?.toString(),
      flightNumber: f[ApiJsonKeys.flightNumber]?.toString(),
      airlineIcao: f[ApiJsonKeys.airlineIcao]?.toString(),
      airlineIata: f[ApiJsonKeys.airlineIata]?.toString(),
      // Departure
      depIcao: f[ApiJsonKeys.depIcao]?.toString(),
      depIata: f[ApiJsonKeys.depIata]?.toString(),
      depTerminal: f[ApiJsonKeys.depTerminal]?.toString(),
      depGate: f[ApiJsonKeys.depGate]?.toString(),
      depTime: f[ApiJsonKeys.depTime]?.toString(),
      depTimeUtc: f[ApiJsonKeys.depTimeUtc]?.toString(),
      depEstimated: f[ApiJsonKeys.depEstimated]?.toString(),
      depActual: f[ApiJsonKeys.depActual]?.toString(),
      depDelayed: f[ApiJsonKeys.depDelayed] as int?,
      // Arrival
      arrIcao: f[ApiJsonKeys.arrIcao]?.toString(),
      arrIata: f[ApiJsonKeys.arrIata]?.toString(),
      arrTerminal: f[ApiJsonKeys.arrTerminal]?.toString(),
      arrGate: f[ApiJsonKeys.arrGate]?.toString(),
      arrBaggage: f[ApiJsonKeys.arrBaggage]?.toString(),
      arrTime: f[ApiJsonKeys.arrTime]?.toString(),
      arrTimeUtc: f[ApiJsonKeys.arrTimeUtc]?.toString(),
      arrEstimated: f[ApiJsonKeys.arrEstimated]?.toString(),
      arrActual: f[ApiJsonKeys.arrActual]?.toString(),
      arrDelayed: f[ApiJsonKeys.arrDelayed] as int?,
      // Status
      status: f[ApiJsonKeys.status]?.toString(),
      duration: f[ApiJsonKeys.duration] as int?,
      // Aircraft details
      hex: f[ApiJsonKeys.hex]?.toString(),
      regNumber: f[ApiJsonKeys.regNumber]?.toString(),
      aircraftIcao: f[ApiJsonKeys.aircraftIcao]?.toString(),
      model: f[ApiJsonKeys.model]?.toString(),
      manufacturer: f[ApiJsonKeys.manufacturer]?.toString(),
      type: f[ApiJsonKeys.type]?.toString(),
      engine: f[ApiJsonKeys.engine]?.toString(),
      engineCount: f[ApiJsonKeys.engineCount]?.toString(),
      built: f[ApiJsonKeys.built] as int?,
      age: f[ApiJsonKeys.age] as int?,
      msn: f[ApiJsonKeys.msn]?.toString(),
      // Position
      lat: (f[ApiJsonKeys.lat] as num?)?.toDouble(),
      lng: (f[ApiJsonKeys.lng] as num?)?.toDouble(),
      altitude: (f[ApiJsonKeys.alt] as num?)?.toDouble(),
      speed: (f[ApiJsonKeys.speed] as num?)?.toDouble(),
      heading: (f[ApiJsonKeys.dir] as num?)?.toDouble(),
      squawk: f[ApiJsonKeys.squawk]?.toString(),
      flag: f[ApiJsonKeys.flag]?.toString(),
    );
  }
}

/// Comprehensive flight data from Airlabs /flight endpoint
class AirlabsFlight {
  // Identifiers
  final String? flightIcao, flightIata, flightNumber;
  final String? airlineIcao, airlineIata;
  // Departure
  final String? depIcao, depIata, depTerminal, depGate;
  final String? depTime, depTimeUtc, depEstimated, depActual;
  final int? depDelayed;
  // Arrival
  final String? arrIcao, arrIata, arrTerminal, arrGate, arrBaggage;
  final String? arrTime, arrTimeUtc, arrEstimated, arrActual;
  final int? arrDelayed;
  // Status
  final String? status;
  final int? duration; // minutes
  // Aircraft
  final String? hex, regNumber, aircraftIcao;
  final String? model, manufacturer, type, engine, engineCount, msn;
  final int? built, age;
  final String? flag;
  // Position
  final double? lat, lng, altitude, speed, heading;
  final String? squawk;

  AirlabsFlight({
    this.flightIcao,
    this.flightIata,
    this.flightNumber,
    this.airlineIcao,
    this.airlineIata,
    this.depIcao,
    this.depIata,
    this.depTerminal,
    this.depGate,
    this.depTime,
    this.depTimeUtc,
    this.depEstimated,
    this.depActual,
    this.depDelayed,
    this.arrIcao,
    this.arrIata,
    this.arrTerminal,
    this.arrGate,
    this.arrBaggage,
    this.arrTime,
    this.arrTimeUtc,
    this.arrEstimated,
    this.arrActual,
    this.arrDelayed,
    this.status,
    this.duration,
    this.hex,
    this.regNumber,
    this.aircraftIcao,
    this.model,
    this.manufacturer,
    this.type,
    this.engine,
    this.engineCount,
    this.msn,
    this.built,
    this.age,
    this.flag,
    this.lat,
    this.lng,
    this.altitude,
    this.speed,
    this.heading,
    this.squawk,
  });

  bool get hasRoute => depIcao != null && arrIcao != null;
  bool get isDelayed => (depDelayed ?? 0) > 0 || (arrDelayed ?? 0) > 0;

  /// Full aircraft description
  String get aircraftDescription {
    if (model != null) return model!;
    if (manufacturer != null && aircraftIcao != null)
      return '$manufacturer $aircraftIcao';
    return aircraftIcao ?? 'Unknown';
  }

  /// Gate info display
  String? get depGateDisplay {
    if (depTerminal != null && depGate != null)
      return 'T$depTerminal / Gate $depGate';
    if (depGate != null) return 'Gate $depGate';
    if (depTerminal != null) return 'Terminal $depTerminal';
    return null;
  }

  String? get arrGateDisplay {
    final parts = <String>[];
    if (arrTerminal != null) parts.add('T$arrTerminal');
    if (arrGate != null) parts.add('Gate $arrGate');
    if (arrBaggage != null) parts.add('Baggage $arrBaggage');
    return parts.isNotEmpty ? parts.join(' / ') : null;
  }
}
