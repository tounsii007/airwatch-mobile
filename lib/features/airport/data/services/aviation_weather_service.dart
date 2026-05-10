import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Outcome of a METAR + TAF fetch — either the raw strings (which the
/// caller passes through `decodeMetar` / `decodeTaf`), an "upstream
/// unavailable" state when both fail, or an offline/network state.
///
/// <p>Each field is independently nullable so a partial result still
/// surfaces the bit we managed to fetch — the operator sees METAR
/// "right now" even if the 6-hourly TAF fetch flaked out.
class MetarTafResult {
  final String? metarRaw;
  final String? tafRaw;
  final bool upstreamUnavailable;
  final bool networkError;

  const MetarTafResult({
    this.metarRaw,
    this.tafRaw,
    this.upstreamUnavailable = false,
    this.networkError = false,
  });

  bool get hasAnything => metarRaw != null || tafRaw != null;
}

/// Outcome of a NOTAM fetch — either the parsed list, an empty list
/// for "no NOTAMs reported", or one of the failure flags so the UI
/// can render a "unavailable" placeholder rather than a generic error.
class NotamResult {
  final List<NotamRecord> items;
  final bool upstreamUnavailable;
  final bool networkError;

  const NotamResult({
    this.items = const [],
    this.upstreamUnavailable = false,
    this.networkError = false,
  });

  bool get isEmpty => items.isEmpty;
}

/// Mobile mirror of the web frontend's `ParsedNotam`. Tolerates several
/// upstream-shape aliases (`notamNumber` / `number` / `id`,
/// `text` / `message` / `rawText`, `effectiveStart` / `startDate`, …)
/// so swapping upstream providers via `airwatch.proxy.notam-base-url`
/// on the backend doesn't require a mobile change.
class NotamRecord {
  final String id;
  final String text;
  final String? classification;
  final String? start;
  final String? end;

  const NotamRecord({
    required this.id,
    required this.text,
    this.classification,
    this.start,
    this.end,
  });

  factory NotamRecord.fromMap(Map<String, dynamic> raw) {
    String? readString(List<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    return NotamRecord(
      id: readString(['notamNumber', 'number', 'id']) ?? '?',
      text: readString(['text', 'message', 'rawText']) ?? '',
      classification: readString(['classification']),
      start: readString(['effectiveStart', 'startDate']),
      end: readString(['effectiveEnd', 'endDate']),
    );
  }
}

/// Thin client for the airwatch-api `/api/proxy/{metar,taf,notam}/{ICAO}`
/// endpoints. The backend handles caching + circuit breaking + fallback
/// — this service is intentionally simple. All errors map to the
/// `*Unavailable` flags so the UI stays on its happy path.
class AviationWeatherService {
  final Dio _dio;

  AviationWeatherService({Dio? dio})
      : _dio = dio ??
            AppHttpClient.create(receiveTimeout: AppConfig.shortTimeout);

  /// Fetch METAR + TAF for an ICAO airport in parallel. ICAO is a
  /// 4-letter code (EDDF, KSFO, LFPG); the backend regex enforces this
  /// and returns 400 for anything else, so we don't double-validate.
  Future<MetarTafResult> loadMetarTaf(String icao) async {
    if (icao.length != 4) {
      return const MetarTafResult();
    }
    try {
      final results = await Future.wait([
        _fetchOne(ApiConstants.metar(icao), 'rawOb'),
        _fetchOne(ApiConstants.taf(icao), 'rawTAF'),
      ]);
      final String? metarRaw = results[0];
      final String? tafRaw = results[1];
      // When both upstreams are 503 we surface a single "unavailable"
      // state instead of two empty rows.
      if (metarRaw == null && tafRaw == null) {
        return const MetarTafResult(upstreamUnavailable: true);
      }
      return MetarTafResult(metarRaw: metarRaw, tafRaw: tafRaw);
    } catch (e, stack) {
      debugPrint('[AviationWeather] metar/taf $icao: $e\n$stack');
      return const MetarTafResult(networkError: true);
    }
  }

  /// Fetch the NOTAM list for an ICAO airport. The backend's fallback
  /// returns an empty array (`[]`) on circuit-open, so an empty list
  /// is ambiguous between "no NOTAMs" and "upstream open" — we treat
  /// it as "no NOTAMs reported" and let the UI render the empty state
  /// (matches the web frontend's behaviour).
  Future<NotamResult> loadNotams(String icao) async {
    if (icao.length != 4) {
      return const NotamResult();
    }
    try {
      final response = await _dio.get<dynamic>(ApiConstants.notam(icao));
      if (response.statusCode == 503) {
        return const NotamResult(upstreamUnavailable: true);
      }
      if (response.statusCode != 200) {
        return const NotamResult();
      }
      final body = response.data;
      // Different upstreams ship different envelopes — accept the bare
      // array, `{notams: [...]}` and `{items: [...]}` so a backend env
      // swap to a non-aviationweather provider doesn't require a
      // client release.
      final List<dynamic> list = switch (body) {
        final List<dynamic> arr => arr,
        final Map<String, dynamic> map => switch (map) {
            {'notams': final List<dynamic> arr} => arr,
            {'items': final List<dynamic> arr} => arr,
            _ => const [],
          },
        _ => const [],
      };

      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(NotamRecord.fromMap)
          .where((n) => n.text.isNotEmpty)
          .toList(growable: false);

      return NotamResult(items: parsed);
    } catch (e, stack) {
      debugPrint('[AviationWeather] notam $icao: $e\n$stack');
      return const NotamResult(networkError: true);
    }
  }

  /// Fetch a single METAR/TAF endpoint and pull the raw observation
  /// out of the upstream payload. The aviationweather.gov shape is
  /// `[{rawOb: "..."}]` for METAR and `[{rawTAF: "..."}]` for TAF.
  /// Returns null on any non-2xx or empty payload — caller decides
  /// what unavailable means.
  Future<String?> _fetchOne(String url, String rawKey) async {
    try {
      final response = await _dio.get<dynamic>(url);
      if (response.statusCode != 200) return null;
      final body = response.data;
      if (body is! List || body.isEmpty) return null;
      final first = body.first;
      if (first is! Map) return null;
      final raw = first[rawKey];
      return raw is String && raw.isNotEmpty ? raw : null;
    } on DioException catch (e) {
      debugPrint('[AviationWeather] $url: ${e.message}');
      return null;
    }
  }
}
