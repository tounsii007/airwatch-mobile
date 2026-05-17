import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Per-route bucket counters returned by the airwatch-api
/// `/api/routes/{dep}/{arr}` endpoint. The badge hides itself entirely
/// when [observed] is false OR every bucket is 0 — mirrors the
/// web frontend's "no eyesore zero" rule.
class RouteStats {
  final String depIata;
  final String arrIata;
  final bool observed;
  final int todayCount;
  final int weekCount;
  final int monthCount;

  const RouteStats({
    required this.depIata,
    required this.arrIata,
    this.observed = false,
    this.todayCount = 0,
    this.weekCount = 0,
    this.monthCount = 0,
  });

  /// True only when there's something worth displaying. Mirrors the
  /// web's hide-rule: `!observed || (today + week + month == 0)`.
  bool get hasData =>
      observed && (todayCount > 0 || weekCount > 0 || monthCount > 0);

  factory RouteStats.fromMap(Map<String, dynamic> map) {
    int parseInt(Object? raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    return RouteStats(
      depIata: map['depIata']?.toString() ?? '',
      arrIata: map['arrIata']?.toString() ?? '',
      observed: map['observed'] == true,
      todayCount: parseInt(map['todayCount']),
      weekCount: parseInt(map['weekCount']),
      monthCount: parseInt(map['monthCount']),
    );
  }
}

/// Tiny IATA validator that mirrors the api regex
/// (`^[A-Za-z0-9]{3,4}$` per `IATA_PATTERN`). Accepts 3 or 4 chars
/// — both happen in the wild (TLV vs LFPG when ICAO sneaks through).
final _iataRe = RegExp(r'^[A-Za-z0-9]{3,4}$');

/// Thin client for the route-frequency endpoint (api commit 3007502).
class RouteStatsService {
  final Dio _dio;

  RouteStatsService({Dio? dio})
    : _dio =
          dio ?? AppHttpClient.create(receiveTimeout: AppConfig.shortTimeout);

  /// Fetch counters for a `dep → arr` pair. Returns null on missing /
  /// malformed inputs and on any network failure — the badge silently
  /// hides in those cases.
  Future<RouteStats?> load(String? dep, String? arr) async {
    final d = (dep ?? '').toUpperCase();
    final a = (arr ?? '').toUpperCase();
    if (!_iataRe.hasMatch(d) || !_iataRe.hasMatch(a)) return null;
    try {
      final response = await _dio.get<dynamic>(ApiConstants.routeStats(d, a));
      if (response.statusCode != 200) return null;
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;
      return RouteStats.fromMap(body);
    } catch (e, stack) {
      debugPrint('[RouteStats] $d/$a: $e\n$stack');
      return null;
    }
  }
}
