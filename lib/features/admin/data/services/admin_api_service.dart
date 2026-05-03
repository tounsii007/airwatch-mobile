import 'package:dio/dio.dart';

import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// Pure helper — extract the `AIRWATCH_ADMIN_SID` cookie out of the
/// `POST /admin/login` response. Returns null if the backend signals
/// a bad login (via the `error=` query flag on the redirect target)
/// or if no matching `Set-Cookie` header is present.
///
/// <p>Top-level + public so unit tests can drive it directly without
/// constructing the whole [AdminApiService] or mocking Dio.
String? parseAdminSessionCookie({
  required String location,
  required Iterable<String> setCookieHeaders,
}) {
  if (location.contains('error=')) return null;
  for (final header in setCookieHeaders) {
    if (header.startsWith('AIRWATCH_ADMIN_SID=')) {
      // Drop attributes (Path=, HttpOnly, Secure, …) — only the name=value
      // pair is what we replay on subsequent requests.
      return header.split(';').first;
    }
  }
  return null;
}

/// HTTP client for the airwatch-api admin surface.
///
/// <p>Wraps the shared [AppHttpClient]: every request goes through
/// the same retry-on-5xx interceptor and the same debug logger as the rest
/// of the app — so a transient backend hiccup heals automatically and a
/// stale `AIRWATCH_ADMIN_SID` cookie surfaces uniformly through the
/// service tree.
///
/// <h3>Cookie handling</h3>
/// <p>The admin endpoint at `/admin/login` returns a
/// `302 Set-Cookie: AIRWATCH_ADMIN_SID=...` response. We capture the
/// cookie on first login and replay it on every subsequent request via the
/// per-call `Cookie` header. We <em>don't</em> use a global Dio
/// cookie jar because the public flight-feed Dio instance must remain
/// cookie-free (no fingerprinting on anonymous traffic).
///
/// <h3>Read-only by design</h3>
/// <p>Mobile only consumes `/admin/api/overview`. Mutating endpoints
/// (cache clear, force-logout, run-job) live on the web dashboard and are
/// blocked server-side for the recommended VIEWER role anyway.
class AdminApiService {
  AdminApiService({Dio? dio}) : _dio = dio ?? AppHttpClient.create();

  final Dio _dio;
  String? _sessionCookie;

  bool get isSignedIn => _sessionCookie != null;

  /// POST /admin/login as a form submission. On success the backend returns
  /// 302 → `/admin/overview` with `Set-Cookie: AIRWATCH_ADMIN_SID=...`;
  /// the cookie is harvested and replayed on every subsequent request.
  ///
  /// @return `true` on success, `false` on bad credentials.
  Future<bool> login(String username, String password, {String? totp}) async {
    try {
      final form = {
        'username': username,
        'password': password,
        if (totp != null && totp.isNotEmpty) 'totp': totp,
      };
      final r = await _dio.post<dynamic>(
        '/admin/login',
        data: form,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // Don't follow the post-login 302 — we need the Set-Cookie header
          // from the redirect response itself.
          followRedirects: false,
          // Accept 302 explicitly. Anything ≥ 500 still triggers the retry
          // interceptor in AppHttpClient.
          validateStatus: (s) => s != null && (s == 302 || s < 400),
        ),
      );
      // Login filter returns 302 with a fresh session cookie on success,
      // 302 back to /admin/login?error=... on failure.
      final location = r.headers.value('location') ?? '';
      final cookies = r.headers.map['set-cookie'] ?? const <String>[];
      final cookie = parseAdminSessionCookie(
        location: location,
        setCookieHeaders: cookies,
      );
      if (cookie == null) return false;
      _sessionCookie = cookie;
      return true;
    } on DioException {
      return false;
    }
  }

  /// GET /admin/api/overview — live metrics snapshot. Returns null if the
  /// session is missing or the server rejects us (timeout, role changed).
  Future<Map<String, dynamic>?> fetchOverview() async {
    final cookie = _sessionCookie;
    if (cookie == null) return null;
    try {
      final r = await _dio.get<dynamic>(
        '/admin/api/overview',
        options: Options(
          headers: {'Cookie': cookie},
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (r.statusCode != 200) return null;
      if (r.data is! Map) return null;
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException {
      return null;
    }
  }

  /// Pure helper — extract the `AIRWATCH_ADMIN_SID` cookie from the
  /// login response, or return null if the response indicates a failed login.
  ///
  /// <p>Public + top-level so unit tests can drive it with synthetic header
  /// maps without standing up a Dio mock. Two distinct failure modes:
  /// <ul>
  ///   <li>The `Location` header carries an `error=` flag → the
  ///       backend deliberately rejected the credentials.</li>
  ///   <li>No matching `Set-Cookie` entry → the backend's session
  ///       configuration changed; treat as failure rather than guess.</li>
  /// </ul>
  /// Both cases yield `null`; callers should surface "bad credentials".

  /// Best-effort logout. Forgets the cookie locally regardless of network
  /// outcome — an offline logout is still a logout from the user's POV.
  Future<void> logout() async {
    final c = _sessionCookie;
    _sessionCookie = null;
    if (c == null) return;
    try {
      await _dio.post<dynamic>(
        '/admin/logout',
        options: Options(
          headers: {'Cookie': c},
          followRedirects: false,
          validateStatus: (s) => s != null && s < 400,
        ),
      );
    } on DioException {
      // Cookie is already cleared locally; server cleanup is advisory.
    }
  }
}
