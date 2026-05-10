import 'dart:async';

import 'package:airwatch_mobile/features/map/data/datasources/airlabs_flights_datasource.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_websocket_service.dart';
import 'package:airwatch_mobile/features/map/data/datasources/live_flights_repository.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test stubs — extend the real services and override the bits the
/// repository touches. Both `AirlabsFlightsDatasource.stateStream` and
/// `FlightWebSocketService.stateStream / connectionStream` are public
/// getters; we shadow them with controller-backed streams we drive
/// from tests.
class _FakePolling extends AirlabsFlightsDatasource {
  final _controller = StreamController<List<AircraftState>>.broadcast();
  bool startedPolling = false;
  bool stoppedPolling = false;

  @override
  Stream<List<AircraftState>> get stateStream => _controller.stream;

  @override
  void startPolling({Duration interval = const Duration(minutes: 5)}) {
    startedPolling = true;
  }

  @override
  void stopPolling() {
    stoppedPolling = true;
  }

  @override
  void dispose() {
    _controller.close();
  }

  /// Push a frame as if the upstream poll just resolved.
  void emit(List<AircraftState> states) => _controller.add(states);
}

class _FakeWs extends FlightWebSocketService {
  final _frames = StreamController<List<AircraftState>>.broadcast();
  final _conn = StreamController<WsConnectionState>.broadcast();
  WsConnectionState _state = WsConnectionState.idle;
  bool connectCalled = false;

  @override
  Stream<List<AircraftState>> get stateStream => _frames.stream;

  @override
  Stream<WsConnectionState> get connectionStream => _conn.stream;

  @override
  WsConnectionState get currentState => _state;

  @override
  void connect() {
    connectCalled = true;
  }

  @override
  void dispose() {
    _frames.close();
    _conn.close();
  }

  /// Push a connection-state transition + update the cached state in
  /// lockstep — the repo reads `currentState` synchronously when
  /// deciding whether to swallow a poll frame.
  void setConnectionState(WsConnectionState s) {
    _state = s;
    _conn.add(s);
  }

  /// Push a WS frame as if the api just broadcast.
  void emit(List<AircraftState> states) => _frames.add(states);
}

AircraftState _ac(String hex) => AircraftState(icao24: hex);

void main() {
  group('LiveFlightsRepository', () {
    late _FakePolling polling;
    late _FakeWs ws;
    late LiveFlightsRepository repo;
    late List<Map<String, AircraftState>> emissions;
    late StreamSubscription<Map<String, AircraftState>> sub;

    setUp(() {
      polling = _FakePolling();
      ws = _FakeWs();
      repo = LiveFlightsRepository(ws: ws, polling: polling);
      emissions = [];
      sub = repo.stream.listen(emissions.add);
      repo.start();
    });

    tearDown(() async {
      await sub.cancel();
      repo.dispose();
      polling.dispose();
      ws.dispose();
    });

    test('start() kicks off both polling and WS connect', () {
      expect(polling.startedPolling, isTrue);
      expect(ws.connectCalled, isTrue);
    });

    test('cold-start: polling frames flow through until WS delivers',
        () async {
      polling.emit([_ac('aaa111'), _ac('bbb222')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.last.keys, containsAll(['aaa111', 'bbb222']));
    });

    test('once WS delivers, subsequent polling frames are dropped',
        () async {
      // 1. Polling primes the stream.
      polling.emit([_ac('aaa111')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 1);

      // 2. WS connects + delivers — emission count goes up.
      ws.setConnectionState(WsConnectionState.connected);
      await Future<void>.delayed(Duration.zero);
      ws.emit([_ac('zzz999')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 2);
      expect(emissions.last.keys, ['zzz999']);

      // 3. A later polling frame must NOT overwrite the fresher WS feed.
      polling.emit([_ac('old001'), _ac('old002')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 2,
          reason: 'WS already delivered; poll frame should be swallowed');
    });

    test('WS disconnect: polling resumes flowing through immediately',
        () async {
      // Establish the WS-dominant state.
      ws.setConnectionState(WsConnectionState.connected);
      ws.emit([_ac('ws0001')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['ws0001']);

      // WS goes offline — repo flips _wsHasDelivered back to false.
      ws.setConnectionState(WsConnectionState.offline);
      await Future<void>.delayed(Duration.zero);

      // A polling frame after offline DOES land now.
      polling.emit([_ac('pol001')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['pol001']);
    });

    test('WS connecting (handshake in flight): polling still flows',
        () async {
      ws.setConnectionState(WsConnectionState.connecting);
      polling.emit([_ac('pol001')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['pol001']);
    });

    test('lastFrame snapshot tracks the most recent emission', () async {
      polling.emit([_ac('aaa111')]);
      await Future<void>.delayed(Duration.zero);
      expect(repo.lastFrame.keys, ['aaa111']);

      ws.setConnectionState(WsConnectionState.connected);
      ws.emit([_ac('bbb222'), _ac('ccc333')]);
      await Future<void>.delayed(Duration.zero);
      expect(repo.lastFrame.keys, containsAll(['bbb222', 'ccc333']));
    });

    test('aircraft with empty icao24 are dropped from the map', () async {
      polling.emit([_ac(''), _ac('abc123')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys.length, 1);
      expect(emissions.last.containsKey('abc123'), isTrue);
    });

    test('reconnect cycle: WS down then up again flows correctly',
        () async {
      // First cycle: WS connects + delivers.
      ws.setConnectionState(WsConnectionState.connected);
      ws.emit([_ac('ws0001')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['ws0001']);

      // Disconnect — polling should resume.
      ws.setConnectionState(WsConnectionState.offline);
      await Future<void>.delayed(Duration.zero);
      polling.emit([_ac('pol001')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['pol001']);

      // Reconnect — fresh WS frame takes over again.
      ws.setConnectionState(WsConnectionState.connecting);
      ws.setConnectionState(WsConnectionState.connected);
      ws.emit([_ac('ws0002')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['ws0002']);

      // Polling frame post-reconnect is again swallowed.
      polling.emit([_ac('stale')]);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.keys, ['ws0002']);
    });

    test('dispose stops polling and closes the controller', () async {
      repo.dispose();
      // Re-listening to a closed stream throws — caller can hold a
      // reference without it leaking observers.
      expect(polling.stoppedPolling, isTrue);
      // Listening to the now-closed stream throws (broadcast streams
      // don't have a "isClosed" public flag, so we just check the
      // poll-stop side-effect).
    });
  });
}
