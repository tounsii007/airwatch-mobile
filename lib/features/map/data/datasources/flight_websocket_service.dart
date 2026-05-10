import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// Per-flight WebSocket client for the airwatch-api `/ws/flights`
/// endpoint (api commit b1df5f1).
///
/// <h3>Why a separate service from AirlabsFlightsDatasource</h3>
/// AirlabsFlightsDatasource polls the global feed every 5 minutes —
/// fine for the map's "show every plane in the world" mode but wasteful
/// when the user is tracking a single flight. The api WS endpoint
/// supports per-session `subscribe` / `unsubscribe` frames that filter
/// the broadcast to specific icao24 codes:
///
/// <pre>
///   { "type":"subscribe",   "icao24":["abc123","def456"], "replace":true }
///   { "type":"unsubscribe", "icao24":[]                                 }
/// </pre>
///
/// A subscribed session receives ~200 bytes per push (one tracked
/// aircraft) instead of the full ~50 KB feed — a 250× bandwidth
/// reduction that matters on cellular and saves battery via fewer
/// radio wake-ups.
///
/// <h3>Resilience</h3>
/// The client auto-reconnects with exponential backoff (1s → 30s)
/// on disconnect, mirrors the subscription set across reconnects,
/// and surfaces connection state through [stateStream] so the UI
/// can render a "connecting / live / offline" pill. Back-pressure
/// on the server side is handled by the api itself — the mobile
/// client only needs to drain frames it receives.
class FlightWebSocketService {
  /// Live aircraft snapshots — emits the most recent decoded payload
  /// each time the server pushes a frame. Empty list means "no
  /// matching aircraft right now" (subscribed flights might be on
  /// the ground or out of coverage).
  Stream<List<AircraftState>> get stateStream => _stateController.stream;

  /// Connection state — useful for the UI to show a connecting /
  /// live / offline indicator.
  Stream<WsConnectionState> get connectionStream => _connState.stream;

  /// Currently subscribed icao24 codes (read-only view).
  Set<String> get subscriptions => Set<String>.unmodifiable(_subscriptions);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;

  /// Subscribed icao24 codes — kept across reconnects so the server
  /// state matches the client's intent automatically.
  final Set<String> _subscriptions = <String>{};

  final _stateController =
      StreamController<List<AircraftState>>.broadcast();
  final _connState =
      StreamController<WsConnectionState>.broadcast();

  WsConnectionState _currentState = WsConnectionState.idle;
  WsConnectionState get currentState => _currentState;

  /// Open the WS connection. Idempotent — calling again on an open
  /// connection is a no-op.
  void connect() {
    if (_disposed) return;
    if (_channel != null) return;
    _setState(WsConnectionState.connecting);
    try {
      final url = ApiConstants.wsFlights;
      _channel = WebSocketChannel.connect(Uri.parse(url));
    } catch (e) {
      debugPrint('[FlightWS] connect failed: $e');
      _scheduleReconnect();
      return;
    }
    _channelSub = _channel!.stream.listen(
      _onMessage,
      onError: (Object e, StackTrace s) {
        debugPrint('[FlightWS] error: $e');
        _onClosed();
      },
      onDone: () {
        debugPrint('[FlightWS] closed');
        _onClosed();
      },
      cancelOnError: true,
    );
    _setState(WsConnectionState.connected);
    _reconnectAttempt = 0;
    // Re-establish any subscription set the caller had registered
    // before the (re)connect — server-side filter state is lost on
    // disconnect.
    if (_subscriptions.isNotEmpty) _sendSubscribe(replace: true);
  }

  /// Add icao24 codes to the per-session filter. Codes are normalised
  /// to lowercase and deduped client-side. The server caps at 200 codes
  /// per session — additional codes silently fail server-side; we don't
  /// pre-validate that here.
  void subscribe(Iterable<String> icao24Codes) {
    final added = <String>{};
    for (final raw in icao24Codes) {
      final code = raw.trim().toLowerCase();
      if (code.length != 6) continue;
      if (_subscriptions.add(code)) added.add(code);
    }
    if (added.isEmpty) return;
    _sendSubscribe(codes: added);
  }

  /// Remove icao24 codes from the per-session filter. Empty iterable
  /// clears the filter entirely (back to the unfiltered broadcast).
  void unsubscribe(Iterable<String> icao24Codes) {
    final list = icao24Codes
        .map((c) => c.trim().toLowerCase())
        .where(_subscriptions.contains)
        .toSet();
    for (final c in list) {
      _subscriptions.remove(c);
    }
    _sendUnsubscribe(list);
  }

  /// Replace the entire subscription set in one round-trip — handy when
  /// the user navigates between screens that track different flights.
  void replaceSubscriptions(Iterable<String> icao24Codes) {
    _subscriptions
      ..clear()
      ..addAll(icao24Codes
          .map((c) => c.trim().toLowerCase())
          .where((c) => c.length == 6));
    _sendSubscribe(replace: true);
  }

  void _sendSubscribe({Iterable<String>? codes, bool replace = false}) {
    final ch = _channel;
    if (ch == null) return;
    final payload = {
      'type': 'subscribe',
      'icao24': (codes ?? _subscriptions).toList(),
      'replace': replace,
    };
    try {
      ch.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[FlightWS] send subscribe failed: $e');
    }
  }

  void _sendUnsubscribe(Iterable<String> codes) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode({
        'type': 'unsubscribe',
        'icao24': codes.toList(),
      }));
    } catch (e) {
      debugPrint('[FlightWS] send unsubscribe failed: $e');
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      // Subscription ACKs / status frames don't carry a `data` array —
      // ignore them here (the server replies after every subscribe).
      if (decoded['type'] != 'flights') return;
      final data = decoded['data'];
      if (data is! List) return;
      final states = data
          .whereType<Map<String, dynamic>>()
          .map(_decodeAircraft)
          .where((a) => a.icao24.isNotEmpty)
          .toList(growable: false);
      _stateController.add(states);
    } catch (e) {
      debugPrint('[FlightWS] parse failed: $e');
    }
  }

  /// Decode a single aircraft from the api's WS payload. Field names
  /// match the api's [com.airwatch.model.Aircraft] DTO. We map the
  /// subset the mobile client uses; missing fields fall through to
  /// the model's defaults.
  AircraftState _decodeAircraft(Map<String, dynamic> m) {
    final lat = (m['latitude'] ?? m['lat']) as num?;
    final lon = (m['longitude'] ?? m['lng']) as num?;
    return AircraftState(
      icao24: (m['icao24'] ?? m['hex'] ?? '').toString().toLowerCase(),
      callsign: m['callsign']?.toString(),
      originCountry: m['originCountry']?.toString(),
      latitude: lat?.toDouble(),
      longitude: lon?.toDouble(),
      baroAltitude: (m['baroAltitude'] ?? m['altitude']) is num
          ? (m['baroAltitude'] ?? m['altitude'] as num).toDouble()
          : null,
      onGround: m['onGround'] == true,
      velocity: (m['velocity'] ?? m['speed']) is num
          ? (m['velocity'] ?? m['speed'] as num).toDouble()
          : null,
      trueTrack: (m['trueTrack'] ?? m['heading']) is num
          ? (m['trueTrack'] ?? m['heading'] as num).toDouble()
          : null,
      verticalRate: (m['verticalRate']) is num
          ? (m['verticalRate'] as num).toDouble()
          : null,
      squawk: m['squawk']?.toString(),
      category: m['category'] is num ? (m['category'] as num).toInt() : 0,
    );
  }

  void _onClosed() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
    if (_disposed) return;
    _setState(WsConnectionState.offline);
    _scheduleReconnect();
  }

  /// Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (clamped). Resets
  /// to 0 on a successful connect.
  void _scheduleReconnect() {
    if (_disposed) return;
    final delaySeconds = (1 << _reconnectAttempt).clamp(1, 30);
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(0, 5);
    debugPrint('[FlightWS] reconnect in ${delaySeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), connect);
  }

  void _setState(WsConnectionState s) {
    if (s == _currentState) return;
    _currentState = s;
    _connState.add(s);
  }

  /// Tear down the connection + timers. After dispose the service is
  /// unusable — create a new instance to reconnect.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channelSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _stateController.close();
    _connState.close();
  }
}

/// Connection state surfaced through [FlightWebSocketService.connectionStream].
enum WsConnectionState {
  /// Never connected, or after dispose.
  idle,

  /// connect() called, awaiting the upgrade.
  connecting,

  /// Upgraded — receiving frames.
  connected,

  /// Lost connection — auto-reconnect scheduled.
  offline,
}

/// Singleton-style provider so multiple screens (favourites watcher,
/// flight-details panel, geofence alert listener) can share one
/// connection instead of stacking N WS sessions per device.
final flightWebSocketProvider = Provider<FlightWebSocketService>((ref) {
  final service = FlightWebSocketService();
  ref.onDispose(service.dispose);
  return service;
});
