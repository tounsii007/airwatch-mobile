import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/features/map/data/datasources/airlabs_flights_datasource.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_websocket_service.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Hybrid live-flights stream — WebSocket first, Airlabs polling
/// as fallback.
///
/// <h3>Why hybrid</h3>
/// The airwatch-api WebSocket pushes a fresh full feed every 60s
/// (vs the 5-min direct Airlabs poll), and supports per-flight
/// subscriptions for bandwidth-friendly tracking on cellular. But
/// the WS isn't always available — network blips, captive portals
/// on coffee-shop Wi-Fi, or the api being temporarily down. The
/// repository falls back to direct Airlabs polling in those cases
/// so the map never goes blank.
///
/// <h3>Switching strategy</h3>
///   * Cold start: kick off polling immediately (data while WS
///     connects), open the WS in parallel.
///   * Once WS receives its first frame: stop polling.
///   * If WS goes offline (connection dropped, server restart,
///     long client-side suspend): resume polling within seconds.
///   * Reconnect attempts run inside FlightWebSocketService with
///     exponential backoff — we just listen to its state stream.
///
/// <h3>Output</h3>
/// One [stream] of `Map<String, AircraftState>` keyed by icao24.
/// Callers can `ref.watch` this provider just like the old
/// pure-polling stream.
class LiveFlightsRepository {
  final FlightWebSocketService _ws;
  final AirlabsFlightsDatasource _polling;

  final _controller = StreamController<Map<String, AircraftState>>.broadcast();
  StreamSubscription<List<AircraftState>>? _wsSub;
  StreamSubscription<List<AircraftState>>? _pollSub;
  StreamSubscription<WsConnectionState>? _connSub;

  /// Whether a WS frame has ever landed in this session. Used to
  /// decide whether to keep polling running as a backup or stop it.
  bool _wsHasDelivered = false;

  /// Snapshot of the last successful frame, regardless of source.
  /// Lets a freshly-subscribing consumer get an immediate value
  /// instead of waiting for the next push/poll.
  Map<String, AircraftState> _lastFrame = const {};

  /// Public stream — fan-out broadcast so multiple ref.watch'ers
  /// share one upstream connection.
  Stream<Map<String, AircraftState>> get stream => _controller.stream;

  Map<String, AircraftState> get lastFrame => _lastFrame;

  LiveFlightsRepository({
    required FlightWebSocketService ws,
    required AirlabsFlightsDatasource polling,
  }) : _ws = ws,
       _polling = polling;

  /// Start both transports. Idempotent — safe to call from a
  /// Provider's build() body.
  void start() {
    if (_wsSub != null) return;

    // 1. Polling first (instant data while WS handshakes).
    _polling.startPolling();
    _pollSub = _polling.stateStream.listen((list) {
      // Drop polled frames once the WS is delivering — the WS feed
      // is fresher (60s) and we don't want to overwrite it with the
      // 5-min old polling snapshot.
      if (_wsHasDelivered && _ws.currentState == WsConnectionState.connected) {
        return;
      }
      _emit(list);
    });

    // 2. WS subscription — full feed (no per-flight filter).
    _ws.connect();
    _wsSub = _ws.stateStream.listen((list) {
      _wsHasDelivered = true;
      _emit(list);
    });

    // 3. Connection state — flips polling on/off as WS goes
    // up/down. We deliberately don't `stopPolling` immediately
    // when WS connects because the WS may not have a frame yet
    // (the api pushes every 60s); polling provides cover until
    // the first real WS frame lands (handled by the early-return
    // in the polling listener above).
    _connSub = _ws.connectionStream.listen((state) {
      switch (state) {
        case WsConnectionState.connected:
          // Nothing to do — the early-return on the poll listener
          // will swallow new poll frames once WS has delivered.
          break;
        case WsConnectionState.offline:
          // WS dropped. Reset the flag so polling frames flow
          // again until the WS reconnects + delivers a fresh one.
          _wsHasDelivered = false;
          // Make sure polling is alive — it might have stopped
          // earlier on the user's pause/resume cycle.
          _polling.startPolling();
          break;
        case WsConnectionState.idle:
        case WsConnectionState.connecting:
          break;
      }
    });
  }

  void _emit(List<AircraftState> list) {
    final next = <String, AircraftState>{};
    for (final ac in list) {
      if (ac.icao24.isNotEmpty) next[ac.icao24] = ac;
    }
    _lastFrame = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  /// Tear down both transports. After dispose the repository is
  /// unusable — the Provider auto-recreates on next watch.
  void dispose() {
    _wsSub?.cancel();
    _pollSub?.cancel();
    _connSub?.cancel();
    _polling.stopPolling();
    // We don't dispose the WS service here — it's a separate
    // singleton Provider that other features (FlightDetailsPanel
    // per-flight subscribe) may still need. Its own Provider's
    // onDispose handles teardown when its ref-count drops to 0.
    _controller.close();
    debugPrint('[LiveFlightsRepository] disposed');
  }
}

/// Singleton-style provider so multiple screens can share one
/// repository instance instead of stacking N WS connections + poll
/// timers per device.
final liveFlightsRepositoryProvider = Provider<LiveFlightsRepository>((ref) {
  final ws = ref.watch(flightWebSocketProvider);
  final polling = AirlabsFlightsDatasource();
  ref.onDispose(polling.dispose);
  final repo = LiveFlightsRepository(ws: ws, polling: polling);
  repo.start();
  ref.onDispose(repo.dispose);
  return repo;
});
