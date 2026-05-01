import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/aircraft_state.dart';
import 'flight_providers.dart';

/// Lightweight interpolation — only computes for aircraft currently
/// displayed on screen (managed by the marker layer).
/// Updates at 5fps (200ms) which is smooth enough without being expensive.
class InterpolationState {
  final Map<String, LatLng> positions;
  final DateTime lastApiUpdate;

  const InterpolationState({
    this.positions = const {},
    required this.lastApiUpdate,
  });
}

class InterpolationNotifier extends Notifier<InterpolationState> {
  Timer? _timer;
  Map<String, AircraftState> _aircraft = {};

  @override
  InterpolationState build() {
    ref.listen(filteredAircraftProvider, (_, next) {
      _aircraft = next;
      state = InterpolationState(
        positions: state.positions,
        lastApiUpdate: DateTime.now(),
      );
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    ref.onDispose(() => _timer?.cancel());

    return InterpolationState(lastApiUpdate: DateTime.now());
  }

  void _tick() {
    if (_aircraft.isEmpty) return;

    final elapsed = DateTime.now().difference(state.lastApiUpdate).inMilliseconds;
    // Interpolate over 5 minutes (300,000ms) = the update interval
    final t = (elapsed / 300000).clamp(0.0, 1.0);
    if (t >= 1.0) return; // No more interpolation needed

    final positions = <String, LatLng>{};
    for (final entry in _aircraft.entries) {
      final ac = entry.value;
      if (!ac.hasPosition || ac.previousPosition == null) continue;
      if (ac.onGround) continue; // Don't interpolate grounded aircraft

      // Velocity-based projection instead of simple lerp
      // Use heading + speed to project where the aircraft should be NOW
      if (ac.velocity != null && ac.velocity! > 20 && ac.trueTrack != null) {
        // Distance traveled since last update (m/s * seconds elapsed)
        final distM = ac.velocity! * (elapsed / 1000);
        final distDeg = distM / 111320; // rough m→degrees conversion

        final hdgRad = ac.trueTrack! * 3.14159265 / 180;
        final lat = ac.latitude! + distDeg * _cos(hdgRad);
        final lng = ac.longitude! + distDeg * _sin(hdgRad) / _cos(ac.latitude! * 3.14159265 / 180);

        positions[entry.key] = LatLng(lat, lng);
      }
    }

    if (positions.isNotEmpty) {
      state = InterpolationState(
        positions: positions,
        lastApiUpdate: state.lastApiUpdate,
      );
    }
  }

  double _cos(double x) => _fastTrig(x, true);
  double _sin(double x) => _fastTrig(x, false);

  // Fast trig approximation to avoid dart:math overhead at 5fps * 800 aircraft
  double _fastTrig(double x, bool isCos) {
    if (isCos) x += 1.5707963;
    x %= 6.2831853;
    if (x < 0) x += 6.2831853;
    final sign = x > 3.14159265 ? -1.0 : 1.0;
    if (x > 3.14159265) x -= 3.14159265;
    final x2 = x * x;
    return sign * (x - x2 * x / 6 + x2 * x2 * x / 120);
  }
}

final interpolationProvider =
    NotifierProvider<InterpolationNotifier, InterpolationState>(
        InterpolationNotifier.new);
