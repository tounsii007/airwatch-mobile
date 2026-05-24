import 'dart:async';
import 'dart:math';

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
///
/// **Retry policy**
/// METAR/TAF/NOTAM fetches are idempotent GETs against a backend that
/// already caches aggressively, so a transient 5xx / network blip is
/// safe to retry. We give each fetch up to 3 total attempts with
/// jittered exponential backoff (base 200ms, ×2, ×4, capped at 1s).
/// Anything 4xx (or the 503-specific "upstream open" sentinel for
/// NOTAM) short-circuits to "unavailable" immediately — those aren't
/// going to fix themselves on the next packet.
class AviationWeatherService {
  final Dio _dio;
  final Random _rng;

  /// Hook for tests to drop the backoff wait. Production paths use the
  /// real `Future.delayed`.
  final Future<void> Function(Duration) _wait;

  AviationWeatherService({Dio? dio, Random? rng, Future<void> Function(Duration)? wait})
    : _dio = dio ?? AppHttpClient.create(receiveTimeout: AppConfig.shortTimeout),
      _rng = rng ?? Random(),
      _wait = wait ?? Future.delayed;

  /// Maximum attempts (including the first) for a transient failure.
  /// Three attempts × ~1s worst-case backoff = ~3s total tail latency,
  /// well inside the panel's "loading" state budget.
  static const int _maxAttempts = 3;
  static const Duration _backoffBase = Duration(milliseconds: 200);
  static const Duration _backoffCap = Duration(seconds: 1);

  /// Retry a GET with jittered exponential backoff on transient failure.
  ///
  /// "Transient" = `DioExceptionType.{connectionTimeout, receiveTimeout,
  /// sendTimeout, connectionError}` or a 5xx response (but NOT the
  /// NOTAM-specific 503 — that's the backend's circuit-open sentinel
  /// and callers want it surfaced verbatim, so they pass `treat503Open`
  /// to short-circuit).
  ///
  /// Returns the successful response, or the LAST failure response so
  /// the caller can still inspect [Response.statusCode] for things like
  /// the 503 sentinel.
  Future<Response<dynamic>?> _getWithRetry(
    String url, {
    bool treat503Open = false,
  }) async {
    DioException? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _dio.get<dynamic>(url);
        final code = response.statusCode ?? 0;
        // 2xx + 4xx → terminal. 5xx → retry, unless caller wants 503
        // forwarded for the "upstream open" UI state.
        if (code < 500 || (treat503Open && code == 503)) return response;
        // 5xx falls through to the backoff path.
      } on DioException catch (e) {
        lastError = e;
        if (!_isTransient(e)) {
          // Non-retryable — surface immediately, callers map to null.
          debugPrint('[AviationWeather] $url terminal: ${e.message}');
          return null;
        }
      }
      if (attempt == _maxAttempts) break;
      await _wait(_jitteredBackoff(attempt));
    }
    if (lastError != null) {
      debugPrint(
        '[AviationWeather] $url exhausted ${_maxAttempts}x: ${lastError.message}',
      );
    }
    return null;
  }

  bool _isTransient(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.badResponse =>
      (e.response?.statusCode ?? 0) >= 500,
    _ => false,
  };

  /// `base * 2^(attempt-1)` plus 0–base jitter, capped at [_backoffCap].
  /// Jitter dodges the thundering-herd problem when the backend is the
  /// thing that just woke up.
  Duration _jitteredBackoff(int attempt) {
    final exp = _backoffBase * (1 << (attempt - 1));
    final jitter = Duration(
      milliseconds: _rng.nextInt(_backoffBase.inMilliseconds),
    );
    final total = exp + jitter;
    return total > _backoffCap ? _backoffCap : total;
  }

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
      final response = await _getWithRetry(
        ApiConstants.notam(icao),
        treat503Open: true,
      );
      if (response == null) {
        return const NotamResult(networkError: true);
      }
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
  /// what unavailable means. Uses [_getWithRetry] so a transient 5xx
  /// or network blip gets up to 3 attempts before giving up.
  Future<String?> _fetchOne(String url, String rawKey) async {
    final response = await _getWithRetry(url);
    if (response == null) return null;
    if (response.statusCode != 200) return null;
    final body = response.data;
    if (body is! List || body.isEmpty) return null;
    final first = body.first;
    if (first is! Map) return null;
    final raw = first[rawKey];
    return raw is String && raw.isNotEmpty ? raw : null;
  }
}
