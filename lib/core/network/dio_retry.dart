import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Shared "GET with jittered exponential backoff" helper for the data
/// services that talk to the airwatch-api proxy endpoints.
///
/// <p>METAR / TAF / NOTAM / Flight-history / Routes / Schedules are all
/// idempotent GETs against a backend that already caches aggressively,
/// so a transient 5xx or network blip is safe to retry. Three total
/// attempts with worst-case ~1s tail latency is the sweet spot —
/// inside every panel's "loading…" budget but still gives enough head-
/// room to ride out a backend rolling-deploy without flipping the UI
/// to "unavailable".
///
/// **Transient vs terminal**
/// * Transient (retried): Dio
///   {connectionTimeout, receiveTimeout, sendTimeout, connectionError},
///   plus 5xx responses (with optional 503 short-circuit for endpoints
///   that use 503 as a circuit-open sentinel — e.g. the NOTAM proxy).
/// * Terminal (not retried): 4xx responses (deterministic — won't fix
///   itself on the next packet) and non-network Dio errors
///   (`badCertificate`, `cancel`).
///
/// **Why a class not a top-level function?**
/// Injection. Tests need to substitute `Random` (for deterministic
/// jitter) and the wait fn (to skip real sleeps). A class lets them
/// pass these in once at construction; a top-level function would
/// force every test setup to thread them through every call site.
///
/// **Why not put it on Dio itself via an interceptor?**
/// Dio interceptors fire on every request including the ones data
/// services explicitly want to fail-fast on (POST / DELETE writes,
/// auth flows). Keeping retry opt-in at the service layer means a
/// future POST endpoint doesn't accidentally inherit retry semantics
/// that could double-charge users.
class DioRetry {
  final Random _rng;

  /// Hook for tests to skip the backoff wait. Production uses
  /// `Future.delayed`.
  final Future<void> Function(Duration) _wait;

  DioRetry({Random? rng, Future<void> Function(Duration)? wait})
    : _rng = rng ?? Random(),
      _wait = wait ?? Future.delayed;

  /// Default ceiling on attempts (1 initial + retries). 3 attempts at
  /// 200ms / 400ms backoff = ≤ ~600ms + jitter before giving up.
  static const int kDefaultMaxAttempts = 3;
  static const Duration kBaseBackoff = Duration(milliseconds: 200);
  static const Duration kBackoffCap = Duration(seconds: 1);

  /// Retry a GET with jittered exponential backoff on transient failure.
  ///
  /// Returns the successful response, or — when the retry budget is
  /// exhausted on transient errors — the LAST non-2xx response if any
  /// reached the server, otherwise null. Callers can inspect
  /// `response?.statusCode` to distinguish "upstream gave us an error
  /// code" from "we never reached upstream at all".
  ///
  /// Pass [treat503Open] when the endpoint uses 503 as a circuit-open
  /// sentinel that the UI wants to render verbatim (NOTAM proxy);
  /// otherwise 503 is treated as transient like any other 5xx.
  Future<Response<dynamic>?> get(
    Dio dio,
    String url, {
    int maxAttempts = kDefaultMaxAttempts,
    bool treat503Open = false,
    String logTag = '[DioRetry]',
  }) async {
    DioException? lastError;
    Response<dynamic>? lastResponse;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await dio.get<dynamic>(url);
        final code = response.statusCode ?? 0;
        // 2xx + 4xx → terminal. 5xx → retry, unless the caller asked us
        // to forward 503 verbatim (circuit-open sentinel).
        if (code < 500 || (treat503Open && code == 503)) return response;
        lastResponse = response; // capture 5xx for the eventual return
      } on DioException catch (e) {
        lastError = e;
        if (!_isTransient(e)) {
          debugPrint('$logTag $url terminal: ${e.message}');
          return null;
        }
      }
      if (attempt == maxAttempts) break;
      await _wait(_jitteredBackoff(attempt));
    }
    if (lastError != null) {
      debugPrint(
        '$logTag $url exhausted ${maxAttempts}x: ${lastError.message}',
      );
    }
    return lastResponse;
  }

  bool _isTransient(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.badResponse => (e.response?.statusCode ?? 0) >= 500,
    _ => false,
  };

  /// `base * 2^(attempt-1)` plus 0–base jitter, capped at [kBackoffCap].
  /// Jitter dodges the thundering-herd problem when the backend is the
  /// thing that just woke up.
  Duration _jitteredBackoff(int attempt) {
    final exp = kBaseBackoff * (1 << (attempt - 1));
    final jitter = Duration(
      milliseconds: _rng.nextInt(kBaseBackoff.inMilliseconds),
    );
    final total = exp + jitter;
    return total > kBackoffCap ? kBackoffCap : total;
  }
}
