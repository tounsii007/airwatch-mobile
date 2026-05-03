/// Base exception for all AirWatch app errors.
/// All custom exceptions extend this for unified error handling.
sealed class AirWatchException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AirWatchException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() =>
      '[$runtimeType] $message${code != null ? " ($code)" : ""}';
}

// ═══════════════════ NETWORK ═══════════════════

/// API call failed (timeout, no internet, DNS failure)
class NetworkException extends AirWatchException {
  final int? statusCode;
  final String? url;

  const NetworkException({
    required super.message,
    this.statusCode,
    this.url,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  bool get isTimeout => code == 'timeout';
  bool get isNoInternet => code == 'no_internet';
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
}

/// API returned data but in unexpected format
class ApiParseException extends AirWatchException {
  final String? endpoint;
  final String? rawResponse;

  const ApiParseException({
    required super.message,
    this.endpoint,
    this.rawResponse,
    super.originalError,
    super.stackTrace,
  });
}

/// Rate limit exceeded (Airlabs 1000/month, OpenSky 4000/day)
class RateLimitException extends AirWatchException {
  final String apiName;
  final Duration? retryAfter;

  const RateLimitException({
    required this.apiName,
    this.retryAfter,
    super.code = 'rate_limited',
    super.message = 'API rate limit exceeded',
  });
}

// ═══════════════════ DATA ═══════════════════

/// Aircraft data not found for given ICAO24 or callsign
class AircraftNotFoundException extends AirWatchException {
  final String? icao24;
  final String? callsign;

  const AircraftNotFoundException({
    this.icao24,
    this.callsign,
    super.message = 'Aircraft not found',
  });
}

/// Airport data not found
class AirportNotFoundException extends AirWatchException {
  final String? icaoCode;
  final String? iataCode;

  const AirportNotFoundException({
    this.icaoCode,
    this.iataCode,
    super.message = 'Airport not found',
  });
}

/// Route data not available for this flight
class RouteNotFoundException extends AirWatchException {
  final String callsign;

  const RouteNotFoundException({
    required this.callsign,
    super.message = 'Route not found',
  });
}

// ═══════════════════ CACHE ═══════════════════

/// Cache read/write error
class CacheException extends AirWatchException {
  const CacheException({required super.message, super.originalError});
}

// ═══════════════════ LOCATION ═══════════════════

/// GPS/Location permission denied or unavailable
class LocationException extends AirWatchException {
  final bool permissionDenied;

  const LocationException({
    required super.message,
    this.permissionDenied = false,
  });
}

// ═══════════════════ MEDIA ═══════════════════

/// Aircraft photo not available
class PhotoNotFoundException extends AirWatchException {
  final String icao24;

  const PhotoNotFoundException({
    required this.icao24,
    super.message = 'Aircraft photo not found',
  });
}

/// Camera not available (for AR mode)
class CameraException extends AirWatchException {
  const CameraException({required super.message, super.originalError});
}

// ═══════════════════ HELPER ═══════════════════

/// Convert any exception to an AirWatchException
AirWatchException wrapException(dynamic error, [StackTrace? stack]) {
  if (error is AirWatchException) return error;

  final msg = error.toString();

  // Detect common error patterns
  if (msg.contains('SocketException') || msg.contains('Connection refused')) {
    return NetworkException(
      message: 'No connection to server. Is the proxy running?',
      code: 'no_internet',
      originalError: error,
      stackTrace: stack,
    );
  }

  if (msg.contains('TimeoutException') || msg.contains('timed out')) {
    return NetworkException(
      message: 'Request timed out',
      code: 'timeout',
      originalError: error,
      stackTrace: stack,
    );
  }

  if (msg.contains('429') || msg.contains('Too many requests')) {
    return const RateLimitException(apiName: 'unknown');
  }

  if (msg.contains('FormatException') || msg.contains('type')) {
    return ApiParseException(
      message: 'Failed to parse API response',
      originalError: error,
      stackTrace: stack,
    );
  }

  return NetworkException(
    message: msg.length > 200 ? '${msg.substring(0, 200)}...' : msg,
    originalError: error,
    stackTrace: stack,
  );
}
