import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/certificate_pinning.dart';

/// Factory for the shared [Dio] instance every data-layer service
/// consumes.
///
/// <p>The mobile app now talks exclusively to `airwatch-api` — see
/// [AppConfig#apiBaseUrl]. This client is pre-configured to:
/// <ul>
///   <li>point at the backend by default (so callers can issue relative paths);</li>
///   <li>fail fast on timeouts ([AppConfig#apiTimeout] for connect,
///       [AppConfig#longTimeout] for receive);</li>
///   <li>accept any HTTP status &lt; 500 so service callers can branch on
///       404 / 429 without Dio throwing;</li>
///   <li>retry once on transient failures (timeout / connection-reset /
///       5xx) — keeps the UX smooth on flaky cellular links without
///       masking real server errors;</li>
///   <li>log requests + response codes in debug mode only, so release
///       builds stay quiet and GDPR-clean.</li>
/// </ul>
class AppHttpClient {
  const AppHttpClient._();

  static Dio create({
    Duration connectTimeout = AppConfig.apiTimeout,
    Duration receiveTimeout = AppConfig.longTimeout,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        // Let services branch on status code instead of receiving an
        // exception for every 404 / 429 / 401.
        validateStatus: (status) => status != null && status < 500,
        headers: const {'Accept': 'application/json'},
      ),
    );

    // Apply SPKI/cert pinning if API_CERT_PINS is set at build time.
    // No-op in debug mode and when no pins are configured.
    CertificatePinning.apply(dio);

    dio.interceptors.add(_RetryInterceptor(dio));
    if (kDebugMode) dio.interceptors.add(_DebugLogInterceptor());

    return dio;
  }
}

/// Retries a request once on network-level failures or 5xx responses.
///
/// <p>We deliberately retry only once — a dead backend, an expired DNS cache,
/// or a 502 LB blip all recover within a second; anything permanent is handed
/// back to the caller after the second attempt so the UI can show an error.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const Duration _backoff = Duration(milliseconds: 400);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final attempt = (req.extra['attempt'] as int?) ?? 0;
    if (attempt >= 1 || !_isRetryable(err)) {
      return handler.next(err);
    }
    await Future<void>.delayed(_backoff);
    req.extra['attempt'] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(req);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(
        e is DioException ? e : DioException(requestOptions: req, error: e),
      );
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return code >= 500 && code < 600;
      case DioExceptionType.unknown:
        return err.error is SocketException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return false;
    }
  }
}

/// Minimal request/response logger — active only in debug builds.
///
/// <p>We intentionally do NOT log request bodies or headers here: that's where
/// auth tokens, passwords, or personal data live. Only the method, path, and
/// the resulting status code are printed — enough to spot broken routes
/// without leaking sensitive values into adb-logs.
class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[api] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint('[api] ← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode?.toString() ?? err.type.name;
    debugPrint('[api] ✖ $code ${err.requestOptions.uri}');
    handler.next(err);
  }
}
