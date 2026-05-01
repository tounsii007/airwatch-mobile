import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/features/map/domain/turbulence/parse_sigmet.dart';

/// Lightweight datasource for SIGMET turbulence data. Talks to the
/// backend-proxied `/turbulence` endpoint (the web frontend does the
/// same — single source of truth for the AWC SIGMET feed).
class TurbulenceDatasource {
  final Dio _dio;

  TurbulenceDatasource({Dio? dio})
      : _dio = dio ??
            AppHttpClient.create(
              connectTimeout: AppConfig.shortTimeout,
              receiveTimeout: AppConfig.shortTimeout,
            );

  /// Fetch the latest SIGMET response and parse it. Returns an empty
  /// list on any error — the overlay degrades gracefully when the
  /// service is offline.
  Future<List<TurbulenceZone>> fetchZones() async {
    try {
      final r = await _dio.get<dynamic>('${AppConfig.apiBaseUrl}/turbulence');
      if (r.statusCode != 200) return const [];
      final data = r.data is String
          ? jsonDecode(r.data as String)
          : r.data;
      return parseSigmetResponse(data);
    } on DioException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
