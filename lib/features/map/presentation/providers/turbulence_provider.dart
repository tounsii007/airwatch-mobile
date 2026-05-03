import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/features/map/data/datasources/turbulence_datasource.dart';
import 'package:airwatch_mobile/features/map/domain/turbulence/parse_sigmet.dart';

/// Toggle for the turbulence overlay (off by default).
///
/// <p>Controlled from the map controls panel; mirrors the web
/// frontend's `showTurbulence` setting in `settingsStore`.
class ShowTurbulenceNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
  void toggle() => state = !state;
}

final showTurbulenceProvider = NotifierProvider<ShowTurbulenceNotifier, bool>(
  ShowTurbulenceNotifier.new,
);

/// Long-lived datasource (Dio client kept warm).
final turbulenceDatasourceProvider = Provider<TurbulenceDatasource>((ref) {
  return TurbulenceDatasource();
});

/// Live SIGMET feed — refreshes every 5 minutes while the toggle is on.
/// AWC publishes new SIGMETs every ~5–10 min so polling at 5 min gives
/// near-real-time data without overloading the backend cache.
final turbulenceZonesProvider =
    StreamProvider.autoDispose<List<TurbulenceZone>>((ref) async* {
      final enabled = ref.watch(showTurbulenceProvider);
      if (!enabled) {
        yield const [];
        return;
      }
      final ds = ref.watch(turbulenceDatasourceProvider);
      while (true) {
        final zones = await ds.fetchZones();
        yield zones;
        await Future<void>.delayed(const Duration(minutes: 5));
      }
    });
