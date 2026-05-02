// ignore_for_file: avoid_print, unused_local_variable

import 'dart:io';
import 'dart:convert';

/// AirWatch CORS Proxy — lightweight, Airlabs-only.
///
/// Routes:
///   /airlabs/*  → airlabs.co/api/v9/*  (flight data, schedules, airports, routes)
///   /weather/*  → open-meteo.com        (airport weather, free, no key)
///   /hexdb/*    → hexdb.io              (aircraft metadata)
///   /photo/*    → planespotters.net     (aircraft photo URLs)
///   /img/*      → image proxy           (CORS bypass for photo images)
///   /lookup     → aggregated endpoint   (all data in 1 call)
///
/// Env vars:
///   AIRLABS_KEY  — Airlabs API key (required)
///   ENABLE_HTTPS — set to "true" for HTTPS on port 8443
///
/// Usage:
///   $env:AIRLABS_KEY="your-key"
///   dart run proxy/bin/proxy_server.dart
void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final httpsPort = int.tryParse(Platform.environment['HTTPS_PORT'] ?? '8443') ?? 8443;
  final airlabsKey = Platform.environment['AIRLABS_KEY'] ?? '57d9c6c9-b0bf-4738-adf8-b5bc2af59b40';
  final enableHttps = Platform.environment['ENABLE_HTTPS'] == 'true';
  final bindHost = Platform.environment['PROXY_HOST'] ?? 'localhost';
  final allowedOrigins = _parseAllowedOrigins(
    Platform.environment['ALLOWED_ORIGINS'],
  );

  // In-memory caches
  _lookupCache = {};
  _notFoundPaths = {};

  // Optional HTTPS
  HttpServer? httpsServer;
  if (enableHttps) {
    try {
      final certPath = Platform.environment['TLS_CERT_PATH'];
      final keyPath = Platform.environment['TLS_KEY_PATH'];
      if (certPath != null && keyPath != null) {
        final cert = File(certPath);
        final key = File(keyPath);
        final ctx = SecurityContext()
          ..useCertificateChain(cert.path)
          ..usePrivateKey(key.path);
        httpsServer = await HttpServer.bindSecure(
          _resolveBindAddress(bindHost),
          httpsPort,
          ctx,
        );
        _writeLog('HTTPS on https://$bindHost:$httpsPort');
      } else {
        _writeLog('HTTPS disabled: set TLS_CERT_PATH and TLS_KEY_PATH to enable it.');
      }
    } catch (e) {
      _writeLog('HTTPS failed: $e');
    }
  }

  final server = await HttpServer.bind(_resolveBindAddress(bindHost), port);

  _writeLog('AirWatch Proxy on http://$bindHost:$port');
  print('  /airlabs/* → airlabs.co ${airlabsKey.isEmpty ? "(NO KEY!)" : "(configured)"}');
  print('  /weather/* → open-meteo.com (free)');
  print('  /hexdb/*   → hexdb.io');
  print('  /photo/*   → planespotters.net');
  print('  /img/*     → image proxy');
  print('  /turbulence → aviationweather.gov (SIGMET)');
  print('  /lookup    → aggregated');

  if (airlabsKey.isEmpty) {
    print('\n  ⚠ WARNING: No AIRLABS_KEY set! Flights will not load.');
    print('  Set: \$env:AIRLABS_KEY="your-key"');
  }

  print('\nReady.\n');

  // Start the 5-minute stats timer
  _counterStartTime = DateTime.now();
  _startStatsTimer();

  // Request handler
  void Function(HttpRequest) handler;
  handler = (request) async {
    try {
    final corsApplied = _applyCorsHeaders(
      request,
      request.response,
      allowedOrigins,
    );

    if (request.method == 'OPTIONS') {
      if (!corsApplied) {
        request.response.statusCode = HttpStatus.forbidden;
      } else {
        request.response.statusCode = HttpStatus.noContent;
      }
      await request.response.close();
      return;
    }

    if (!corsApplied) {
      _send(request, HttpStatus.forbidden, '{"error":"Origin not allowed"}');
      return;
    }

    if (airlabsKey.isEmpty && (request.uri.path.startsWith('/airlabs/') || request.uri.path == '/lookup')) {
      _send(request, HttpStatus.serviceUnavailable, '{"error":"AIRLABS_KEY is not configured"}');
      return;
    }

    if (!_isAllowedPath(request.uri.path)) {
      _send(request, HttpStatus.notFound, '{"error":"Unknown route"}');
      return;
    }

    final path = request.uri.toString();

    // ── Cache: skip known 404s ──
    if (_notFoundPaths.contains(path)) {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"route":null,"cached":true}');
      await request.response.close();
      return;
    }

    // ── Aggregated lookup ──
    if (path.startsWith('/lookup')) {
      await _handleLookup(request, path, airlabsKey);
      return;
    }

    // ── Route to target ──
    String targetUrl;

    if (path.startsWith('/weather/')) {
      final parts = path.replaceFirst('/weather/', '').split('/');
      if (parts.length >= 2) {
        targetUrl = 'https://api.open-meteo.com/v1/forecast?latitude=${parts[0]}&longitude=${parts[1]}'
            '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,'
            'weather_code,cloud_cover,is_day&timezone=auto';
      } else {
        _send(request, 400, '{"error":"Format: /weather/LAT/LON"}');
        return;
      }
    } else if (path.startsWith('/hexdb/')) {
      targetUrl = 'https://hexdb.io/api/v1/aircraft/${path.replaceFirst('/hexdb/', '')}';
    } else if (path.startsWith('/airlabs/')) {
      final rest = path.replaceFirst('/airlabs/', '');
      final sep = rest.contains('?') ? '&' : '?';
      targetUrl = 'https://airlabs.co/api/v9/$rest${sep}api_key=$airlabsKey';
      _incrementAirlabsCounter();
    } else if (path.startsWith('/photo/')) {
      targetUrl = 'https://api.planespotters.net/pub/photos/hex/${path.replaceFirst('/photo/', '')}';
    } else if (path.startsWith('/turbulence')) {
      targetUrl = 'https://aviationweather.gov/api/data/airsigmet?format=json';
    } else if (path.startsWith('/img/')) {
      // Binary image proxy for CORS bypass
      final imageUrl = Uri.decodeComponent(path.replaceFirst('/img/', ''));
      try {
        final client = HttpClient();
        final imgReq = await client.getUrl(Uri.parse(imageUrl));
        final imgRes = await imgReq.close();
        request.response.statusCode = imgRes.statusCode;
        final ct = imgRes.headers.contentType;
        if (ct != null) request.response.headers.contentType = ct;
        await imgRes.pipe(request.response);
        client.close();
        return;
      } catch (_) {
        _send(request, 502, 'Image proxy error');
        return;
      }
    } else {
      _send(request, 404, '{"error":"Unknown route: $path"}');
      return;
    }

    // ── Forward request ──
    final ts = DateTime.now().toIso8601String().substring(11, 19);

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final proxyReq = await client.getUrl(Uri.parse(targetUrl));
      proxyReq.headers.set('Accept', 'application/json');
      proxyReq.headers.set('User-Agent', 'AirWatch/2.0');

      final proxyRes = await proxyReq.close();
      final body = await proxyRes.transform(utf8.decoder).join();

      // Cache 404s for routes/tracks to avoid repeated failures
      if (proxyRes.statusCode == 404 && (path.contains('/routes') || path.contains('/photo'))) {
        _notFoundPaths.add(path);
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"route":null,"status":404}');
        _log(ts, path, 404);
        client.close();
        await request.response.close();
        return;
      }

      // Check for Airlabs API errors in the response body
      if (path.startsWith('/airlabs/') && proxyRes.statusCode == 200) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map && parsed.containsKey('error')) {
            final errCode = parsed['error']['code'] ?? 'unknown';
            final errMsg = parsed['error']['message'] ?? 'Unknown error';
            if (errCode == 'month_limit_exceeded') {
              print('[$ts] ⚠ AIRLABS MONTHLY LIMIT EXCEEDED — $errMsg');
              print('[$ts] ⚠ No more API calls until next month. Create a new key at https://airlabs.co');
            } else if (errCode == 'hour_limit_exceeded' || errCode == 'minute_limit_exceeded') {
              print('[$ts] ⚠ AIRLABS RATE LIMITED — $errMsg');
            } else if (errCode.toString().contains('key')) {
              print('[$ts] ⚠ AIRLABS API KEY ERROR — $errMsg');
            } else {
              print('[$ts] ⚠ AIRLABS ERROR [$errCode] — $errMsg');
            }
          }
        } catch (_) {
          // Not JSON or parse error — ignore
        }
      }

      request.response.statusCode = proxyRes.statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(body);
      _log(ts, path, proxyRes.statusCode);
      client.close();
    } catch (e) {
      print('[$ts] ERR $path → $e');
      _send(request, 502, jsonEncode({'error': e.toString()}));
    }

    await request.response.close();
    } catch (e) {
      // Prevent proxy crash on response errors (e.g., headers already sent)
      _writeLog('Request error: $e');
    }
  };

  server.listen(handler);
  httpsServer?.listen(handler);
}

// ═══════════════════ HELPERS ═══════════════════

void _writeLog(String message) {
  stdout.writeln(message);
}

InternetAddress _resolveBindAddress(String bindHost) {
  if (bindHost == 'localhost') {
    return InternetAddress.loopbackIPv4;
  }

  return InternetAddress(bindHost);
}

Set<String> _parseAllowedOrigins(String? rawOrigins) {
  final configuredOrigins =
      rawOrigins?.split(',').map((origin) => origin.trim()).where((origin) => origin.isNotEmpty);

  return {
    ...?configuredOrigins,
    // Allow all localhost ports for development
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:8080',
    'http://127.0.0.1:8080',
    'http://localhost:8888',
    'http://127.0.0.1:8888',
    'https://localhost:8443',
    'https://127.0.0.1:8443',
  };
}

bool _applyCorsHeaders(
  HttpRequest request,
  HttpResponse response,
  Set<String> allowedOrigins,
) {
  final origin = request.headers.value('origin');
  if (origin == null) return true;
  // Allow listed origins + any local network IP (192.168.x.x, 10.x.x.x)
  final isAllowed = allowedOrigins.contains(origin) || _isLocalNetworkOrigin(origin);
  if (!isAllowed) return false;

  response.headers
    ..set('Access-Control-Allow-Origin', origin)
    ..set('Vary', 'Origin')
    ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type');
  return true;
}

bool _isLocalNetworkOrigin(String origin) {
  try {
    final uri = Uri.parse(origin);
    final host = uri.host;
    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.16.') ||
        host.startsWith('172.17.') ||
        host.startsWith('172.18.') ||
        host.startsWith('172.19.') ||
        host.startsWith('172.2') ||
        host.startsWith('172.3');
  } catch (_) {
    return false;
  }
}

bool _isAllowedPath(String path) {
  return path.startsWith('/weather/') ||
      path.startsWith('/hexdb/') ||
      path.startsWith('/airlabs/') ||
      path.startsWith('/photo/') ||
      path.startsWith('/img/') ||
      path.startsWith('/turbulence') ||
      path.startsWith('/lookup');
}

void _send(HttpRequest req, int status, String body) {
  req.response.statusCode = status;
  req.response.headers.contentType = ContentType.json;
  req.response.write(body);
  req.response.close();
}

void _log(String ts, String path, int status) {
  final remaining = _airlabsMonthlyLimit - _airlabsRequestCount;
  if (path.contains('/flights') && status == 200) {
    print('[$ts] ✈ flights loaded [$_airlabsRequestCount/$_airlabsMonthlyLimit used, $remaining left]');
  } else if (path.startsWith('/airlabs/')) {
    final short = path.length > 50 ? '${path.substring(0, 50)}...' : path;
    print('[$ts] $status $short [$_airlabsRequestCount/$_airlabsMonthlyLimit]');
  } else {
    final short = path.length > 60 ? '${path.substring(0, 60)}...' : path;
    print('[$ts] $status $short');
  }
}

// ═══════════════════ REQUEST COUNTER ═══════════════════

const int _airlabsMonthlyLimit = 1000;
int _airlabsRequestCount = 5; // Starting at 5 (already sent before)
DateTime _counterStartTime = DateTime.now();

void _incrementAirlabsCounter() {
  _airlabsRequestCount++;
}

void _startStatsTimer() {
  Future.doWhile(() async {
    await Future.delayed(const Duration(minutes: 5));
    final remaining = _airlabsMonthlyLimit - _airlabsRequestCount;
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    final elapsed = DateTime.now().difference(_counterStartTime);
    final hours = elapsed.inHours;
    final mins = elapsed.inMinutes % 60;
    print('');
    print('[$ts] ╔══════════════════════════════════════╗');
    print('[$ts] ║  📊 AIRLABS API USAGE STATS          ║');
    print('[$ts] ╠══════════════════════════════════════╣');
    print('[$ts] ║  Requests sent:  $_airlabsRequestCount / $_airlabsMonthlyLimit');
    print('[$ts] ║  Remaining:      $remaining');
    print('[$ts] ║  Uptime:         ${hours}h ${mins}m');
    if (remaining <= 100) {
      print('[$ts] ║  ⚠ WARNING: Low remaining requests!');
    }
    if (remaining <= 0) {
      print('[$ts] ║  🛑 LIMIT REACHED — API calls blocked');
    }
    print('[$ts] ╚══════════════════════════════════════╝');
    print('');
    return true; // keep running
  });
}

// ═══════════════════ CACHES ═══════════════════

var _lookupCache = <String, Map<String, dynamic>>{};
var _notFoundPaths = <String>{};

// ═══════════════════ AGGREGATED LOOKUP ═══════════════════

/// /lookup?icao24=ABC&callsign=DLH123&airline_iata=LH
/// Fetches from multiple APIs in parallel and returns one combined response.
Future<void> _handleLookup(HttpRequest request, String path, String airlabsKey) async {
  final params = request.uri.queryParameters;
  final icao24 = params['icao24'] ?? '';
  final callsign = params['callsign'] ?? '';
  final cacheKey = '${icao24}_$callsign';
  final ts = DateTime.now().toIso8601String().substring(11, 19);

  // Check cache
  if (_lookupCache.containsKey(cacheKey)) {
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(_lookupCache[cacheKey]));
    await request.response.close();
    return;
  }

  print('[$ts] LOOKUP $callsign ($icao24)');

  // Count Airlabs calls from lookup (2 Airlabs calls per lookup: /flight + /routes)
  _incrementAirlabsCounter();
  _incrementAirlabsCounter();

  // Parallel fetches
  final futures = await Future.wait([
    // 1. Airlabs /flight — route + status + delays + aircraft details
    _fetchJson('https://airlabs.co/api/v9/flight?flight_icao=$callsign&api_key=$airlabsKey'),
    // 2. hexdb — aircraft metadata (type, registration)
    icao24.isNotEmpty ? _fetchJson('https://hexdb.io/api/v1/aircraft/$icao24') : Future.value(),
    // 3. Planespotters — photo
    icao24.isNotEmpty ? _fetchJson('https://api.planespotters.net/pub/photos/hex/${icao24.toUpperCase()}') : Future.value(),
    // 4. Airlabs /routes — fallback static route
    _fetchJson('https://airlabs.co/api/v9/routes?flight_icao=$callsign&api_key=$airlabsKey'),
  ]);

  final airlabsFlight = futures[0];
  final hexdb = futures[1];
  final photos = futures[2];
  final routeDb = futures[3];

  // Extract flight data from Airlabs
  Map<String, dynamic>? flightData;
  if (airlabsFlight != null) {
    final resp = airlabsFlight['response'];
    if (resp is Map && resp.isNotEmpty) {
      flightData = Map<String, dynamic>.from(resp);
    }
  }

  // Extract route from routes DB
  Map<String, dynamic>? routeData;
  if (routeDb != null) {
    final resp = routeDb['response'];
    if (resp is List && resp.isNotEmpty) {
      routeData = Map<String, dynamic>.from(resp.first as Map);
    }
  }

  // Extract photo URL
  String? photoUrl;
  if (photos != null) {
    final photoList = photos['photos'] as List?;
    if (photoList != null && photoList.isNotEmpty) {
      final thumb = (photoList.first as Map)['thumbnail_large'] as Map?;
      photoUrl = thumb?['src']?.toString();
    }
  }

  final result = <String, dynamic>{
    'flight': flightData,
    'aircraft': hexdb,
    'photo_url': photoUrl,
    'route_db': routeData,
  };

  _lookupCache[cacheKey] = result;

  request.response.statusCode = 200;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(result));
  await request.response.close();
}

/// Fetch JSON from URL, return null on error
Future<Map<String, dynamic>?> _fetchJson(String url) async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('Accept', 'application/json');
    req.headers.set('User-Agent', 'AirWatch/2.0');
    final res = await req.close();
    if (res.statusCode == 200) {
      final body = await res.transform(utf8.decoder).join();
      client.close();
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    client.close();
    return null;
  } catch (_) {
    return null;
  }
}
