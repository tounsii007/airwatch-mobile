import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-export the shared weather-emoji helper so existing consumers
// (`getWeatherEmoji` callers that import this file) don't have to
// switch their imports. New code should import the canonical helper
// directly from `core/utils/weather_emoji.dart`.
export 'package:airwatch_mobile/core/utils/weather_emoji.dart'
    show getWeatherEmoji;

/// Module-scope airport-weather cache that the imperative airport-label
/// layer can read synchronously while still firing real network calls
/// on demand.
///
/// <p>Mirrors airwatch-web's `useAirportWeather.ts` (commit 1e1bfb7) —
/// same TTL, same throttle, same emoji map, so a user moving between
/// platforms sees the same icon for the same airport at the same time.
///
/// <h3>Why module-scope?</h3>
/// The airport-label render path rebuilds on every map pan/zoom. Storing
/// the cache inside a [State] or provider would either rebuild it on
/// every map gesture (terrible) or force every render to walk through
/// async machinery (also terrible). A pair of plain top-level maps lets
/// the per-frame label build stay synchronous and side-effect-free.

class _CacheEntry {
  final int weatherCode;
  final bool isDay;
  final DateTime fetchedAt;
  const _CacheEntry(this.weatherCode, this.isDay, this.fetchedAt);
}

/// Cache TTL — Open-Meteo refreshes its forecast roughly every 15 min;
/// 30 min keeps the staleness reasonable while halving the call volume.
const _ttl = Duration(minutes: 30);

/// Global gap between consecutive Open-Meteo calls. A fast pan over
/// Europe can put 200+ airports on the map; firing all of them at once
/// would open 200 sockets, get rate-limited, and starve the visible
/// labels of any actual data. 250 ms staggers the bursts so the user
/// sees emoji land progressively rather than all-or-nothing.
const _minGap = Duration(milliseconds: 250);

final Map<String, _CacheEntry> _cache = {};
final Set<String> _inFlight = {};
DateTime _lastFire = DateTime.fromMillisecondsSinceEpoch(0);

/// Bumps every time a cache entry lands. The map's airport-marker
/// rebuild watches this to repaint when the first weather fetches
/// resolve, without us having to wire a stream end-to-end. Riverpod 3
/// dropped `StateProvider` so we use a tiny [Notifier] instead.
class AirportWeatherTickNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final airportWeatherTickProvider =
    NotifierProvider<AirportWeatherTickNotifier, int>(
  AirportWeatherTickNotifier.new,
);

/// Synchronous read from the in-memory cache. Returns null until the
/// first fetch for [iata] lands (or after TTL expiry).
({int code, bool isDay})? getCachedAirportWeather(String iata) {
  final entry = _cache[iata];
  if (entry == null) return null;
  if (DateTime.now().difference(entry.fetchedAt) > _ttl) {
    _cache.remove(iata);
    return null;
  }
  return (code: entry.weatherCode, isDay: entry.isDay);
}

/// Fire-and-forget prefetch. Safe inside a render loop because:
///   * the [_inFlight] set deduplicates calls for the same IATA,
///   * the [_minGap] throttle prevents bursts during fast pans.
/// Calls [onLanded] (if provided) the moment the cache landed; the
/// label layer uses this to bump the tick provider.
void prefetchAirportWeather(
  String iata,
  double lat,
  double lon, {
  bool enabled = true,
  void Function()? onLanded,
}) {
  if (!enabled) return;
  if (_cache.containsKey(iata)) {
    final cached = _cache[iata]!;
    if (DateTime.now().difference(cached.fetchedAt) <= _ttl) return;
  }
  if (_inFlight.contains(iata)) return;

  // Global rate-limit gate — schedule the next call _minGap after the
  // last one so a pan flood doesn't open all sockets simultaneously.
  final now = DateTime.now();
  final delay = _lastFire.add(_minGap).isAfter(now)
      ? _lastFire.add(_minGap).difference(now)
      : Duration.zero;
  _lastFire = now.add(delay);
  _inFlight.add(iata);

  Future<void>.delayed(delay, () async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final r = await dio.get<dynamic>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'weather_code,is_day',
        },
      );
      if (r.statusCode == 200 && r.data is Map) {
        final current = (r.data as Map)['current'];
        if (current is Map) {
          final code = (current['weather_code'] as num?)?.toInt();
          final isDay = (current['is_day'] as num?)?.toInt() == 1;
          if (code != null) {
            _cache[iata] = _CacheEntry(code, isDay, DateTime.now());
            onLanded?.call();
          }
        }
      }
    } catch (_) {
      // Silent fail — the next pan / TTL expiry will retry.
    } finally {
      _inFlight.remove(iata);
    }
  });
}

/// Test hook — drops every entry. Production callers don't need this.
void debugResetAirportWeatherCache() {
  _cache.clear();
  _inFlight.clear();
  _lastFire = DateTime.fromMillisecondsSinceEpoch(0);
}
