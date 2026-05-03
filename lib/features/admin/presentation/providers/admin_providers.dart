import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/features/admin/data/services/admin_api_service.dart';

/// Process-wide singleton for the admin API service. Kept alive across
/// screen navigations so the session cookie survives route transitions —
/// users don't want to re-login when popping back from the metrics screen.
final adminApiProvider = Provider<AdminApiService>((ref) => AdminApiService());

/// Boolean flag mirror of `AdminApiService.isSignedIn`. A
/// `NotifierProvider` so screens can react to login/logout without
/// polling the service.
final adminSignedInProvider = NotifierProvider<AdminSignedInNotifier, bool>(
  AdminSignedInNotifier.new,
);

class AdminSignedInNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(adminApiProvider).isSignedIn;

  Future<bool> login(String user, String pw, {String? totp}) async {
    final ok = await ref.read(adminApiProvider).login(user, pw, totp: totp);
    if (ok) state = true;
    return ok;
  }

  Future<void> logout() async {
    await ref.read(adminApiProvider).logout();
    state = false;
  }
}

/// Periodically polls `/admin/api/overview` while the user is on the
/// metrics screen. Emits `null` when unauthenticated or on transient
/// errors — the UI renders a graceful "not connected" state instead of
/// tearing the stream down.
final adminOverviewStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
      final service = ref.read(adminApiProvider);
      while (true) {
        if (!service.isSignedIn) {
          yield null;
        } else {
          yield await service.fetchOverview();
        }
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    });
