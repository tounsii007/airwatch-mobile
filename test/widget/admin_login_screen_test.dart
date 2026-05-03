import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/admin/data/services/admin_api_service.dart';
import 'package:airwatch_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:airwatch_mobile/features/admin/presentation/screens/admin_login_screen.dart';

/// Widget tests for [AdminLoginScreen]. The real `login()`
/// method goes through Dio — we override the [adminApiProvider]
/// with a fake whose `login()` we can set per-test, so the form
/// renders, validates and routes deterministically.
class _FakeAdminApi implements AdminApiService {
  _FakeAdminApi({required this.willSucceed});
  final bool willSucceed;

  bool _signedIn = false;
  String? lastUser, lastPw, lastTotp;

  @override
  bool get isSignedIn => _signedIn;

  @override
  Future<bool> login(String username, String password, {String? totp}) async {
    lastUser = username;
    lastPw = password;
    lastTotp = totp;
    _signedIn = willSucceed;
    return willSucceed;
  }

  @override
  Future<Map<String, dynamic>?> fetchOverview() async => null;

  @override
  Future<void> logout() async => _signedIn = false;
}

Widget _harness({required Widget child, required AdminApiService api}) =>
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: MaterialApp(home: child),
    );

void main() {
  group('AdminLoginScreen', () {
    testWidgets('renders the username + password + TOTP fields', (
      tester,
    ) async {
      final api = _FakeAdminApi(willSucceed: false);
      await tester.pumpWidget(
        _harness(child: const AdminLoginScreen(), api: api),
      );
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('TOTP (optional)'), findsWidgets);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('shows an error banner when login fails', (tester) async {
      final api = _FakeAdminApi(willSucceed: false);
      await tester.pumpWidget(
        _harness(child: const AdminLoginScreen(), api: api),
      );

      await tester.enterText(find.byType(TextField).at(0), 'viewer');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-pw');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid username or password'), findsOneWidget);
      expect(api.lastUser, 'viewer');
      expect(api.lastPw, 'wrong-pw');
    });

    testWidgets('submits TOTP when the user enters one', (tester) async {
      final api = _FakeAdminApi(willSucceed: false);
      await tester.pumpWidget(
        _harness(child: const AdminLoginScreen(), api: api),
      );

      await tester.enterText(find.byType(TextField).at(0), 'viewer');
      await tester.enterText(find.byType(TextField).at(1), 'pw');
      await tester.enterText(find.byType(TextField).at(2), '123456');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(api.lastTotp, '123456');
    });
  });
}
