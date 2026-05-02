import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One entry in the user's recently-visited airports list. The
/// schema mirrors the web frontend's `recentAirportsStore` so a
/// future cross-device sync can replay either side's history.
class RecentAirport {
  final String iata;
  final String? city;
  final String? country;
  final DateTime visitedAt;

  RecentAirport({
    required this.iata,
    this.city,
    this.country,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'iata': iata,
        'city': city,
        'country': country,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory RecentAirport.fromJson(Map<String, dynamic> j) => RecentAirport(
        iata: j['iata'] as String,
        city: j['city'] as String?,
        country: j['country'] as String?,
        visitedAt: DateTime.tryParse(j['visitedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// SharedPreferences-backed Riverpod store of recent airport visits.
///
/// <p>Mirrors the web's `recentAirportsStore` (Zustand). Records are
/// capped at [_maxEntries] — the oldest entry falls off when the
/// list overflows. Recording the same IATA twice de-duplicates: the
/// existing entry is moved to position 0 with a refreshed timestamp,
/// not appended a second time.
class RecentAirportsNotifier extends Notifier<List<RecentAirport>> {
  static const _key = 'recent_airports_v1';
  static const _maxEntries = 20;

  @override
  List<RecentAirport> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      state = (jsonDecode(raw) as List)
          .map((e) => RecentAirport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  /// Record a visit. Pulls an existing entry to the top instead of
  /// duplicating it; trims the tail to respect [_maxEntries].
  void record({required String iata, String? city, String? country}) {
    final code = iata.trim().toUpperCase();
    if (code.isEmpty) return;

    final filtered = state.where((e) => e.iata != code).toList();
    final next = [
      RecentAirport(iata: code, city: city, country: country),
      ...filtered,
    ];
    state = next.length > _maxEntries
        ? next.sublist(0, _maxEntries)
        : next;
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}

final recentAirportsProvider =
    NotifierProvider<RecentAirportsNotifier, List<RecentAirport>>(
        RecentAirportsNotifier.new);
