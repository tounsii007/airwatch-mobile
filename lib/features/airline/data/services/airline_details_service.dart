import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/features/airline/data/models/airline_flight_info.dart';

/// Service for loading airline detail data from Airlabs API.
class AirlineDetailsService {
  final Dio _dio;

  AirlineDetailsService({Dio? dio})
      : _dio = dio ??
            AppHttpClient.create(
              
            );

  /// Fetch all flights for an airline — combines live + schedule data.
  ///
  /// Strategy:
  /// 1. /flights?airline_icao=XXX — live/active flights (en-route + ground)
  /// 2. /schedules?airline_iata=XX — today's full schedule (includes landed)
  ///
  /// NOTE: Each call counts against the monthly API limit.
  /// Free Plan: 1,000 calls/month total.
  /// Starter Plan (9.90 USD): 10,000 calls/month.
  /// Developer Plan (49 USD): 25,000 calls/month.
  Future<List<AirlineFlightInfo>> fetchActiveFlights(
    String airlineIcao, {
    String? airlineIata,
  }) async {
    final seen = <String>{};
    final result = <AirlineFlightInfo>[];

    // 1. Live flights via /flights endpoint
    //    Returns currently active flights (en-route + on ground).
    //    NOTE: Free Plan — counts as 1 API call.
    try {
      final url = AppConfig.flightsUrl('airline_icao=$airlineIcao');
      debugPrint('[AirlineDetails] Fetching live flights for $airlineIcao...');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final flights = (response.data as Map)[ApiJsonKeys.response] as List?;
        if (flights != null) {
          for (final f in flights) {
            if (f is! Map) continue;
            final flight = AirlineFlightInfo.fromMap(f);
            final key = flight.displayCode;
            if (key.isNotEmpty && seen.add(key)) {
              result.add(flight);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AirlineDetails] Live flights error: $e');
    }

    // 2. Schedule data via /schedules endpoint — includes landed flights
    //    Returns today's full schedule (scheduled, en-route, landed).
    //    NOTE: Free Plan — counts as 1 additional API call. Limited to 50 results.
    //    TODO: With Starter Plan, limit increases to 200 results.
    final iata = airlineIata ?? _icaoToIata(airlineIcao);
    if (iata != null && iata.isNotEmpty) {
      try {
        final url = AppConfig.scheduleByAirlineUrl(airlineIata: iata);
        debugPrint('[AirlineDetails] Fetching schedule for $iata...');
        final response = await _dio.get(url);

        if (response.statusCode == 200 && response.data is Map) {
          final schedules = (response.data as Map)[ApiJsonKeys.response] as List?;
          if (schedules != null) {
            for (final s in schedules) {
              if (s is! Map) continue;
              final flight = AirlineFlightInfo.fromMap(s);
              final key = flight.displayCode;
              if (key.isNotEmpty && seen.add(key)) {
                result.add(flight);
              }
            }
          }
        }
      } catch (e) {
        // NOTE: May fail if Free Plan monthly limit (1,000 calls) is reached.
        debugPrint('[AirlineDetails] Schedule error: $e');
      }
    }

    // Sort: airborne first, then landed, then scheduled — within each group by flight code
    result.sort((a, b) {
      final aPriority = a.isAirborne ? 0 : (a.status == 'landed' ? 1 : 2);
      final bPriority = b.isAirborne ? 0 : (b.status == 'landed' ? 1 : 2);
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return a.displayCode.compareTo(b.displayCode);
    });

    debugPrint('[AirlineDetails] Total: ${result.length} flights for $airlineIcao');
    return result;
  }

  /// Try to resolve ICAO to IATA for schedule lookups.
  /// Returns null if not found.
  String? _icaoToIata(String icao) {
    try {
      final airline = FlightCodeFormatter.resolveAirline('${icao}000');
      return airline?.iata;
    } catch (_) {
      return null;
    }
  }
}
