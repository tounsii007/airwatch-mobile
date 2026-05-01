import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/admin/data/services/admin_api_service.dart';

/// Verifies the cookie-parsing logic that `AdminApiService.login`
/// relies on. Pure helper, so we can exercise every edge case without a
/// Dio mock.
void main() {
  group('parseAdminSessionCookie', () {
    test('happy path — returns the session cookie unchanged through "name=value"', () {
      final out = parseAdminSessionCookie(
        location: '/admin/overview',
        setCookieHeaders: const [
          'AIRWATCH_ADMIN_SID=abc123XYZ; Path=/; HttpOnly; SameSite=Strict',
        ],
      );
      expect(out, 'AIRWATCH_ADMIN_SID=abc123XYZ');
    });

    test('preserves cookies with rich values (Base64 / dashes / equals padding)', () {
      // Tomcat session ids contain Base64 characters; SameSite cookies sometimes
      // include "=" inside the value via Base64 padding. The first ";" defines
      // the cookie boundary, so the value before it MUST stay intact verbatim.
      final out = parseAdminSessionCookie(
        location: '/admin/overview',
        setCookieHeaders: const [
          'AIRWATCH_ADMIN_SID=ABCdef-_=/+; Path=/; HttpOnly',
        ],
      );
      expect(out, 'AIRWATCH_ADMIN_SID=ABCdef-_=/+');
    });

    test('rejects when location indicates a login error', () {
      final out = parseAdminSessionCookie(
        location: '/admin/login?error=bad_credentials',
        setCookieHeaders: const ['AIRWATCH_ADMIN_SID=stale; Path=/'],
      );
      expect(out, isNull);
    });

    test('rejects when no AIRWATCH_ADMIN_SID cookie was set', () {
      final out = parseAdminSessionCookie(
        location: '/admin/overview',
        setCookieHeaders: const [
          'JSESSIONID=garbage; Path=/',
          'XSRF-TOKEN=irrelevant; Path=/',
        ],
      );
      expect(out, isNull);
    });

    test('picks AIRWATCH_ADMIN_SID even when other cookies share the response', () {
      final out = parseAdminSessionCookie(
        location: '/admin/overview',
        setCookieHeaders: const [
          'JSESSIONID=garbage; Path=/',
          'AIRWATCH_ADMIN_SID=real-session; Path=/; HttpOnly',
          'XSRF-TOKEN=irrelevant; Path=/',
        ],
      );
      expect(out, 'AIRWATCH_ADMIN_SID=real-session');
    });

    test('empty inputs are safe (no exceptions)', () {
      expect(parseAdminSessionCookie(location: '', setCookieHeaders: const []), isNull);
    });
  });
}
